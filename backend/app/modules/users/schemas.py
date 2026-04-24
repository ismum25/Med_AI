from pydantic import BaseModel
from typing import Optional, Any, Dict, List
import uuid

from app.modules.users.availability import WeeklyAvailability


class DoctorProfileResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    full_name: str
    specialization: str
    license_number: str
    hospital: Optional[str] = None
    bio: Optional[str] = None
    consultation_fee: Optional[float] = None
    available_slots: Optional[Dict[str, Any]] = None
    availability_timezone: Optional[str] = None
    rating: float = 0.0

    class Config:
        from_attributes = True


class PatientProfileResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    full_name: str
    date_of_birth: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[List] = None
    emergency_contact: Optional[Dict] = None

    class Config:
        from_attributes = True


class UpdateDoctorRequest(BaseModel):
    full_name: Optional[str] = None
    specialization: Optional[str] = None
    hospital: Optional[str] = None
    bio: Optional[str] = None
    consultation_fee: Optional[float] = None
    available_slots: Optional[WeeklyAvailability] = None
    availability_timezone: Optional[str] = None


class UpdatePatientRequest(BaseModel):
    full_name: Optional[str] = None
    date_of_birth: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[List] = None
    emergency_contact: Optional[Dict] = None


class DoctorListItem(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    full_name: str
    specialization: str
    hospital: Optional[str] = None
    consultation_fee: Optional[float] = None
    rating: float = 0.0

    class Config:
        from_attributes = True
