from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid


class CreateSessionRequest(BaseModel):
    title: Optional[str] = "New Conversation"
    context_patient_id: Optional[uuid.UUID] = None


class SessionResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    context_patient_id: Optional[uuid.UUID] = None
    created_at: datetime

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    id: uuid.UUID
    session_id: uuid.UUID
    role: str
    content: str
    created_at: datetime

    class Config:
        from_attributes = True


class SendMessageRequest(BaseModel):
    content: str


class SessionWithMessagesResponse(SessionResponse):
    messages: List[MessageResponse] = []
