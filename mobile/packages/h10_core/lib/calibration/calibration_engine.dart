import 'dart:math' as math;
import '../models/calibration_record.dart';

class CalibrationEngine {
  static const fingerNames = ['thumb', 'index', 'middle', 'ring', 'pinky'];
  final int minSpanThreshold;
  final double maxStabilitySd;
  final double driftToleranceRatio; // default 0.15 (15%)

  const CalibrationEngine({
    this.minSpanThreshold = 300,
    this.maxStabilitySd = 40.0,
    this.driftToleranceRatio = 0.15,
  });

  /// Computes median of a numerical list.
  static double median(List<num> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<num>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid].toDouble();
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }

  /// Computes population standard deviation.
  static double standardDeviation(List<num> values) {
    if (values.length < 2) return 0.0;
    final mean = values.fold<double>(0.0, (acc, x) => acc + x.toDouble()) / values.length;
    final sumSq = values.fold<double>(0.0, (acc, x) {
      final diff = x.toDouble() - mean;
      return acc + (diff * diff);
    });
    return math.sqrt(sumSq / values.length);
  }

  /// Validates a single capture window (open or fist).
  /// [windowSamples] is a list of 5-element flex readings across the 2 s capture window.
  Map<String, dynamic> evaluateCaptureWindow(List<List<int>> windowSamples) {
    if (windowSamples.isEmpty) {
      return {'is_stable': false, 'reason': 'No samples in capture window'};
    }

    final perFingerMedians = <double>[];
    final perFingerSds = <double>[];
    final unstableFingers = <String>[];

    for (var f = 0; f < 5; f++) {
      final chValues = windowSamples.map((s) => s[f]).toList();
      final med = median(chValues);
      final sd = standardDeviation(chValues);
      perFingerMedians.add(med);
      perFingerSds.add(sd);

      if (sd > maxStabilitySd) {
        unstableFingers.add('${fingerNames[f]} (SD: ${sd.toStringAsFixed(1)})');
      }
    }

    final isStable = unstableFingers.isEmpty;
    return {
      'is_stable': isStable,
      'medians': perFingerMedians,
      'sds': perFingerSds,
      'unstable_fingers': unstableFingers,
      'reason': isStable ? null : 'Signal unstable on: ${unstableFingers.join(', ')}',
    };
  }

  /// Combines open hand capture and fist capture into a full CalibrationRecord.
  CalibrationRecord buildRecord({
    required String id,
    String? patientId,
    String? deviceId,
    required List<double> openMedians,
    required List<double> openSds,
    required List<double> closedMedians,
    required List<double> closedSds,
  }) {
    final fingers = <FingerCalibration>[];
    var allValid = true;

    for (var f = 0; f < 5; f++) {
      final openVal = openMedians[f];
      final closedVal = closedMedians[f];
      final span = (closedVal - openVal).abs();
      final polarity = closedVal >= openVal ? 1 : -1;

      String? rejectReason;
      var isValid = true;

      if (span < minSpanThreshold) {
        isValid = false;
        rejectReason = 'Span $span < minimum threshold $minSpanThreshold';
      }

      if (!isValid) {
        allValid = false;
      }

      fingers.add(FingerCalibration(
        fingerIndex: f,
        name: fingerNames[f],
        openValue: openVal,
        closedValue: closedVal,
        span: span,
        polarity: polarity,
        isValid: isValid,
        rejectReason: rejectReason,
        openSd: openSds[f],
        closedSd: closedSds[f],
      ));
    }

    return CalibrationRecord(
      id: id,
      patientId: patientId,
      deviceId: deviceId,
      capturedAt: DateTime.now().toUtc(),
      minSpanThreshold: minSpanThreshold,
      fingers: fingers,
      status: allValid ? 'valid' : 'invalid',
    );
  }

  /// Checks for drift on session start:
  /// Compares a 1 s open hand reading with stored open.
  /// If deviation > 15% of span for any finger, recalibration is recommended.
  Map<String, dynamic> checkDrift({
    required CalibrationRecord record,
    required List<List<int>> oneSecOpenSamples,
  }) {
    if (oneSecOpenSamples.isEmpty) {
      return {'drift_detected': false, 'reason': 'No drift samples provided'};
    }

    final driftedFingers = <String>[];
    final deviations = <double>[];

    for (var f = 0; f < 5; f++) {
      final chValues = oneSecOpenSamples.map((s) => s[f]).toList();
      final currentOpenMed = median(chValues);
      final storedFinger = record.fingers[f];
      final delta = (currentOpenMed - storedFinger.openValue).abs();
      final allowedDrift = storedFinger.span * driftToleranceRatio;
      deviations.add(delta);

      if (delta > allowedDrift) {
        driftedFingers.add(
          '${fingerNames[f]} shifted by ${delta.toStringAsFixed(1)} (allowed: ${allowedDrift.toStringAsFixed(1)})',
        );
      }
    }

    final driftDetected = driftedFingers.isNotEmpty;
    return {
      'drift_detected': driftDetected,
      'drifted_fingers': driftedFingers,
      'deviations': deviations,
      'status': driftDetected ? 'recalibration_recommended' : 'pass',
      'message': driftDetected
          ? 'Recalibration recommended: ${driftedFingers.join('; ')}'
          : 'Calibration drift check passed',
    };
  }
}
