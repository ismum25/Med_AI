import uuid
from datetime import date, datetime, time, timedelta, timezone
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from fastapi import HTTPException

from app.modules.appointments.models import Appointment
from app.modules.appointments.schemas import (
    AppointmentResponse,
    CreateAppointmentRequest,
    DoctorSlotsResponse,
    SlotItem,
    UpdateAppointmentRequest,
)
from app.modules.auth.models import User
from app.modules.users.models import DoctorProfile
from app.modules.users import availability as avail

SLOT_DURATION_MINUTES = 30


def _slot_starts_for_day(raw_slots: dict, tz_name: str, local_date: date) -> list[datetime]:
    weekly = avail.try_parse_weekly(raw_slots)
    if weekly is None:
        return []
    key = avail.WEEKDAY_KEYS[local_date.weekday()]
    intervals: List[str] = getattr(weekly, key)
    tz = avail.resolve_zoneinfo(tz_name)
    starts: list[datetime] = []
    for interval in intervals:
        start_m, end_m = avail.parse_interval_string(interval)
        cursor = start_m
        while cursor + SLOT_DURATION_MINUTES <= end_m:
            hh, mm = divmod(cursor, 60)
            local_start = datetime.combine(local_date, time(hour=hh, minute=mm), tzinfo=tz)
            starts.append(local_start)
            cursor += SLOT_DURATION_MINUTES
    starts.sort()
    return starts


async def get_doctor_slots_for_date(
    doctor_user_id: uuid.UUID, local_date: date, db: AsyncSession
) -> DoctorSlotsResponse:
    result = await db.execute(
        select(User).where(User.id == doctor_user_id, User.role == "doctor")
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Doctor not found")

    prof_result = await db.execute(
        select(DoctorProfile).where(DoctorProfile.user_id == doctor_user_id)
    )
    dprof = prof_result.scalar_one_or_none()
    if not dprof:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    raw_slots = dprof.available_slots
    tz_name = (dprof.availability_timezone or "").strip()
    if (
        avail.legacy_availability_not_configured(raw_slots)
        or avail.explicit_empty_week(raw_slots)
        or not tz_name
        or avail.try_parse_weekly(raw_slots) is None
    ):
        return DoctorSlotsResponse(
            doctor_id=doctor_user_id,
            date=local_date,
            timezone=tz_name or None,
            slot_duration_mins=SLOT_DURATION_MINUTES,
            slots=[],
        )

    slot_starts_local = _slot_starts_for_day(raw_slots, tz_name, local_date)
    if not slot_starts_local:
        return DoctorSlotsResponse(
            doctor_id=doctor_user_id,
            date=local_date,
            timezone=tz_name,
            slot_duration_mins=SLOT_DURATION_MINUTES,
            slots=[],
        )

    tz = avail.resolve_zoneinfo(tz_name)
    day_start_local = datetime.combine(local_date, time.min, tzinfo=tz)
    next_day_local = day_start_local + timedelta(days=1)
    day_start_utc = day_start_local.astimezone(timezone.utc)
    next_day_utc = next_day_local.astimezone(timezone.utc)

    booked = await db.execute(
        select(Appointment.scheduled_at).where(
            and_(
                Appointment.doctor_id == doctor_user_id,
                Appointment.scheduled_at >= day_start_utc,
                Appointment.scheduled_at < next_day_utc,
                Appointment.status.not_in(["cancelled", "no_show"]),
            )
        )
    )
    booked_starts_utc = {avail.normalize_utc(row[0]) for row in booked.all()}
    now_utc = datetime.now(timezone.utc)

    slot_items: list[SlotItem] = []
    for local_start in slot_starts_local:
        utc_start = local_start.astimezone(timezone.utc)
        if utc_start <= now_utc:
            continue
        if utc_start in booked_starts_utc:
            continue
        slot_items.append(
            SlotItem(
                label_local=local_start.strftime("%I:%M %p").lstrip("0"),
                start_at_utc=utc_start,
            )
        )

    return DoctorSlotsResponse(
        doctor_id=doctor_user_id,
        date=local_date,
        timezone=tz_name,
        slot_duration_mins=SLOT_DURATION_MINUTES,
        slots=slot_items,
    )


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
        raise HTTPException(status_code=400, detail="Doctor has not configured bookable slots yet")
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
