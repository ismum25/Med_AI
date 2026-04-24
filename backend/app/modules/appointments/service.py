import uuid
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from fastapi import HTTPException

from app.modules.appointments.models import Appointment
from app.modules.appointments.schemas import AppointmentResponse, CreateAppointmentRequest, UpdateAppointmentRequest
from app.modules.auth.models import User
from app.modules.users.models import DoctorProfile
from app.modules.users import availability as avail


async def create_appointment(patient_id: uuid.UUID, data: CreateAppointmentRequest, db: AsyncSession) -> Appointment:
    result = await db.execute(select(User).where(User.id == data.doctor_id, User.role == "doctor"))
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Doctor not found")

    prof_result = await db.execute(select(DoctorProfile).where(DoctorProfile.user_id == data.doctor_id))
    dprof = prof_result.scalar_one_or_none()
    if not dprof:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    raw_slots = dprof.available_slots
    utc_start = avail.normalize_utc(data.scheduled_at)

    if avail.legacy_availability_not_configured(raw_slots):
        pass
    elif avail.try_parse_weekly(raw_slots) is None:
        raise HTTPException(status_code=400, detail="Doctor availability is misconfigured")
    elif avail.explicit_empty_week(raw_slots):
        raise HTTPException(status_code=400, detail="This doctor has no available hours")
    elif avail.has_any_slot(raw_slots):
        tzname = dprof.availability_timezone
        if not tzname or not str(tzname).strip():
            raise HTTPException(status_code=400, detail="Doctor availability is incomplete")
        if not avail.appointment_start_fits_availability(utc_start, raw_slots, tzname):
            raise HTTPException(
                status_code=400,
                detail="Requested time is outside the doctor's available hours",
            )

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


def _appointment_to_response(
    appt: Appointment, role: str, doctor_by_user_id: dict[uuid.UUID, DoctorProfile]
) -> AppointmentResponse:
    r = AppointmentResponse.model_validate(appt, from_attributes=True)
    if role == "patient":
        prof = doctor_by_user_id.get(appt.doctor_id)
        if prof:
            return r.model_copy(
                update={
                    "doctor_full_name": prof.full_name,
                    "doctor_specialization": prof.specialization,
                    "doctor_profile_id": prof.id,
                }
            )
    return r


async def appointments_to_responses(
    items: List[Appointment], role: str, db: AsyncSession
) -> List[AppointmentResponse]:
    doctor_by_user_id: dict[uuid.UUID, DoctorProfile] = {}
    if role == "patient" and items:
        doc_user_ids = {a.doctor_id for a in items}
        res = await db.execute(
            select(DoctorProfile).where(DoctorProfile.user_id.in_(doc_user_ids))
        )
        for prof in res.scalars().all():
            doctor_by_user_id[prof.user_id] = prof
    return [_appointment_to_response(a, role, doctor_by_user_id) for a in items]


async def appointment_to_response(
    appt: Appointment, role: str, db: AsyncSession
) -> AppointmentResponse:
    return (await appointments_to_responses([appt], role, db))[0]


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
