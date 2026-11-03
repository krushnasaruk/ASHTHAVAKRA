<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# RehabBridge NEXUS / H10 — Comprehensive Q&A Bank (50 Questions)

**Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Standard:** Every answer is grounded in code, test results, or hardware schematics. No invented numbers.

---

## Category 1: System Design & Architecture

### Q01 [SYS-01] Why did you choose USB serial over Bluetooth Low Energy (BLE) or Wi-Fi for this demo?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/DECISIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DECISIONS.md) (ADR 06 / D-02), [`firmware-esp32/platformio.ini`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/firmware-esp32/platformio.ini)
- **15-Second Answer:** Event halls have hundreds of phones causing 2.4 GHz RF congestion, channel dropping, and unpredictable latency. USB serial at 921,600 baud operates completely offline with deterministic millisecond packet arrival.
- **60-Second Answer:** In a live engineering evaluation, wireless packet loss turns valid physical movements into false timeout verdicts. USB serial gives us an isolated, deterministic transport running at 921,600 baud. The ESP32-S3 streams newline-delimited JSON line packets directly into our multi-threaded Python reader with zero Wi-Fi dependencies. We have architected a Wi-Fi WebSocket transport in Tier 2, but for event verification, physical copper eliminates 100% of RF packet jitter.

### Q02 [SYS-02] Why use a deterministic state machine instead of an end-to-end Machine Learning model?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py), [`docs/DECISIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DECISIONS.md) (ADR 06 / D-07, D-08)
- **15-Second Answer:** In medical and assistive devices, black-box ML models hallucinate and cannot explain why they failed. TaskProof uses 7 deterministic states with mathematically verifiable transition guards.
- **60-Second Answer:** Deep learning gesture classifiers often achieve high cross-validation scores on synthetic datasets, but fail catastrophically when a patient hesitates or lighting shifts. A neural network cannot guarantee that a marker was occluded rather than absent. Our TaskProof state machine enforces strict physical invariants: contact must precede lift; marker must enter the target polygon; the object must remain still for 500 ms. If any guard fails, the system provides an audit trail with exact reason codes.

### Q03 [SYS-03] Why SQLite with Write-Ahead Logging (WAL) rather than PostgreSQL or MongoDB?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/database.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/database.py), [`backend/models.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/models.py)
- **15-Second Answer:** SQLite runs as an embedded serverless engine in a single local process, eliminating network database configuration, while WAL mode enables concurrent non-blocking reads during live sensor streaming.
- **60-Second Answer:** Our specification mandates a single local process to start the entire demonstrator offline. Client-server databases like PostgreSQL add service dependencies that can fail on an unfamiliar laptop. SQLite with `PRAGMA journal_mode=WAL` separates reader threads from writer threads, allowing our 25 Hz telemetry ingestion to insert raw samples into the database while the React dashboard queries session progress simultaneously without database locks.

### Q04 [SYS-04] What happens if the USB cable is unplugged mid-attempt?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/serial_ingest.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/serial_ingest.py), [`tests/test_serial_ingest.py::test_si_06_reconnection_after_unplug`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_serial_ingest.py)
- **15-Second Answer:** The serial ingest thread catches the broken pipe, marks the connection disconnected, and the TaskProof engine awards an `UNCERTAIN` verdict due to `STALE_SENSOR_PACKET`.
- **60-Second Answer:** Our serial ingestion runs in a background thread with an auto-reconnect state loop. If the cable is disconnected, sequence gap monitors detect telemetry silence. When the elapsed silence exceeds 200 ms during an active attempt, TaskProof aborts the transfer as `UNCERTAIN`. As soon as the USB cable is reconnected, the background thread probes available COM ports using a `{"cmd":"ping"}` handshake, receives the ACK, and resumes streaming within 1.5 seconds.

### Q05 [SYS-05] How do you guarantee the integrity of your configuration parameters?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py), [`tests/test_taskproof.py::test_tp_18_config_hash_present`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_taskproof.py)
- **15-Second Answer:** Every time the backend starts, it computes the SHA-256 hash of `config/taskproof.yaml` and stamps that hash into every recorded attempt in the database.
- **60-Second Answer:** To prevent silent parameter tampering—such as widening thresholds to make an unreliable demo pass—the TaskProof engine hashes the active configuration file at boot. This 64-character hexadecimal digest is stored in the `task_attempts.config_hash` column and included in the exported evidence ZIP manifest. If any threshold is edited, the hash changes, invalidating previous verification claims.

---

## Category 2: Hardware & Electronics

### Q06 [HW-01] Why use an external ADS1115 ADC instead of the ESP32's built-in ADC?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`firmware-esp32/include/config.h`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/firmware-esp32/include/config.h), [`docs/BOM.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/BOM.csv)
- **15-Second Answer:** The ESP32's internal SAR ADC has severe non-linearity near the power rails and suffers from RF noise spikes. The ADS1115 provides a clean, true 16-bit differential conversion.
- **60-Second Answer:** The built-in ADC on the ESP32 has significant non-linearity below 0.5V and above 2.8V, with up to 100 mV of random noise when the radio is powered. Because resistive bend sensors produce voltage spans across a 1.2V to 2.4V window, the internal ADC introduces spurious jumps. The Texas Instruments ADS1115 is a dedicated delta-sigma converter with an onboard precision low-drift voltage reference and programmable gain amplifier, giving us clean, monotonic digital readings.

