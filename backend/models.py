import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, Text, JSON, ForeignKey
)
from sqlalchemy.orm import relationship
from backend.database import Base


class PatientModel(Base):
    __tablename__ = "patients"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    pseudonym = Column(String(50), unique=True, nullable=False, index=True)
    affected_hand = Column(String(20), nullable=False, default="unknown")
    created_at = Column(DateTime, default=datetime.utcnow)
    notes = Column(Text, default="")
    data_source = Column(String(20), default="real")
    is_deleted = Column(Boolean, default=False)

    plans = relationship("PlanModel", back_populates="patient", cascade="all, delete-orphan")
    sessions = relationship("SessionModel", back_populates="patient", cascade="all, delete-orphan")
    flags = relationship("FlagModel", back_populates="patient", cascade="all, delete-orphan")


class PlanModel(Base):
    __tablename__ = "plans"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=False, index=True)
    exercise_id = Column(String(50), nullable=False)
    target_reps = Column(Integer, nullable=False, default=10)
    target_rom_min = Column(Float, nullable=False, default=70.0)
    target_rom_max = Column(Float, nullable=False, default=100.0)
    hold_s = Column(Float, nullable=False, default=0.5)
    rest_s = Column(Float, nullable=False, default=2.0)
    sessions_per_week = Column(Integer, nullable=False, default=5)
    stop_instruction = Column(Text, default="Stop if you feel sharp pain. Rest as needed.")
    fatigue_drop_threshold = Column(Float, default=20.0)
    valid_from = Column(DateTime, default=datetime.utcnow)
    valid_to = Column(DateTime, nullable=True)
    set_by = Column(String(100), default="Clinician")
    version = Column(Integer, default=1)

    patient = relationship("PatientModel", back_populates="plans")


class ExerciseModel(Base):
    __tablename__ = "exercises"

    id = Column(String(50), primary_key=True)
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(100), nullable=False)
    instructions = Column(Text, default="")
    required_channels = Column(JSON, default=list)
    defaults = Column(JSON, default=dict)


class SessionModel(Base):
    __tablename__ = "sessions"

    id = Column(String(36), primary_key=True) # Client UUID used for idempotency
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=False, index=True)
    exercise_code = Column(String(50), nullable=False)
    plan_version = Column(Integer, default=1)
    started_at = Column(DateTime, nullable=False)
    ended_at = Column(DateTime, nullable=False)
    duration_s = Column(Float, nullable=False)
    reps_completed = Column(Integer, nullable=False)
    reps_target = Column(Integer, nullable=False)
    reps_interrupted = Column(Integer, default=0)
    mean_rom = Column(Float, nullable=False)
    max_rom = Column(Float, nullable=False)
    mean_rep_duration_s = Column(Float, nullable=False)
    smoothness = Column(Float, nullable=True)
    hold_s = Column(Float, default=0.0)
    consistency = Column(Float, nullable=True)
    consistency_components = Column(JSON, nullable=True)
    fatigue_drop_pct = Column(Float, nullable=True)
    pain_before = Column(Integer, nullable=True)
    pain_after = Column(Integer, nullable=False)
    fatigue_before = Column(Integer, nullable=True)
    fatigue_after = Column(Integer, nullable=False)
    note = Column(Text, default="")
    data_quality = Column(String(20), default="good")
    data_source = Column(String(20), default="real")
    device_id = Column(String(100), default="unknown")
    firmware = Column(String(50), default="1.0.0")
    calibration_ref = Column(String(100), default="")
    model_version = Column(String(50), nullable=True)
    client_version = Column(String(50), default="1.0.0")
    created_at = Column(DateTime, default=datetime.utcnow)
    received_at = Column(DateTime, default=datetime.utcnow)
    is_deleted = Column(Boolean, default=False) # Tombstone

    patient = relationship("PatientModel", back_populates="sessions")
    repetitions = relationship("RepetitionModel", back_populates="session", cascade="all, delete-orphan")


class RepetitionModel(Base):
    __tablename__ = "repetitions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String(36), ForeignKey("sessions.id"), nullable=False, index=True)
    index = Column(Integer, nullable=False)
    start_ms = Column(Integer, nullable=False)
    end_ms = Column(Integer, nullable=False)
    duration_s = Column(Float, nullable=False)
    peak = Column(Float, nullable=False)
    mean = Column(Float, nullable=False)
    min = Column(Float, nullable=False)
    rom = Column(Float, nullable=False)
    hold_s = Column(Float, default=0.0)
    smoothness = Column(Float, nullable=True)
    quality = Column(String(20), default="good")
    status = Column(String(20), default="complete")
    reject_reason = Column(String(100), nullable=True)

    session = relationship("SessionModel", back_populates="repetitions")


class FlagModel(Base):
    __tablename__ = "flags"

    id = Column(String(100), primary_key=True)
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=False, index=True)
    type = Column(String(50), nullable=False)
    severity = Column(String(20), default="info")
    created_at = Column(DateTime, default=datetime.utcnow)
    session_ids = Column(JSON, default=list)
    message = Column(Text, nullable=False)
    metric_values = Column(JSON, default=dict)
    threshold_used = Column(JSON, default=dict)
    acknowledged_at = Column(DateTime, nullable=True)
    acknowledged_by = Column(String(100), nullable=True)
    ack_note = Column(Text, nullable=True)

    patient = relationship("PatientModel", back_populates="flags")


class CalibrationModel(Base):
    __tablename__ = "calibrations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String(36), nullable=False, index=True)
    device_id = Column(String(100), default="")
    captured_at = Column(DateTime, default=datetime.utcnow)
    min_span_threshold = Column(Integer, default=300)
    fingers = Column(JSON, nullable=False)
    status = Column(String(20), default="valid")
