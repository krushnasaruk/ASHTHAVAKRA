<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# RehabBridge NEXUS / H10 — Technical & Clinical Glossary

**Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Standard:** Clear, plain-language engineering and physiological definitions.

---

### 1. Hardware & Electronics
- **ADC (Analog-to-Digital Converter):** An electronic integrated circuit that converts continuous physical voltages (e.g. from a bending sensor) into discrete binary integer numbers (e.g. 16-bit counts from 0 to 32,767).
- **ADS1115:** A high-precision 16-bit, 4-channel delta-sigma analog-to-digital converter made by Texas Instruments, communicating over the I2C serial bus.
- **PGA (Programmable Gain Amplifier):** An internal circuit inside the ADS1115 that amplifies weak analog input voltages prior to analog-to-digital conversion to maximize resolution.
- **FSR (Force-Sensing Resistor):** A polymer thick-film sensor whose electrical resistance decreases non-linearly as mechanical compressive force is applied to its active surface area.
- **IMU (Inertial Measurement Unit):** An electronic sensor package (MPU6050) combining a 3-axis accelerometer (measuring linear forces and gravity) and a 3-axis gyroscope (measuring rotational velocity).
- **LDO (Low-Dropout Regulator):** A DC linear voltage regulator that steps down supply voltages (e.g. 5V USB to clean 3.3V) with minimal electrical ripple and noise.
- **Voltage Divider:** A passive circuit consisting of two resistors connected in series that divides an input voltage proportionally to their resistance values ($V_{out} = V_{in} \cdot \frac{R_2}{R_1 + R_2}$).
- **UART / Serial (Universal Asynchronous Receiver-Transmitter):** A physical hardware communication protocol transmitting binary bits sequentially over a pair of data wires (TX/RX) at a fixed baud rate (921,600 baud).

---

### 2. Computer Vision & Kinematics
- **ArUco Marker:** A synthetic 2D square fiducial marker with an outer black border and an inner binary pattern (e.g. $4\times 4$ bits) developed for fast, robust computer vision camera pose estimation.
- **Fiducial:** An artificial, visually prominent reference object placed in the field of view of an imaging system to act as a point of reference or spatial anchor.
- **Homography:** A 2D projective transformation mapping points from one plane (e.g. the tabletop surface) to another plane (e.g. the camera sensor pixel grid).
- **Hysteresis:** A property where the state of a system depends on its history rather than just its current input. Used in NEXUS both spatially (10 px boundary buffer) and electrically (Schmitt trigger with separate turn-on and turn-off thresholds) to prevent signal chatter.
- **Occlusion:** The physical blockage of a visual line-of-sight between the camera lens and an optical target (such as a hand blocking the ArUco marker).
- **Sub-Pixel Corner Extraction:** An image processing refinement algorithm (e.g. `cv2.cornerSubPix`) that estimates the location of marker corners with mathematical precision beyond integer pixel boundaries.

---

### 3. Signal Processing & Mathematics
- **EMA (Exponential Moving Average):** A first-order infinite impulse response (IIR) digital filter that applies exponentially decreasing weighting factors to older samples ($y_t = \alpha \cdot x_t + (1 - \alpha) \cdot y_{t-1}$).
- **Median Filter:** A non-linear digital filter that replaces each sample with the median value of neighboring samples within a sliding window (e.g. window size 3), ideal for stripping single-sample impulse noise spikes.
- **Schmitt Trigger:** A dual-threshold comparator circuit or software logic with separate high threshold ($k_{on}$) and low threshold ($k_{off}$) to turn digital states on and off cleanly without rapid jitter.
- **Dimensionless Jerk:** A mathematically normalized kinematic metric of movement smoothness that penalizes changes in acceleration while remaining independent of movement duration and distance ($D_J = -\frac{T^5}{A^2} \int \dot{a}^2 dt$).
- **ROM (Range of Motion):** In this prototype, normalized percentage of finger travel between a user's resting open-hand baseline ($0\%$) and closed-fist posture ($100\%$). It does not assert medical degrees.

---

### 4. Verification, Statistics & Software
- **TaskProof:** The deterministic 7-state verification state machine developed for NEXUS that validates the physical sequence of functional object manipulation.
- **UNCERTAIN:** An intentional honest verdict indicating that incoming sensor telemetry was incomplete, stale (>200 ms), occluded (>150 ms), or contradictory, preventing a safe determination of success or failure.
- **Wilson Score Interval:** An asymmetric statistical confidence interval formula for binomial proportions that remains mathematically valid even with small sample sizes ($n < 30$) or extreme proportions ($p = 1.0$).
- **Precision:** The proportion of predicted positive attempts that are true positives according to ground truth ($\frac{TP}{TP + FP}$).
- **Recall (Sensitivity):** The proportion of true positive physical attempts that were correctly identified by the system ($\frac{TP}{TP + FN}$).
- **SQLite WAL (Write-Ahead Logging):** A database journaling mode where writes are appended sequentially to a separate WAL file, allowing concurrent read queries without blocking incoming write transactions.
- **SHA-256 (Secure Hash Algorithm 256-bit):** A cryptographic hash function that outputs an immutable 64-character hexadecimal digest representing the exact contents of a file or data payload.
- **Okabe-Ito Palette:** An internationally recognized color palette engineered by Masataka Okabe and Kei Ito, designed to be completely unambiguous to individuals with all forms of color vision deficiency.
- **CDSCO (Central Drugs Standard Control Organisation):** India's national regulatory body governing pharmaceuticals, cosmetics, and medical devices.
