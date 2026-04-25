import io
import importlib
import logging
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image, ImageEnhance, ImageFilter
import pytesseract

from app.config import settings
from app.modules.ocr.shared import collect_text_fragments, normalize_whitespace

logger = logging.getLogger(__name__)

_PADDLE_OCR: Any = None
_PP_STRUCTURE: Any = None


def preprocess_image(image: Image.Image) -> Image.Image:
    image = image.convert("L")
    image = ImageEnhance.Contrast(image).enhance(2.0)
    image = image.filter(ImageFilter.SHARPEN)
    return image


def _engine_priority() -> List[str]:
    value = getattr(settings, "OCR_ENGINE_PRIORITY", "paddle,surya,tesseract")
    engines = [normalize_whitespace(item).lower() for item in value.split(",") if item.strip()]
    return engines or ["tesseract"]


def _load_paddle_ocr() -> Optional[Any]:
    global _PADDLE_OCR

    if _PADDLE_OCR is not None:
        return _PADDLE_OCR

    try:
        paddleocr_module = importlib.import_module("paddleocr")
        PaddleOCR = getattr(paddleocr_module, "PaddleOCR")

        _PADDLE_OCR = PaddleOCR(
            use_angle_cls=True,
            lang=getattr(settings, "OCR_LANG", "en"),
            show_log=False,
            use_gpu=bool(getattr(settings, "OCR_USE_GPU", False)),
        )
    except Exception as exc:
        logger.warning("PaddleOCR unavailable. Falling back to next OCR engine. Reason: %s", exc)
        _PADDLE_OCR = None

    return _PADDLE_OCR


def _load_pp_structure() -> Optional[Any]:
    global _PP_STRUCTURE

    if _PP_STRUCTURE is not None:
        return _PP_STRUCTURE

    try:
        paddleocr_module = importlib.import_module("paddleocr")
        PPStructure = getattr(paddleocr_module, "PPStructure")

        _PP_STRUCTURE = PPStructure(
            layout=True,
            table=True,
            ocr=True,
            show_log=False,
        )
    except Exception as exc:
        logger.warning("PP-Structure unavailable. Continuing without table/layout parser. Reason: %s", exc)
        _PP_STRUCTURE = None

    return _PP_STRUCTURE


def _extract_with_tesseract(image: Image.Image) -> Dict[str, Any]:
    preprocessed = preprocess_image(image)
    data = pytesseract.image_to_data(preprocessed, output_type=pytesseract.Output.DICT)
    text = pytesseract.image_to_string(preprocessed).strip()

    confidences = [int(c) for c in data.get("conf", []) if str(c) != "-1" and int(c) > 0]
    avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0

    return {
        "engine": "tesseract",
        "text": text,
        "confidence": avg_confidence,
        "tables": [],
        "layout_blocks": [],
    }


def _extract_with_paddle(image: Image.Image) -> Optional[Dict[str, Any]]:
    paddle = _load_paddle_ocr()
    if paddle is None:
        return None

    try:
        import cv2
        import numpy as np

        np_img = cv2.cvtColor(np.array(image.convert("RGB")), cv2.COLOR_RGB2BGR)
        ocr_output = paddle.ocr(np_img, cls=True) or []

        line_texts: List[str] = []
        confidences: List[float] = []
        for block in ocr_output:
            for item in block or []:
                try:
                    text = str(item[1][0]).strip()
                    conf = float(item[1][1])
                    if text:
                        line_texts.append(text)
                    if conf >= 0:
                        confidences.append(conf * 100 if conf <= 1 else conf)
                except Exception:
                    continue

        table_lines: List[str] = []
        layout_blocks: List[Dict[str, Any]] = []

        pp_structure = _load_pp_structure()
        if pp_structure is not None:
            try:
                structured_blocks = pp_structure(np_img) or []
                for block in structured_blocks:
                    block_type = normalize_whitespace(str(block.get("type", "unknown")).lower())
                    text_fragments = collect_text_fragments(block.get("res"))

                    if text_fragments:
                        layout_blocks.append({
                            "type": block_type,
                            "text": text_fragments[:40],
                        })

                    if "table" in block_type and text_fragments:
                        table_lines.extend(text_fragments)
            except Exception as exc:
                logger.warning("PP-Structure failed on page: %s", exc)

        sections: List[str] = []
        if line_texts:
            sections.append("\n".join(line_texts))
        if table_lines:
            sections.append("TABLE CONTENT\n" + "\n".join(table_lines))

        combined_text = "\n\n".join(section for section in sections if section).strip()
        avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0

        return {
            "engine": "paddleocr",
            "text": combined_text,
            "confidence": avg_confidence,
            "tables": table_lines,
            "layout_blocks": layout_blocks,
        }
    except Exception as exc:
        logger.warning("PaddleOCR extraction failed on page: %s", exc)
        return None