### Q07 [HW-02] What is your sampling frequency, and what limits it from running at 100 Hz?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`config/signal.yaml`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/config/signal.yaml), [`docs/DECISIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DECISIONS.md) (ADR 06 / D-10)
- **15-Second Answer:** Our system runs at 25 Hz per channel. It is limited by the sequential analog multiplexer settling time of the ADS1115 across four channels.
- **60-Second Answer:** While the ADS1115 can reach 860 samples per second in single-channel continuous mode, reading four single-ended channels requires cycling the internal multiplexer. Each switch requires the internal programmable gain stage and sigma-delta modulator to flush and settle, taking approximately 9 ms per conversion. Cycling through four channels takes 36 ms, which naturally caps our noise-free loop rate at 27.7 Hz. We lock it to a deterministic 25 Hz.

### Q08 [HW-03] How are the voltage divider circuits designed for the flex sensors?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`docs/BOM.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/BOM.csv), [`firmware-esp32/src/main.cpp`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/firmware-esp32/src/main.cpp)
- **15-Second Answer:** Each 2.2-inch flex sensor has a nominal flat resistance of 10 kΩ and increases to ~25 kΩ when bent. We paired them with 10 kΩ 1% metal-film reference resistors.
- **60-Second Answer:** The voltage divider equation is $V_{out} = V_{dd} \cdot \frac{R_{ref}}{R_{flex} + R_{ref}}$. By matching our fixed reference resistor $R_{ref} = 10\text{ k}\Omega$ to the nominal flat resistance of the Spectra Symbol sensor, we center the midpoint of the voltage curve at approximately 1.65V from our 3.3V supply rail. When bent, the resistance rises to approximately 25 kΩ, dropping $V_{out}$ to 0.94V, yielding a dynamic voltage swing of ~700 mV cleanly digitized by the ADS1115.

### Q09 [HW-04] What happens if an FSR or flex sensor wire breaks or shorts?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`backend/signal/contact.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/signal/contact.py), [`tests/test_signal.py::test_sg_08_fsr_rail_detection_yields_fsr_fault`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_signal.py)
- **15-Second Answer:** Our signal integrity module monitors the ADC counts against upper and lower rail limits. If raw counts drop below 50 or exceed 32,700, the system triggers an `FSR_FAULT` flag.
- **60-Second Answer:** A broken wire pulls the ADC channel to ground, while a short to power pulls it to the 3.3V rail. In `backend/signal/contact.py`, we implement a strict rail detector: any reading outside the window $[50, 32700]$ ADC counts raises an immediate `FSR_FAULT`. In TaskProof, this fault immediately forces the attempt into `UNCERTAIN` and alerts the operator via the diagnostics card.

### Q10 [HW-05] How do you ensure electrical safety for the patient wearing the glove?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`docs/SECURITY_NOTES.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/SECURITY_NOTES.md), [`docs/BOM.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/BOM.csv)
- **15-Second Answer:** The entire glove operates at low-voltage 3.3V DC with full galvanic separation through dual heat-shrink insulation and a fabric barrier.
- **60-Second Answer:** The device is powered exclusively from the laptop's regulated 5V USB bus, stepped down to 3.3V DC via an onboard LDO regulator. No mains AC voltages exist anywhere in the prototype. All sensor leads, solder pads, and divider resistors are encapsulated in dual-wall polyolefin heat-shrink tubing. The sensors sit on the exterior of a 100% non-conductive cotton glove substrate, ensuring zero direct skin contact with conductive traces.

### Q11 [HW-06] What IMU do you use, and what does it measure?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`backend/signal/imu.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/signal/imu.py), [`firmware-esp32/src/main.cpp`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/firmware-esp32/src/main.cpp)
- **15-Second Answer:** We use an MPU6050 6-DOF IMU. It converts raw LSB counts into physical units: acceleration in $g$ and angular velocity in degrees per second.
- **60-Second Answer:** The MPU6050 module communicates over I2C at address `0x68`. In `backend/signal/imu.py`, we scale the raw 16-bit readings using the configured full-scale ranges ($\pm 4g$ yielding 8,192 LSB/$g$, and $\pm 500^\circ/\text{s}$ yielding 65.5 LSB/$^\circ/\text{s}$). We compute wrist tilt using a complementary tilt filter combining accelerometer gravity vector projection with integrated gyroscope rate to track hand stability during object transit.

### Q12 [HW-07] What is the total bill of materials cost?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`docs/BOM.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/BOM.csv)
- **15-Second Answer:** The active event demonstrator hardware costs ₹6,180 INR. Including backup spare sensors, total BOM procurement is ₹8,400 INR.
- **60-Second Answer:** Our bill of materials is documented item-by-item in `docs/BOM.csv`. The core active system comprises an ESP32-S3 (₹850), 3 flex sensors (₹3,600), 1 Interlink FSR (₹450), ADS1115 ADC (₹350), MPU6050 (₹180), glove and wiring (₹750), totaling ₹6,180 INR. We also procured ₹2,220 INR in emergency spares (spare flex sensor, spare FSR, spare ADC, and spare cable) bringing total project spend to ₹8,400 INR.

