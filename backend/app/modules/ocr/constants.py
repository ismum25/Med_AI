STRUCTURED_EXTRACTION_PROMPT = """You are a medical data extraction assistant.
Extract structured data from OCR text from medical lab/radiology reports.

Return ONLY valid JSON with this exact schema:
{
  "patient_info": {
    "name": "patient name",
    "age": "age if available",
    "sex": "sex/gender if available",
    "patient_id": "patient identifier if available"
  },
  "report_meta": {
    "test_name": "panel/report name",
    "lab_name": "lab/hospital name",
    "report_date": "report date",
    "doctor_name": "doctor/referrer name"
  },
  "data_type": "one of: blood_report, urine_report, radiology_report, other",
  "results": [
    {
      "parameter": "parameter/test name",
      "value": "measured value",
      "unit": "unit",
      "reference_range": "normal range",
      "flag": "normal/high/low/critical/unknown"
    }
  ],
  "radiology": {
    "modality": "xray/mri/ct/usg/etc",
    "body_part": "examined region",
    "findings": "findings text",
    "impression": "impression text",
    "recommendation": "recommendation text"
  }
}

Rules:
- Use null when missing.
- Extract all rows from tables into results.
- Keep units and reference ranges exactly if possible.
- If report is radiology and no numeric labs exist, keep results empty.

OCR TEXT:
{text}
"""

TOP_LEVEL_ALIASES = {
    "patient_info": ["patient_info", "patient", "patient_details", "patientdata"],
    "report_meta": ["report_meta", "report", "metadata", "report_details", "meta"],
    "data_type": ["data_type", "report_type", "type", "category"],
    "results": ["results", "tests", "observations", "parameters", "values", "table_rows"],
    "radiology": ["radiology", "imaging", "radiology_report", "scan", "study"],
}

PATIENT_ALIASES = {
    "name": ["name", "patient_name", "full_name"],
    "age": ["age", "patient_age"],
    "sex": ["sex", "gender"],
    "patient_id": ["patient_id", "id", "registration_no", "uhid", "mrn"],
}

REPORT_ALIASES = {
    "test_name": ["test_name", "report_name", "panel_name", "investigation", "study_name"],
    "lab_name": ["lab_name", "laboratory", "lab", "hospital_name", "diagnostic_center"],
    "report_date": ["report_date", "date", "collection_date", "issued_on"],
    "doctor_name": ["doctor_name", "consultant", "referring_doctor", "physician"],
}

RESULT_ALIASES = {
    "parameter": ["parameter", "test", "test_name", "name", "analyte", "investigation"],
    "value": ["value", "result", "observed", "reading"],
    "unit": ["unit", "units"],
    "reference_range": ["reference_range", "range", "normal_range", "bio_reference", "ref_range"],
    "flag": ["flag", "status", "interpretation"],
    "value_num": ["value_num", "numeric_value", "result_num"],
    "ref_low": ["ref_low", "range_low", "lower_limit"],
    "ref_high": ["ref_high", "range_high", "upper_limit"],
    "source_confidence": ["source_confidence", "confidence", "ocr_confidence"],
    "source_page": ["source_page", "page"],
}

RADIOLOGY_ALIASES = {
    "modality": ["modality", "scan_type", "study_type"],
    "body_part": ["body_part", "region", "examined_part", "anatomy"],
    "findings": ["findings", "observation", "description"],
    "impression": ["impression", "conclusion", "summary"],
    "recommendation": ["recommendation", "advice", "suggestion"],
}

DATA_TYPE_KEYWORDS = {
    "blood_report": [
        "cbc",
        "complete blood",
        "hemoglobin",
        "hgb",
        "wbc",
        "rbc",
        "platelet",
        "lipid",
        "thyroid",
        "hba1c",
        "serum",
    ],
    "urine_report": [
        "urine",
        "urinalysis",
        "specific gravity",
        "leukocyte",
        "nitrite",
        "epithelial",
        "pus cell",
    ],
    "radiology_report": [
        "x-ray",
        "xray",
        "mri",
        "ct",
        "ultrasound",
        "usg",
        "impression",
        "findings",
        "radiology",
    ],
}

BLOOD_PARAMETER_ALIASES = {
    "hemoglobin": ["hb", "hgb", "haemoglobin", "hemoglobin"],
    "wbc": ["wbc", "white blood cell", "white blood cells", "tlc", "leukocyte"],
    "rbc": ["rbc", "red blood cell", "red blood cells"],
    "platelet_count": ["platelet", "platelet count", "plt"],
    "glucose": ["glucose", "blood sugar", "fbs", "rbs"],
    "cholesterol_total": ["total cholesterol", "cholesterol"],
    "hdl": ["hdl", "hdl cholesterol"],
    "ldl": ["ldl", "ldl cholesterol"],
    "triglycerides": ["triglycerides", "tg"],
    "creatinine": ["creatinine", "serum creatinine"],
    "urea": ["urea", "blood urea", "bun"],
    "tsh": ["tsh", "thyroid stimulating hormone"],
}

URINE_PARAMETER_ALIASES = {
    "ph": ["ph", "reaction", "urine ph"],
    "specific_gravity": ["specific gravity", "sp gravity", "sg"],
    "protein": ["protein", "albumin"],
    "glucose": ["glucose", "sugar"],
    "ketones": ["ketone", "ketones"],
    "bilirubin": ["bilirubin"],
    "urobilinogen": ["urobilinogen"],
    "nitrite": ["nitrite", "nitrate"],
    "leukocyte_esterase": ["leukocyte", "leukocyte esterase", "leucocyte"],
    "rbc": ["rbc", "red blood cell", "red cells"],
    "wbc": ["wbc", "white blood cell", "pus cell", "pus cells"],
    "epithelial_cells": ["epithelial cells", "epithelial cell"],
}

UNIT_NORMALIZATION = {
    "mg/dl": "mg/dL",
    "g/dl": "g/dL",
    "mmol/l": "mmol/L",
    "iu/l": "IU/L",
    "cells/hpf": "cells/HPF",
}
