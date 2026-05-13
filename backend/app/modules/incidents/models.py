import uuid

from app.database.base import Base
from sqlalchemy import JSON, Column, DateTime, Float, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship


class Incident(Base):
    __tablename__ = "incidents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String(255))
    notes = Column(Text)
    file_url = Column(Text, nullable=False)
    file_name = Column(String(255))
    file_type = Column(String(20))
    analysis_status = Column(String(30), default="pending", nullable=False)
    injury_type = Column(String(120))
    severity = Column(String(50))
    body_area = Column(String(120))
    description = Column(Text)
    summary = Column(Text)
    confidence = Column(Float)
    analysis_payload = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    patient = relationship("User", foreign_keys=[patient_id], backref="incidents")
    uploaded_by_user = relationship("User", foreign_keys=[uploaded_by])
