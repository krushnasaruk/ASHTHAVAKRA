/**
 * RehabBridge NEXUS / H10 Firmware (ESP32-S3)
 * High-speed USB serial acquisition: 3 flex + FSR + MPU6050 IMU at 25 Hz.
 */

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <MPU6050.h>
#include <ArduinoJson.h>
#include "config.h"
#include "protocol_v1.h"

// Hardware instances
Adafruit_ADS1115 ads;
MPU6050 imu;

// State
static uint32_t packet_seq = 0;
static bool streaming_enabled = true;
static bool ads_connected = false;
static bool imu_connected = false;
static uint32_t sample_rate_hz = TARGET_SAMPLE_RATE_HZ;
static uint32_t scan_interval_ms = SCAN_INTERVAL_MS;
static unsigned long last_scan_ms = 0;

void handleCommand(const String& line) {
    JsonDocument req;
    DeserializationError err = deserializeJson(req, line);
    if (err) {
        JsonDocument errDoc;
        errDoc["ok"] = false;
        errDoc["error"] = "INVALID_JSON";
        serializeJson(errDoc, Serial);
        Serial.println();
        return;
    }

    const char* cmd = req["cmd"] | "";
    const char* id = req["id"] | "";

    JsonDocument resp;
    resp["ack"] = id;

    if (strcmp(cmd, "ping") == 0) {
        resp["ok"] = true;
        resp["fw"] = FIRMWARE_VERSION;
        resp["profile"] = DEFAULT_PROFILE;
    } else if (strcmp(cmd, "config") == 0) {
        resp["ok"] = true;
        resp["fw"] = FIRMWARE_VERSION;
        resp["profile"] = DEFAULT_PROFILE;
        resp["sample_rate_hz"] = sample_rate_hz;
        JsonArray channels = resp["channels"].to<JsonArray>();
        channels.add("flex_thumb");
        channels.add("flex_index");
        channels.add("flex_middle");
        channels.add("fsr_contact");
    } else if (strcmp(cmd, "rate") == 0) {
        uint32_t requested_hz = req["hz"] | TARGET_SAMPLE_RATE_HZ;
        if (requested_hz == 25 || requested_hz == 50) {
            sample_rate_hz = requested_hz;
            scan_interval_ms = 1000 / sample_rate_hz;
            resp["ok"] = true;
            resp["hz"] = sample_rate_hz;
        } else {
            resp["ok"] = false;
            resp["error"] = "UNSUPPORTED_RATE";
            resp["hz"] = sample_rate_hz;
        }
    } else if (strcmp(cmd, "stream") == 0) {
        streaming_enabled = req["on"] | true;
        resp["ok"] = true;
        resp["streaming"] = streaming_enabled;
    } else if (strcmp(cmd, "buzz") == 0) {
        resp["ok"] = false;
        resp["error"] = "NO_BUZZER";
    } else {
        resp["ok"] = false;
        resp["error"] = "UNKNOWN_COMMAND";
    }

    serializeJson(resp, Serial);
    Serial.println();
}

void setup() {
    Serial.begin(SERIAL_BAUD);
    unsigned long start_wait = millis();
    while (!Serial && (millis() - start_wait < 2000)) {
        delay(10);
    }

    // Status LED
    pinMode(STATUS_LED_PIN, OUTPUT);
    digitalWrite(STATUS_LED_PIN, LOW);

    // Initialize I2C bus
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN, 400000);

    // Emit boot notification line per Section 4.5
    emitBootLine(Serial, FIRMWARE_VERSION, DEFAULT_PROFILE);

    // Initialize ADS1115
    ads.setGain(GAIN_ONE); // ±4.096V 1-bit = 0.125mV
    ads.setDataRate(RATE_ADS1115_128SPS);
    if (ads.begin(ADS1115_I2C_ADDR, &Wire)) {
        ads_connected = true;
    } else {
        ads_connected = false;
    }

    // Initialize MPU6050
    imu.initialize();
    if (imu.testConnection()) {
        imu_connected = true;
        imu.setFullScaleAccelRange(ACCEL_CONFIG_RANGE); // ±4g
        imu.setFullScaleGyroRange(GYRO_CONFIG_RANGE);   // ±500 deg/s
    } else {
        imu_connected = false;
    }

    digitalWrite(STATUS_LED_PIN, (ads_connected && imu_connected) ? HIGH : LOW);
}

void loop() {
    // Process serial incoming commands
    while (Serial.available() > 0) {
        String line = Serial.readStringUntil('\n');
        line.trim();
        if (line.length() > 0) {
            handleCommand(line);
        }
    }

    // Periodic acquisition loop at 25 Hz / 40 ms
    unsigned long now_ms = millis();
    if (streaming_enabled && (now_ms - last_scan_ms >= scan_interval_ms)) {
        last_scan_ms = now_ms;

        PacketV1 pkt;
        pkt.v = 1;
        pkt.seq = ++packet_seq;
        pkt.t_ms = now_ms;
        pkt.flex_count = 3;
        pkt.has_fsr = true;
        pkt.adc_ok = ads_connected;
        pkt.imu_ok = imu_connected;
        pkt.flags = 0;
        if (streaming_enabled) {
            pkt.flags |= (1 << 1); // stream active
        }

        // ADS1115 conversions
        if (ads_connected) {
            pkt.flex[0] = ads.readADC_SingleEnded(FLEX_CH_THUMB);
            pkt.flex[1] = ads.readADC_SingleEnded(FLEX_CH_INDEX);
            pkt.flex[2] = ads.readADC_SingleEnded(FLEX_CH_MIDDLE);
            pkt.fsr = ads.readADC_SingleEnded(FSR_CH_CONTACT);
            pkt.fsr_ok = (pkt.fsr >= 0 && pkt.fsr < 31500);
        } else {
            pkt.flex[0] = 0;
            pkt.flex[1] = 0;
            pkt.flex[2] = 0;
            pkt.fsr = 0;
            pkt.fsr_ok = false;
        }

        // MPU6050 conversions
        if (imu_connected) {
            imu.getMotion6(&pkt.imu[0], &pkt.imu[1], &pkt.imu[2],
                           &pkt.imu[3], &pkt.imu[4], &pkt.imu[5]);
        } else {
            for (int i = 0; i < 6; ++i) pkt.imu[i] = 0;
        }

        // Serialize line-delimited JSON
        serializePacketV1(pkt, Serial);
    }
}

