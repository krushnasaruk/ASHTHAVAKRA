# H10 — Security, Privacy & Compliance Notes

This document details the data security boundaries, threat model, and regulatory compliance constraints of the H10 prototype.

---

## 1. Regulatory Status & Non-Medical Device Notice

> **CRITICAL CLINICAL BOUNDARY**  
> H10 is a research prototype monitoring system for physical therapy evaluation. **It is not a certified medical device** under EU MDR 2017/745 or US FDA 21 CFR Part 820.
> - It does not provide clinical diagnosis.
> - It does not provide medical treatment or prescribe therapy.
> - It does not predict recovery milestones or dates.
> - All telemetry, consistency scores, and fatigue indices are descriptive physical measurements requiring qualified clinical interpretation.

---

## 2. Privacy & Pseudonymization Architecture

### 2.1 Zero-PII Policy
In accordance with research ethics standards (HIPAA Safe Harbor / GDPR Article 89 for research), H10 enforces a **Zero-PII** architecture:
- Patients are identified exclusively by random alphanumeric research pseudonyms (e.g. `P-014`).
- No names, national identity numbers, dates of birth, email addresses, phone numbers, or facial photos are accepted or stored in the database.
- Any API request attempting to send PII attributes triggers a hard `400 Bad Request` rejection with audit logging.

### 2.2 Local Prototype Disclaimer
In this local prototype demonstration:
- Transport is local Wi-Fi / HTTP / WebSocket without TLS certificates.
- Database storage is a local SQLite file (`h10_rehab.db`) without encryption-at-rest.
- **Mandatory Statement:** *The local development prototype is unsuitable for real identifiable clinical patient records without the deployment of TLS 1.3 transport encryption, user authentication / OAuth2 tokens, database encryption (SQLCipher), and institutional review board (IRB) ethics approval.*

---

## 3. Data Integrity & Threat Mitigation

| Threat Vector | Mitigation in H10 |
|---|---|
| **Telemetry Tampering / Ingestion Replays** | Sessions calculate a deterministic SHA-256 payload hash. Ingestion is idempotent; conflicting replays are rejected with `409 Conflict`. |
| **Model Weight Tampering** | On-device ML loading verifies the SHA-256 cryptographic hash of `model_a.tflite` against `model_manifest.json` before initialization. |
| **Unauthorized Plan Alteration** | Every plan update creates a new version with required clinical justification, clinician ID, and immutable logging in `audit_log`. |
| **Silent Sensor Disconnection** | Session quality gate detects loss of variance ($\sigma = 0$) or out-of-bounds ADC readings ($< 50$ or $> 4000$), raising an immediate error. |

