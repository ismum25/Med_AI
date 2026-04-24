from pydantic import BaseModel, Field
from typing import Optional, Any, Dict
from datetime import datetime
import uuid


class ReportResponse(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    uploaded_by: uuid.UUID
    title: Optional[str] = None
    report_type: Optional[str] = None
    report_date: Optional[str] = None
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    ocr_status: str
    ocr_confidence: Optional[float] = None
    verified_by: Optional[uuid.UUID] = None
    verified_at: Optional[datetime] = None
    notes: Optional[str] = None
    created_at: datetime
    extracted_data: Optional[Dict[str, Any]] = Field(
        default=None,
        description="OCR structured payload; set on GET /reports/{id} for doctors when present.",
    )

    class Config:
        from_attributes = True


class ExtractedDataResponse(BaseModel):
    id: uuid.UUID
    report_id: uuid.UUID
    data: Dict[str, Any]
    data_type: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class VerifyReportRequest(BaseModel):
    data: Dict[str, Any]
    notes: Optional[str] = None


class UpdateReportRequest(BaseModel):
    title: Optional[str] = None


class UploadReportResponse(BaseModel):
    report_id: uuid.UUID
    message: str
    ocr_job_id: Optional[str] = None