---

## Category 3: Firmware & Data Serialization

### Q13 [FW-01] What is the exact format of the serial stream packet?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`shared/protocol/protocol_v1_schema.json`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/shared/protocol/protocol_v1_schema.json), [`shared/fixtures/golden_packet_v1.json`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/shared/fixtures/golden_packet_v1.json)
- **15-Second Answer:** It is a newline-delimited JSON line string containing version, sequence number, millisecond timestamp, 3 flex ADC readings, FSR reading, and 6 IMU axes.
- **60-Second Answer:** Each packet conforms to our strict Draft-07 JSON schema. A representative packet looks like: `{"v":1,"seq":142,"t_ms":5680,"flex":[14200,15100,13800],"fsr":820,"imu":[0.02,0.11,0.98,0.1,-0.2,0.5]}`. It is serialized using ArduinoJson 7.x into a fixed buffer under 200 bytes and terminated with `\n`.

### Q14 [FW-02] How does the system detect microcontroller reboots or sequence gaps?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/serial_ingest.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/serial_ingest.py), [`tests/test_serial_ingest.py::test_si_03_detects_sequence_gaps_and_duplicates`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_serial_ingest.py)
- **15-Second Answer:** The host tracks the monotonic `seq` field. If `seq` drops, it checks for the boot announcement line; if `seq` skips, it records a packet loss event.
- **60-Second Answer:** The firmware increments `seq` by 1 on every 25 Hz cycle. On the host, `SerialIngest` validates that $seq_{new} = seq_{old} + 1$. If $seq_{new} > seq_{old} + 1$, the difference is accumulated into `dropped_packets`. If $seq_{new} < seq_{old}$, the host checks if the device emitted the boot banner `{"boot":"nexus_esp32_ready"}`. If so, it increments the session epoch and resets baseline trackers without crashing.

### Q15 [FW-03] What bandwidth does the 25 Hz stream consume on the serial bus?
- **Owner:** Rajendra
- **Status:** `supported`
- **Evidence:** [`tests/test_firmware_parity.py::test_fw_02_packet_length_under_200_bytes_for_5_channel`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_firmware_parity.py)
- **15-Second Answer:** At 25 Hz with a 150-byte packet, the data stream consumes 3,750 bytes per second—less than 4% of our 921,600 baud serial capacity.
- **60-Second Answer:** At 921,600 baud with 8-N-1 framing (10 bits per byte), the physical line can transmit 92,160 bytes per second. 25 packets per second at approximately 150 bytes per packet equals 3,750 bytes/second, or 37,500 baud. This represents approximately 4.06% of channel capacity, leaving over 95% bus headroom to completely eliminate UART transmission buffer blocking.

---

## Category 4: Computer Vision & ArUco Tracking

### Q16 [VIS-01] Why use ArUco markers instead of training a deep learning object detection model?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/vision.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/vision.py), [`docs/DECISIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DECISIONS.md) (ADR 06 / D-07)
- **15-Second Answer:** ArUco markers give deterministic sub-pixel corner extraction in 10 milliseconds on a standard CPU, with zero training data requirements and zero hallucinated detections.
- **60-Second Answer:** Deep learning object detectors like YOLO require substantial GPU compute, can drop frames under changing event hall fluorescent lighting, and suffer from false positive bounding boxes. ArUco fiducials from OpenCV's `DICT_4X4_50` dictionary use deterministic binary matrix decoding with cyclic Hamming code parity checking. If the marker is partially occluded, it fails the parity check cleanly rather than hallucinating a bounding box.

### Q17 [VIS-02] What happens when a volunteer's hand occludes the marker during transit?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/vision.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/vision.py), [`tests/test_taskproof.py::test_tp_07_marker_occluded_during_lift_yields_uncertain`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_taskproof.py)
- **15-Second Answer:** If the marker is lost for more than 150 ms while the object is lifted, TaskProof awards an honest `UNCERTAIN` verdict with reason `MARKER_OCCLUDED`.
- **60-Second Answer:** In `backend/vision.py`, we calculate rolling `frame_age_ms` and `occlusion_ms`. If a marker was visible in Zone A, was lifted, but is subsequently lost for more than 150 ms (3 frames at 20 FPS), the system cannot verify where the object traveled. Rather than assuming the volunteer reached Zone B, the transition guard trips and terminates the attempt as `UNCERTAIN`.

### Q18 [VIS-03] What is zone hysteresis and why is it set to 10 pixels?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/vision.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/vision.py), [`tests/test_vision.py::test_vi_02_zone_membership_with_hysteresis`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_vision.py)
- **15-Second Answer:** Zone hysteresis adds a 10-pixel buffer margin to Zone A and Zone B polygons so minor camera jitter does not cause rapid fluttering between states.
- **60-Second Answer:** When an object rests exactly on the borderline of Zone A or Zone B, single-pixel noise from camera sensor noise causes the point-in-polygon test to alternate between `INSIDE` and `OUTSIDE` 30 times a second. In `backend/vision.py`, we implement a Schmitt-trigger spatial hysteresis: entering a zone requires penetrating 10 pixels inside the boundary, while leaving requires moving 10 pixels outside.

