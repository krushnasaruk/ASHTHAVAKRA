# H10 — Backend REST API Specification

The H10 backend is implemented in Python using FastAPI, providing high-performance RESTful APIs and SQLite persistence.

---

## 1. Core Principles
- **Base URL:** `http://localhost:8000`
- **Strict Pseudonymization:** All patient endpoints require pseudonym IDs (`P-XXX`). Payloads containing PII (names, emails, phone numbers, SSNs) are rejected with `400 Bad Request`.
- **Idempotent Ingestion:** Mobile clients operating offline may retry syncs. Submitting an identical session ID with identical telemetry returns `200 OK`. Submitting an existing session ID with conflicting telemetry returns `409 Conflict`.
- **Non-Destructive Deletions:** Deleting a patient creates a tombstone and detaches associated records.

---

## 2. API Endpoints

### 2.1 Health Check
- **`GET /health`**
- **Response `200 OK`:**
  ```json
  {
    "status": "healthy",
    "service": "H10 Rehabilitation Research Backend",
    "version": "1.0.0",
    "timestamp": "2026-11-01T10:00:00Z"
  }
  ```

### 2.2 Patient Management
- **`GET /patients`**: Returns list of active patients.
- **`POST /patients`**: Registers new pseudonymized patient.
  - Body: `{"pseudonym": "P-042", "affected_hand": "right", "notes": "Stroke recovery"}`
- **`GET /patients/{patient_id}`**: Retrieves patient demographic and baseline summary.
- **`DELETE /patients/{patient_id}`**: Soft-deletes patient via tombstone flag.

### 2.3 Rehabilitation Plans
- **`GET /plans/{patient_id}`**: Retrieves current active plan for patient.
- **`POST /plans`**: Creates a new versioned rehabilitation plan.
  - Body:
    ```json
    {
      "patient_id": "P-014",
      "exercise_id": "fist_clench",
      "target_reps": 12,
      "target_rom_min": 70.0,
      "target_rom_max": 100.0,
      "hold_s": 0.5,
      "rest_s": 2.0,
      "sessions_per_week": 5,
      "stop_instruction": "Stop if sharp pain.",
      "fatigue_drop_threshold": 20.0,
      "set_by": "Dr. Sarah Adams"
    }
    ```
  - Archiving: Automatically closes validity window (`valid_to = now()`) of previous version.

### 2.4 Sessions & Sync
- **`POST /sessions`**: Ingests completed exercise session with nested repetitions.
  - Idempotency logic:
    - New `session_id` $\to$ inserts record, returns `201 Created`.
    - Existing `session_id` with matching hash $\to$ returns `200 OK`.
    - Existing `session_id` with altered data $\to$ returns `409 Conflict`.
- **`GET /sessions`**: Query sessions by `patient_id`, `exercise_code`, `date_from`, `date_to`.

### 2.5 Clinical Flags & Audit
- **`GET /flags`**: Query flags by `patient_id` and status (`open`, `acknowledged`, `all`).
- **`POST /flags/{flag_id}/acknowledge`**: Clinician reviews and acknowledges flag.
  - Body: `{"clinician_id": "Dr. Sarah Adams", "note": "Adjusted repetition targets."}`
- **`GET /overview`**: Clinician dashboard aggregated metrics (total patients, open flags, sessions today, 7-day adherence rate).
- **`GET /export`**: Telemetry data export in CSV or JSON format.

