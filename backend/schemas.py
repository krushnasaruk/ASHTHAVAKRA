from typing import List, Optional, Dict, Any
from datetime import datetime
import re
from pydantic import BaseModel, Field, field_validator, ConfigDict


# ==========================================
# Patient & Volunteer Schemas
# ==========================================

class PatientBase(BaseModel):
    pseudonym: str = Field(description="Pseudonymous identifier e.g. P-014")
    affected_hand: str = Field(default="unknown")
    notes: Optional[str] = ""
    data_source: str = Field(default="real")

    @field_validator("pseudonym")
    @classmethod
    def validate_pseudonym(cls, v: str) -> str:
        if not re.match(r"^[PV]-[A-Za-z0-9_-]+$", v):
            raise ValueError("Pseudonym must follow format 'P-XXX' or 'V-XXX' (e.g. P-014, V-001)")
        # Reject real names, emails, phones, dates of birth
        pii_patterns = [
            r"@.*?\.",
            r"^[A-Z][a-z]+ [A-Z][a-z]+$",
            r"^\+?[0-9]{10,}$",
            r"\b(19\d\d|20\d\d)[-/](0[1-9]|1[0-2])[-/](0[1-9]|[12]\d|3[01])\b"
        ]
        for p in pii_patterns:
            if re.search(p, v):
                raise ValueError("PII rejected: Real names, dates of birth, emails, and phone numbers are strictly prohibited")
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


class VolunteerCreate(BaseModel):
    pseudonym: str = Field(description="Volunteer pseudonym, e.g. V-001")
    glove_size: str = Field(default="M")
    affected_hand: str = Field(default="right")
    notes: Optional[str] = ""

    @field_validator("pseudonym")
    @classmethod
    def validate_volunteer_pseudonym(cls, v: str) -> str:
        if not re.match(r"^V-[A-Za-z0-9_-]+$", v):
            raise ValueError("Volunteer pseudonym must match 'V-XXX' (e.g. V-001)")
        # PII checks
        if " " in v or "@" in v:
            raise ValueError("PII rejected: Names and contact details are prohibited")
        return v


class VolunteerRead(BaseModel):
    id: str
    pseudonym: str
    glove_size: str
    affected_hand: str
    notes: Optional[str]
    created_at: datetime
    data_source: str

    model_config = ConfigDict(from_attributes=True)


class ConsentCreate(BaseModel):
    volunteer_pseudonym: str
    consent_version: str = "1.0.0"
    consent_text_hash: str


class ConsentRead(BaseModel):
    id: str
    volunteer_pseudonym: str
    consent_version: str
    consent_text_hash: str
    signed_at: datetime
    withdrawn_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# Plan & Repetition Schemas (H10)
# ==========================================

class PlanCreate(BaseModel):
    exercise_id: str
    target_reps: int = 10
    target_rom_min: float = 70.0
    target_rom_max: float = 100.0
    hold_s: float = 0.5
    rest_s: float = 2.0
    sessions_per_week: int = 5
    stop_instruction: str = "Stop if you feel sharp pain. Rest as needed."
    fatigue_drop_threshold: float = 20.0
    set_by: str = "Clinician"


class PlanRead(PlanCreate):
    id: str
    patient_id: str
    version: int
    valid_from: datetime
    valid_to: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class RepetitionCreate(BaseModel):
    rep_number: int
    exercise_type: str
    rom_achieved: float
    peak_angle: float
    hold_duration_s: float = 0.0
    smoothness_score: float = 0.0
    consistency_score: float = 0.0
    quality: str = "GOOD"
    rep_duration_s: float = 0.0
    feedback: str = ""
    data_source: str = "live"


class RepetitionRead(RepetitionCreate):
    id: str
    session_id: str
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)


class SessionCreate(BaseModel):
    id: Optional[str] = None
    patient_id: Optional[str] = None
    volunteer_id: Optional[str] = None
    mode: str = "task"
    exercise_code: Optional[str] = None
    plan_version: Optional[int] = None
    device_id: Optional[str] = None
    calibration_id: Optional[str] = None
    started_at: datetime
    ended_at: Optional[datetime] = None
    data_source: str = "live"
    config_hash: Optional[str] = None
    client_version: str = "3.0.0"
    notes: Optional[str] = ""
    pain_before: Optional[int] = None
    pain_after: Optional[int] = None
    fatigue_before: Optional[int] = None
    fatigue_after: Optional[int] = None
    repetitions: List[RepetitionCreate] = []


class SessionRead(BaseModel):
    id: str
    patient_id: Optional[str]
    volunteer_id: Optional[str]
    mode: str
    started_at: datetime
    ended_at: Optional[datetime]
    data_source: str
    config_hash: Optional[str]
    repetitions: List[RepetitionRead] = []

    model_config = ConfigDict(from_attributes=True)


class FlagRead(BaseModel):
    id: str
    patient_id: str
    severity: str
    flag_type: str
    message: str
    created_at: datetime
    acknowledged: bool

    model_config = ConfigDict(from_attributes=True)


class FlagAcknowledge(BaseModel):
    acknowledged_by: str = "Clinician"
    resolution_notes: Optional[str] = ""


# ==========================================
# TaskProof & NEXUS Schemas
# ==========================================

class TaskAttemptCreate(BaseModel):
    id: Optional[str] = None
    session_id: str
    attempt_index: int
    verdict: str  # VERIFIED, FAILED, UNCERTAIN, ABORTED
    reason_codes: List[str] = []
    started_at: datetime
    ended_at: Optional[datetime] = None
    durations: Dict[str, float] = {}
    camera_visibility: float = 1.0
    packet_loss: float = 0.0
    config_hash: Optional[str] = None
    data_source: str = "live"


class TaskAttemptRead(BaseModel):
    id: str
    session_id: str
    attempt_index: int
    verdict: str
    reason_codes_json: List[str]
    started_at: datetime
    ended_at: Optional[datetime]
    durations_json: Dict[str, float]
    camera_visibility: float
    packet_loss: float
    config_hash: Optional[str]
    data_source: str

    model_config = ConfigDict(from_attributes=True)


class GroundTruthCreate(BaseModel):
    attempt_id: str
    label: str  # success | failure | no_attempt | uncertain_expected
    marker_source: str = "operator_key"
    labeller_pseudonym: str = "operator"
    notes: Optional[str] = ""


class GroundTruthRead(BaseModel):
    id: str
    attempt_id: str
    label: str
    marker_source: str
    labeller_pseudonym: str
    labelled_at: datetime
    notes: Optional[str]

    model_config = ConfigDict(from_attributes=True)


class PreflightCheckItem(BaseModel):
    name: str
    status: str  # pass | warn | fail
    required: bool
    details: str
    hint: Optional[str] = None


class PreflightResponse(BaseModel):
    overall_status: str  # pass | warn | fail
    ready_to_start: bool
    checks: List[PreflightCheckItem]


class EvaluationResponse(BaseModel):
    total_attempts: int
    verified_count: int
    failed_count: int
    uncertain_count: int
    aborted_count: int
    ground_truth_count: int
    agreements: int
    disagreements: int
    precision: Optional[float]
    recall: Optional[float]
    precision_wilson_ci: Optional[List[float]]
    recall_wilson_ci: Optional[List[float]]
    uncertain_rate: float
