import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.modules.reports.models import MedicalReport, ExtractedReportData
from app.modules.reports.storage import download_file
from app.modules.ocr.extractor import extract_text_from_bytes
from app.modules.ocr.parser import parse_structured_data


async def run_ocr_pipeline(report_id: str, db: AsyncSession) -> bool:
    report_uuid = uuid.UUID(report_id)

    result = await db.execute(select(MedicalReport).where(MedicalReport.id == report_uuid))
    report = result.scalar_one_or_none()
    if not report:
        return False

    try:
        report.ocr_status = "processing"
        await db.commit()

        file_bytes = await download_file(report.file_url)
        file_type = report.file_type or "jpg"
        raw_text, confidence = await extract_text_from_bytes(file_bytes, file_type)
        structured = await parse_structured_data(raw_text)

        report.ocr_raw_text = raw_text
        report.ocr_confidence = confidence
        report.ocr_status = "extracted"

        if structured:
            existing = await db.execute(
                select(ExtractedReportData).where(ExtractedReportData.report_id == report_uuid)
            )
            extracted = existing.scalar_one_or_none()
            if extracted:
                extracted.data = structured
                extracted.data_type = structured.get("data_type", "other")
            else:
                extracted = ExtractedReportData(
                    report_id=report_uuid,
                    data=structured,
                    data_type=structured.get("data_type", "other"),
                )
                db.add(extracted)

        await db.commit()
        return True

    except Exception as e:
        report.ocr_status = "failed"
        await db.commit()
        raise e
