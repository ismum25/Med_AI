import logging

import app.modules.ai.models  # noqa: F401
import app.modules.appointments.models  # noqa: F401
import app.modules.auth.models  # noqa: F401
import app.modules.incidents.models  # noqa: F401
import app.modules.reports.models  # noqa: F401

# Import all models so Base.metadata knows about them
import app.modules.users.models  # noqa: F401
from app.config import settings
from app.database.base import Base
from app.modules.ai.router import router as ai_router
from app.modules.appointments.router import router as appointments_router
from app.modules.auth.router import router as auth_router
from app.modules.incidents.router import router as incidents_router
from app.modules.ocr.router import router as ocr_router
from app.modules.reports.router import router as reports_router
from app.modules.users.router import router as users_router
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import create_async_engine

logging.basicConfig(level=settings.LOG_LEVEL)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Health Care API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users_router, prefix="/api/v1/users", tags=["Users"])
app.include_router(appointments_router, prefix="/api/v1/appointments", tags=["Appointments"])
app.include_router(reports_router, prefix="/api/v1/reports", tags=["Reports"])
app.include_router(incidents_router, prefix="/api/v1/incidents", tags=["Incidents"])
app.include_router(ocr_router, prefix="/api/v1/ocr", tags=["OCR"])
app.include_router(ai_router, prefix="/api/v1/chat", tags=["AI Chatbot"])


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.APP_NAME}


@app.on_event("startup")
async def startup_event():
    logger.info(f"Starting {settings.APP_NAME} in {settings.APP_ENV} mode")
    key = settings.OPENROUTER_API_KEY
    logger.info(f"OpenRouter key loaded: {'(empty)' if not key else key[:12] + '...'}")
    logger.info(f"OpenRouter model: {settings.OPENROUTER_MODEL}")
    import asyncio
    from app.database.session import engine as shared_engine

    max_retries = 10
    delay = 3  # seconds between retries
    for attempt in range(1, max_retries + 1):
        try:
            async with shared_engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("Database tables ensured.")
            return
        except Exception as exc:
            logger.warning(
                "DB not ready (attempt %d/%d): %s — retrying in %ds…",
                attempt, max_retries, exc, delay,
            )
            if attempt == max_retries:
                logger.error("Could not connect to DB after %d attempts. Aborting startup.", max_retries)
                raise
            await asyncio.sleep(delay)

