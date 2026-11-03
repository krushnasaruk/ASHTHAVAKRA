#ifndef NEXUS_CONFIG_H
#define NEXUS_CONFIG_H

#include <Arduino.h>

#ifndef FIRMWARE_VERSION
#define FIRMWARE_VERSION "1.0.0"
#endif

#ifndef DEFAULT_PROFILE
#define DEFAULT_PROFILE "demo3"
#endif

#ifndef SERIAL_BAUD
#define SERIAL_BAUD 921600
#endif

// Hardware I2C Pin Definitions for ESP32-S3 DevKit
#define I2C_SDA_PIN 8
#define I2C_SCL_PIN 9
#define STATUS_LED_PIN 47

// ADS1115 Configuration
#define ADS1115_I2C_ADDR 0x48
#define FLEX_CH_THUMB  0
#define FLEX_CH_INDEX  1
#define FLEX_CH_MIDDLE 2
#define FSR_CH_CONTACT 3

// Sampling Rate & Timing
#define TARGET_SAMPLE_RATE_HZ 25
#define SCAN_INTERVAL_MS (1000 / TARGET_SAMPLE_RATE_HZ) // 40 ms

// IMU Scale factors (MPU6050)
// Accel ±4g -> 8192 LSB/g
// Gyro ±500 °/s -> 65.5 LSB/(°/s)
#define ACCEL_CONFIG_RANGE 0x01 // ±4g
#define GYRO_CONFIG_RANGE  0x01 // ±500 deg/s

#endif // NEXUS_CONFIG_H
