import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('PacketDecoder Tests', () {
    late PacketDecoder decoder;

    setUp(() {
      decoder = PacketDecoder();
    });

    test('Decodes golden binary packets accurately', () {
      final fixturesFile = File('../../../shared/fixtures/golden_packets.json');
      expect(fixturesFile.existsSync(), isTrue);
      final jsonList = jsonDecode(fixturesFile.readAsStringSync()) as List;

      for (final fixture in jsonList) {
        final hexStr = fixture['hex'] as String;
        final expected = fixture['expected'] as Map<String, dynamic>;

        // Convert hex to Uint8List
        final bytes = Uint8List(hexStr.length ~/ 2);
        for (var i = 0; i < bytes.length; i++) {
          bytes[i] = int.parse(hexStr.substring(i * 2, i * 2 + 2), radix: 16);
        }

        final packet = decoder.decodeBinary(bytes);

        expect(packet.timestampMs, equals(expected['timestamp_ms']));
        expect(packet.flex, equals(expected['flex']));
        expect(packet.imu, equals(expected['imu']));
        expect(packet.fsr, equals(expected['fsr']));
        expect(packet.flags, equals(expected['flags']));
        expect(packet.batteryPct, equals(expected['battery_pct']));
        expect(packet.isCalibrated, equals(expected['is_calibrated']));
        expect(packet.isLowBattery, equals(expected['is_low_battery']));
        expect(packet.isSessionActive, equals(expected['is_session_active']));
        expect(packet.isSimulated, equals(expected['is_simulated']));
      }
    });

    test('Rejects invalid packet length', () {
      final shortBytes = Uint8List(29);
      expect(() => decoder.decodeBinary(shortBytes), throwsFormatException);

      final longBytes = Uint8List(31);
      expect(() => decoder.decodeBinary(longBytes), throwsFormatException);
      expect(decoder.diagnostics.decodeErrors, equals(2));
    });

    test('Rejects out-of-range ADC flex value', () {
      final data = ByteData(30);
      data.setUint32(0, 1000, Endian.little);
      data.setUint16(4, 4500, Endian.little); // 4500 > 4095
      final bytes = data.buffer.asUint8List();

      expect(() => decoder.decodeBinary(bytes), throwsFormatException);
    });

    test('Rejects out-of-range battery percentage', () {
      final data = ByteData(30);
      data.setUint32(0, 1000, Endian.little);
      data.setUint8(29, 105); // 105 > 100
      final bytes = data.buffer.asUint8List();

      expect(() => decoder.decodeBinary(bytes), throwsFormatException);
    });

    test('Tracks duplicate timestamps and gaps', () {
      final data1 = ByteData(30);
      data1.setUint32(0, 1000, Endian.little);
      decoder.decodeBinary(data1.buffer.asUint8List());

      // Duplicate timestamp
      final data2 = ByteData(30);
      data2.setUint32(0, 1000, Endian.little);
      decoder.decodeBinary(data2.buffer.asUint8List());
      expect(decoder.diagnostics.duplicateTimestamps, equals(1));

      // Gap (> 100ms)
      final data3 = ByteData(30);
      data3.setUint32(0, 1250, Endian.little);
      decoder.decodeBinary(data3.buffer.asUint8List());
      expect(decoder.diagnostics.gapsDetected, equals(1));
    });

    test('Decodes JSON packet format fallback', () {
      final jsonStr = jsonEncode({
        'v': 1,
        't': 5000,
        'flex': [1000, 1100, 1200, 1300, 1400],
        'imu': [0, 0, 980, 0, 0, 0],
        'fsr': 50,
        'flags': 9,
        'battery': 90,
        'simulated': true
      });

      final packet = decoder.decodeJson(jsonStr);
      expect(packet.timestampMs, equals(5000));
      expect(packet.flex.length, equals(5));
      expect(packet.imu.length, equals(6));
      expect(packet.isSimulated, isTrue);
    });
  });
}