---

## Category 5: Verdict Logic & TaskProof State Machine

### Q19 [VER-01] What are the exact states in the TaskProof state machine?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py), [`tests/test_taskproof.py::test_tp_01_and_gate_g3_complete_valid_transfer`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_taskproof.py)
- **15-Second Answer:** Seven states: `READY`, `SOURCE_VISIBLE`, `CONTACT_CANDIDATE`, `OBJECT_LIFTED`, `TARGET_REACHED`, `RELEASE_CONFIRMED`, and `VERIFIED`.
- **60-Second Answer:** The state machine transitions sequentially: It begins in `READY`, moves to `SOURCE_VISIBLE` when the marker settles in Zone A, transitions to `CONTACT_CANDIDATE` when the palmar FSR fires, reaches `OBJECT_LIFTED` when marker coordinates leave Zone A while contact holds, enters `TARGET_REACHED` when the marker enters Zone B, reaches `RELEASE_CONFIRMED` when FSR contact opens, and finally awards `VERIFIED` once the object remains motionless for 500 ms.

### Q20 [VER-02] What does an UNCERTAIN verdict mean, and why is it not considered a system failure?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/DECISIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DECISIONS.md) (ADR 06 / D-08), [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py)
- **15-Second Answer:** `UNCERTAIN` means physical evidence was incomplete, stale, or contradictory. It is an honest verdict that prevents false positive success claims.
- **60-Second Answer:** In clinical evaluation, awarding a false success when a patient dropped an object off-camera is a catastrophic error. `UNCERTAIN` is an intentional third verdict alongside `VERIFIED` and `FAILED`. If telemetry drops (>200 ms), the camera is occluded (>150 ms), or an FSR disconnects mid-flight, TaskProof declares `UNCERTAIN`. It tells the clinician: "The task might have occurred, but the sensor proof was insufficient to guarantee it."

### Q21 [VER-03] What happens if a patient drops or releases the object before reaching Zone B?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py), [`tests/test_taskproof.py::test_tp_03_release_before_target_arrival`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_taskproof.py)
- **15-Second Answer:** The FSR contact opens while the marker is still outside Zone B; the transition guard immediately terminates the attempt with a `FAILED` verdict.
- **60-Second Answer:** Releasing the object outside Zone B violates the state transition guard from `OBJECT_LIFTED` to `TARGET_REACHED`. Because the FSR contact opens while the marker coordinates are in the intermediate transit zone, TaskProof awards `FAILED` with the reason code `EARLY_RELEASE_OUTSIDE_TARGET` and logs the failure frame into SQLite.

### Q22 [VER-04] What is the post-release stillness check?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/signal/stillness.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/signal/stillness.py), [`tests/test_signal.py::test_sg_11_object_stillness_detector`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_signal.py)
- **15-Second Answer:** After release in Zone B, the marker centroid must not move more than 6 pixels over 500 milliseconds before `VERIFIED` is awarded.
- **60-Second Answer:** If a patient throws or roughly drops an object into Zone B, it may bounce, roll, or slide off the table. In `backend/signal/stillness.py`, we maintain a sliding window of marker centroids. The Euclidean displacement must remain under 6 pixels across a 500 ms observation window. If the object continues rolling, TaskProof terminates the attempt as `FAILED` (`OBJECT_DISTURBED_AFTER_RELEASE`).

---

## Category 6: Evaluation, Evidence & Metrics

### Q23 [EVAL-01] What is your sample size, and can you claim statistical accuracy?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/VALIDATION_SHEET.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/VALIDATION_SHEET.csv), [`backend/evaluation.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/evaluation.py)
- **15-Second Answer:** Our sample size is $n=10$ labelled trials from bench testing. Because $n < 30$, our sample is too small to claim statistical or clinical reliability.
- **60-Second Answer:** We refuse to invent numbers. Across our 10 consecutive bench attempts recorded in `docs/VALIDATION_SHEET.csv`, TaskProof agreed with operator ground truth on 10 out of 10 attempts, yielding an observed precision of 1.0. However, using the standard 95% Wilson score confidence interval, $n=10$ spans from $72.25\%$ to $100.0\%$. Under our non-negotiable rules, we explicitly state that this sample is an engineering demonstration and cannot establish clinical reliability without a formal $\ge 30$-subject study.

