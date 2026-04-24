import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, JSON, Float, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base


class MedicalReport(Base):
    __tablename__ = "medical_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String(255))
    report_type = Column(String(50))
    report_date = Column(String(30))
    file_url = Column(Text, nullable=False)
    file_name = Column(String(255))
    file_type = Column(String(10))
    ocr_status = Column(String(30), default="pending", nullable=False)
    ocr_raw_text = Column(Text)
    ocr_confidence = Column(Float)
    ocr_job_id = Column(String(255))
    verified_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    verified_at = Column(DateTime(timezone=True))
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    patient = relationship("User", foreign_keys=[patient_id], backref="medical_reports")
    uploaded_by_user = relationship("User", foreign_keys=[uploaded_by])
    verifier = relationship("User", foreign_keys=[verified_by])
    extracted = relationship("ExtractedReportData", back_populates="report", uselist=False)


class ExtractedReportData(Base):
    __tablename__ = "extracted_report_data"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("medical_reports.id", ondelete="CASCADE"), unique=True, nullable=False)
    data = Column(JSON, nullable=False)
    data_type = Column(String(50))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    report = relationship("MedicalReport", back_populates="extracted")
