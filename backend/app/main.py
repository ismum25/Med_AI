from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import settings
from app.database.base import Base
from app.modules.auth.router import router as auth_router
from app.modules.users.router import router as users_router
from app.modules.appointments.router import router as appointments_router
from app.modules.reports.router import router as reports_router
from app.modules.ocr.router import router as ocr_router
from app.modules.ai.router import router as ai_router

# Import all models so Base.metadata knows about them
import app.modules.users.models  # noqa: F401
import app.modules.auth.models  # noqa: F401
import app.modules.appointments.models  # noqa: F401
import app.modules.reports.models  # noqa: F401
import app.modules.ai.models  # noqa: F401

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
app.include_router(ocr_router, prefix="/api/v1/ocr", tags=["OCR"])
app.include_router(ai_router, prefix="/api/v1/chat", tags=["AI Chatbot"])


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": settings.APP_NAME}


@app.on_event("startup")
async def startup_event():
    logger.info(f"Starting {settings.APP_NAME} in {settings.APP_ENV} mode")
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    logger.info("Database tables ensured.")