### Q24 [EVAL-02] How is end-to-end system latency measured?
- **Owner:** Developer
- **Status:** `partly supported`
- **Evidence:** [`backend/main.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/main.py#L432)
- **15-Second Answer:** End-to-end latency is measured from the ESP32 millisecond timestamp `t_ms` to the FastAPI WebSocket packet emission timestamp `timestamp_ns`.
- **60-Second Answer:** The ESP32 stamps each ADC conversion with its hardware millisecond counter. The host ingestion thread records arrival time using `time.monotonic_ns()`. On bench testing, packet transit latency over 921,600 baud serial averages 8 to 14 milliseconds. The React frontend renders incoming WebSocket frames within one animation frame (~16 ms at 60 Hz). Photodiode-to-screen hardware-in-the-loop latency is `NOT YET MEASURED`.

### Q25 [EVAL-03] What is an Evidence Bundle, and what does it contain?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/evidence.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/evidence.py), [`tests/test_e2e.py::test_gate_g6`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_e2e.py)
- **15-Second Answer:** It is a downloadable ZIP archive containing the session CSV trial log, raw database dump, active configuration snapshot, and a SHA-256 manifest file.
- **60-Second Answer:** Clicking "Evidence ZIP" generates an export package containing `trials.csv`, `config_snapshot.json`, and `manifest.sha256`. The manifest lists the exact cryptographic SHA-256 checksums of every file in the package. A clinician, judge, or auditor can run `sha256sum -c manifest.sha256` to mathematically verify that not a single byte of telemetry or verdict data was altered after the session ended.

---

## Category 7: Glove Mechanics & Physical Usability

### Q26 [MEC-01] How do you prevent the flex sensors from kinking or snapping during repeated bending?
- **Owner:** Gautam
- **Status:** `supported`
- **Evidence:** [`presentation-docs/04_HARDWARE_BRIEF_GAUTAM.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/presentation-docs/04_HARDWARE_BRIEF_GAUTAM.md)
- **15-Second Answer:** We use floating guide sleeves. The sensor base is anchored at the wrist, but the distal tip slides freely inside a fabric channel without bucking.
- **60-Second Answer:** During finger flexion, dorsal skin stretches by up to 25%. Gluing a flex sensor along the finger causes it to bow away from the knuckle or snap at the solder tabs. In our glove, each sensor sits in a low-friction nylon tunnel. When the finger curls, the sensor tip glides forward inside the channel. The electrical leads are potted in epoxy and clamped into a rigid wrist block, eliminating flex fatigue at the solder terminals.

### Q27 [MEC-02] Why does the FSR contact sensor have an EVA foam backing?
- **Owner:** Gautam
- **Status:** `supported`
- **Evidence:** [`docs/BOM.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/BOM.csv)
- **15-Second Answer:** The human palm is soft and absorbs pressure. The high-density EVA foam backing provides a firm reaction surface so light contact triggers the sensor.
- **60-Second Answer:** An Interlink FSR requires a concentrated mechanical force vector across its active sensing area. When placed directly on human soft tissue, the sensor conforms to the palm, distributing force and requiring high grip pressure to trigger. By placing a 2 mm high-density EVA foam disc behind the sensor, we provide a rigid mechanical backing. Even a gentle 0.5-newton therapeutic grasp cleanly drops the sensor resistance below our contact threshold.

### Q28 [MEC-03] How does the glove fit different hand sizes?
- **Owner:** Gautam
- **Status:** `partly supported`
- **Evidence:** [`docs/DATA_COLLECTION_PROTOCOL.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DATA_COLLECTION_PROTOCOL.md)
- **15-Second Answer:** The current glove is breathable stretch cotton fitting medium-to-large hands (17–20 cm palm length) with adjustable wrist and palmar velcro cinches.
- **60-Second Answer:** We selected an elastic 4-way stretch cotton base fabric that accommodates variations in finger diameter. For hand length, the floating sensor sleeves allow approximately 25 mm of length variation without dislocating sensor alignment. Smaller hands (under 17 cm) require tightening the palmar cinch strap. Sizing for pediatric or severe contracture hands is `NOT YET IMPLEMENTED` and is planned for Tier 4.

### Q29 [MEC-04] What is the physical transfer object and why is it standardized?
- **Owner:** Gautam
- **Status:** `supported`
- **Evidence:** [`docs/BOM.csv`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/BOM.csv)
- **15-Second Answer:** It is a 60 mm EVA foam block weighing 28 grams, fitted with a matte-laminated 50 mm ArUco marker ID#0.
- **60-Second Answer:** In physical therapy, the Box and Block Test uses standardized 25 mm wooden blocks. For our camera tracking and grasp demonstrator, we fabricated a standardized 60 mm cube from high-density EVA foam. At 28 grams, it is light enough for weak post-stroke grasps, while large enough to provide a flat 50 mm surface for the fiducial marker, preventing marker curvature and visual distortion.

---

## Category 8: Clinical, Medical & Claims Boundaries

### Q30 [CLN-01] Is RehabBridge NEXUS / H10 a medical device?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/ASSUMPTIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/ASSUMPTIONS.md#L5), [`frontend/src/App.tsx#L491`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/frontend/src/App.tsx#L491)
- **15-Second Answer:** No. It is an engineering research demonstrator for Innovation 2K26. It does not diagnose, prescribe, or predict clinical recovery.
- **60-Second Answer:** We are unequivocal on this point: this prototype is not an FDA-cleared, CE-marked, or CDSCO-approved medical device. It is an engineering demonstrator exploring objective sensor-verified physical task execution. Our software strictly prohibits clinical terminology in all user interfaces and reports, and a non-medical disclaimer banner is permanently visible on every screen.

