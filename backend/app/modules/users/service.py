from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
import uuid

from app.modules.users.models import DoctorProfile, PatientProfile
from app.modules.users.schemas import UpdateDoctorRequest, UpdatePatientRequest
from app.modules.users.availability import (
    WeeklyAvailability,
    weekly_availability_to_storage_dict,
    validate_timezone_required_for_slots,
)


async def get_all_doctors(db: AsyncSession, specialization: str = None) -> list:
    query = select(DoctorProfile)
    if specialization:
        query = query.where(DoctorProfile.specialization.ilike(f"%{specialization}%"))
    result = await db.execute(query)
    return result.scalars().all()


async def get_doctor_by_id(doctor_id: uuid.UUID, db: AsyncSession) -> DoctorProfile:
    result = await db.execute(select(DoctorProfile).where(DoctorProfile.id == doctor_id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return doctor


async def get_doctor_by_user_id(user_id: uuid.UUID, db: AsyncSession):
    result = await db.execute(select(DoctorProfile).where(DoctorProfile.user_id == user_id))
    return result.scalar_one_or_none()


async def get_patient_by_id(patient_id: uuid.UUID, db: AsyncSession) -> PatientProfile:
    result = await db.execute(select(PatientProfile).where(PatientProfile.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


async def get_patient_by_user_id(user_id: uuid.UUID, db: AsyncSession):
    result = await db.execute(select(PatientProfile).where(PatientProfile.user_id == user_id))
    return result.scalar_one_or_none()


async def update_doctor_profile(user_id: uuid.UUID, data: UpdateDoctorRequest, db: AsyncSession):
    doctor = await get_doctor_by_user_id(user_id, db)
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    payload = data.model_dump(exclude_unset=True)

    merged_slots = doctor.available_slots if doctor.available_slots is not None else {}
    merged_tz = getattr(doctor, "availability_timezone", None)

    if "available_slots" in payload and payload["available_slots"] is not None:
        wa = WeeklyAvailability.model_validate(payload["available_slots"])
        merged_slots = weekly_availability_to_storage_dict(wa)
    if "availability_timezone" in payload:
        merged_tz = payload["availability_timezone"]

    validate_timezone_required_for_slots(merged_slots, merged_tz)

    for field, value in payload.items():
        if field == "available_slots":
            setattr(doctor, "available_slots", merged_slots)
        elif field == "availability_timezone":
            setattr(doctor, "availability_timezone", merged_tz)
        else:
            setattr(doctor, field, value)

    await db.commit()
    await db.refresh(doctor)
    return doctor


async def update_patient_profile(user_id: uuid.UUID, data: UpdatePatientRequest, db: AsyncSession):
    patient = await get_patient_by_user_id(user_id, db)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(patient, field, value)
    await db.commit()
    await db.refresh(patient)
    return patient
