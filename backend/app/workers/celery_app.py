from celery import Celery
from app.config import settings

celery_app = Celery(
    "healthcare",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.workers.ocr_worker", "app.workers.notification_worker"],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_routes={
        "app.workers.ocr_worker.*": {"queue": "ocr"},
        "app.workers.notification_worker.*": {"queue": "notifications"},
    },
    beat_schedule={
        "retry-failed-ocr-every-5-minutes": {
            "task": "app.workers.ocr_worker.retry_failed_ocr_jobs",
            "schedule": 300.0,
        },
        "send-appointment-reminders-hourly": {
            "task": "app.workers.notification_worker.send_appointment_reminders",
            "schedule": 3600.0,
        },
    },
)
