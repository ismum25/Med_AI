import asyncio
import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy import select, and_
from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.workers.notification_worker.send_appointment_reminders")
def send_appointment_reminders():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(_send_reminders())
    loop.close()


async def _send_reminders():
    from app.database.session import AsyncSessionLocal
    from app.modules.appointments.models import Appointment

    now = datetime.now(timezone.utc)
    window_start = now + timedelta(hours=23)
    window_end = now + timedelta(hours=25)

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Appointment).where(
                and_(
                    Appointment.scheduled_at >= window_start,
                    Appointment.scheduled_at <= window_end,
                    Appointment.status == "confirmed",
                )
            )
        )
        for appt in result.scalars().all():
            logger.info(f"Sending reminder for appointment {appt.id}")
            # TODO: integrate SendGrid / FCM


@celery_app.task(name="app.workers.notification_worker.send_notification")
def send_notification(user_id: str, title: str, body: str, notification_type: str = "push"):
    logger.info(f"Sending {notification_type} notification to user {user_id}: {title}")
    # TODO: implement FCM / SendGrid
