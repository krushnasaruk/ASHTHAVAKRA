# H10 — Database Schema & Architecture

The database is built on SQLite using SQLAlchemy ORM (`backend/models.py`), structured for fast relational queries, non-destructive auditability, and pseudonymized patient privacy.

---

## 1. Entity-Relationship Diagram

```mermaid
erDiagram
    PATIENTS ||--o{ PLANS : "prescribed"
    PATIENTS ||--o{ SESSIONS : "performs"
    PATIENTS ||--o{ FLAGS : "triggers"
    SESSIONS ||--o{ REPETITIONS : "contains"
    SESSIONS ||--o{ CALIBRATIONS : "calibrated_by"
    PLANS ||--o{ AUDIT_LOGS : "audits"
    FLAGS ||--o{ AUDIT_LOGS : "audits"

    PATIENTS {
        string id PK
        string pseudonym UK
        string affected_hand
        string notes
        string data_source
        boolean is_deleted
        datetime created_at
    }

    PLANS {
        string id PK
        string patient_id FK
        string exercise_id
        integer version
        integer target_reps
        float target_rom_min
        float target_rom_max
        float hold_s
        float rest_s
        integer sessions_per_week
        string stop_instruction
        float fatigue_drop_threshold
        datetime valid_from
        datetime valid_to
        string set_by
    }

    SESSIONS {
        string id PK
        string patient_id FK
        string exercise_code
        integer plan_version
        datetime started_at
        datetime ended_at
        float duration_s
        integer reps_completed
        integer reps_target
        float mean_rom
        float max_rom
        float mean_rep_duration_s
        float hold_s
        float consistency
        float fatigue_drop_pct
        integer pain_before
        integer pain_after
        integer fatigue_before
        integer fatigue_after
        string data_quality
        string data_source
        string payload_hash
        datetime received_at
    }

    REPETITIONS {
        string id PK
        string session_id FK
        integer rep_index
        integer start_ms
        integer end_ms
        float duration_s
        float peak
        float mean
        float min
        float rom
        float hold_s
        float smoothness
        string quality
        string status
        string reject_reason
    }

    FLAGS {
        string id PK
        string patient_id FK
        string type
        string severity
        string message
        text metric_values_json
        text threshold_used_json
        datetime created_at
        datetime acknowledged_at
        string acknowledged_by
        string ack_note
    }

    AUDIT_LOGS {
        integer id PK
        string action
        string entity_id
        string clinician_id
        string justification
        datetime timestamp
    }
```

---

## 2. Table Specifications

### 2.1 `patients`
- Primary key: `id` (UUID).
- `pseudonym`: Unique constraint (e.g. `P-014`). No patient names, phone numbers, or emails are stored.
- `is_deleted`: Tombstone boolean flag for soft deletion.

### 2.2 `plans`
- Versioning: `version` monotonically increments (v1, v2, v3...) upon modification.
- Validity windows: `valid_from` and `valid_to` track temporal activation; previous plans are archived, never overwritten.

### 2.3 `sessions`
- `payload_hash`: SHA-256 hash of core telemetry fields used to guarantee idempotency on retry.
- `data_source`: Marked `'real'` or `'simulated'`.
- `data_quality`: `'good'`, `'reduced'`, or `'invalid'`.

### 2.4 `repetitions`
- Detailed breakdown of each segmented cycle within the session.
- Tracks peak excursion, mean, dimensionless jerk smoothness, hold time, and validation status (`complete`, `interrupted`, `rejected`).
