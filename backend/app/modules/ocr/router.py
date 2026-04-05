from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from app.database.session import get_db
from app.dependencies import get_current_user
from app.modules.reports.models import MedicalReport
from app.modules.ocr.schemas import OCRJobStatus

router = APIRouter()


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
    return OCRJobStatus(job_id=task.id, report_id=report_id, status="processing")
