# Electronics & Firmware Speech — Rajendra (Hardware Engineering)

**Time Slot:** Minute 2:30 – 3:45 (75 seconds)  
**Demo Step Accompanied:** Sensor stream acquisition, GPIO 47 hardware status LED, and sensor disconnect fail-safe verification  
**Source Files Relied On:** `firmware-esp32/include/config.h`, `firmware-esp32/src/main.cpp`, `docs/BOM.csv`, `tests/test_serial_ingest.py`  

---

## Spoken Speech

I am Rajendra, responsible for the embedded electronics and firmware on RehabBridge NEXUS. I wrote our acquisition firmware in firmware-esp32/src/main.cpp on an ESP32-S3 microcontroller, reading three bend sensors and one force sensor through an external ADS1115 sixteen-bit converter. The ADC and MPU6050 motion sensor communicate over dedicated hardware I2C lines on GPIO 8 and 9, streaming structured telemetry over USB serial at 921600 baud. I configured our sampling rate to 25 Hz to allow the analog multiplexer to settle cleanly between channels and prevent electrical crosstalk. If any sensor wire disconnects, the firmware immediately sets the hardware health flag to false, zeroes the channel value, and turns off the status LED on GPIO 47. You will see our live sensor stream maintain stable sequence numbers without dropped packets, and see the onboard LED confirm active bus communication. Our current prototype relies on tethered USB power and data, because wireless battery streaming is not yet enabled in firmware. I will now pass to Gautam, who built the mechanical glove and oversaw our physical testing.

---

## If a judge asks

1. **Why did you choose an external ADS1115 ADC rather than the ESP32-S3 internal ADC?**  
   The ESP32 internal ADC exhibits non-linear response and thermal drift, whereas the 16-bit ADS1115 on I2C pins 8 and 9 provides differential precision and programmable gain, as defined in `firmware-esp32/include/config.h`.

2. **How does the software detect if a sensor cable is severed during an exercise?**  
   The firmware detects open-circuit voltage out of range, sets `adc_ok` or `fsr_ok` to false, and the Python serial ingest terminates the trial with a hardware error, verified in `tests/test_serial_ingest.py::test_si_10_range_bounds`.

3. **What is the hardware cost to build this glove?**  
   The active hardware components total 6,180 Indian rupees, backed by our itemized bill of materials in `docs/BOM.csv`.
