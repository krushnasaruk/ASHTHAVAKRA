<!-- Generated from commit cabf24c on 2026-11-03. Re-generate after any code change. -->

# Briefing Pack: Rajendra (Hardware Electronics & Firmware — Proposed)

**Role:** Circuit Pinout, ADC & IMU Configuration, Voltage Dividers, Firmware Serialization, Electrical Safety  
**Direct Ownership:** `firmware-esp32/`, `docs/BOM.csv`, `config/signal.yaml`  
**Commits Owned:** `d320c68`, `cabf24c`

---

## 1. What I Built & Own
- **ESP32-S3 Firmware Architecture** ([`firmware-esp32/src/main.cpp`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/firmware-esp32/src/main.cpp)):
  - 25 Hz non-blocking scan loop reading 4 channels of ADS1115 ADC and 6 axes of MPU6050 IMU.
  - Strict line-delimited JSON packet serializer (`< 200` bytes).
  - Bidirectional command handler supporting `ping`, `config`, `rate`, `buzz`, and `boot` messages.
- **Hardware Circuit Pinout & I2C Bus** ([`firmware-esp32/include/config.h`](file:///c:/Users/Krushna/OneDrive/Documents/projects%20for%20github/asthavakra/firmware-esp32/include/config.h)):
  - Microcontroller: ESP32-S3 DevKit-C (Xtensa dual-core 240 MHz).
  - I2C Bus: SDA on GPIO 8, SCL on GPIO 9 running at 400 kHz fast mode.
  - External ADC: ADS1115 16-bit 4-channel ADC at address `0x48`.
  - IMU: MPU6050 6-DOF at address `0x68`.
  - Status LED on GPIO 10, Piezo buzzer on GPIO 11.
- **Analog Front-End (Voltage Dividers):**
  - Channels A0–A2: 2.2-inch resistive flex sensors paired with 10 kΩ 1% metal-film reference resistors.
  - Channel A3: Interlink FSR 402 force-sensing contact resistor with 10 kΩ pull-down.
  - Rail protection: Dedicated 3.3V LDO reference avoiding ESP32 noisy internal ADC channels.

---

## 2. What Is Working & How I Know
- **FW-01 / Gate G0 Valid Packet Delivery:** Confirmed by `tests/test_firmware_parity.py::test_fw_01_and_gate_g0_board_sends_valid_packet_python_receives`. Board sends valid Protocol v1 JSON received by Python.
- **FW-02 Packet Byte Budget:** Confirmed by `test_fw_02`. Full 5-channel JSON packet length is strictly under 200 bytes (typical size: 148 bytes).
- **FW-05 Command-Response Contract:** Confirmed by `test_fw_05`. Responds to `{"cmd":"ping"}` with `{"ack":"ping","status":"ok"}` within 10 ms.
- **FW-07 Boot Notification Line:** Confirmed by `test_fw_07`. Board emits `{"boot":"nexus_esp32_ready","v":1}` on power-up/reset.
- **Throughput Rate:** Bench verified at stable 25 Hz ($\pm 1.2$ Hz) without FIFO buffer overrun (`test_si_08`).

---

## 3. What Is NOT Working or Not Finished
- **Battery Voltage Telemetry:** The event prototype does NOT include an onboard battery fuel gauge or LiPo charging circuit. It runs on isolated 5V USB bus power. In accordance with honest claims rule #8, battery is reported as `unsupported`, never estimated.
- **ADC Rate Beyond 25 Hz:** Although the ADS1115 can reach 860 SPS in single-shot mode, sequential multiplexing across 4 differential channels limits safe, noise-free sampling to 25 Hz per channel. Raising to 50 Hz introduces channel cross-talk and is deferred to Tier 2 hardware revisions.

---

## 4. 90-Second Speaking Script
> "Judges, the most common hardware flaw in flex sensor gloves is using the ESP32’s internal ADC. The ESP32 internal ADC is notoriously non-linear, especially below 0.5 volts and above 2.8 volts, and suffers from RF noise spikes whenever the radio activates.
> 
> We solved this by designing a dedicated external analog front-end. We routed our 3 flex sensors and the palmar FSR through a precision 16-bit Texas Instruments ADS1115 ADC over a 400 kHz I2C bus. Each bend sensor forms a voltage divider with a 10 kilo-ohm, 1% tolerance metal-film resistor, powered from a clean 3.3-volt regulated rail.
> 
> We chose a 25 Hz sampling rate. Why 25 Hz? Because sequential multiplexing across four channels on the ADS1115 requires approximately 9 milliseconds per conversion in continuous mode. 25 Hz gives us clean, settle-time-compliant digitization without channel cross-talk.
> 
> For transport, we run USB serial at 921,600 baud. The entire packet fits in 148 bytes, consuming less than 1.5% of our available bus bandwidth. If a wire breaks or shorts to ground, our rail detector flags an immediate fault.
> 
> I now hand over to Gautam to explain how these sensors are mechanically fitted to the glove."

---

## 5. Live Demo Steps
1. Show the ESP32-S3 DevKit and the custom prototype perfboard to the judges.
2. Point out:
   - ADS1115 16-bit ADC module at address `0x48`.
   - MPU6050 IMU module at address `0x68`.
   - 10 kΩ 1% metal-film divider resistors.
   - Heat-shrink insulated wire harness.
3. Plug in the USB cable: show the green status LED illuminate and the piezo buzzer chirp once.
4. Point to the terminal: show the boot line `{"boot":"nexus_esp32_ready","v":1}` appearing on COM port enumeration.
5. In the Operator View, point out the raw ADC readings updating smoothly in real-time.
6. *If serial connection drops:* State calmly: "The serial endpoint lost enumeration. I am checking the USB-C cable seating." Unplug and re-seat cable; within 1.5s the auto-reconnect handler picks up the port.

---

## 6. Numbers I May Quote vs Must NOT Quote

### Allowed Numbers (Sourced):
- **Serial Baud Rate:** 921,600 baud (`firmware-esp32/platformio.ini`).
- **ADC Resolution:** 16-bit (differential range 0 to 32,767 counts) (`include/config.h`).
- **I2C Clock:** 400 kHz Fast-Mode (`src/main.cpp#L32`).
- **Sampling Frequency:** 25 Hz per channel (`config/signal.yaml`).
- **Divider Resistors:** 10 kΩ $\pm 1\%$ metal-film (`docs/BOM.csv`).
- **Packet Size:** $< 200$ bytes (average 148 bytes) (`tests/test_firmware_parity.py`).
- **Total Hardware BOM Cost:** ₹8,400 INR total (₹6,180 active system + ₹2,220 backup spares) (`docs/BOM.csv`).

### Numbers I Must NOT Quote:
- **"50 Hz or 100 Hz Streaming":** Prohibited. Hardware is locked to 25 Hz to maintain ADS1115 channel settling stability.
- **Battery mAh or Percentage:** Prohibited. Prototype is USB powered. Battery reporting is `unsupported`.

---

## 7. Question Ownership & Handoffs

### Questions I Own:
- `HW-01` (Why use an external ADS1115 instead of the built-in ESP32 ADC?)
- `HW-02` (What is the sampling frequency and how does multiplexing limit it?)
- `HW-03` (How are the voltage dividers designed for the flex sensors?)
- `HW-04` (How do you isolate sensor noise from the microcontroller logic?)
- `HW-05` (What happens electrically if an FSR wire breaks or shorts?)
- `HW-06` (What is the electrical safety and isolation for the human wearer?)
- `HW-07` (What is the total bill of materials cost?)

### Questions I Hand Off:
- TaskProof state transitions, software algorithms, SQLite WAL $\rightarrow$ **Hand off to Developer**.
- Glove fabric, seam strain relief, physical cube dimensions $\rightarrow$ **Hand off to Gautam**.
- Judge View UI, color-blind palette, accessibility $\rightarrow$ **Hand off to Vaishnavi**.

---

## 8. Failure Script
> "Judges, the A3 channel is currently reading at ground zero counts, which our signal integrity layer has immediately flagged as an `FSR_FAULT` rail condition. This indicates a physical disconnect in the contact line. Notice that rather than producing erroneous touch verdicts, the system locked the TaskProof engine into `UNCERTAIN`. I have an identical backup ADS1115 and pre-terminated FSR harness right here in our spares kit, which can be hot-swapped in under two minutes."
