import '../models/calibration_record.dart';

/// Pure normalization functions mapping raw ADC counts to personal flexion percentage (0-100%).
class Normalizer {
  /// Normalizes a single raw ADC value for a specific finger.
  static double normalizeFinger({
    required double raw,
    required FingerCalibration calibration,
  }) {
    final denominator = calibration.closedValue - calibration.openValue;
    if (denominator.abs() < 1e-5) {
      return 0.0; // Prevent divide by zero defensively
    }
    final rawRatio = (raw - calibration.openValue) / denominator;
    final pct = rawRatio * 100.0;
    if (pct < 0.0) return 0.0;
    if (pct > 100.0) return 100.0;
    return pct;
  }

  /// Normalizes all 5 flex sensor readings.
  static List<double> normalizeAll({
    required List<int> rawFlex,
    required CalibrationRecord calibration,
  }) {
    if (rawFlex.length != 5 || calibration.fingers.length != 5) {
      throw ArgumentError('Expected 5 channels for normalization');
    }
    final result = <double>[];
    for (var i = 0; i < 5; i++) {
      final pct = normalizeFinger(
        raw: rawFlex[i].toDouble(),
        calibration: calibration.fingers[i],
      );
      result.add(pct);
    }
    return result;
  }
}

