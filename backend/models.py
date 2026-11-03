import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, Text, JSON, ForeignKey, BigInteger, Index
)
from sqlalchemy.orm import relationship
from backend.database import Base


def get_utc_now():
    return datetime.now(timezone.utc)


# ==========================================
# H10 Platform Tables (Full Original Fields Preserved)
# ==========================================

class PatientModel(Base):
    __tablename__ = "patients"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    pseudonym = Column(String(50), unique=True, nullable=False, index=True)
    affected_hand = Column(String(20), nullable=False, default="unknown")
    created_at = Column(DateTime, default=get_utc_now)
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
    valid_from = Column(DateTime, default=get_utc_now)
    valid_to = Column(DateTime, nullable=True)
    set_by = Column(String(100), default="Clinician")
    version = Column(Integer, default=1)

    patient = relationship("PatientModel", back_populates="plans")


class ExerciseModel(Base):
    __tablename__ = "exercises"

    id = Column(String(50), primary_key=True)
    code = Column(String(50), unique=True, nullable=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, default="")
    instructions = Column(Text, default="")
    required_channels = Column(JSON, default=list)
    defaults = Column(JSON, default=dict)
    primary_sensor = Column(String(50), default="flex_all")
    target_rom_default = Column(Float, default=80.0)


class SessionModel(Base):
    __tablename__ = "sessions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=True, index=True)
    volunteer_id = Column(String(36), ForeignKey("volunteers.id"), nullable=True, index=True)
    mode = Column(String(20), default="task")  # task | exercise | game
    exercise_code = Column(String(50), nullable=True)
    plan_version = Column(Integer, default=1)
    started_at = Column(DateTime, default=get_utc_now)
    ended_at = Column(DateTime, nullable=True)
    duration_s = Column(Float, default=0.0)
    reps_completed = Column(Integer, default=0)
    reps_target = Column(Integer, default=0)
    reps_interrupted = Column(Integer, default=0)
    mean_rom = Column(Float, default=0.0)
    max_rom = Column(Float, default=0.0)
    mean_rep_duration_s = Column(Float, default=0.0)
    smoothness = Column(Float, nullable=True)
    hold_s = Column(Float, default=0.0)
    consistency = Column(Float, nullable=True)
    consistency_components = Column(JSON, nullable=True)
    fatigue_drop_pct = Column(Float, nullable=True)
    pain_before = Column(Integer, nullable=True)
    pain_after = Column(Integer, default=0)
    fatigue_before = Column(Integer, nullable=True)
    fatigue_after = Column(Integer, default=0)
    note = Column(Text, default="")
    notes = Column(Text, default="")
    data_quality = Column(String(20), default="good")
    data_source = Column(String(20), default="real")
    device_id = Column(String(100), default="unknown")
    firmware = Column(String(50), default="1.0.0")
    calibration_id = Column(String(50), nullable=True)
    calibration_ref = Column(String(100), default="")
    client_version = Column(String(50), default="3.0.0")
    synced_at = Column(DateTime, default=get_utc_now)
    sync_status = Column(String(20), default="synced")
    is_deleted = Column(Boolean, default=False)
    config_hash = Column(String(64), nullable=True)
    glove_size = Column(String(10), default="M")
    sensor_position_ok = Column(Boolean, default=True)

    patient = relationship("PatientModel", back_populates="sessions")
    volunteer = relationship("VolunteerModel", back_populates="sessions")
    repetitions = relationship("RepetitionModel", back_populates="session", cascade="all, delete-orphan")
    task_attempts = relationship("TaskAttemptModel", back_populates="session", cascade="all, delete-orphan")


class RepetitionModel(Base):
    __tablename__ = "repetitions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String(36), ForeignKey("sessions.id"), nullable=False, index=True)
    rep_number = Column(Integer, nullable=False)
    exercise_type = Column(String(50), nullable=False)
    rom_achieved = Column(Float, nullable=False)
    peak_angle = Column(Float, nullable=False)
    hold_duration_s = Column(Float, default=0.0)
    smoothness_score = Column(Float, default=0.0)
    consistency_score = Column(Float, default=0.0)
    quality = Column(String(20), default="GOOD")
    timestamp = Column(DateTime, default=get_utc_now)
    rep_duration_s = Column(Float, default=0.0)
    feedback = Column(Text, default="")
    data_source = Column(String(20), default="live")

    session = relationship("SessionModel", back_populates="repetitions")


class FlagModel(Base):
    __tablename__ = "flags"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=False, index=True)
    severity = Column(String(20), default="INFO")
    flag_type = Column(String(50), nullable=False)
    message = Column(Text, default="")
    session_ids = Column(JSON, default=list)
    metrics = Column(JSON, default=dict)
    threshold = Column(JSON, default=dict)
    created_at = Column(DateTime, default=get_utc_now)
    acknowledged = Column(Boolean, default=False)
    acknowledged_by = Column(String(100), nullable=True)
    acknowledged_at = Column(DateTime, nullable=True)
    ack_note = Column(Text, nullable=True)
    resolution_notes = Column(Text, default="")

    patient = relationship("PatientModel", back_populates="flags")


# ==========================================
# RehabBridge NEXUS Specification v3 Tables
# ==========================================

class ConsentModel(Base):
    __tablename__ = "consents"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    volunteer_pseudonym = Column(String(50), nullable=False, index=True)
    consent_version = Column(String(20), default="1.0.0")
    consent_text_hash = Column(String(64), nullable=False)
    signed_at = Column(DateTime, default=get_utc_now)
    withdrawn_at = Column(DateTime, nullable=True)


