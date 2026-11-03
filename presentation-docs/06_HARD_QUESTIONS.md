<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# RehabBridge NEXUS / H10 — Adversarial Judge Defense (12 Hard Questions)

**Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Rule:** Concede what is true, state what the prototype does measure, and name the next step. Never deflect or claim unmeasured performance.

---

### HQ-01: "What is your sample size, and can you claim any accuracy?"
- **Primary Owner:** Developer
- **What is True (The Concession):** Our sample size is exactly $n=10$ labelled trials conducted during bench testing. We cannot claim statistical reliability or clinical accuracy.
- **What We Do Measure:** Across our 10 consecutive bench attempts, our deterministic state machine achieved 10 out of 10 agreements with operator ground truth (observed precision: 1.0). However, calculating the standard 95% Wilson score confidence interval on $n=10$ yields a wide range of $[72.25\%, 100.0\%]$.
- **The Next Step:** We explicitly report this in our evaluation exports as an engineering demonstration. Establishing real clinical accuracy requires an institutional ethics-approved trial with a minimum of 30 stroke survivors.

---

### HQ-02: "Isn't this just a camera and a flex sensor put together?"
- **Primary Owner:** Developer
- **What is True (The Concession):** Yes, the physical hardware consists of an off-the-shelf camera, resistive flex sensors, an FSR, and an ESP32. We have not invented a novel sensor physics transducer.
- **What We Do Measure:** The core innovation is not the transducer—it is the **TaskProof deterministic verification state machine**. An isolated flex sensor cannot prove an object was moved; an isolated camera cannot prove hand contact. We fuse the two modalities through an invariant 7-state pipeline: physical contact must precede lift; spatial translation must traverse zones; post-release stillness must hold for 500 ms. If visual tracking drops for 150 ms, the system issues an honest `UNCERTAIN` verdict instead of guessing.
- **The Next Step:** Transition from individual commercial breakout components to a monolithic custom PCB with integrated medical-grade flex arrays.

---

### HQ-03: "Why would a therapist trust a verdict from a student project?"
- **Primary Owner:** Developer / Vaishnavi
- **What is True (The Concession):** A qualified therapist should not make clinical diagnostic or treatment decisions based on this student prototype today.
- **What We Do Measure:** Our system does not diagnose or give medical advice. It acts as an objective task ledger. Today, when a patient exercises at home, therapists receive zero objective data—only unreliable self-reported diaries. What our tool provides is an immutable, timestamped audit trail: exact start times, transfer durations, and cryptographic SHA-256 evidence bundles that prove whether the patient completed their prescribed repetitions.
- **The Next Step:** Partner with local physiotherapy clinics to run concurrent blinded trials comparing TaskProof session logs against therapist clinical observation scores.

---

### HQ-04: "What happens if the volunteer cheats or fakes the grip?"
- **Primary Owner:** Gautam
- **What is True (The Concession):** If a volunteer wears the glove and carefully lifts the block using only their fingernails without touching the palmar FSR, the system can be fooled into rejecting a valid transfer or failing to register contact.
- **What We Do Measure:** The system prevents common cheating vectors:
  1. *Moving the block with the other bare hand:* The camera sees the block move, but the gloved hand registers zero FSR contact $\rightarrow$ Verdict: `FAILED`.
  2. *Making a fist next to the block without touching it:* Flex sensors trigger, but FSR is open and marker does not move $\rightarrow$ Verdict: `FAILED` (timeout).
  3. *Throwing the block:* Object is released before entering Zone B $\rightarrow$ Verdict: `FAILED`.
- **The Next Step:** Add fingertip FSR contact sensors on the thumb and index finger pads to complement the palmar contact sensor.

---

### HQ-05: "Does this work on every hand size and skin tone?"
- **Primary Owner:** Gautam / Vaishnavi
- **What is True (The Concession):** No. Our prototype has only been verified on medium-to-large adult hands (17–20 cm palm length) and uses a cotton glove substrate.
- **What We Do Measure:** Skin tone has **zero impact** on our sensing pipeline because we do not use optical PPG or RGB skin-segmentation computer vision. Tracking relies strictly on black-and-white ArUco fiducial markers with adaptive local thresholding, and kinematics rely on resistive bend physics. For hand size, our floating sleeve design accommodates up to 25 mm of finger length variation.
- **The Next Step:** Fabricate three modular glove sizes (Small, Medium, Large) using elastomeric silicone webbing to fit pediatric and arthritic patients.

---

### HQ-06: "Why not use machine learning for gesture recognition?"
- **Primary Owner:** Developer
- **What is True (The Concession):** Machine learning models are powerful for complex, high-dimensional gesture vocabularies like American Sign Language.
- **What We Do Measure:** For functional task verification, ML introduces unacceptable failure modes: black-box hallucinations, sensitivity to unmodeled lighting shifts, and an inability to explain *why* a classification failed. If a patient drops an object mid-air, an ML model may still output "Grasp: 88%" based on finger posture alone. TaskProof uses deterministic state guards that can be formally audited and mathematically verified.
- **The Next Step:** Deploy our trained Colab ML model (`ml/colab/`) purely as an assistive classifier for repetition counting in Tier 2, while retaining deterministic TaskProof for safety-critical task verification.

