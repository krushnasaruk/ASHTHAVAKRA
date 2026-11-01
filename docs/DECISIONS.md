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
