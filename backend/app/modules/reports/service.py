import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, UploadFile

from app.modules.reports.models import MedicalReport, ExtractedReportData
from app.modules.reports.schemas import VerifyReportRequest
from app.modules.reports import storage

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/jpg", "application/pdf", "image/tiff"}
MAX_FILE_SIZE_MB = 20


async def upload_report(
    patient_id: uuid.UUID,
    uploader_id: uuid.UUID,
    file: UploadFile,
    report_type: Optional[str],
    title: Optional[str],
    report_date: Optional[str],
    db: AsyncSession,
) -> MedicalReport:
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=400, detail=f"File type {file.content_type} not allowed")

    file_bytes = await file.read()
    if len(file_bytes) > MAX_FILE_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"File too large. Max {MAX_FILE_SIZE_MB}MB")

    object_key = await storage.upload_file(
        file_bytes=file_bytes, file_name=file.filename, content_type=file.content_type
    )

    report = MedicalReport(
        patient_id=patient_id,
        uploaded_by=uploader_id,
        title=title or file.filename,
        report_type=report_type,
        report_date=report_date,
        file_url=object_key,
        file_name=file.filename,
        file_type=file.content_type.split("/")[-1],
        ocr_status="pending",
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    try:
        from app.workers.ocr_worker import process_ocr_task
        task = process_ocr_task.delay(str(report.id))
        report.ocr_job_id = task.id
        report.ocr_status = "processing"
        await db.commit()
    except Exception:
        pass

    return report


async def get_patient_reports(
    patient_id: uuid.UUID, requester_id: uuid.UUID, requester_role: str, db: AsyncSession
) -> List[MedicalReport]:
    if requester_role == "patient" and patient_id != requester_id:
        raise HTTPException(status_code=403, detail="Access denied")
    result = await db.execute(
        select(MedicalReport).where(MedicalReport.patient_id == patient_id).order_by(MedicalReport.created_at.desc())
    )
    return result.scalars().all()


async def get_report_by_id(
    report_id: uuid.UUID, requester_id: uuid.UUID, requester_role: str, db: AsyncSession
) -> MedicalReport:
    result = await db.execute(select(MedicalReport).where(MedicalReport.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if requester_role == "patient" and report.patient_id != requester_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return report


async def get_report_download_url(
    report_id: uuid.UUID, requester_id: uuid.UUID, requester_role: str, db: AsyncSession
) -> str:
    report = await get_report_by_id(report_id, requester_id, requester_role, db)
    return storage.get_presigned_url(report.file_url)


async def verify_report(
    report_id: uuid.UUID, doctor_id: uuid.UUID, data: VerifyReportRequest, db: AsyncSession
) -> MedicalReport:
    result = await db.execute(select(MedicalReport).where(MedicalReport.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if report.ocr_status not in ("extracted", "verified"):
        raise HTTPException(status_code=400, detail="Report not ready for verification")

    existing = await db.execute(select(ExtractedReportData).where(ExtractedReportData.report_id == report_id))
    extracted = existing.scalar_one_or_none()

    if extracted:
        extracted.data = data.data
    else:
        extracted = ExtractedReportData(report_id=report_id, data=data.data)
        db.add(extracted)

    report.ocr_status = "verified"
    report.verified_by = doctor_id
    report.verified_at = datetime.now(timezone.utc)
    if data.notes:
        report.notes = data.notes

    await db.commit()
    await db.refresh(report)
    return report
