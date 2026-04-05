import io
from typing import Tuple
from PIL import Image, ImageEnhance, ImageFilter
import pytesseract


def preprocess_image(image: Image.Image) -> Image.Image:
    image = image.convert("L")
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)
    image = image.filter(ImageFilter.SHARPEN)
    return image


def extract_text_tesseract(image_bytes: bytes) -> Tuple[str, float]:
    image = Image.open(io.BytesIO(image_bytes))
    image = preprocess_image(image)

    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    text = pytesseract.image_to_string(image)

    confidences = [int(c) for c in data["conf"] if str(c) != "-1" and int(c) > 0]
    avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0

    return text.strip(), avg_confidence


async def extract_text_from_bytes(file_bytes: bytes, file_type: str) -> Tuple[str, float]:
    if file_type == "pdf":
        return await _extract_from_pdf(file_bytes)
    return extract_text_tesseract(file_bytes)


async def _extract_from_pdf(pdf_bytes: bytes) -> Tuple[str, float]:
    try:
        from pdf2image import convert_from_bytes
        images = convert_from_bytes(pdf_bytes, dpi=200)
        all_texts = []
        all_confidences = []
        for image in images:
            img_bytes = io.BytesIO()
            image.save(img_bytes, format="PNG")
            text, confidence = extract_text_tesseract(img_bytes.getvalue())
            all_texts.append(text)
            all_confidences.append(confidence)
        full_text = "\n\n--- Page Break ---\n\n".join(all_texts)
        avg_conf = sum(all_confidences) / len(all_confidences) if all_confidences else 0.0
        return full_text, avg_conf
    except Exception as e:
        return f"PDF extraction failed: {str(e)}", 0.0
