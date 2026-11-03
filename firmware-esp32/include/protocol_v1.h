#ifndef NEXUS_PROTOCOL_V1_H
#define NEXUS_PROTOCOL_V1_H

#include <Arduino.h>
#include <ArduinoJson.h>

struct PacketV1 {
    uint8_t v = 1;
    uint32_t seq = 0;
    uint32_t t_ms = 0;
    int16_t flex[5] = {0};
    uint8_t flex_count = 3;
    int32_t fsr = 0;
    bool has_fsr = true;
    int16_t imu[6] = {0}; // [ax, ay, az, gx, gy, gz]
    bool fsr_ok = true;
    bool imu_ok = true;
    bool adc_ok = true;
    uint8_t flags = 0;
};

inline void serializePacketV1(const PacketV1& pkt, Print& output) {
    JsonDocument doc;
    doc["v"] = pkt.v;
    doc["seq"] = pkt.seq;
    doc["t_ms"] = pkt.t_ms;

    JsonArray flexArr = doc["flex"].to<JsonArray>();
    for (uint8_t i = 0; i < pkt.flex_count; ++i) {
        flexArr.add(pkt.flex[i]);
    }

    if (pkt.has_fsr) {
        doc["fsr"] = pkt.fsr;
    } else {
        doc["fsr"] = nullptr;
    }

    JsonArray imuArr = doc["imu"].to<JsonArray>();
    for (uint8_t i = 0; i < 6; ++i) {
        imuArr.add(pkt.imu[i]);
    }

    doc["fsr_ok"] = pkt.fsr_ok;
    doc["imu_ok"] = pkt.imu_ok;
    doc["adc_ok"] = pkt.adc_ok;
    doc["flags"] = pkt.flags;

    serializeJson(doc, output);
    output.println();
}

inline void emitBootLine(Print& output, const char* fw, const char* profile) {
    JsonDocument doc;
    doc["boot"] = true;
    doc["fw"] = fw;
    doc["profile"] = profile;
    serializeJson(doc, output);
    output.println();
}

#endif // NEXUS_PROTOCOL_V1_H
