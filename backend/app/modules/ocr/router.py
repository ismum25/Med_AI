from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from app.database.session import get_db
from app.dependencies import get_current_user
from app.modules.reports.models import MedicalReport
from app.modules.ocr.schemas import OCRJobStatus

router = APIRouter()


def _build_status_message(status: str) -> str:
    messages = {
        "pending": "OCR job is pending and will start soon.",
        "processing": "OCR is currently processing this report.",
        "extracted": "OCR extraction completed successfully.",
        "verified": "OCR extraction is completed and verified.",
        "failed": "OCR extraction failed. Please retry this report.",
    }
    return messages.get(status, f"OCR status: {status}")


@router.get("/jobs/{report_id}", response_model=OCRJobStatus)
async def get_ocr_status(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(MedicalReport).where(MedicalReport.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return OCRJobStatus(
        job_id=report.ocr_job_id or str(report_id),
        report_id=report_id,
        status=report.ocr_status,
        message=_build_status_message(report.ocr_status),
    )


@router.post("/retry/{report_id}", response_model=OCRJobStatus)
async def retry_ocr(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(MedicalReport).where(MedicalReport.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    from app.workers.ocr_worker import process_ocr_task
    task = process_ocr_task.delay(str(report_id))
    report.ocr_status = "processing"
    report.ocr_job_id = task.id
    await db.commit()
    return OCRJobStatus(
        job_id=task.id,
        report_id=report_id,
        status="processing",
        message=_build_status_message("processing"),
    )
