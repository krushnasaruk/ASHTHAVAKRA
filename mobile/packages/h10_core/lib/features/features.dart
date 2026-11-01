import 'dart:math' as math;

/// Exact Dart implementation of the feat-v1 feature extraction engine.
/// Matches Python reference in ml/features.py with parity < 1e-6.
class FeatureExtractor {
  static const int windowSamples = 75;
  static const int strideSamples = 25;
  static const int featureCount = 84;

  static const List<String> channelNames = [
    'flex_thumb',
    'flex_index',
    'flex_middle',
    'flex_ring',
    'flex_pinky',
    'accel_mag',
    'gyro_mag',
  ];

  /// Counts peaks matching Python reference prominence formula.
  static double countPeaks(List<double> x, {double prominenceRatio = 0.05}) {
    final n = x.length;
    if (n < 3) return 0.0;

    var minVal = x[0];
    var maxVal = x[0];
    for (var i = 1; i < n; i++) {
      if (x[i] < minVal) minVal = x[i];
      if (x[i] > maxVal) maxVal = x[i];
    }
    final valRange = maxVal - minVal;
    final prominenceThresh = math.max(1.0, valRange * prominenceRatio);

    var count = 0;
    for (var i = 1; i < n - 1; i++) {
      if (x[i] > x[i - 1] && x[i] >= x[i + 1]) {
        final prom = x[i] - math.min(x[i - 1], x[i + 1]);
        if (prom >= prominenceThresh) {
          count++;
        }
      }
    }
    return count.toDouble();
  }

  /// Extracts 12 deterministic metrics for a single channel.
  static List<double> extractChannelFeatures(List<double> x) {
    final n = x.length;
    if (n == 0) return List<double>.filled(12, 0.0);

    var sum = 0.0;
    var sumSq = 0.0;
    var minVal = x[0];
    var maxVal = x[0];

    for (var i = 0; i < n; i++) {
      final v = x[i];
      sum += v;
      sumSq += v * v;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    final meanVal = sum / n;
    final energyVal = sumSq / n;
    final rmsVal = math.sqrt(energyVal);
    final rangeVal = maxVal - minVal;

    // Population std (ddof=0)
    var sqDiffSum = 0.0;
    for (var i = 0; i < n; i++) {
      final diff = x[i] - meanVal;
      sqDiffSum += diff * diff;
    }
    final stdVal = math.sqrt(sqDiffSum / n);

    // Median
    final sorted = List<double>.from(x)..sort();
    final mid = n ~/ 2;
    final double medianVal;
    if (n % 2 == 1) {
      medianVal = sorted[mid];
    } else {
      medianVal = (sorted[mid - 1] + sorted[mid]) / 2.0;
    }

    // Differences and slope
    double meanDiffVal = 0.0;
    double meanAbsDiffVal = 0.0;
    double slopeVal = 0.0;

    if (n > 1) {
      var diffSum = 0.0;
      var absDiffSum = 0.0;
      for (var i = 0; i < n - 1; i++) {
        final d = x[i + 1] - x[i];
        diffSum += d;
        absDiffSum += d.abs();
      }
      meanDiffVal = diffSum / (n - 1);
      meanAbsDiffVal = absDiffSum / (n - 1);

      // Linear regression slope
      final tBar = (n - 1.0) / 2.0;
      var varT = 0.0;
      var covTX = 0.0;
      for (var i = 0; i < n; i++) {
        final tDiff = i.toDouble() - tBar;
        varT += tDiff * tDiff;
        covTX += tDiff * (x[i] - meanVal);
      }
      slopeVal = covTX / varT;
    }

    final peakCountVal = countPeaks(x);

    return [
      meanVal,
      stdVal,
      minVal,
      maxVal,
      rangeVal,
      medianVal,
      rmsVal,
      meanDiffVal,
      meanAbsDiffVal,
      slopeVal,
      peakCountVal,
      energyVal,
    ];
  }

  /// Extracts 84 features from a window of samples.
  /// Each sample has 'flex' (5 values) and 'imu' (6 values).
  static List<double> extractWindowFeatures(List<Map<String, dynamic>> windowSamples) {
    final n = windowSamples.length;
    if (n == 0) return List<double>.filled(featureCount, 0.0);

    final chData = List.generate(7, (_) => <double>[]);

    for (var s = 0; s < n; s++) {
      final sample = windowSamples[s];
      final flex = (sample['flex'] as List).map((v) => (v as num).toDouble()).toList();
      for (var f = 0; f < 5; f++) {
        chData[f].add(flex[f]);
      }

      final imu = (sample['imu'] as List).map((v) => (v as num).toDouble()).toList();
      final ax = imu[0];
      final ay = imu[1];
      final az = imu[2];
      final gx = imu[3];
      final gy = imu[4];
      final gz = imu[5];

      final accelMag = math.sqrt(ax * ax + ay * ay + az * az);
      final gyroMag = math.sqrt(gx * gx + gy * gy + gz * gz);

      chData[5].add(accelMag);
      chData[6].add(gyroMag);
    }

    final features = <double>[];
    for (var ch = 0; ch < 7; ch++) {
      final chFeats = extractChannelFeatures(chData[ch]);
      features.addAll(chFeats);
    }

    return features;
  }
}

