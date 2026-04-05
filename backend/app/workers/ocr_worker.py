import asyncio
import logging
from sqlalchemy import select
from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.workers.ocr_worker.process_ocr_task", bind=True, max_retries=3)
def process_ocr_task(self, report_id: str):
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(_run_pipeline(report_id))
        loop.close()
        return {"status": "success", "report_id": report_id}
    except Exception as exc:
        logger.error(f"OCR task failed for report {report_id}: {exc}")
        raise self.retry(exc=exc, countdown=60 * (self.request.retries + 1))


async def _run_pipeline(report_id: str):
    from app.database.session import AsyncSessionLocal
    from app.modules.ocr.pipeline import run_ocr_pipeline
    async with AsyncSessionLocal() as db:
        await run_ocr_pipeline(report_id, db)


@celery_app.task(name="app.workers.ocr_worker.retry_failed_ocr_jobs")
def retry_failed_ocr_jobs():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(_retry_failed())
    loop.close()


async def _retry_failed():
    from app.database.session import AsyncSessionLocal
    from app.modules.reports.models import MedicalReport
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(MedicalReport).where(MedicalReport.ocr_status == "failed").limit(10)
        )
        for report in result.scalars().all():
            process_ocr_task.delay(str(report.id))
            logger.info(f"Retrying OCR for report {report.id}")
