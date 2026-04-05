import uuid
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from fastapi import HTTPException

from app.modules.appointments.models import Appointment
from app.modules.appointments.schemas import CreateAppointmentRequest, UpdateAppointmentRequest
from app.modules.auth.models import User


async def create_appointment(patient_id: uuid.UUID, data: CreateAppointmentRequest, db: AsyncSession) -> Appointment:
    result = await db.execute(select(User).where(User.id == data.doctor_id, User.role == "doctor"))
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Doctor not found")

    conflict = await db.execute(
        select(Appointment).where(
            and_(
                Appointment.doctor_id == data.doctor_id,
                Appointment.scheduled_at == data.scheduled_at,
                Appointment.status.not_in(["cancelled", "no_show"]),
            )
        )
    )
    if conflict.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Time slot already booked")

    appointment = Appointment(
        patient_id=patient_id,
        doctor_id=data.doctor_id,
        scheduled_at=data.scheduled_at,
        duration_mins=data.duration_mins or 30,
        reason=data.reason,
        status="pending",
    )
    db.add(appointment)
    await db.commit()
    await db.refresh(appointment)
    return appointment


async def get_appointments_for_user(
    user_id: uuid.UUID, role: str, db: AsyncSession, status_filter: Optional[str] = None
) -> List[Appointment]:
    if role == "doctor":
        query = select(Appointment).where(Appointment.doctor_id == user_id)
    else:
        query = select(Appointment).where(Appointment.patient_id == user_id)
    if status_filter:
        query = query.where(Appointment.status == status_filter)
    query = query.order_by(Appointment.scheduled_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


async def get_appointment_by_id(
    appointment_id: uuid.UUID, user_id: uuid.UUID, role: str, db: AsyncSession
) -> Appointment:
    result = await db.execute(select(Appointment).where(Appointment.id == appointment_id))
    appointment = result.scalar_one_or_none()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if role == "patient" and appointment.patient_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    if role == "doctor" and appointment.doctor_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return appointment


async def update_appointment(
    appointment_id: uuid.UUID, user_id: uuid.UUID, role: str, data: UpdateAppointmentRequest, db: AsyncSession
) -> Appointment:
    appointment = await get_appointment_by_id(appointment_id, user_id, role, db)
    update_data = data.model_dump(exclude_unset=True)

    if role == "patient" and "status" in update_data and update_data["status"] != "cancelled":
        raise HTTPException(status_code=403, detail="Patients can only cancel appointments")

    for field, value in update_data.items():
        setattr(appointment, field, value)

    await db.commit()
    await db.refresh(appointment)
    return appointment


async def cancel_appointment(
    appointment_id: uuid.UUID, user_id: uuid.UUID, role: str, reason: Optional[str], db: AsyncSession
) -> Appointment:
    appointment = await get_appointment_by_id(appointment_id, user_id, role, db)
    if appointment.status in ("completed", "cancelled"):
        raise HTTPException(status_code=400, detail=f"Cannot cancel a {appointment.status} appointment")
    appointment.status = "cancelled"
    if reason:
        appointment.cancellation_reason = reason
    await db.commit()
    await db.refresh(appointment)
    return appointment
