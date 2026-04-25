import logging
import json
import re
from typing import Any, Dict, List, Optional

import anthropic
import httpx

from app.config import settings
from app.modules.ocr.constants import (
    DATA_TYPE_KEYWORDS,
    PATIENT_ALIASES,
    RADIOLOGY_ALIASES,
    REPORT_ALIASES,
    RESULT_ALIASES,
    STRUCTURED_EXTRACTION_PROMPT,
    TOP_LEVEL_ALIASES,
)
from app.modules.ocr.shared import (
    fuzzy_pick,
    infer_flag,
    normalize_key,
    normalize_whitespace,
    parse_reference_range,
    to_float,
    to_text,
)

logger = logging.getLogger(__name__)

CODE_BLOCK_PREFIX = "```"
CODE_BLOCK_STRIP_RE = re.compile(r"```json?\n?|```", re.IGNORECASE)

COLON_PATTERN = re.compile(
    r"^(?P<parameter>[A-Za-z][A-Za-z0-9\s/()\-+%]{1,80})\s*[:=]\s*(?P<value>-?\d+(?:\.\d+)?)\s*(?P<unit>[A-Za-z/%^0-9]+)?\s*(?P<range>(?:[<>]=?\s*)?-?\d+(?:\.\d+)?\s*(?:-|–|—|to)?\s*-?\d*(?:\.\d+)?)?$",
    flags=re.IGNORECASE,
)
TABLE_PATTERN = re.compile(
    r"^(?P<parameter>[A-Za-z][A-Za-z0-9\s/()\-+%]{1,80})\s{2,}(?P<value>-?\d+(?:\.\d+)?)\s*(?P<unit>[A-Za-z/%^0-9]+)?\s*(?P<range>(?:[<>]=?\s*)?-?\d+(?:\.\d+)?\s*(?:-|–|—|to)?\s*-?\d*(?:\.\d+)?)?$",
    flags=re.IGNORECASE,
)


def _build_structured_prompt(llm_input_text: str) -> str:
    # Use placeholder replacement instead of str.format so JSON braces in the template remain literal.
    return STRUCTURED_EXTRACTION_PROMPT.replace("{text}", llm_input_text[:12000])


def _decode_llm_json(response_text: str) -> Dict[str, Any]:
    candidate = response_text.strip()
    if candidate.startswith(CODE_BLOCK_PREFIX):
        candidate = CODE_BLOCK_STRIP_RE.sub("", candidate).strip()

    decoded = json.loads(candidate)
    return decoded if isinstance(decoded, dict) else {}


def _extract_text_from_llm_content(content: Any) -> str:
    if isinstance(content, str):
        return content.strip()

    if isinstance(content, list):
        text_parts: List[str] = []
        for item in content:
            if isinstance(item, str):
                text_parts.append(item)
                continue

            if isinstance(item, dict):
                text = item.get("text")
                if isinstance(text, str):
                    text_parts.append(text)
                    continue

            text = getattr(item, "text", None)
            if isinstance(text, str):
                text_parts.append(text)

        return "\n".join(part.strip() for part in text_parts if part).strip()

    text = getattr(content, "text", None)
    if isinstance(text, str):
        return text.strip()

    return ""


def _parse_with_anthropic(llm_input_text: str) -> Dict[str, Any]:
    client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
    message = client.messages.create(
        model=settings.LLM_MODEL,
        max_tokens=2500,
        messages=[{"role": "user", "content": _build_structured_prompt(llm_input_text)}],
    )
    response_text = _extract_text_from_llm_content(message.content)
    if not response_text:
        return {}
    return _decode_llm_json(response_text)


