# 💡 H10 / Asthavakra — Professional Q&A Guide
**Clinical & Technical Answers for Smart Evaluators & Physiotherapists**

When presenting to clinical professionals, biomechanics researchers, or software judges, you will receive in-depth questions about our methodology. Use this guide to answer with scientific rigor, clinical precision, and design clarity.

---

### Q1: How do you measure Range of Motion (ROM) without a calibrated goniometer or optical motion capture?
**Answer:**
> *"That is a fundamental design principle of H10: **we never claim joint angles in degrees unless a validated clinical calibration exists**.  
> Instead, we measure normalized flexion percentage ($0–100\%$) derived from individual sensor ADC values. During our two-stage calibration wizard, we capture the patient's resting open-hand baseline ($0\%$) and active fist clench ($100\%$). All subsequent session movements are normalized against the patient's individual dynamic range. This gives therapists an objective, reproducible measure of relative excursion without fabricating non-validated degree angles."*

---

### Q2: Why compare recovery against the patient's own baseline instead of population norms?
**Answer:**
> *"In neuro-rehabilitation, comparing a 70-year-old stroke patient to a healthy 20-year-old population average is clinically misleading and emotionally demoralizing.  
> Every hand has distinct anatomical geometry, tissue resistance, and baseline impairment. H10 calculates the median of the patient's first three valid sessions to establish their **individualized recovery baseline**. We then classify progress into five clinical trends: Improving, Stable, Deteriorating, Plateau, or Insufficient Data. This provides therapists with meaningful longitudinal delta metrics."*

---

### Q3: How does your repetition counter prevent false counts from involuntary tremors or spasms?
**Answer:**
> *"We do not use simple threshold crossings or peak detectors, which are notoriously prone to tremor-induced false positives.  
> Instead, we implemented a **dual-threshold hysteresis state machine**:
> 1. The flexion signal must pass the **Upper Threshold** (e.g., $70\%$ ROM) to enter the `flexing` state.
> 2. The patient must sustain that flexion for a prescribed **Hold Time** (default $0.5\text{ s}$).
> 3. The repetition is only registered after the patient actively relaxes below the **Lower Threshold** (e.g., $30\%$ ROM).
> 4. Additionally, we enforce a **$300\text{ ms}$ debounce window** and physiological duration bounds ($0.6\text{ s} \le t \le 8.0\text{ s}$). Tremors and twitch oscillations never complete a valid cycle."*

---

### Q4: What is the streaming latency and sampling rate?
**Answer:**
> *"The flex sensors sample at $50\text{ Hz}$ and the MPU6050 IMU samples internally at $100\text{ Hz}$, downsampled to the $50\text{ Hz}$ application stream.  
> Packets are transmitted over local Wi-Fi WebSocket using a compact **30-byte little-endian binary packet**. End-to-end latency from physical finger bend to canvas rendering on screen is under **$25\text{ ms}$**, which is well below the human visual perception threshold of $50\text{ ms}$, creating instantaneous real-time biofeedback."*

---

### Q5: How do you handle patient data privacy and medical compliance?
**Answer:**
> *"H10 follows strict privacy-by-design principles:
> 1. **PII Refusal:** The local app and FastAPI backend strictly refuse names, phone numbers, email addresses, or government IDs. Patients are identified exclusively by randomized research pseudonyms (e.g. `P-014`).
> 2. **Offline-First:** All calibration data, session repetitions, and ROM calculations are executed and persisted locally on the device. An internet connection is never required to complete rehabilitation.
> 3. **Non-Medical Boundary:** The system clearly identifies itself on all screens as a monitoring prototype for research and demonstration, never issuing medical diagnoses or prescriptions."*

---

### Q6: How do you objectively detect muscle fatigue before injury occurs?
**Answer:**
> *"We monitor the **Fatigue Drop Index**. A session requires at least 6 repetitions to evaluate fatigue. The engine calculates the average peak ROM of the first 3 repetitions versus the last 3 repetitions:
> $$\text{Drop} = \frac{\overline{\text{ROM}}_{\text{first 3}} - \overline{\text{ROM}}_{\text{last 3}}}{\overline{\text{ROM}}_{\text{first 3}}} \times 100\%$$
> If the drop exceeds the prescribed threshold (typically $20\%$), or if the dimensionless jerk increases significantly (indicating jerky, compensatory motor recruitment), the system flags potential fatigue for the therapist to review."*

---

### Q7: What automated clinical flags does the system generate for physiotherapists?
**Answer:**
> *"We built 6 rule-based clinical flags that automatically alert therapists on their dashboard:
> 1. `rom_below_plan`: Peak ROM failed to reach prescribed target.
> 2. `fatigue_detected`: Sustained drop in repetition amplitude $> 20\%$.
> 3. `pain_increase`: Borg pain rating increased by $\ge 2$ points compared to baseline.
> 4. `adherence_low`: Weekly completed sessions fell below the prescribed plan.
> 5. `plateau_detected`: Zero significant ROM change over 14 consecutive days.
> 6. `abnormal_jerk`: Movement smoothness deteriorated significantly, suggesting spasticity or compensatory shoulder movement."*

---

### Q8: Why did you choose Flutter over native iOS/Android or React Native?
**Answer:**
> *"Three reasons:
> 1. **Custom Canvas Performance:** We draw a live 2D articulated hand and real-time Okabe-Ito finger bars using Flutter's hardware-accelerated Skia/Impeller `CustomPainter` at 60 FPS.
> 2. **Single-Source Parity:** The exact same Dart codebase compiles to native Android APK, iOS, and Web without duplicating UI logic or signal math.
> 3. **Accessible Design Consistency:** Flutter allows absolute control over typography, touch target dimensions ($48\text{ px}$ minimum), and high-contrast styling across all platforms."*

---

### Q9: What is the role of Machine Learning (Model A) in this prototype?
**Answer:**
> *"Model A is an on-device exercise recognition classifier. It extracts a 14-dimensional kinematic feature vector (`feat-v1`) across 2-second sliding windows (mean, standard deviation, and range per flex channel plus IMU magnitude) to classify whether the patient is performing a Fist Clench, Finger Tap, Pinch, or Wrist Rotation.  
> It operates under a feature flag as an assistive verification layer to confirm exercise adherence without replacing our deterministic physics engine."*

