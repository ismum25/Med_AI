from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import uuid

from app.database.session import get_db
from app.dependencies import get_current_user
from app.core.permissions import require_doctor, require_patient
from app.modules.reports import schemas, service

router = APIRouter()


@router.post("/", response_model=schemas.UploadReportResponse, status_code=201)
async def upload_report(
    file: UploadFile = File(...),
    report_type: Optional[str] = Form(None),
    title: Optional[str] = Form(None),
    report_date: Optional[str] = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_patient),
):
    report = await service.upload_report(
        patient_id=current_user.id,
        uploader_id=current_user.id,
        file=file,
        report_type=report_type,
        title=title,
        report_date=report_date,
        db=db,
    )
    return schemas.UploadReportResponse(
        report_id=report.id,
        message="Report uploaded. OCR processing started.",
        ocr_job_id=report.ocr_job_id,
    )


@router.get("/", response_model=List[schemas.ReportResponse])
async def list_my_reports(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_patient),
):
    return await service.get_patient_reports(current_user.id, current_user.id, current_user.role, db)


# Two-segment path lives outside the single-segment /{report_id} capture,
# so it cannot be shadowed by the UUID route regardless of ordering.
@router.get("/queue/pending-review", response_model=List[schemas.ReportResponse])
async def get_pending_review_reports(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_doctor),
):
    return await service.get_pending_review_reports(current_user.id, db)


@router.get("/patient/{patient_id}", response_model=List[schemas.ReportResponse])
async def get_patient_reports(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_doctor),
):
    return await service.get_patient_reports(patient_id, current_user.id, current_user.role, db)


@router.get("/{report_id}", response_model=schemas.ReportResponse)
async def get_report(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    report = await service.get_report_by_id(report_id, current_user.id, current_user.role, db)
    return await service.report_to_response(report, db, current_user.role)


@router.get("/{report_id}/download")
async def download_report(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    url = await service.get_report_download_url(report_id, current_user.id, current_user.role, db)
    return {"download_url": url}


@router.patch("/{report_id}", response_model=schemas.ReportResponse)
async def update_report(
    report_id: uuid.UUID,
    data: schemas.UpdateReportRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_patient),
):
    report = await service.update_report(
        report_id, current_user.id, current_user.role, data, db
    )
    return await service.report_to_response(report, db, current_user.role)


@router.patch("/{report_id}/verify", response_model=schemas.ReportResponse)
async def verify_report(
    report_id: uuid.UUID,
    data: schemas.VerifyReportRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_doctor),
):
    report = await service.verify_report(report_id, current_user.id, data, db)
    return await service.report_to_response(report, db, "doctor")
