import '../models/sensor_packet.dart';
import '../models/calibration_record.dart';

enum QualityGateLevel { pass, warn, fail }

class QualityCheckResult {
  final QualityGateLevel level;
  final String checkName;
  final String message;
  final String? fixSuggestion;

  const QualityCheckResult({
    required this.level,
    required this.checkName,
    required this.message,
    this.fixSuggestion,
  });
}

class SessionQualityGate {
  final int maxCalibrationAgeDays;
  final double maxPacketLossPct;

  const SessionQualityGate({
    this.maxCalibrationAgeDays = 14,
    this.maxPacketLossPct = 2.0,
  });

  /// Evaluates pre-session readiness.
  List<QualityCheckResult> checkPreSession({
    required CalibrationRecord? calibration,
    required DecoderDiagnostics diagnostics,
    required bool isDeviceConnected,
    int? batteryPct,
  }) {
    final results = <QualityCheckResult>[];

    // 1. Connection check
    if (!isDeviceConnected) {
      results.add(const QualityCheckResult(
        level: QualityGateLevel.fail,
        checkName: 'device_connection',
        message: 'Glove device is not connected.',
        fixSuggestion: 'Connect by IP or select Simulator in Device tab.',
      ));
      return results;
    }

    // 2. Battery check
    if (batteryPct != null) {
      if (batteryPct < 10) {
        results.add(QualityCheckResult(
          level: QualityGateLevel.fail,
          checkName: 'battery',
          message: 'Battery level critically low ($batteryPct%).',
          fixSuggestion: 'Charge the device before starting therapy session.',
        ));
      } else if (batteryPct < 20) {
        results.add(QualityCheckResult(
          level: QualityGateLevel.warn,
          checkName: 'battery',
          message: 'Battery level is low ($batteryPct%).',
          fixSuggestion: 'Consider charging soon.',
        ));
      }
    }

    // 3. Calibration presence and age check
    if (calibration == null || !calibration.isValid) {
      results.add(const QualityCheckResult(
        level: QualityGateLevel.fail,
        checkName: 'calibration_present',
        message: 'Valid calibration record missing.',
        fixSuggestion: 'Complete the two-stage calibration wizard in Device tab.',
      ));
    } else {
      final ageDays = DateTime.now().toUtc().difference(calibration.capturedAt).inDays;
      if (ageDays > maxCalibrationAgeDays) {
        results.add(QualityCheckResult(
          level: QualityGateLevel.warn,
          checkName: 'calibration_age',
          message: 'Calibration is stale ($ageDays days old > max $maxCalibrationAgeDays days).',
          fixSuggestion: 'Perform a quick recalibration for best accuracy.',
        ));
      }
    }

    return results;
  }

  /// Evaluates live in-session signal stream health across sliding window of packets.
  List<QualityCheckResult> checkLiveStream({
    required List<SensorPacket> recentPackets, // last 10 seconds (~500 packets at 50 Hz)
    required DecoderDiagnostics diagnostics,
    required bool isExerciseActive,
  }) {
    final results = <QualityCheckResult>[];

    if (recentPackets.isEmpty) {
      results.add(const QualityCheckResult(
        level: QualityGateLevel.fail,
        checkName: 'stream_active',
        message: 'No sensor packets received.',
        fixSuggestion: 'Check Wi-Fi connection and glove power.',
      ));
      return results;
    }

    // 1. Packet loss check over the last 10s
    if (diagnostics.gapsDetected > 0 && diagnostics.totalPacketsDecoded > 0) {
      final lossPct = (diagnostics.gapsDetected / (diagnostics.totalPacketsDecoded + diagnostics.gapsDetected)) * 100.0;
      if (lossPct > maxPacketLossPct) {
        results.add(QualityCheckResult(
          level: lossPct > 10.0 ? QualityGateLevel.fail : QualityGateLevel.warn,
          checkName: 'packet_loss',
          message: 'Packet loss elevated (${lossPct.toStringAsFixed(1)}% > $maxPacketLossPct%).',
          fixSuggestion: 'Move closer to Wi-Fi access point or check RF interference.',
        ));
      }
    }

    // 2. Out-of-bounds check
    var outOfBoundsCount = 0;
    for (final p in recentPackets) {
      for (final f in p.flex) {
        if (f < 0 || f > 4095) outOfBoundsCount++;
      }
    }
    if (outOfBoundsCount > 0) {
      results.add(QualityCheckResult(
        level: QualityGateLevel.fail,
        checkName: 'sensor_bounds',
        message: '$outOfBoundsCount flex samples exceeded valid ADC bounds (0-4095).',
        fixSuggestion: 'Check sensor wiring for open/short circuit.',
      ));
    }

    // 3. Channel flatline check (if exercise is active for >= 3s = 150 samples)
    if (isExerciseActive && recentPackets.length >= 150) {
      final window150 = recentPackets.sublist(recentPackets.length - 150);
      for (var f = 0; f < 5; f++) {
        final vals = window150.map((p) => p.flex[f]).toSet();
        if (vals.length == 1) {
          // Zero variation for 3s during active exercise
          results.add(QualityCheckResult(
            level: QualityGateLevel.warn,
            checkName: 'flatline_channel_$f',
            message: 'Channel $f flatlined with constant value (${vals.first}) for 3s during exercise.',
            fixSuggestion: 'Ensure glove finger is flexing properly.',
          ));
        }
      }
    }

    return results;
  }
}