class VolunteerModel(Base):
    __tablename__ = "volunteers"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    pseudonym = Column(String(50), unique=True, nullable=False, index=True)
    glove_size = Column(String(10), default="M")
    affected_hand = Column(String(20), default="right")
    notes = Column(Text, default="")
    created_at = Column(DateTime, default=get_utc_now)
    data_source = Column(String(20), default="real")

    sessions = relationship("SessionModel", back_populates="volunteer", cascade="all, delete-orphan")


class DeviceModel(Base):
    __tablename__ = "devices"

    id = Column(String(50), primary_key=True)
    serial_port = Column(String(50), nullable=False)
    firmware_version = Column(String(20), default="1.0.0")
    protocol_version = Column(Integer, default=1)
    profile = Column(String(20), default="demo3")
    first_seen = Column(DateTime, default=get_utc_now)
    last_seen = Column(DateTime, default=get_utc_now)


class CalibrationDBModel(Base):
    __tablename__ = "calibrations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = Column(String(50), nullable=True)
    volunteer_id = Column(String(36), nullable=True)
    profile = Column(String(20), default="demo3")
    parameters_json = Column(JSON, nullable=False)
    status = Column(String(20), default="active")
    created_at = Column(DateTime, default=get_utc_now)
    repeat_index = Column(Integer, default=1)
    config_hash = Column(String(64), nullable=True)

CalibrationModel = CalibrationDBModel


class SensorSampleModel(Base):
    __tablename__ = "sensor_samples"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(36), ForeignKey("sessions.id"), nullable=False, index=True)
    seq = Column(BigInteger, nullable=False)
    device_t_ms = Column(BigInteger, nullable=False)
    host_monotonic_ns = Column(BigInteger, nullable=False, index=True)
    flex_json = Column(JSON, nullable=False)
    fsr = Column(Integer, nullable=True)
    imu_json = Column(JSON, nullable=True)
    flags = Column(Integer, default=0)
    data_source = Column(String(20), default="live")


class VisionSampleModel(Base):
    __tablename__ = "vision_samples"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(36), ForeignKey("sessions.id"), nullable=False, index=True)
    frame_id = Column(BigInteger, nullable=False)
    host_monotonic_ns = Column(BigInteger, nullable=False, index=True)
    marker_visible = Column(Boolean, default=False)
    center_x = Column(Float, nullable=True)
    center_y = Column(Float, nullable=True)
    zone = Column(String(20), default="none")
    detection_rate_1s = Column(Float, default=0.0)


class TaskAttemptModel(Base):
    __tablename__ = "task_attempts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String(36), ForeignKey("sessions.id"), nullable=False, index=True)
    attempt_index = Column(Integer, nullable=False)
    verdict = Column(String(20), nullable=False)  # VERIFIED, FAILED, UNCERTAIN, ABORTED
    reason_codes_json = Column(JSON, default=list)
    started_at = Column(DateTime, default=get_utc_now)
    ended_at = Column(DateTime, nullable=True)
    durations_json = Column(JSON, default=dict)
    camera_visibility = Column(Float, default=1.0)
    packet_loss = Column(Float, default=0.0)
    config_hash = Column(String(64), nullable=True)
    data_source = Column(String(20), default="live")

    session = relationship("SessionModel", back_populates="task_attempts")
    events = relationship("TaskEventDBModel", back_populates="attempt", cascade="all, delete-orphan")
    ground_truth = relationship("GroundTruthModel", back_populates="attempt", uselist=False, cascade="all, delete-orphan")


class TaskEventDBModel(Base):
    __tablename__ = "task_events"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    attempt_id = Column(String(36), ForeignKey("task_attempts.id"), nullable=False, index=True)
    host_monotonic_ns = Column(BigInteger, nullable=False)
    from_state = Column(String(30), nullable=False)
    to_state = Column(String(30), nullable=False)
    reason = Column(String(100), nullable=False)
    evidence_json = Column(JSON, default=dict)

    attempt = relationship("TaskAttemptModel", back_populates="events")


class GroundTruthModel(Base):
    __tablename__ = "ground_truth"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    attempt_id = Column(String(36), ForeignKey("task_attempts.id"), unique=True, nullable=False, index=True)
    label = Column(String(30), nullable=False)  # success | failure | no_attempt | uncertain_expected
    marker_source = Column(String(30), default="operator_key")
    labeller_pseudonym = Column(String(50), default="operator")
    labelled_at = Column(DateTime, default=get_utc_now)
    notes = Column(Text, default="")

    attempt = relationship("TaskAttemptModel", back_populates="ground_truth")


class IngestErrorModel(Base):
    __tablename__ = "ingest_errors"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(36), nullable=True)
    host_ns = Column(BigInteger, nullable=False)
    reason = Column(String(100), nullable=False)
    raw_line_hash = Column(String(64), nullable=True)


class ConfigSnapshotModel(Base):
    __tablename__ = "config_snapshots"

    hash = Column(String(64), primary_key=True)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=get_utc_now)


class AppEventModel(Base):
    __tablename__ = "app_events"

    id = Column(Integer, primary_key=True, autoincrement=True)
    host_ns = Column(BigInteger, nullable=False)
    level = Column(String(20), default="INFO")
    component = Column(String(50), nullable=False)
    message = Column(Text, nullable=False)
