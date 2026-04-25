import logging
import uuid
from difflib import SequenceMatcher
from typing import Any, Dict, Optional

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.ocr.constants import (
    BLOOD_PARAMETER_ALIASES,
    DATA_TYPE_KEYWORDS,
    PATIENT_ALIASES,
    REPORT_ALIASES,
    RESULT_ALIASES,
    UNIT_NORMALIZATION,
    URINE_PARAMETER_ALIASES,
)
from app.modules.ocr.extractor import extract_text_from_bytes
from app.modules.ocr.parser import parse_structured_data
from app.modules.ocr.shared import (
    fuzzy_pick,
    infer_flag,
    normalize_key,
    parse_reference_range,
    to_float,
    to_int,
    to_text,
)
from app.modules.reports.models import (
    BloodTestReport,
    BloodTestResult,
    ExtractedReportData,
    MedicalReport,
    RadiologyReport,
    UrineTestReport,
    UrineTestResult,
)
from app.modules.reports.storage import download_file

logger = logging.getLogger(__name__)

LAB_REPORT_CONFIG = {
    "blood_report": (BloodTestReport, BloodTestResult, "blood_report_id"),
    "urine_report": (UrineTestReport, UrineTestResult, "urine_report_id"),
}

TYPED_REPORT_MODELS = {
    "blood_report": BloodTestReport,
    "urine_report": UrineTestReport,
    "radiology_report": RadiologyReport,
}


def _similarity(left: str, right: str) -> float:
    return SequenceMatcher(None, left, right).ratio()


def _normalize_data_type(value: Optional[str], report_type: Optional[str], structured: Dict[str, Any]) -> str:
    hints = " ".join(
        to_text(candidate) or ""
        for candidate in [
            value,
            report_type,
            structured.get("test_name"),
            structured.get("report_meta", {}).get("test_name") if isinstance(structured.get("report_meta"), dict) else None,
            structured.get("radiology", {}).get("modality") if isinstance(structured.get("radiology"), dict) else None,
        ]
    ).lower()

    for data_type, keywords in DATA_TYPE_KEYWORDS.items():
        if any(keyword in hints for keyword in keywords):
            return data_type

    results = structured.get("results")
    if isinstance(results, list) and results:
        return "blood_report"
    return "other"


def _canonical_parameter_name(raw_name: Optional[str], data_type: str) -> Optional[str]:
    if not raw_name:
        return None

    aliases = BLOOD_PARAMETER_ALIASES if data_type == "blood_report" else URINE_PARAMETER_ALIASES
    normalized = normalize_key(raw_name)

    for canonical, alias_list in aliases.items():
        if normalized == normalize_key(canonical) or any(normalized == normalize_key(alias) for alias in alias_list):
            return canonical

    best_score = 0.0
    best_match = None
    for canonical, alias_list in aliases.items():
        for candidate in [canonical, *alias_list]:
            score = _similarity(normalized, normalize_key(candidate))
            if score > best_score:
                best_score = score
                best_match = canonical

    if best_match and best_score >= 0.8:
        return best_match

    return raw_name.strip().lower().replace(" ", "_")


def _normalize_unit(unit: Optional[str]) -> Optional[str]:
    if not unit:
        return None
    normalized = unit.strip()
    return UNIT_NORMALIZATION.get(normalized.lower(), normalized)


def _extract_common_metadata(structured: Dict[str, Any]) -> Dict[str, Optional[str]]:
    patient_info = structured.get("patient_info") if isinstance(structured.get("patient_info"), dict) else {}
    report_meta = structured.get("report_meta") if isinstance(structured.get("report_meta"), dict) else {}

    return {
        "patient_name": to_text(fuzzy_pick(patient_info, PATIENT_ALIASES["name"])) or to_text(structured.get("patient_name")),
        "patient_identifier": to_text(fuzzy_pick(patient_info, PATIENT_ALIASES["patient_id"])),
        "lab_name": to_text(fuzzy_pick(report_meta, REPORT_ALIASES["lab_name"])) or to_text(structured.get("lab_name")),
        "doctor_name": to_text(fuzzy_pick(report_meta, REPORT_ALIASES["doctor_name"])) or to_text(structured.get("doctor_name")),
        "report_date": to_text(fuzzy_pick(report_meta, REPORT_ALIASES["report_date"])) or to_text(structured.get("report_date")),
        "study_name": to_text(fuzzy_pick(report_meta, REPORT_ALIASES["test_name"])) or to_text(structured.get("test_name")),
    }