def _extract_with_surya(image: Image.Image) -> Optional[Dict[str, Any]]:
    try:
        import numpy as np

        np_img = np.array(image.convert("RGB"))

        # Surya APIs vary across versions; try common entry points defensively.
        surya_ocr = importlib.import_module("surya.ocr")

        result: Any = None
        if hasattr(surya_ocr, "run_ocr"):
            result = surya_ocr.run_ocr(np_img)
        elif hasattr(surya_ocr, "predict"):
            result = surya_ocr.predict([np_img])

        text_fragments = collect_text_fragments(result)
        if not text_fragments:
            return None

        return {
            "engine": "surya",
            "text": "\n".join(text_fragments),
            "confidence": 0.0,
            "tables": [],
            "layout_blocks": [],
        }
    except Exception as exc:
        logger.warning("Surya fallback unavailable/failed: %s", exc)
        return None


def _extract_page(image: Image.Image) -> Dict[str, Any]:
    engines = _engine_priority()
    low_conf_threshold = float(getattr(settings, "OCR_SURYA_FALLBACK_CONFIDENCE", 70.0))

    paddle_result: Optional[Dict[str, Any]] = None

    for engine in engines:
        if engine == "paddle":
            paddle_result = _extract_with_paddle(image)
            if paddle_result and paddle_result.get("text"):
                if (
                    "surya" in engines
                    and paddle_result.get("confidence", 0.0) < low_conf_threshold
                ):
                    surya_result = _extract_with_surya(image)
                    if surya_result and len(surya_result.get("text", "")) > len(paddle_result.get("text", "")):
                        return surya_result
                return paddle_result

        elif engine == "surya":
            surya_result = _extract_with_surya(image)
            if surya_result and surya_result.get("text"):
                return surya_result

        elif engine == "tesseract":
            tess_result = _extract_with_tesseract(image)
            if tess_result.get("text"):
                return tess_result

    return _extract_with_tesseract(image)


def extract_text_tesseract(image_bytes: bytes) -> Tuple[str, float]:
    with Image.open(io.BytesIO(image_bytes)) as image:
        result = _extract_with_tesseract(image)
    return result["text"], result["confidence"]


def _build_page_payload(index: int, page_result: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "page": index,
        "engine": page_result.get("engine"),
        "confidence": float(page_result.get("confidence", 0.0)),
        "tables": page_result.get("tables", []),
        "layout_blocks": page_result.get("layout_blocks", []),
    }


async def extract_text_from_bytes(file_bytes: bytes, file_type: str) -> Tuple[str, float, Dict[str, Any]]:
    if (file_type or "").lower() == "pdf":
        return await _extract_from_pdf(file_bytes)

    with Image.open(io.BytesIO(file_bytes)) as image:
        page = _extract_page(image)

    page_payload = _build_page_payload(1, page)
    payload = {
        "pages": [page_payload],
        "engines_used": [page.get("engine")],
    }
    return page.get("text", "").strip(), page.get("confidence", 0.0), payload


async def _extract_from_pdf(pdf_bytes: bytes) -> Tuple[str, float, Dict[str, Any]]:
    try:
        from pdf2image import convert_from_bytes

        images = convert_from_bytes(pdf_bytes, dpi=int(getattr(settings, "OCR_PDF_DPI", 250)))
        all_texts: List[str] = []
        all_confidences: List[float] = []
        pages_payload: List[Dict[str, Any]] = []

        for index, image in enumerate(images, start=1):
            page_result = _extract_page(image)
            all_texts.append(page_result.get("text", ""))
            all_confidences.append(float(page_result.get("confidence", 0.0)))
            pages_payload.append(_build_page_payload(index, page_result))

        full_text = "\n\n--- Page Break ---\n\n".join(section for section in all_texts if section).strip()
        avg_conf = sum(all_confidences) / len(all_confidences) if all_confidences else 0.0
        payload = {
            "pages": pages_payload,
            "engines_used": sorted({p.get("engine") for p in pages_payload if p.get("engine")}),
        }
        return full_text, avg_conf, payload
    except Exception as exc:
        logger.exception("PDF extraction failed")
        return f"PDF extraction failed: {exc}", 0.0, {"pages": [], "engines_used": []}