---

### HQ-07: "Where is your regulatory approval (CDSCO, FDA, CE)?"
- **Primary Owner:** Developer
- **What is True (The Concession):** We have zero regulatory approvals. This prototype is strictly an engineering demonstrator built for Innovation 2K26.
- **What We Do Measure:** We have architected the software and hardware to comply with foundational medical device engineering principles: strict PII elimination, cryptographic audit hashing, electrical low-voltage 3.3V isolation, and permanent non-medical disclaimer notices across every screen.
- **The Next Step:** Follow the Central Drugs Standard Control Organisation (CDSCO) Class B pathway, preparing technical documentation for ISO 13485 quality systems and IEC 60601-1 electrical safety testing.

---

### HQ-08: "What did the simulator show versus the real physical glove?"
- **Primary Owner:** Developer
- **What is True (The Concession):** Our initial software simulator produced clean, idealized data that hid physical hardware noise and mechanical latency.
- **What We Do Measure:** When we connected the real physical glove, three distinct real-world physical phenomena appeared:
  1. *FSR Mechanical Settling Lag:* The EVA foam backing retains mechanical deformation for ~100 ms after release, requiring us to add a 150 ms release hold time in code.
  2. *Sensor Span Drift:* Taking the glove on and off shifted baseline resistance by up to 12%, prompting our two-point calibration routine.
  3. *Channel Settling on ADS1115:* Attempting to scan at 50 Hz caused cross-channel charge leakage, proving that 25 Hz was the maximum clean sampling rate.
- **The Next Step:** Build hardware-in-the-loop automated test fixtures with motorized finger actuators to benchmark sensor fatigue over 10,000 cycles.

---

### HQ-09: "Why should anyone pay for this when a therapist can just watch with their eyes?"
- **Primary Owner:** Vaishnavi
- **What is True (The Concession):** In a one-on-one clinic visit, an experienced physiotherapist provides clinical judgment that no glove can replace.
- **What We Do Measure:** The problem is that clinic visits last only 45 minutes once or twice a week. Motor recovery requires hundreds of repetitions performed at home every single day. A therapist cannot sit in a patient's living room 7 days a week. NEXUS acts as an objective remote extension: it verifies home compliance, logs movement smoothness, and flags fatigue drop-offs so the therapist can optimize clinic time.
- **The Next Step:** Deploy a home-clinic tele-rehabilitation sync portal linking the patient mobile app directly to the hospital dashboard.

---

### HQ-10: "What happens if the camera is bumped or moved during the demo?"
- **Primary Owner:** Developer / Gautam
- **What is True (The Concession):** If the camera tripod is bumped significantly, the pre-calibrated pixel coordinates for Zone A and Zone B polygons will misalign with the physical table.
- **What We Do Measure:** Our system includes a rapid camera calibration utility in `backend/vision.py` that recalculates zone homography in under 10 seconds. Furthermore, our preflight diagnostics tool immediately flags if Zone A or Zone B polygons are incomplete or corrupt.
- **The Next Step:** Print ArUco boundary markers on the corners of the table mat so zone polygons self-register dynamically using planar homography regardless of camera orientation.

---

### HQ-11: "Why did you build 3 flex channels instead of all 5 fingers?"
- **Primary Owner:** Rajendra
- **What is True (The Concession):** The event hardware profile (`demo3`) instruments only the Thumb, Index, and Middle fingers. The Ring and Pinky fingers are uninstrumented.
- **What We Do Measure:** In functional grasp kinematics (such as the standard 3-jaw chuck grasp or precision pinch), the thumb, index, and middle fingers provide over 85% of functional grasp prehension. Our Texas Instruments ADS1115 ADC has exactly 4 channels: Channels A0, A1, and A2 digitize the 3 flex sensors, while Channel A3 digitizes the palmar FSR. This matched our event budget and ADC channel limits without adding a second multiplexer.
- **The Next Step:** In Tier 2, we have designed the `full5` profile using an 8-channel SPI ADC (MCP3008) or dual ADS1115 modules to instrument all five digits.

---

### HQ-12: "What happens when a wire snaps during a hospital patient session?"
- **Primary Owner:** Rajendra / Developer
- **What is True (The Concession):** Thin sensor wires under constant flexing will eventually fatigue and break.
- **What We Do Measure:** When a wire breaks, the analog channel floats or pulls to rail. In `backend/signal/contact.py`, our rail detector flags any ADC reading below 50 counts as an immediate `FSR_FAULT`. The TaskProof state machine refuses to award a false positive, locks the session into `UNCERTAIN`, and alerts the operator. The patient is never given false reassurance.
- **The Next Step:** Replace individual discrete wires with flexible printed flat-ribbon circuits (FPC) encapsulated in medical-grade TPU with molded strain relief boots.
