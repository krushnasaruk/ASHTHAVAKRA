# H10 — Architecture Decision Records (ADRs)

Key architectural decisions, trade-offs, and design rationales made during the development of H10.

---

## ADR 01: Pure Dart Package (`h10_core`) for Signal Mathematics
- **Status:** Accepted & Implemented.
- **Context:** Signal processing, digital filtering, repetition detection, and kinematic scoring are shared between the mobile patient app and the clinician dashboard.
- **Decision:** Implement all mathematics, filters, quality gates, and data models in a standalone pure Dart package (`mobile/packages/h10_core`) with **zero Flutter dependencies**.
- **Consequences:**
  - Enables unit testing in isolation (`dart test`) without launching the Flutter test environment.
  - Allows seamless code reuse between the mobile patient app (`mobile/`) and the clinician web dashboard (`admin/`).
  - Strict separation of business logic from UI widgets.

---

## ADR 02: Hysteresis State Machine Over Zero-Crossing / Peak Detection
- **Status:** Accepted & Implemented.
- **Context:** Neurological rehabilitation patients frequently suffer from tremor, hesitation, spasticity, and multi-effort attempts during a single repetition. Naive peak finders cause severe double-counting.
- **Decision:** Implement an 8-state hysteresis state machine requiring signal ascent above $70\%$, sustained hold of $0.5\text{ s}$, descent below $25\%$, and a $300\text{ ms}$ refractory debounce.
- **Consequences:** Eliminates spurious triggers during tremulous oscillations; accurately flags incomplete repetitions.

---

## ADR 03: Dimensionless Jerk for Movement Smoothness
- **Status:** Accepted & Implemented.
- **Context:** Smoothness reflects motor coordination recovery. Simple mean jerk magnitude varies with the amplitude and duration of movement.
- **Decision:** Adopt the dimensionless jerk formulation:
  $$D_J = -\frac{(t_{\text{end}} - t_{\text{start}})^5}{(s_{\text{max}} - s_{\text{min}})^2} \int \left(\frac{d^3 s}{dt^3}\right)^2 dt$$
- **Consequences:** Normalizes for differing movement tempos and amplitudes, allowing direct longitudinal comparison across sessions.

---

## ADR 04: Google Colab Training Workflow for ML
- **Status:** Accepted & Implemented.
- **Context:** Training ML models with deep cross-validation locally consumes developer hardware resources and requires heavy dependencies.
- **Decision:** Provide self-contained Google Colab notebooks and scripts (`ml/colab/`) for reproducible remote training on GPU/CPU runtimes, while maintaining complete feature extraction parity ($< 10^{-6}$) and on-device inference testing locally.
- **Consequences:** Zero waste of local compute resources while preserving complete scientific reproducibility.

---

## ADR 05: Idempotent Sync with SHA-256 Conflict Detection
- **Status:** Accepted & Implemented.
- **Context:** Mobile apps operate in home environments with unreliable network connectivity, resulting in retry storms and duplicate HTTP requests.
- **Decision:** Compute a deterministic SHA-256 hash of session telemetry. If an identical session ID is submitted with an identical hash, return `200 OK` (idempotent success). If submitted with differing telemetry, return `409 Conflict`.
- **Consequences:** Guarantees zero duplicate database rows while preventing silent data overwrites.

---

## ADR 06: Unified Hackathon Decisions (D-01 through D-11)
- **Status:** Accepted & Implemented in Build Spec v3.

| ID | Topic | Decision | Reason |
|---|---|---|---|
| **D-01** | Hardware profile | Two profiles: `demo3` (thumb, index, middle flex + FSR + IMU) and `full5` (all five flex + FSR + IMU). The software supports any subset of five flex channels. | Keeps H10 five-finger requirement while matching event budget. |
| **D-02** | Event transport | USB serial, newline-delimited JSON at 921600 baud. | Reliable, works completely offline, zero Wi-Fi dependency at the venue. |
| **D-03** | Later transport | Wi-Fi WebSocket adapter with the same logical packet (H10 §5.3 binary packet). | Preserves long-term H10 requirement. |
| **D-04** | Processing engine | Python for event; Dart port in T3 verified by parity fixture. | One authoritative source of truth for the event engine. |
| **D-05** | Frontend | React + Vite + TypeScript for event; Flutter apps consume the same HTTP and WebSocket API. | Fastest reliable demo UI with dual operator/judge view. |
| **D-06** | Backend | FastAPI, SQLite with WAL mode, single local process. | One simple process to start during live demo. |
| **D-07** | Object tracking | ArUco fiducial markers (OpenCV `DICT_4X4_50`). No ML training for object recognition. | Deterministic, testable, robust under event lighting. |
| **D-08** | Verdict set | `VERIFIED`, `FAILED`, `UNCERTAIN`, `ABORTED`, `NOT_STARTED`. | Adds `ABORTED` for operator stops and `UNCERTAIN` for missing/stale telemetry. |
| **D-09** | Repetition exercises | H10 repetition engine kept; used in T2 for exercise modes. The event task uses TaskProof. Both share the same signal layer. | Keeps both feature sets seamlessly integrated. |
| **D-10** | Sample rate | Flex and FSR at 25 readings/s per channel from one ADS1115 scan loop; IMU at 25 Hz; stream packet at 25 Hz. | ADS1115 multiplexing limits per-channel rate reliably. |
| **D-11** | Clinical claims | Output is task-level only. No health score in the event build. H10 metrics appear with explicit non-medical disclaimers. | Matches honest-claims mandate. |


