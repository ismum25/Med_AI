import difflib
import re
from typing import Any, Dict, Iterable, List, Optional, Tuple


def normalize_whitespace(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def normalize_key(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", str(value).lower())


def to_text(value: Any) -> Optional[str]:
    if value is None:
        return None
    text = normalize_whitespace(str(value))
    return text or None


def to_float(value: Any) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)

    match = re.search(r"-?\d+(?:\.\d+)?", str(value).replace(",", ""))
    if not match:
        return None

    try:
        return float(match.group(0))
    except ValueError:
        return None


def to_int(value: Any) -> Optional[int]:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def parse_reference_range(reference_range: Optional[str]) -> Tuple[Optional[float], Optional[float]]:
    if not reference_range:
        return None, None

    text = reference_range.replace("to", "-")
    span = re.search(r"(-?\d+(?:\.\d+)?)\s*(?:-|–|—)\s*(-?\d+(?:\.\d+)?)", text)
    if span:
        return float(span.group(1)), float(span.group(2))

    lower = re.search(r">=?\s*(-?\d+(?:\.\d+)?)", text)
    upper = re.search(r"<=?\s*(-?\d+(?:\.\d+)?)", text)

    low = float(lower.group(1)) if lower else None
    high = float(upper.group(1)) if upper else None
    return low, high


def infer_flag(
    existing_flag: Optional[str],
    value_num: Optional[float],
    ref_low: Optional[float],
    ref_high: Optional[float],
) -> str:
    if existing_flag:
        normalized_flag = existing_flag.strip().lower()
        if normalized_flag in {"normal", "high", "low", "critical", "unknown"}:
            return normalized_flag

    if value_num is None:
        return "unknown"
    if ref_low is not None and value_num < ref_low:
        return "low"
    if ref_high is not None and value_num > ref_high:
        return "high"
    if ref_low is not None or ref_high is not None:
        return "normal"
    return "unknown"


def fuzzy_pick(mapping: Dict[str, Any], aliases: Iterable[str], threshold: float = 0.78) -> Any:
    if not isinstance(mapping, dict):
        return None

    normalized = {normalize_key(key): value for key, value in mapping.items()}
    normalized_aliases = [normalize_key(alias) for alias in aliases]

    for alias in normalized_aliases:
        if alias in normalized:
            return normalized[alias]

    best_score = 0.0
    best_value: Any = None
    for key, value in normalized.items():
        for alias in normalized_aliases:
            score = difflib.SequenceMatcher(None, key, alias).ratio()
            if score > best_score:
                best_score = score
                best_value = value

    return best_value if best_score >= threshold else None


def collect_text_fragments(payload: Any) -> List[str]:
    if isinstance(payload, str):
        candidate = normalize_whitespace(payload)
        if candidate and any(ch.isalnum() for ch in candidate):
            return [candidate]
        return []

    fragments: List[str] = []
    if isinstance(payload, dict):
        for value in payload.values():
            fragments.extend(collect_text_fragments(value))
        return fragments

    if isinstance(payload, (list, tuple)):
        for value in payload:
            fragments.extend(collect_text_fragments(value))

    return fragments
