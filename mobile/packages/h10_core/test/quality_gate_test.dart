import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('SessionQualityGate Tests', () {
    const gate = SessionQualityGate(maxCalibrationAgeDays: 14, maxPacketLossPct: 2.0);

    test('Pre-session fails when device is disconnected', () {
      final res = gate.checkPreSession(
        calibration: null,
        diagnostics: DecoderDiagnostics(),
        isDeviceConnected: false,
      );
      expect(res.any((r) => r.level == QualityGateLevel.fail), isTrue);
      expect(res.first.checkName, equals('device_connection'));
    });

    test('Pre-session warns on stale calibration (> 14 days old)', () {
      final oldDate = DateTime.now().toUtc().subtract(const Duration(days: 20));
      final calRecord = CalibrationRecord(
        id: 'cal_old',
        capturedAt: oldDate,
        fingers: List.generate(5, (i) => FingerCalibration(
          fingerIndex: i, name: 'f$i', openValue: 1000, closedValue: 3000,
          span: 2000, polarity: 1, isValid: true, openSd: 5, closedSd: 5,
        )),
        status: 'valid',
      );

      final res = gate.checkPreSession(
        calibration: calRecord,
        diagnostics: DecoderDiagnostics(),
        isDeviceConnected: true,
        batteryPct: 80,
      );
      expect(res.any((r) => r.level == QualityGateLevel.warn && r.checkName == 'calibration_age'), isTrue);
    });

    test('Live stream warns on flatlined channel during active exercise', () {
      // 150 packets where channel 0 is constant 1200 with 0 variation
      final packets = List.generate(150, (i) => SensorPacket(
        timestampMs: 1000 + (i * 20),
        flex: [1200, 1000 + i, 1100 + i, 1050 + i, 990 + i], // channel 0 is flatlined
        imu: [0, 0, 980, 0, 0, 0],
        fsr: 0,
        flags: 9,
        batteryPct: 90,
        isSimulated: true,
      ));

      final res = gate.checkLiveStream(
        recentPackets: packets,
        diagnostics: DecoderDiagnostics(),
        isExerciseActive: true,
      );

      expect(res.any((r) => r.checkName == 'flatline_channel_0'), isTrue);
    });
  });
}

