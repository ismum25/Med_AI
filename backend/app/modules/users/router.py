from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import uuid

from app.database.session import get_db
from app.dependencies import get_current_user
from app.core.permissions import require_doctor, require_patient
from app.modules.users import schemas, service

router = APIRouter()


@router.get("/doctors", response_model=List[schemas.DoctorListItem])
async def list_doctors(
    specialization: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await service.get_all_doctors(db, specialization)


@router.get("/doctors/{doctor_id}", response_model=schemas.DoctorProfileResponse)
async def get_doctor(
    doctor_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await service.get_doctor_by_id(doctor_id, db)


@router.get("/me/profile")
async def get_my_profile(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role == "doctor":
        profile = await service.get_doctor_by_user_id(current_user.id, db)
        return schemas.DoctorProfileResponse.model_validate(profile)
    else:
        profile = await service.get_patient_by_user_id(current_user.id, db)
        return schemas.PatientProfileResponse.model_validate(profile)


@router.get("/me/patients", response_model=List[schemas.PatientProfileResponse])
async def list_my_patients(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_doctor),
):
    return await service.list_patients_for_doctor(current_user.id, db)


@router.patch("/me/doctor-profile", response_model=schemas.DoctorProfileResponse)
async def update_doctor_profile(
    data: schemas.UpdateDoctorRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_doctor),
):
    return await service.update_doctor_profile(current_user.id, data, db)


@router.patch("/me/patient-profile", response_model=schemas.PatientProfileResponse)
async def update_patient_profile(
    data: schemas.UpdatePatientRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_patient),
):
    return await service.update_patient_profile(current_user.id, data, db)


@router.get("/patients/{patient_id}", response_model=schemas.PatientProfileResponse)
async def get_patient(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_doctor),
):
    return await service.get_patient_by_id(patient_id, db)