def _extract_result_payload(item: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    raw_parameter = to_text(fuzzy_pick(item, RESULT_ALIASES["parameter"]))
    if not raw_parameter:
        return None

    value_text = to_text(fuzzy_pick(item, RESULT_ALIASES["value"]))
    value_num = to_float(fuzzy_pick(item, RESULT_ALIASES["value_num"]))
    if value_num is None:
        value_num = to_float(value_text)

    reference_range = to_text(fuzzy_pick(item, RESULT_ALIASES["reference_range"]))
    ref_low = to_float(fuzzy_pick(item, RESULT_ALIASES["ref_low"]))
    ref_high = to_float(fuzzy_pick(item, RESULT_ALIASES["ref_high"]))
    if ref_low is None and ref_high is None:
        ref_low, ref_high = parse_reference_range(reference_range)

    flag = to_text(fuzzy_pick(item, RESULT_ALIASES["flag"]))

    return {
        "raw_parameter": raw_parameter,
        "value_text": value_text,
        "value_num": value_num,
        "unit": _normalize_unit(to_text(fuzzy_pick(item, RESULT_ALIASES["unit"]))),
        "reference_range": reference_range,
        "ref_low": ref_low,
        "ref_high": ref_high,
        "flag": infer_flag(flag, value_num, ref_low, ref_high),
        "source_confidence": to_float(fuzzy_pick(item, RESULT_ALIASES["source_confidence"])),
        "source_page": to_int(fuzzy_pick(item, RESULT_ALIASES["source_page"])),
    }


async def _get_medical_report(db: AsyncSession, report_uuid: uuid.UUID) -> Optional[MedicalReport]:
    result = await db.execute(select(MedicalReport).where(MedicalReport.id == report_uuid))
    return result.scalar_one_or_none()


async def _get_or_create_typed_report(db: AsyncSession, model: Any, report_uuid: uuid.UUID) -> Any:
    result = await db.execute(select(model).where(model.report_id == report_uuid))
    typed_report = result.scalar_one_or_none()
    if typed_report is None:
        typed_report = model(report_id=report_uuid)
        db.add(typed_report)
        await db.flush()
    return typed_report


async def _delete_non_matching_typed_reports(report_uuid: uuid.UUID, keep_type: str, db: AsyncSession) -> None:
    for data_type, model in TYPED_REPORT_MODELS.items():
        if data_type == keep_type:
            continue

        result = await db.execute(select(model).where(model.report_id == report_uuid))
        existing = result.scalar_one_or_none()
        if existing is not None:
            await db.delete(existing)


async def _upsert_lab_report(
    report_uuid: uuid.UUID,
    structured: Dict[str, Any],
    db: AsyncSession,
    report_model: Any,
    result_model: Any,
    result_fk_column: str,
    data_type: str,
) -> None:
    metadata = _extract_common_metadata(structured)
    typed_report = await _get_or_create_typed_report(db, report_model, report_uuid)

    typed_report.patient_name = metadata["patient_name"]
    typed_report.patient_identifier = metadata["patient_identifier"]
    typed_report.lab_name = metadata["lab_name"]
    typed_report.doctor_name = metadata["doctor_name"]
    typed_report.report_date = metadata["report_date"]
    typed_report.raw_metadata = {
        "patient_info": structured.get("patient_info"),
        "report_meta": structured.get("report_meta"),
        "test_name": metadata["study_name"],
    }

    # Recreate rows each run to keep inserts deterministic.
    await db.execute(delete(result_model).where(getattr(result_model, result_fk_column) == typed_report.id))

    for item in structured.get("results", []):
        if not isinstance(item, dict):
            continue

        payload = _extract_result_payload(item)
        if payload is None:
            continue

        db.add(
            result_model(
                **{
                    result_fk_column: typed_report.id,
                    "raw_parameter": payload["raw_parameter"],
                    "canonical_parameter": _canonical_parameter_name(payload["raw_parameter"], data_type),
                    "value_text": payload["value_text"],
                    "value_num": payload["value_num"],
                    "unit": payload["unit"],
                    "reference_range": payload["reference_range"],
                    "ref_low": payload["ref_low"],
                    "ref_high": payload["ref_high"],
                    "flag": payload["flag"],
                    "source_confidence": payload["source_confidence"],
                    "source_page": payload["source_page"],
                }
            )
        )


async def _upsert_radiology_report(report_uuid: uuid.UUID, structured: Dict[str, Any], db: AsyncSession) -> None:
    metadata = _extract_common_metadata(structured)
    radiology = structured.get("radiology") if isinstance(structured.get("radiology"), dict) else {}
    typed_report = await _get_or_create_typed_report(db, RadiologyReport, report_uuid)

    typed_report.patient_name = metadata["patient_name"]
    typed_report.patient_identifier = metadata["patient_identifier"]
    typed_report.lab_name = metadata["lab_name"]
    typed_report.doctor_name = metadata["doctor_name"]
    typed_report.report_date = metadata["report_date"]
    typed_report.study_name = metadata["study_name"]
    typed_report.modality = to_text(fuzzy_pick(radiology, ["modality", "scan_type", "study_type"]))
    typed_report.body_part = to_text(fuzzy_pick(radiology, ["body_part", "region", "examined_part"]))
    typed_report.findings = to_text(fuzzy_pick(radiology, ["findings", "observation", "description"]))
    typed_report.impression = to_text(fuzzy_pick(radiology, ["impression", "conclusion", "summary"]))
    typed_report.recommendation = to_text(fuzzy_pick(radiology, ["recommendation", "advice", "suggestion"]))
    typed_report.raw_metadata = {
        "patient_info": structured.get("patient_info"),
        "report_meta": structured.get("report_meta"),
        "radiology": radiology,
    }


async def _upsert_typed_report_tables(
    report_uuid: uuid.UUID,
    data_type: str,
    structured: Dict[str, Any],
    db: AsyncSession,
) -> None:
    await _delete_non_matching_typed_reports(report_uuid, data_type, db)

    if data_type in LAB_REPORT_CONFIG:
        report_model, result_model, result_fk_column = LAB_REPORT_CONFIG[data_type]
        await _upsert_lab_report(
            report_uuid=report_uuid,
            structured=structured,
            db=db,
            report_model=report_model,
            result_model=result_model,
            result_fk_column=result_fk_column,
            data_type=data_type,
        )
        return

    if data_type == "radiology_report":
        await _upsert_radiology_report(report_uuid, structured, db)


async def _upsert_extracted_data(
    report_uuid: uuid.UUID,
    data_type: str,
    structured: Dict[str, Any],
    db: AsyncSession,
) -> None:
    result = await db.execute(select(ExtractedReportData).where(ExtractedReportData.report_id == report_uuid))
    extracted = result.scalar_one_or_none()

    if extracted is None:
        db.add(ExtractedReportData(report_id=report_uuid, data=structured, data_type=data_type))
        return

    extracted.data = structured
    extracted.data_type = data_type


def _enrich_structured_payload(
    structured: Dict[str, Any],
    data_type: str,
    confidence: float,
    ocr_payload: Dict[str, Any],
) -> Dict[str, Any]:
    structured["data_type"] = data_type
    structured.setdefault("ocr_meta", {})

    if isinstance(structured["ocr_meta"], dict):
        structured["ocr_meta"]["avg_confidence"] = confidence
        structured["ocr_meta"]["engines_used"] = ocr_payload.get("engines_used", [])
        structured["ocr_meta"]["pages"] = len(ocr_payload.get("pages", []))

    return structured


async def run_ocr_pipeline(report_id: str, db: AsyncSession) -> bool:
    """Run OCR extraction, structure parsing, and normalized persistence for one report."""
    try:
        report_uuid = uuid.UUID(report_id)
    except ValueError:
        logger.warning("OCR pipeline received invalid report id: %s", report_id)
        return False

    report = await _get_medical_report(db, report_uuid)
    if report is None:
        return False

    report.ocr_status = "processing"
    await db.commit()

    try:
        file_bytes = await download_file(report.file_url)
        file_type = report.file_type or "jpg"
        raw_text, confidence, ocr_payload = await extract_text_from_bytes(file_bytes, file_type)

        structured = await parse_structured_data(raw_text, ocr_payload) or {}
        data_type = _normalize_data_type(structured.get("data_type"), report.report_type, structured)
        structured = _enrich_structured_payload(structured, data_type, confidence, ocr_payload)

        report.ocr_raw_text = raw_text
        report.ocr_confidence = confidence
        report.ocr_status = "extracted"

        await _upsert_extracted_data(report_uuid, data_type, structured, db)
        await _upsert_typed_report_tables(report_uuid, data_type, structured, db)

        await db.commit()
        return True
    except Exception:
        logger.exception("OCR pipeline failed for report_id=%s", report_id)
        try:
            report.ocr_status = "failed"
            await db.commit()
        except Exception:
            await db.rollback()
        raise
