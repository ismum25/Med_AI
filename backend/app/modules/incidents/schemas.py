import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel, Field


class IncidentResponse(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    uploaded_by: uuid.UUID
    title: Optional[str] = None
    notes: Optional[str] = None
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    analysis_status: str
    injury_type: Optional[str] = None
    severity: Optional[str] = None
    body_area: Optional[str] = None
    description: Optional[str] = None
    summary: Optional[str] = None
    confidence: Optional[float] = None
    analysis_payload: Optional[Dict[str, Any]] = Field(default=None)
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
