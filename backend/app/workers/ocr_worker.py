import asyncio
import logging
from sqlalchemy import select
from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.workers.ocr_worker.process_ocr_task", bind=True, max_retries=3)
def process_ocr_task(self, report_id: str):
    try:
        asyncio.run(_run_pipeline(report_id))
        return {"status": "success", "report_id": report_id}
    except Exception as exc:
        logger.exception("OCR task failed for report %s", report_id)
        if self.request.retries >= self.max_retries:
            try:
                asyncio.run(_mark_report_failed(report_id))
            except Exception:
                logger.exception("Failed to mark report %s as failed after terminal OCR error", report_id)
            raise
        raise self.retry(exc=exc, countdown=60 * (self.request.retries + 1))


async def _run_pipeline(report_id: str):
    _ensure_model_mappers_loaded()

    from app.database.session import AsyncSessionLocal, engine
    from app.modules.ocr.pipeline import run_ocr_pipeline
    try:
        async with AsyncSessionLocal() as db:
            await run_ocr_pipeline(report_id, db)
    finally:
        await engine.dispose()


def _ensure_model_mappers_loaded() -> None:
    # Import all models once in worker processes so SQLAlchemy relationship() targets resolve.
    import app.modules.users.models  # noqa: F401
    import app.modules.auth.models  # noqa: F401
    import app.modules.appointments.models  # noqa: F401
    import app.modules.reports.models  # noqa: F401
    import app.modules.ai.models  # noqa: F401


async def _mark_report_failed(report_id: str) -> None:
    from app.database.session import AsyncSessionLocal, engine
    from app.modules.reports.models import MedicalReport

    try:
        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(MedicalReport).where(MedicalReport.id == report_id)
            )
            report = result.scalar_one_or_none()
            if report:
                report.ocr_status = "failed"
                await db.commit()
    finally:
        await engine.dispose()


@celery_app.task(name="app.workers.ocr_worker.retry_failed_ocr_jobs")
def retry_failed_ocr_jobs():
    asyncio.run(_retry_failed())


async def _retry_failed():
    _ensure_model_mappers_loaded()

    from app.database.session import AsyncSessionLocal, engine
    from app.modules.reports.models import MedicalReport
    try:
        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(MedicalReport).where(MedicalReport.ocr_status == "failed").limit(10)
            )
            for report in result.scalars().all():
                process_ocr_task.delay(str(report.id))
                logger.info("Retrying OCR for report %s", report.id)
    finally:
        await engine.dispose()