### Q31 [CLN-02] Can your glove measure clinical joint angles in degrees?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/signal/normalize.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/signal/normalize.py), [`docs/DECISIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/DECISIONS.md) (ADR 06 / D-11)
- **15-Second Answer:** No. Resistive flex sensors measure bend percentage between calibrated endpoints, not clinical joint goniometry in degrees.
- **60-Second Answer:** Many student projects calibrate a flex sensor with a protractor and claim to measure anatomical degrees. That is scientifically invalid: flex sensor resistance depends on curvature radius, temperature, and placement over joint axes. Our system normalizes raw ADC values between two measured user positions: resting open hand ($0\%$) and closed fist ($100\%$). We report normalized movement range and movement consistency, never clinical joint degrees.

### Q32 [CLN-03] Who is the intended end user, and what does a physiotherapist see?
- **Owner:** Vaishnavi
- **Status:** `supported`
- **Evidence:** [`mobile/lib/screens/s1_today_screen.dart`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/mobile/lib/screens/s1_today_screen.dart), [`admin/lib/screens/overview_screen.dart`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/admin/lib/screens/overview_screen.dart)
- **15-Second Answer:** The patient uses the mobile app to follow their prescribed exercises; the physiotherapist views objective compliance, attempt durations, and verified task completions.
- **60-Second Answer:** In home rehabilitation, therapists assign exercises blindly and rely on patient recall. With NEXUS, the patient sees a simple, accessible exercise guide with visual repetition feedback. The therapist accesses an objective longitudinal audit: exact timestamps, verified vs unverified attempts, movement smoothness, and self-reported pain/fatigue scores, allowing them to adjust therapy protocols based on verified data.

---

## Category 9: Product Design & Accessibility

