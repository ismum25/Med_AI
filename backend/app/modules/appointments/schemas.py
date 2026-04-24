from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid


class CreateAppointmentRequest(BaseModel):
    doctor_id: uuid.UUID
    scheduled_at: datetime
    duration_mins: Optional[int] = 30
    reason: Optional[str] = None


class UpdateAppointmentRequest(BaseModel):
    status: Optional[str] = None
    notes: Optional[str] = None
    meeting_link: Optional[str] = None
    cancellation_reason: Optional[str] = None
    scheduled_at: Optional[datetime] = None


class AppointmentResponse(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    doctor_id: uuid.UUID
    scheduled_at: datetime
    duration_mins: int
    status: str
    reason: Optional[str] = None
    notes: Optional[str] = None
    meeting_link: Optional[str] = None
    cancellation_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    doctor_full_name: Optional[str] = None
    doctor_specialization: Optional[str] = None
    doctor_profile_id: Optional[uuid.UUID] = None

    class Config:
        from_attributes = True
