import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, JSON, Float, Integer, func
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
    extracted_data = relationship("ExtractedReportData", back_populates="report", uselist=False)
    blood_test_report = relationship("BloodTestReport", back_populates="report", uselist=False)
    urine_test_report = relationship("UrineTestReport", back_populates="report", uselist=False)
    radiology_report = relationship("RadiologyReport", back_populates="report", uselist=False)


class ExtractedReportData(Base):
    __tablename__ = "extracted_report_data"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("medical_reports.id", ondelete="CASCADE"), unique=True, nullable=False)
    data = Column(JSON, nullable=False)
    data_type = Column(String(50))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    report = relationship("MedicalReport", back_populates="extracted_data")


class BloodTestReport(Base):
    __tablename__ = "blood_test_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("medical_reports.id", ondelete="CASCADE"), unique=True, nullable=False)
    patient_name = Column(String(255))
    patient_identifier = Column(String(120))
    lab_name = Column(String(255))
    doctor_name = Column(String(255))
    report_date = Column(String(30))
    raw_metadata = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    report = relationship("MedicalReport", back_populates="blood_test_report")
    results = relationship("BloodTestResult", back_populates="blood_report", cascade="all, delete-orphan")


class BloodTestResult(Base):
    __tablename__ = "blood_test_results"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    blood_report_id = Column(UUID(as_uuid=True), ForeignKey("blood_test_reports.id", ondelete="CASCADE"), nullable=False)
    raw_parameter = Column(String(255), nullable=False)
    canonical_parameter = Column(String(255), index=True)
    value_text = Column(String(120))
    value_num = Column(Float)
    unit = Column(String(50))
    reference_range = Column(String(120))
    ref_low = Column(Float)
    ref_high = Column(Float)
    flag = Column(String(30))
    source_confidence = Column(Float)
    source_page = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    blood_report = relationship("BloodTestReport", back_populates="results")


class UrineTestReport(Base):
    __tablename__ = "urine_test_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("medical_reports.id", ondelete="CASCADE"), unique=True, nullable=False)
    patient_name = Column(String(255))
    patient_identifier = Column(String(120))
    lab_name = Column(String(255))
    doctor_name = Column(String(255))
    report_date = Column(String(30))
    raw_metadata = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    report = relationship("MedicalReport", back_populates="urine_test_report")
    results = relationship("UrineTestResult", back_populates="urine_report", cascade="all, delete-orphan")


class UrineTestResult(Base):
    __tablename__ = "urine_test_results"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    urine_report_id = Column(UUID(as_uuid=True), ForeignKey("urine_test_reports.id", ondelete="CASCADE"), nullable=False)
    raw_parameter = Column(String(255), nullable=False)
    canonical_parameter = Column(String(255), index=True)
    value_text = Column(String(120))
    value_num = Column(Float)
    unit = Column(String(50))
    reference_range = Column(String(120))
    ref_low = Column(Float)
    ref_high = Column(Float)
    flag = Column(String(30))
    source_confidence = Column(Float)
    source_page = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    urine_report = relationship("UrineTestReport", back_populates="results")


class RadiologyReport(Base):
    __tablename__ = "radiology_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(UUID(as_uuid=True), ForeignKey("medical_reports.id", ondelete="CASCADE"), unique=True, nullable=False)
    patient_name = Column(String(255))
    patient_identifier = Column(String(120))
    lab_name = Column(String(255))
    doctor_name = Column(String(255))
    report_date = Column(String(30))
    modality = Column(String(120))
    body_part = Column(String(120))
    study_name = Column(String(255))
    findings = Column(Text)
    impression = Column(Text)
    recommendation = Column(Text)
    raw_metadata = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    report = relationship("MedicalReport", back_populates="radiology_report")
