import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, JSON, Numeric, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.base import Base


class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    specialization = Column(String(255), nullable=False, default="")
    license_number = Column(String(100), unique=True, nullable=False)
    hospital = Column(String(255))
    bio = Column(Text)
    consultation_fee = Column(Numeric(10, 2))
    available_slots = Column(JSON, default=dict)
    rating = Column(Numeric(3, 2), default=0.0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="doctor_profile")
    appointments = relationship("Appointment", back_populates="doctor", foreign_keys="Appointment.doctor_id")


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    date_of_birth = Column(String(20))
    blood_type = Column(String(10))
    allergies = Column(JSON, default=list)
    emergency_contact = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="patient_profile")
    appointments = relationship("Appointment", back_populates="patient", foreign_keys="Appointment.patient_id")
    reports = relationship("MedicalReport", back_populates="patient")