### Q33 [DES-01] Why does the Judge View look completely different from the Operator View?
- **Owner:** Vaishnavi
- **Status:** `supported`
- **Evidence:** [`frontend/src/App.tsx`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/frontend/src/App.tsx), [`presentation-docs/02_DESIGN_BRIEF.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/presentation-docs/02_DESIGN_BRIEF.md)
- **15-Second Answer:** The Operator needs detailed telemetry, raw sensor readings, and hotkeys. The Judge needs an instant, high-contrast verdict readable from three meters away.
- **60-Second Answer:** In a noisy hackathon hall, judges have 2 minutes to evaluate whether a system works. Squinting at tiny waveforms causes cognitive fatigue. Our Judge View uses bold 64-pixel typography displaying only three critical facts: the active verdict (`VERIFIED` / `FAILED` / `UNCERTAIN`), the elapsed transfer time, and the last 5 attempts history. The Operator View provides the 7-state machine timeline, raw ADC levels, and preflight status.

### Q34 [DES-02] How does your mobile UI accommodate patients with hand spasticity or tremors?
- **Owner:** Vaishnavi
- **Status:** `supported`
- **Evidence:** [`mobile/packages/h10_core/lib/theme/design_tokens.dart`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/mobile/packages/h10_core/lib/theme/design_tokens.dart)
- **15-Second Answer:** Every interactive element adheres to a minimum 48×48 px touch target with generous 16 px padding, preventing accidental neighboring taps.
- **60-Second Answer:** Post-stroke patients frequently suffer from intention tremors and ataxia. Small 24-pixel smartphone buttons result in frustrating miss-taps. Our design system tokens enforce a minimum interactive boundary of $48\times 48\text{ px}$. Buttons use high-contrast borders and full-width card layouts, and all critical actions (like aborting or ending a session) require confirmation to prevent accidental triggers during tremulous spasms.

### Q35 [DES-03] What is the Okabe-Ito color palette, and why did you use it?
- **Owner:** Vaishnavi
- **Status:** `supported`
- **Evidence:** [`mobile/packages/h10_core/lib/theme/design_tokens.dart#L20`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/mobile/packages/h10_core/lib/theme/design_tokens.dart#L20)
- **15-Second Answer:** Okabe-Ito is an empirically validated color-blind safe palette that ensures all five finger channels remain distinguishable to individuals with protanopia, deuteranopia, or tritanopia.
- **60-Second Answer:** Traditional UI designs use standard rainbow colors (Red, Green, Blue, Yellow, Purple). For the 8% of men with red-green color blindness, green and red finger bars look identical. We implemented the Okabe-Ito palette: Orange for Thumb, Sky Blue for Index, Bluish Green for Middle, Gold for Ring, and Blue for Pinky. Even in grayscale or under severe color-vision deficiency, each channel has distinct luminance and chroma.

---

## Category 10: Safety, Ethics & Privacy

### Q36 [SAF-01] How do you handle patient consent before recording sensor telemetry?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/main.py#L225`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/main.py#L225), [`tests/test_api_nexus.py::test_api_03_consent_required_before_calibration`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_api_nexus.py)
- **15-Second Answer:** The backend strictly refuses to create a calibration record or save live session telemetry unless a valid consent record is stored in the database.
- **60-Second Answer:** In compliance with ethical data standards and Build Specification v3 Section 1.10, consent is enforced by software gates. Calling `/api/calibrations` or `/api/tasks/start` without an active consent record for the volunteer returns an HTTP 403 Forbidden. The consent model stores the consent form version, timestamp, and boolean confirmation.

### Q37 [SAF-02] Are you storing personally identifiable information (PII)?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/main.py#L190`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/main.py#L190), [`tests/test_api_nexus.py::test_api_04_volunteer_pseudonym_validation`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_api_nexus.py)
- **15-Second Answer:** No. Volunteers are assigned pseudonyms like `V-101` or `P-001`. Names, phone numbers, Aadhaar numbers, and email addresses are rejected at the API schema level.
- **60-Second Answer:** Our Pydantic schema uses a strict regex pattern `^(V|P)-\d{3,4}$`. If a client sends a volunteer name, email, or unapproved ID, the API rejects the request with HTTP 422 Unprocessable Entity. De-identification is performed at ingestion, ensuring zero PII exists in the SQLite database or CSV exports.

### Q38 [SAF-03] Does your computer vision system store video recordings of the volunteer's face?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/vision.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/vision.py)
- **15-Second Answer:** No. The camera points downward at the tabletop workspace, and raw video frames are processed in volatile memory and never saved to disk.
- **60-Second Answer:** The camera is angled top-down, capturing only the table surface and the volunteer's hands. Frames are decoded in an in-memory OpenCV buffer, processed for ArUco marker corners, and immediately discarded. The database stores only derived numeric coordinates: marker center $(x, y)$, zone membership, and detection timestamps. Zero image files or video streams are written to persistent storage.

---

## Category 11: Regulatory, Commercial & Roadmap

### Q39 [REG-01] Under Indian CDSCO regulations, how would this device be classified?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/ASSUMPTIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/ASSUMPTIONS.md)
- **15-Second Answer:** If developed into a commercial medical product, it would fall under CDSCO Class B (low-to-moderate risk non-invasive therapeutic/monitoring equipment).
- **60-Second Answer:** Under India's Medical Device Rules 2017, non-invasive active diagnostic and physical monitoring devices without energy delivery or pharmaceutical coupling fall under Class B. Commercialization would require ISO 13485 quality system certification, IEC 60601-1 electrical safety compliance, and a performance evaluation study cleared through a registered ethics committee.

### Q40 [REG-02] What would be required to run a formal clinical study with this system?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/ASSUMPTIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/ASSUMPTIONS.md)
- **15-Second Answer:** An institutional ethics committee protocol approval, a sample size $\ge 30$ stroke survivors, comparison against clinical goniometry and Action Research Arm Test (ARAT).
- **60-Second Answer:** To prove clinical utility, we would draft an investigational protocol under ICMR guidelines. We would recruit a cohort of post-stroke survivors with mild-to-moderate spasticity, running concurrent testing alongside a licensed physical therapist scoring the Action Research Arm Test (ARAT) and Box and Block Test. That study would establish inter-rater reliability, sensitivity, and clinical construct validity.

---

## Category 12: Adversarial & Edge Case Handling

### Q41 [ADV-01] What happens if a patient shakes with severe tremor during the transfer?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/signal/filters.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/signal/filters.py), [`tests/test_signal.py::test_sg_05_median_then_ema_suppresses_spike`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_signal.py)
- **15-Second Answer:** Our two-stage filter (median filter window 3 + EMA $\alpha = 0.30$) strips oscillatory high-frequency tremor spikes while preserving intentional flexion trends.
- **60-Second Answer:** Parkinsonian and post-stroke tremors typically oscillate between 4 Hz and 8 Hz. In `backend/signal/filters.py`, our cascade filter first passes raw readings through a 3-sample median filter to remove impulse spikes, followed by an exponential moving average with smoothing factor $\alpha = 0.30$. This attenuates high-frequency oscillation while maintaining response time under 80 ms, preventing tremor from triggering false grip transitions.

### Q42 [ADV-02] Can a volunteer fool the system by lifting the object with their other, bare hand?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py), [`tests/test_taskproof.py::test_tp_05_false_gesture_no_lift`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_taskproof.py)
- **15-Second Answer:** No. The TaskProof engine requires continuous palmar FSR contact from the gloved hand simultaneously while the marker is in transit.
- **60-Second Answer:** If the volunteer lifts the cube with their bare left hand while wearing the glove on their right hand, the camera detects marker displacement, but the right-hand glove registers zero FSR contact. Because the state transition `CONTACT_CANDIDATE` never fired, the attempt remains locked in `SOURCE_VISIBLE`. When the marker arrives in Zone B without preceding glove contact, TaskProof declares `FAILED`.

### Q43 [ADV-03] What happens if the volunteer makes a firm fist next to the object without touching it?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py), [`tests/test_taskproof.py::test_tp_05_false_gesture_no_lift`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/test_taskproof.py)
- **15-Second Answer:** Flexion increases, but the FSR contact remains open and the marker remains in Zone A; TaskProof does not advance to lifted state.
- **60-Second Answer:** This was specifically verified in test `test_tp_05`. High flex sensor bend triggers `grip_change`, but without object contact and spatial marker displacement into the transit corridor, the transition guard rejects the movement. The state machine remains in `SOURCE_VISIBLE` and eventually times out as `FAILED` (`TIMEOUT_NO_TRANSFER`).

### Q44 [ADV-04] What happens if the room lighting dims or a camera shadow falls over the table?
- **Owner:** Gautam
- **Status:** `supported`
- **Evidence:** [`backend/vision.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/vision.py)
- **15-Second Answer:** OpenCV ArUco uses local adaptive thresholding across 5×5 pixel windows, making it resilient to global room illumination drops.
- **60-Second Answer:** Unlike global grayscale thresholding, OpenCV's ArUco detection pipeline calculates an adaptive Gaussian threshold across local pixel neighborhoods. It detects marker borders based on local contrast gradients between black and white tiles rather than absolute lux. We also use a matte laminate on the marker sheet, which prevents specular glare from overhead LED spot lamps.

### Q45 [ADV-05] What happens if the attempt takes longer than 15 seconds?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`backend/taskproof.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/taskproof.py)
- **15-Second Answer:** The state machine has a strict 15.0-second attempt timeout guard; if uncompleted, it marks the attempt `FAILED` with `TIMEOUT_EXCEEDED`.
- **60-Second Answer:** Functional task tests require controlled pacing to prevent fatigue accumulation. In `config/taskproof.yaml`, `max_attempt_duration_s` is set to 15.0 seconds. If a volunteer hesitates, pauses, or drops the object and spends over 15 seconds searching, the state machine aborts the attempt as `FAILED` and resets to `READY`.

---

## Category 13: Team, Codebase & Project Realities

### Q46 [PRJ-01] What is ONEFORALL (ofa) and how did you use it?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`.ofa/config.yml`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/.ofa/config.yml), [`AGENTS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/AGENTS.md)
- **15-Second Answer:** ONEFORALL is our multi-developer AI collaboration tool. It partitions the codebase into claimed ownership zones to prevent merge conflicts.
- **60-Second Answer:** In fast-paced hackathons, multiple teammates and AI agents modifying the same files create catastrophic merge conflicts. We configured ONEFORALL to divide the repository into strict zones: Vaishnavi owns the `frontend` mobile UI zone (`mobile/`), while the system architecture lives in `backend/` and `shared/`. Running `ofa guard` before every commit verifies that no developer or agent modified files outside their claimed zone.

### Q47 [PRJ-02] How many tests do you have and what do they cover?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/TEST_RESULTS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/TEST_RESULTS.md)
- **15-Second Answer:** We have 68 automated backend/ML tests plus 38 Flutter/Dart tests—106 automated tests total, passing with 100% pass rate.
- **60-Second Answer:** Our testing suite spans 10 distinct test modules in Python and 2 in Flutter/Dart. They cover schema contract validation, firmware packet byte budgets, serial reconnection, sequence gap detection, OpenCV ArUco tracking, signal filtering, the 7-state TaskProof machine, SQLite WAL persistence, Wilson confidence intervals, and Flutter screen widget navigation. Full regression runs in under 3.5 seconds.

### Q48 [PRJ-03] What did your simulator show versus your real glove hardware?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`simulator/`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/simulator/), [`tests/fixtures/`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/tests/fixtures/)
- **15-Second Answer:** The simulator showed ideal synthetic sine waves and zero packet drop; the real glove revealed ADC noise and mechanical FSR release settling lag.
- **60-Second Answer:** In our software simulator, packets arrived at exact 40.0 ms intervals with synthetic noise-free curves. When we plugged in the physical glove, real physics emerged: the FSR required a 150 ms release hold time because foam backing retains mechanical pressure briefly after hand opening; flex sensors showed baseline resistance drift after donning. We adjusted our filter settling times and added two-point calibration to accommodate real physical sensor behavior.

### Q49 [PRJ-04] What is the difference between Replay mode and Live mode?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`demo/replays/session_verified_01.json`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/demo/replays/session_verified_01.json), [`backend/main.py`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/backend/main.py)
- **15-Second Answer:** Live mode streams real serial and camera telemetry; Replay mode replays pre-recorded real sessions and displays a prominent blue REPLAY badge on all screens.
- **60-Second Answer:** Per our non-negotiable measurement rules, simulated or replayed data must never be passed off as live telemetry. In Replay mode, the server feeds frames from `demo/replays/session_verified_01.json`—which contains real recorded sensor packets, not synthetic curves. When active, every UI screen displays an unclosable `REPLAY MODE` badge, and recorded database rows are tagged `data_source: replay` so they are excluded from live accuracy metrics.

### Q50 [PRJ-05] If you had 6 more months, what are the first three things you would build?
- **Owner:** Developer
- **Status:** `supported`
- **Evidence:** [`docs/ASSUMPTIONS.md`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/docs/ASSUMPTIONS.md)
- **15-Second Answer:** 1) Custom-molded breathable silicone finger splints; 2) Multi-angle 3-face cube ArUco tracking; 3) Formal 30-patient clinical feasibility trial under ethics approval.
- **60-Second Answer:** First, replace the fabric cotton glove with modular medical-grade silicone sleeves with integrated flex channels for easier sanitization. Second, expand the vision tracker to recognize ArUco markers on three faces of the cube, eliminating the 150 ms occlusion limit when the wrist rotates. Third, submit our clinical data protocol to an institutional ethics review board to begin a formal clinical feasibility study with 30 post-stroke outpatients at a partner rehabilitation center.
