from pydantic import BaseModel
from typing import Optional, Dict, Any
import uuid


class OCRJobStatus(BaseModel):
    job_id: str
    report_id: uuid.UUID
    status: str
    message: Optional[str] = None


class OCRResult(BaseModel):
    report_id: uuid.UUID
    raw_text: str
    structured_data: Optional[Dict[str, Any]] = None
    confidence: float
