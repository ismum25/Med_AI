import argparse
import difflib
import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from jiwer import cer, wer


def _normalize_key(value: str) -> str:
    return "".join(ch for ch in str(value).lower() if ch.isalnum())


def _normalize_unit(value: Optional[str]) -> str:
    if not value:
        return ""
    unit = value.strip().lower()
    mapping = {
        "mg/dl": "mg/dL",
        "g/dl": "g/dL",
        "mmol/l": "mmol/L",
        "iu/l": "IU/L",
        "cells/hpf": "cells/HPF",
    }
    return mapping.get(unit, value.strip())


def _to_float(value: Any) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)

    import re

    match = re.search(r"-?\d+(?:\.\d+)?", str(value).replace(",", ""))
    if not match:
        return None
    try:
        return float(match.group(0))
    except ValueError:
        return None


def text_metrics(reference_text: str, predicted_text: str) -> Dict[str, float]:
    return {
        "wer": float(wer(reference_text or "", predicted_text or "")),
        "cer": float(cer(reference_text or "", predicted_text or "")),
    }


def _parameter_match_score(left: str, right: str) -> float:
    return difflib.SequenceMatcher(None, _normalize_key(left), _normalize_key(right)).ratio()


def _extract_results(payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    results = payload.get("results", [])
    return results if isinstance(results, list) else []


def structured_metrics(
    ground_truth: Dict[str, Any],
    predicted: Dict[str, Any],
    value_tolerance: float = 0.01) -> Dict[str, float]:
    gt_rows = _extract_results(ground_truth)
    pred_rows = _extract_results(predicted)

    if not gt_rows and not pred_rows:
        return {
            "precision": 1.0,
            "recall": 1.0,
            "f1": 1.0,
            "value_accuracy": 1.0,
        }

    matched_pred_indices = set()
    true_positive = 0
    value_correct = 0

    for gt in gt_rows:
        gt_param = str(gt.get("parameter") or "")
        best_idx = None
        best_score = 0.0

        for idx, pred in enumerate(pred_rows):
            if idx in matched_pred_indices:
                continue
            pred_param = str(pred.get("parameter") or "")
            score = _parameter_match_score(gt_param, pred_param)
            if score > best_score:
                best_score = score
                best_idx = idx

        if best_idx is None or best_score < 0.8:
            continue

        matched_pred_indices.add(best_idx)
        true_positive += 1

        gt_value = _to_float(gt.get("value_num", gt.get("value")))
        pred_value = _to_float(pred_rows[best_idx].get("value_num", pred_rows[best_idx].get("value")))
        gt_unit = _normalize_unit(gt.get("unit"))
        pred_unit = _normalize_unit(pred_rows[best_idx].get("unit"))

        value_match = False
        if gt_value is None and pred_value is None:
            value_match = True
        elif gt_value is not None and pred_value is not None:
            value_match = abs(gt_value - pred_value) <= value_tolerance

        unit_match = (not gt_unit and not pred_unit) or (gt_unit == pred_unit)
        if value_match and unit_match:
            value_correct += 1

    false_positive = max(0, len(pred_rows) - true_positive)
    false_negative = max(0, len(gt_rows) - true_positive)

    precision = true_positive / (true_positive + false_positive) if (true_positive + false_positive) else 0.0
    recall = true_positive / (true_positive + false_negative) if (true_positive + false_negative) else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) else 0.0
    value_accuracy = value_correct / true_positive if true_positive else 0.0

    return {
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "value_accuracy": value_accuracy,
    }


def evaluate_record(record: Dict[str, Any], value_tolerance: float = 0.01) -> Dict[str, Any]:
    text = text_metrics(
        reference_text=record.get("ground_truth_text", ""),
        predicted_text=record.get("predicted_text", ""),
    )
    structured = structured_metrics(
        ground_truth=record.get("ground_truth_structured", {}) or {},
        predicted=record.get("predicted_structured", {}) or {},
        value_tolerance=value_tolerance,
    )
    return {
        "id": record.get("id"),
        "text": text,
        "structured": structured,
    }


def evaluate_dataset(records: List[Dict[str, Any]], value_tolerance: float = 0.01) -> Dict[str, Any]:
    evaluations = [evaluate_record(record, value_tolerance=value_tolerance) for record in records]
    total = len(evaluations) or 1

    avg_wer = sum(item["text"]["wer"] for item in evaluations) / total
    avg_cer = sum(item["text"]["cer"] for item in evaluations) / total
    avg_precision = sum(item["structured"]["precision"] for item in evaluations) / total
    avg_recall = sum(item["structured"]["recall"] for item in evaluations) / total
    avg_f1 = sum(item["structured"]["f1"] for item in evaluations) / total
    avg_value_accuracy = sum(item["structured"]["value_accuracy"] for item in evaluations) / total

    return {
        "summary": {
            "documents": len(evaluations),
            "avg_wer": avg_wer,
            "avg_cer": avg_cer,
            "avg_structured_precision": avg_precision,
            "avg_structured_recall": avg_recall,
            "avg_structured_f1": avg_f1,
            "avg_value_accuracy": avg_value_accuracy,
        },
        "per_document": evaluations,
    }


def _load_records(path: Path) -> List[Dict[str, Any]]:
    if path.suffix.lower() == ".jsonl":
        records: List[Dict[str, Any]] = []
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if line:
                    records.append(json.loads(line))
        return records

    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, list):
        return payload
    raise ValueError("Dataset file must be JSON array or JSONL.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate OCR quality using WER/CER and structured extraction metrics.")
    parser.add_argument("--dataset", required=True, help="Path to JSON/JSONL dataset with ground truth and predictions.")
    parser.add_argument("--value-tolerance", type=float, default=0.01, help="Allowed numeric delta for value matching.")
    parser.add_argument("--output", help="Optional path to write evaluation JSON output.")
    args = parser.parse_args()

    dataset_path = Path(args.dataset)
    records = _load_records(dataset_path)
    report = evaluate_dataset(records, value_tolerance=args.value_tolerance)

    if args.output:
        Path(args.output).write_text(json.dumps(report, indent=2), encoding="utf-8")
    else:
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
