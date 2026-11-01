from typing import List, Optional, Dict, Any
from datetime import datetime
import re
from pydantic import BaseModel, Field, field_validator, ConfigDict


class PatientBase(BaseModel):
    pseudonym: str = Field(description="Pseudonymous identifier e.g. P-014")
    affected_hand: str = Field(default="unknown")
    notes: Optional[str] = ""
    data_source: str = Field(default="real")

    @field_validator("pseudonym")
    @classmethod
    def validate_pseudonym(cls, v: str) -> str:
        # Check pseudonym format (e.g. P-014, P-SIM-001)
        if not re.match(r"^P-[A-Za-z0-9_-]+$", v):
            raise ValueError("Pseudonym must follow format 'P-XXX' (e.g. P-014)")
        # Reject real names, emails, phones
        pii_patterns = [r"@.*?\.", r"^[A-Z][a-z]+ [A-Z][a-z]+$", r"^\+?[0-9]{10,}$"]
        for p in pii_patterns:
            if re.search(p, v):
                raise ValueError("PII rejected: Real names, emails, and phone numbers are strictly prohibited")
        return v


class PatientCreate(PatientBase):
    pass


class PatientUpdate(BaseModel):
    affected_hand: Optional[str] = None
    notes: Optional[str] = None


class PatientRead(PatientBase):
    id: str
    created_at: datetime
    is_deleted: bool

    model_config = ConfigDict(from_attributes=True)


class PlanCreate(BaseModel):
    exercise_id: str
    target_reps: int = Field(default=10, ge=1, le=100)
    target_rom_min: float = Field(default=70.0, ge=0.0, le=100.0)
    target_rom_max: float = Field(default=100.0, ge=0.0, le=100.0)
    hold_s: float = Field(default=0.5, ge=0.0, le=10.0)
    rest_s: float = Field(default=2.0, ge=0.0, le=60.0)
    sessions_per_week: int = Field(default=5, ge=1, le=28)
    stop_instruction: str = Field(default="Stop if you feel sharp pain. Rest as needed.")
    fatigue_drop_threshold: float = Field(default=20.0, ge=5.0, le=50.0)
    set_by: str = Field(default="Clinician")


class PlanRead(PlanCreate):
    id: str
    patient_id: str
    valid_from: datetime
    valid_to: Optional[datetime] = None
    version: int

    model_config = ConfigDict(from_attributes=True)


class RepetitionIn(BaseModel):
    id: Optional[str] = None
    index: int
    start_ms: int
    end_ms: int
    duration_s: float
    peak: float
    mean: float
    min: float
    rom: float
    hold_s: float = 0.0
    smoothness: Optional[float] = None
    quality: str = "good"
    status: str = "complete"
    reject_reason: Optional[str] = None


class SessionCreate(BaseModel):
    id: str = Field(description="Client UUID idempotency key")
    patient_id: str
    exercise_code: str
    plan_version: int = 1
    started_at: datetime
    ended_at: datetime
    duration_s: float
    reps_completed: int
    reps_target: int
    reps_interrupted: int = 0
    mean_rom: float
    max_rom: float
    mean_rep_duration_s: float
    smoothness: Optional[float] = None
    hold_s: float = 0.0
    consistency: Optional[float] = None
    consistency_components: Optional[Dict[str, Any]] = None
    fatigue_drop_pct: Optional[float] = None
    pain_before: Optional[int] = Field(default=None, ge=0, le=10)
    pain_after: int = Field(ge=0, le=10)
    fatigue_before: Optional[int] = Field(default=None, ge=0, le=10)
    fatigue_after: int = Field(ge=0, le=10)
    note: Optional[str] = ""
    data_quality: str = "good"
    data_source: str = "real"
    device_id: str = "unknown"
    firmware: str = "1.0.0"
    calibration_ref: str = ""
    model_version: Optional[str] = None
    client_version: str = "1.0.0"
    created_at: datetime
    repetitions: List[RepetitionIn] = []


class SessionRead(SessionCreate):
    received_at: datetime
    is_deleted: bool

    model_config = ConfigDict(from_attributes=True)


class FlagRead(BaseModel):
    id: str
    patient_id: str
    type: str
    severity: str
    created_at: datetime
    session_ids: List[str]
    message: str
    metric_values: Dict[str, Any]
    threshold_used: Dict[str, Any]
    acknowledged_at: Optional[datetime] = None
    acknowledged_by: Optional[str] = None
    ack_note: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class FlagAcknowledge(BaseModel):
    acknowledged_by: str
    ack_note: Optional[str] = ""
