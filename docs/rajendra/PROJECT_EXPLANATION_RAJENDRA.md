# Project Explanation for Rajendra — Hardware Electronics & Firmware

**Role:** Hardware Electronics & Firmware Lead  
**Direct System Ownership:** Firmware acquisition (`firmware-esp32/src/main.cpp`), circuit pinouts (`firmware-esp32/include/config.h`), ADS1115 ADC configuration, MPU6050 IMU, bill of materials (`docs/BOM.csv`).

---

## 1. What the Project Is & What Hardware You Built

RehabBridge NEXUS requires clean, synchronized physical sensor data to verify that a patient actually grasped and moved an object. 

You built the embedded acquisition system consisting of:
- **Microcontroller:** ESP32-S3 DevKit-C (Xtensa dual-core 240 MHz).
- **External 16-Bit ADC:** Texas Instruments ADS1115 on I2C address `0x48`.
- **Sensors:** 3 Spectra Symbol 2.2" resistive flex sensors (Thumb, Index, Middle) and 1 Interlink FSR 402 palmar force sensor.
- **Motion Tracking:** InvenSense MPU6050 6-DOF IMU on I2C address `0x68`.
- **Signalling:** Onboard status LED on GPIO 47 and high-speed USB serial at 921600 baud.

---

## 2. Why the Hardware Was Designed This Way

### 2.1 Why External ADS1115 Instead of ESP32 Internal ADC?
The ESP32's built-in ADC is notoriously non-linear, has poor sensitivity below 0.5V and above 2.8V, and suffers from RF noise spikes. By adding an external 16-bit ADS1115 ADC on dedicated I2C pins (SDA GPIO 8, SCL GPIO 9), we gain:
- True 16-bit differential precision (1 LSB = 0.125 mV at $\pm 4.096\text{V}$ gain).
- Stable programmable gain and clean analog voltage readings unaffected by CPU load.

### 2.2 Why 25 Hz Sampling Rate?
The ADS1115 multiplexer samples channels sequentially. Converting 4 channels at 128 SPS requires $\approx 32\text{ ms}$ total conversion time. Sampling at **25 Hz** ($40\text{ ms}$ interval) provides a comfortable settling margin, eliminating capacitive crosstalk between finger channels.

### 2.3 Sensor Disconnect Fail-Safe
If any sensor wire disconnects mid-exercise:
1. The voltage divider outputs an open-circuit reading out of valid bounds.
2. The firmware marks `adc_ok = false` or `fsr_ok = false` in the telemetry packet.
3. The firmware immediately turns off the status LED on GPIO 47.
4. The backend serial ingest detects the hardware fault and halts the attempt safely.

---

## 3. Your 90-Second Demo & Presentation Script

> "I am Rajendra, responsible for the embedded electronics and firmware on RehabBridge NEXUS. The most common pitfall in wearable medical prototypes is trusting noisy internal micro-controller ADCs.
> 
> To guarantee measurement integrity, I routed our three finger bend sensors and palmar force sensor through an external 16-bit Texas Instruments ADS1115 ADC over a dedicated 400 kHz I2C bus on GPIO 8 and 9. Each sensor forms a voltage divider with a precision 1% metal-film resistor powered from a clean regulated rail.
> 
> I configured our acquisition loop in firmware to 25 Hz. This guarantees complete analog channel settling without electrical crosstalk between adjacent fingers. Alongside the bend sensors, an MPU6050 motion sensor captures hand tilt and dynamic stability.
> 
> If any sensor wire disconnects, the firmware sets the hardware health flag to false, zeroes out that channel, and extinguishes the status LED on GPIO 47. During our demo, you will see our 25 Hz live data packet stream steadily without sequence drops, and see the onboard LED verify active bus health."

---

## 4. Key Judge Questions You Own

1. **Why did you choose an external ADS1115 ADC rather than the ESP32-S3 internal ADC?**  
   *Answer:* The ESP32 internal ADC exhibits non-linear response and thermal drift, whereas the 16-bit ADS1115 on I2C pins 8 and 9 provides differential precision and programmable gain, as configured in `firmware-esp32/include/config.h`.
2. **How does the software detect if a sensor cable is severed during an exercise?**  
   *Answer:* The firmware detects open-circuit voltage out of range, sets `adc_ok` or `fsr_ok` to false, and the Python serial ingest terminates the trial with a hardware error, verified in `tests/test_serial_ingest.py::test_si_10_range_bounds`.
3. **What is the hardware cost to build this glove?**  
   *Answer:* The active hardware components total 6,180 Indian rupees, backed by our itemized bill of materials in `docs/BOM.csv`.