async def _parse_with_openrouter(llm_input_text: str) -> Dict[str, Any]:
    base_url = settings.OPENROUTER_BASE_URL.rstrip("/")
    url = f"{base_url}/chat/completions"

    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }
    if settings.OPENROUTER_SITE_URL:
        headers["HTTP-Referer"] = settings.OPENROUTER_SITE_URL
    if settings.OPENROUTER_APP_NAME:
        headers["X-Title"] = settings.OPENROUTER_APP_NAME

    payload = {
        "model": settings.OPENROUTER_MODEL,
        "messages": [
            {
                "role": "user",
                "content": _build_structured_prompt(llm_input_text),
            }
        ],
        "temperature": 0,
        "max_tokens": 2500,
    }

    timeout = httpx.Timeout(45.0, connect=10.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(url, headers=headers, json=payload)
        response.raise_for_status()
        body = response.json()

    choices = body.get("choices") if isinstance(body, dict) else None
    if not isinstance(choices, list) or not choices:
        return {}

    first_choice = choices[0]
    if not isinstance(first_choice, dict):
        return {}

    message = first_choice.get("message")
    if not isinstance(message, dict):
        return {}

    response_text = _extract_text_from_llm_content(message.get("content"))
    if not response_text:
        return {}

    return _decode_llm_json(response_text)


def _normalize_result_item(item: Any) -> Optional[Dict[str, Any]]:
    if isinstance(item, str):
        return _regex_extract_line(item)

    if not isinstance(item, dict):
        return None

    parameter = to_text(fuzzy_pick(item, RESULT_ALIASES["parameter"]))
    value = to_text(fuzzy_pick(item, RESULT_ALIASES["value"]))
    unit = to_text(fuzzy_pick(item, RESULT_ALIASES["unit"]))
    reference_range = to_text(fuzzy_pick(item, RESULT_ALIASES["reference_range"]))
    flag = to_text(fuzzy_pick(item, RESULT_ALIASES["flag"]))

    value_num = to_float(fuzzy_pick(item, RESULT_ALIASES["value_num"]))
    if value_num is None:
        value_num = to_float(value)

    ref_low = to_float(fuzzy_pick(item, RESULT_ALIASES["ref_low"]))
    ref_high = to_float(fuzzy_pick(item, RESULT_ALIASES["ref_high"]))
    if ref_low is None and ref_high is None:
        ref_low, ref_high = parse_reference_range(reference_range)

    confidence = to_float(fuzzy_pick(item, RESULT_ALIASES["source_confidence"]))

    if not parameter and not value:
        return None

    return {
        "parameter": parameter,
        "value": value,
        "value_num": value_num,
        "unit": unit,
        "reference_range": reference_range,
        "ref_low": ref_low,
        "ref_high": ref_high,
        "flag": infer_flag(flag, value_num, ref_low, ref_high),
        "source_confidence": confidence,
    }


def _regex_extract_line(line: str) -> Optional[Dict[str, Any]]:
    clean = normalize_whitespace(line)
    if not clean or len(clean) < 4:
        return None

    colon_pattern = COLON_PATTERN.search(clean)
    if colon_pattern:
        parameter = to_text(colon_pattern.group("parameter"))
        value = to_text(colon_pattern.group("value"))
        unit = to_text(colon_pattern.group("unit"))
        ref_range = to_text(colon_pattern.group("range"))
        ref_low, ref_high = parse_reference_range(ref_range)
        value_num = to_float(value)
        return {
            "parameter": parameter,
            "value": value,
            "value_num": value_num,
            "unit": unit,
            "reference_range": ref_range,
            "ref_low": ref_low,
            "ref_high": ref_high,
            "flag": infer_flag(None, value_num, ref_low, ref_high),
            "source_confidence": None,
        }

    table_pattern = TABLE_PATTERN.search(clean)
    if not table_pattern:
        return None

    parameter = to_text(table_pattern.group("parameter"))
    value = to_text(table_pattern.group("value"))
    unit = to_text(table_pattern.group("unit"))
    ref_range = to_text(table_pattern.group("range"))
    ref_low, ref_high = parse_reference_range(ref_range)
    value_num = to_float(value)
    return {
        "parameter": parameter,
        "value": value,
        "value_num": value_num,
        "unit": unit,
        "reference_range": ref_range,
        "ref_low": ref_low,
        "ref_high": ref_high,
        "flag": infer_flag(None, value_num, ref_low, ref_high),
        "source_confidence": None,
    }


def _regex_extract_results(text: str) -> List[Dict[str, Any]]:
    extracted: List[Dict[str, Any]] = []
    seen = set()

    for line in text.splitlines():
        parsed = _regex_extract_line(line)
        if not parsed:
            continue

        key = (
            normalize_key(parsed.get("parameter") or ""),
            normalize_key(parsed.get("value") or ""),
        )
        if key in seen:
            continue
        seen.add(key)
        extracted.append(parsed)

    return extracted[:200]


def _normalize_data_type(value: Optional[str], full_text: str) -> str:
    direct = normalize_key(value or "")
    direct_map = {
        "bloodtest": "blood_report",
        "bloodreport": "blood_report",
        "lipidpanel": "blood_report",
        "metabolicpanel": "blood_report",
        "thyroid": "blood_report",
        "urinalysis": "urine_report",
        "urinereport": "urine_report",
        "urinetest": "urine_report",
        "xrayreport": "radiology_report",
        "mrireport": "radiology_report",
        "radiologyreport": "radiology_report",
        "ctreport": "radiology_report",
    }
    if direct in direct_map:
        return direct_map[direct]

    lowered = full_text.lower()
    for data_type, keywords in DATA_TYPE_KEYWORDS.items():
        if any(keyword in lowered for keyword in keywords):
            return data_type

    return "other"


def _extract_nested(mapping: Dict[str, Any], aliases: Dict[str, List[str]]) -> Dict[str, Optional[str]]:
    return {
        field: to_text(fuzzy_pick(mapping, field_aliases))
        for field, field_aliases in aliases.items()
    }


def _collect_table_lines(ocr_payload: Optional[Dict[str, Any]]) -> str:
    if not ocr_payload:
        return ""

    lines: List[str] = []
    for page in ocr_payload.get("pages", []):
        for line in page.get("tables", []):
            normalized = to_text(line)
            if normalized:
                lines.append(normalized)

    return "\n".join(lines[:1200])


def _normalize_payload(payload: Dict[str, Any], raw_text: str) -> Dict[str, Any]:
    patient_raw = fuzzy_pick(payload, TOP_LEVEL_ALIASES["patient_info"])
    if not isinstance(patient_raw, dict):
        patient_raw = {}

    report_raw = fuzzy_pick(payload, TOP_LEVEL_ALIASES["report_meta"])
    if not isinstance(report_raw, dict):
        report_raw = {}

    radiology_raw = fuzzy_pick(payload, TOP_LEVEL_ALIASES["radiology"])
    if not isinstance(radiology_raw, dict):
        radiology_raw = {}

    patient_info = _extract_nested(patient_raw, PATIENT_ALIASES)
    if not patient_info["name"]:
        patient_info["name"] = to_text(fuzzy_pick(payload, PATIENT_ALIASES["name"]))
    if not patient_info["patient_id"]:
        patient_info["patient_id"] = to_text(fuzzy_pick(payload, PATIENT_ALIASES["patient_id"]))

    report_meta = _extract_nested(report_raw, REPORT_ALIASES)
    for field, aliases in REPORT_ALIASES.items():
        if not report_meta[field]:
            report_meta[field] = to_text(fuzzy_pick(payload, aliases))

    radiology = _extract_nested(radiology_raw, RADIOLOGY_ALIASES)
    for field, aliases in RADIOLOGY_ALIASES.items():
        if not radiology[field]:
            radiology[field] = to_text(fuzzy_pick(payload, aliases))

    results_raw = fuzzy_pick(payload, TOP_LEVEL_ALIASES["results"])
    if isinstance(results_raw, dict):
        nested = fuzzy_pick(results_raw, ["items", "rows", "results", "values"])
        if isinstance(nested, list):
            results_raw = nested
        else:
            results_raw = [results_raw]

    normalized_results: List[Dict[str, Any]] = []
    if isinstance(results_raw, list):
        for item in results_raw:
            normalized_item = _normalize_result_item(item)
            if normalized_item:
                normalized_results.append(normalized_item)

    fallback_results = _regex_extract_results(raw_text)
    if not normalized_results:
        normalized_results = fallback_results
    else:
        existing = {
            (normalize_key(row.get("parameter") or ""), normalize_key(row.get("value") or ""))
            for row in normalized_results
        }
        for row in fallback_results:
            key = (normalize_key(row.get("parameter") or ""), normalize_key(row.get("value") or ""))
            if key not in existing:
                normalized_results.append(row)

    combined_meta_text = " ".join(
        text for text in [
            raw_text,
            report_meta.get("test_name"),
            report_meta.get("lab_name"),
            radiology.get("modality"),
            radiology.get("findings"),
            report_meta.get("doctor_name"),
        ]
        if text
    )
    data_type = _normalize_data_type(to_text(fuzzy_pick(payload, TOP_LEVEL_ALIASES["data_type"])), combined_meta_text)

    return {
        "patient_info": patient_info,
        "report_meta": report_meta,
        "data_type": data_type,
        "results": normalized_results,
        "radiology": radiology,
        "test_name": report_meta.get("test_name"),
        "lab_name": report_meta.get("lab_name"),
        "patient_name": patient_info.get("name"),
        "report_date": report_meta.get("report_date"),
        "doctor_name": report_meta.get("doctor_name"),
    }


async def parse_structured_data(raw_text: str, ocr_payload: Optional[Dict[str, Any]] = None) -> Optional[Dict[str, Any]]:
    if not raw_text or len(raw_text.strip()) < 10:
        return None

    table_lines = _collect_table_lines(ocr_payload)
    llm_input_text = raw_text
    if table_lines:
        llm_input_text = f"{raw_text}\n\nTABLE LINES:\n{table_lines}"

    parsed_payload: Dict[str, Any] = {}

    if settings.ANTHROPIC_API_KEY:
        try:
            parsed_payload = _parse_with_anthropic(llm_input_text)
        except Exception:
            logger.exception("Anthropic structured parsing failed; trying OpenRouter if configured")

    if not parsed_payload and settings.OPENROUTER_API_KEY:
        try:
            parsed_payload = await _parse_with_openrouter(llm_input_text)
        except Exception:
            logger.exception("OpenRouter structured parsing failed; using deterministic fallback")

    normalized = _normalize_payload(parsed_payload, llm_input_text)
    if not normalized.get("results") and normalized.get("data_type") != "radiology_report":
        normalized["results"] = _regex_extract_results(llm_input_text)

    return normalized
