import 'dart:convert';
import 'dart:typed_data';

/// Immutable decoded sensor packet from ESP32 or simulator.
class SensorPacket {
  final int timestampMs;
  final List<int> flex; // 5 flex sensors: thumb, index, middle, ring, pinky
  final List<int> imu;  // ax, ay, az, gx, gy, gz
  final int fsr;
  final int flags;
  final int batteryPct;
  final bool isSimulated;

  const SensorPacket({
    required this.timestampMs,
    required this.flex,
    required this.imu,
    required this.fsr,
    required this.flags,
    required this.batteryPct,
    required this.isSimulated,
  });

  bool get isCalibrated => (flags & 0x01) != 0;
  bool get isLowBattery => (flags & 0x02) != 0;
  bool get isSessionActive => (flags & 0x04) != 0;

  Map<String, dynamic> toJson() => {
    'v': 1,
    't': timestampMs,
    'flex': flex,
    'imu': imu,
    'fsr': fsr,
    'flags': flags,
    'battery': batteryPct,
    'simulated': isSimulated,
  };

  factory SensorPacket.fromJson(Map<String, dynamic> json) {
    final t = json['t'] as int;
    final flexRaw = (json['flex'] as List).cast<int>();
    final imuRaw = (json['imu'] as List).cast<int>();
    final fsr = json['fsr'] as int? ?? 0;
    final flags = json['flags'] as int? ?? 0;
    final battery = json['battery'] as int? ?? 100;
    final sim = json['simulated'] as bool? ?? ((flags & 0x08) != 0);

    return SensorPacket(
      timestampMs: t,
      flex: flexRaw,
      imu: imuRaw,
      fsr: fsr,
      flags: flags,
      batteryPct: battery,
      isSimulated: sim,
    );
  }
}

/// Statistics and diagnostics for the packet stream decoder.
class DecoderDiagnostics {
  int totalPacketsDecoded = 0;
  int decodeErrors = 0;
  int duplicateTimestamps = 0;
  int outOfOrderTimestamps = 0;
  int gapsDetected = 0;
  int lastTimestampMs = -1;
  int lastPacketTimeMillis = 0;

  void reset() {
    totalPacketsDecoded = 0;
    decodeErrors = 0;
    duplicateTimestamps = 0;
    outOfOrderTimestamps = 0;
    gapsDetected = 0;
    lastTimestampMs = -1;
    lastPacketTimeMillis = 0;
  }
}

/// Robust packet decoder supporting 30-byte little-endian binary packets
/// and JSON packets with monotonicity, duplicate, gap, and bounds validation.
class PacketDecoder {
  final int expectedIntervalMs;
  final int maxAllowedGapMs;
  final DecoderDiagnostics diagnostics = DecoderDiagnostics();

  PacketDecoder({this.expectedIntervalMs = 20, this.maxAllowedGapMs = 100});

  /// Decodes a 30-byte little-endian binary buffer.
  /// Throws FormatException on corruption, out of bounds, or length mismatch.
  SensorPacket decodeBinary(Uint8List bytes) {
    if (bytes.length != 30) {
      diagnostics.decodeErrors++;
      throw FormatException('Binary packet length must be 30 bytes, got ${bytes.length}');
    }

    final data = ByteData.sublistView(bytes);

    // Offset 0: uint32 timestamp_ms (4 bytes)
    final timestampMs = data.getUint32(0, Endian.little);

    // Offset 4: 5 x uint16 flex (10 bytes)
    final flex = <int>[];
    for (var i = 0; i < 5; i++) {
      final val = data.getUint16(4 + (i * 2), Endian.little);
      if (val > 4095) {
        diagnostics.decodeErrors++;
        throw FormatException('Flex ADC at index $i is out of range: $val > 4095');
      }
      flex.add(val);
    }

    // Offset 14: 6 x int16 imu (12 bytes: ax, ay, az, gx, gy, gz)
    final imu = <int>[];
    for (var i = 0; i < 6; i++) {
      final val = data.getInt16(14 + (i * 2), Endian.little);
      imu.add(val);
    }

    // Offset 26: uint16 fsr (2 bytes)
    final fsr = data.getUint16(26, Endian.little);

    // Offset 28: uint8 flags (1 byte)
    final flags = data.getUint8(28);

    // Offset 29: uint8 battery_pct (1 byte)
    final batteryPct = data.getUint8(29);
    if (batteryPct > 100) {
      diagnostics.decodeErrors++;
      throw FormatException('Battery percentage out of range: $batteryPct > 100');
    }

    final isSimulated = (flags & 0x08) != 0;

    _validateSequence(timestampMs);

    final packet = SensorPacket(
      timestampMs: timestampMs,
      flex: flex,
      imu: imu,
      fsr: fsr,
      flags: flags,
      batteryPct: batteryPct,
      isSimulated: isSimulated,
    );

    diagnostics.totalPacketsDecoded++;
    return packet;
  }

  /// Decodes a JSON string packet.
  SensorPacket decodeJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final t = map['t'] as int;
      final flexRaw = (map['flex'] as List).cast<int>();
      final imuRaw = (map['imu'] as List).cast<int>();
      final fsr = map['fsr'] as int? ?? 0;
      final flags = map['flags'] as int? ?? 0;
      final battery = map['battery'] as int? ?? 100;
      final sim = map['simulated'] as bool? ?? ((flags & 0x08) != 0);

      if (flexRaw.length != 5) {
        throw FormatException('JSON flex must contain 5 channels');
      }
      for (final f in flexRaw) {
        if (f < 0 || f > 4095) {
          throw FormatException('Flex ADC out of range: $f');
        }
      }
      if (imuRaw.length != 6) {
        throw FormatException('JSON imu must contain 6 channels');
      }
      if (battery < 0 || battery > 100) {
        throw FormatException('Battery out of range: $battery');
      }

      _validateSequence(t);

      final packet = SensorPacket(
        timestampMs: t,
        flex: flexRaw,
        imu: imuRaw,
        fsr: fsr,
        flags: flags,
        batteryPct: battery,
        isSimulated: sim,
      );

      diagnostics.totalPacketsDecoded++;
      return packet;
    } catch (e) {
      diagnostics.decodeErrors++;
      rethrow;
    }
  }

  void _validateSequence(int timestampMs) {
    if (diagnostics.lastTimestampMs != -1) {
      if (timestampMs == diagnostics.lastTimestampMs) {
        diagnostics.duplicateTimestamps++;
      } else if (timestampMs < diagnostics.lastTimestampMs) {
        diagnostics.outOfOrderTimestamps++;
      } else {
        final delta = timestampMs - diagnostics.lastTimestampMs;
        if (delta > maxAllowedGapMs) {
          diagnostics.gapsDetected++;
        }
      }
    }
    diagnostics.lastTimestampMs = timestampMs;
    diagnostics.lastPacketTimeMillis = DateTime.now().millisecondsSinceEpoch;
  }
}
