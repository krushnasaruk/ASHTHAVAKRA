# RehabBridge NEXUS / H10 — Project Status

**Target Event:** Innovation 2K26, College of Engineering, Phaltan (3–4 November 2026)  
**Current Date:** 2026-11-03  
**Status:** In Progress (Phase 1 / Gate G0 Passed)

---

## 1. Gate Status Matrix

| Gate | Target Condition | Deadline | Status | Verified By |
|---|---|---|---|---|
| **G0** | Board enumerates on USB, sends one valid packet, Python receives it | Hour 3 | **PASSED** | `tests/test_firmware_parity.py` & `tests/test_serial_ingest.py` (14/14 tests passing) |
| **G1** | 3 flex + FSR + IMU stream with stable `seq` at 25 Hz | Hour 8 | In Progress | Ingest buffer and rate monitor verified; physical serial verification pending |
| **G2** | ArUco marker detected at $\ge 15$ FPS with $\ge 80\%$ 1s detection rate | Hour 10 | Queued | `backend/vision.py` implementation in Phase 3 |
| **G3** | First verified transfer end-to-end recorded in SQLite | Hour 16 | Queued | `backend/taskproof.py` in Phase 5 |
| **G4** | 10 consecutive attempts without crash; labelled ground-truth trials | Hour 22 | Queued | Phase 7 |
| **G5** | Full demo runs 3 times from fresh clean-start script | Hour 30 | Queued | Phase 7 |
| **G6** | Code freeze; evidence bundle generated | Hour 40 | Queued | Phase 7 |

---

## 2. Completed Phase Deliverables (Phase 1 & Gate G0)

1. **Contracts & Schemas:**
   - `shared/protocol/protocol_v1_schema.json` (Strict Draft-07 JSON Schema)
   - `shared/protocol/command_schema.json` (Ping, Config, Rate, Buzz, Boot lines)
   - `shared/fixtures/golden_packet_v1.json` & `tests/fixtures/packet_golden_v1.json`
   - `config/signal.yaml` (Signal thresholds with explicit `status: provisional` markers)
   - `config/taskproof.yaml` (TaskProof thresholds with explicit `status: provisional` markers)
   - `config/zones.json` (Zone A/B polygon coordinates and marker dimensions)

2. **Firmware (`firmware-esp32/`):**
   - `firmware-esp32/platformio.ini` (Configured for ESP32-S3 DevKit at 921600 baud, pinned libraries: Adafruit ADS1X15, ElectronicCats MPU6050, ArduinoJson 7.x)
   - `firmware-esp32/include/config.h` (I2C SDA/SCL pins 8/9, ADS1115 0x48, 25 Hz scan interval)
   - `firmware-esp32/include/protocol_v1.h` (Packet struct and line-delimited JSON serializer)
   - `firmware-esp32/src/main.cpp` (25 Hz ADS1115 scan loop, MPU6050 reads, boot line notification, bidirectional command handler)

3. **Serial Host Ingestion (`backend/serial_ingest.py`):**
   - Threaded non-blocking line reader
   - Automatic port discovery with ping ACK verification (`{"cmd":"ping"}`)
   - Strict version check (`v == 1`) and required fields validation
   - Monotonic sequence gap and duplicate detection
   - Reboot detection via boot line and sequence regression / epoch management
   - Bounded ring buffer with drop counting

4. **Automated Verification Suite:**
   - `tests/test_contracts.py` (4/4 passed)
   - `tests/test_serial_ingest.py` (6/6 passed)
   - `tests/test_firmware_parity.py` (4/4 passed)
   - Total: 14/14 tests passing in 0.21s.
