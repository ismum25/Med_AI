from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from datetime import date
import uuid

from app.database.session import get_db
from app.dependencies import get_current_user
from app.core.permissions import require_patient
from app.modules.appointments import schemas, service

router = APIRouter()


@router.post("/", response_model=schemas.AppointmentResponse, status_code=201)
async def book_appointment(
    data: schemas.CreateAppointmentRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_patient),
):
    appt = await service.create_appointment(current_user.id, data, db)
    return await service.appointment_to_response(appt, "patient", db)


@router.get("/", response_model=List[schemas.AppointmentResponse])
async def list_appointments(
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    appts = await service.get_appointments_for_user(
        current_user.id, current_user.role, db, status
    )
    return await service.appointments_to_responses(appts, current_user.role, db)


@router.get(
    "/doctors/{doctor_user_id}/slots", response_model=schemas.DoctorSlotsResponse
)
async def list_doctor_slots(
    doctor_user_id: uuid.UUID,
    date_value: date = Query(..., alias="date"),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_patient),
):
    return await service.get_doctor_slots_for_date(doctor_user_id, date_value, db)


@router.get("/{appointment_id}", response_model=schemas.AppointmentResponse)
async def get_appointment(
    appointment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    appt = await service.get_appointment_by_id(
        appointment_id, current_user.id, current_user.role, db
    )
    return await service.appointment_to_response(appt, current_user.role, db)


@router.patch("/{appointment_id}", response_model=schemas.AppointmentResponse)
async def update_appointment(
    appointment_id: uuid.UUID,
    data: schemas.UpdateAppointmentRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    appt = await service.update_appointment(
        appointment_id, current_user.id, current_user.role, data, db
    )
    return await service.appointment_to_response(appt, current_user.role, db)


@router.delete("/{appointment_id}", response_model=schemas.AppointmentResponse)
async def cancel_appointment(
    appointment_id: uuid.UUID,
    reason: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    appt = await service.cancel_appointment(
        appointment_id, current_user.id, current_user.role, reason, db
    )
    return await service.appointment_to_response(appt, current_user.role, db)
