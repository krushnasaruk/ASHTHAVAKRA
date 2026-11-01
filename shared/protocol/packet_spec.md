# H10 Hardware & Simulator Packet Protocol Specification

## 1. WebSocket Transport
- Default endpoint: `ws://<host>:<port>/ws/sensors`
- Frame rate: 50 Hz (default; configurable to 25 Hz if supported).

### 1.1 Handshake / Hello Frame
The first WebSocket frame sent by the device upon connection is a JSON hello message:
```json
{
  "type": "hello",
  "protocol": 1,
  "firmware": "1.0.0",
  "rate_hz": 50,
  "encoding": "binary"
}
```
Clients must verify `protocol == 1`. If an incompatible protocol version is encountered, the client immediately disconnects and shows "Protocol unsupported".

## 2. 30-Byte Little-Endian Binary Packet Structure
All multi-byte numeric fields are encoded in little-endian byte order (`<` in Python `struct`, `Endian.little` in Dart `ByteData`).

| Offset | Size (bytes) | Field Name | Data Type | Value Range / Units | Description |
|:---:|:---:|:---|:---:|:---|:---|
| 0 | 4 | `timestamp_ms` | `uint32` | 0 .. 4,294,967,295 ms | Milliseconds since device boot |
| 4 | 2 | `flex[0]` (Thumb) | `uint16` | 0 .. 4095 ADC counts | Thumb flex sensor ADC |
| 6 | 2 | `flex[1]` (Index) | `uint16` | 0 .. 4095 ADC counts | Index flex sensor ADC |
| 8 | 2 | `flex[2]` (Middle) | `uint16` | 0 .. 4095 ADC counts | Middle flex sensor ADC |
| 10 | 2 | `flex[3]` (Ring) | `uint16` | 0 .. 4095 ADC counts | Ring flex sensor ADC |
| 12 | 2 | `flex[4]` (Pinky) | `uint16` | 0 .. 4095 ADC counts | Pinky flex sensor ADC |
| 14 | 2 | `ax` | `int16` | -32,768 .. 32,767 mg | Acceleration X in milli-g |
| 16 | 2 | `ay` | `int16` | -32,768 .. 32,767 mg | Acceleration Y in milli-g |
| 18 | 2 | `az` | `int16` | -32,768 .. 32,767 mg | Acceleration Z in milli-g |
| 20 | 2 | `gx` | `int16` | -32,768 .. 32,767 (0.1°/s) | Angular rate X |
| 22 | 2 | `gy` | `int16` | -32,768 .. 32,767 (0.1°/s) | Angular rate Y |
| 24 | 2 | `gz` | `int16` | -32,768 .. 32,767 (0.1°/s) | Angular rate Z |
| 26 | 2 | `fsr` | `uint16` | 0 .. 4095 ADC counts | Tip FSR sensor (0 if unequipped) |
| 28 | 1 | `flags` | `uint8` | 0 .. 255 bitmask | Bit 0: Calibrated<br>Bit 1: Low Battery<br>Bit 2: Session Active<br>Bit 3: Simulated |
| 29 | 1 | `battery_pct` | `uint8` | 0 .. 100 % | Battery charge percentage |

Total Packet Length = 30 bytes exactly.

## 3. JSON Packet Fallback
For browser debugging, unit testing, and fallbacks:
```json
{
  "v": 1,
  "t": 123456,
  "flex": [1820, 1950, 2010, 1900, 1850],
  "imu": [50, -30, 980, 2, -1, 0],
  "fsr": 0,
  "flags": 9,
  "battery": 85,
  "simulated": true
}
```

## 4. HTTP REST API Contract (ESP32 & Simulator)
- `GET /api/status` -> 200 `{ "ok": true, "data": { "battery": 85, "uptime_ms": 123456, "rate_hz": 50, "calibrated": true, "session_active": false } }`
- `GET /api/info` -> 200 `{ "ok": true, "data": { "firmware": "1.0.0", "protocol": 1, "device_id": "H10-SIM-01", "fsr_present": false, "haptic_present": true, "allowed_rates": [25, 50] } }`
- `GET /api/calibration` -> 200 `{ "ok": true, "data": { ... } }`
- `POST /api/calibration/open` -> Body: `{"duration_ms": 2000}`. 200 / 409 / 422
- `POST /api/calibration/fist` -> Body: `{"duration_ms": 2000}`. 200 / 409 / 422
- `POST /api/session/start` -> Body: `{"session_id": "<uuid>"}`. 200 / 409
- `POST /api/session/stop` -> Body: `{"session_id": "<uuid>"}`. 200 / 404
- `POST /api/control/haptic` -> Body: `{"motor": "both", "duration_ms": 200}`. 200 / 501
- `POST /api/control/rate` -> Body: `{"hz": 50}`. 200 / 422
