import re
import json
from typing import Dict, Any, Optional
import anthropic
from app.config import settings

STRUCTURED_EXTRACTION_PROMPT = """You are a medical data extraction assistant.
Extract structured data from the following OCR text from a medical test report.

Return a JSON object with this exact structure:
{{
  "test_name": "name of the test",
  "lab_name": "name of the laboratory",
  "patient_name": "patient name if visible",
  "report_date": "date of report",
  "doctor_name": "referring doctor if visible",
  "data_type": "one of: blood_test, urinalysis, lipid_panel, metabolic_panel, thyroid, xray_report, mri_report, other",
  "results": [
    {{
      "parameter": "parameter name",
      "value": "measured value",
      "unit": "unit of measurement",
      "reference_range": "normal range",
      "flag": "normal, high, low, or critical"
    }}
  ]
}}

If a field is not found, use null. Extract ALL parameters visible.

OCR TEXT:
{text}

Respond with ONLY the JSON object, no other text."""


async def parse_structured_data(raw_text: str) -> Optional[Dict[str, Any]]:
    if not raw_text or len(raw_text.strip()) < 10:
        return None

    try:
        client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        message = client.messages.create(
            model=settings.LLM_MODEL,
            max_tokens=2000,
            messages=[{"role": "user", "content": STRUCTURED_EXTRACTION_PROMPT.format(text=raw_text[:4000])}],
        )
        response_text = message.content[0].text.strip()

        if response_text.startswith("```"):
            response_text = re.sub(r"```json?\n?", "", response_text)
            response_text = response_text.replace("```", "").strip()

        return json.loads(response_text)
    except Exception:
        return _regex_extract(raw_text)


def _regex_extract(text: str) -> Dict[str, Any]:
    results = []
    pattern = r"([A-Za-z][A-Za-z\s/\-]+)\s*:\s*([\d.]+)\s*([a-zA-Z/%]+)?\s*(?:\(?([\d.\-]+\s*[-]\s*[\d.]+)\)?)?"
    for match in re.findall(pattern, text):
        param, value, unit, ref_range = match
        param = param.strip()
        if 2 < len(param) < 60:
            results.append({
                "parameter": param,
                "value": value,
                "unit": unit.strip() if unit else None,
                "reference_range": ref_range.strip() if ref_range else None,
                "flag": "unknown",
            })
    return {"test_name": "Unknown", "lab_name": None, "data_type": "other", "results": results[:50]}
