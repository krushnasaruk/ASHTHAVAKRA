import 'dart:math' as math;

/// Computes duration-normalized dimensionless jerk on repetition trajectories.
class SmoothnessCalculator {
  /// Computes dimensionless jerk on raw repetition samples.
  /// Reports null if fewer than 10 samples are in the repetition.
  static double? computeDimensionlessJerk({
    required List<double> signalSamples,
    required double durationS,
    required double rom,
    int resampleGridSize = 100,
  }) {
    final n = signalSamples.length;
    if (n < 10 || durationS <= 0.0 || rom <= 1.0) {
      return null;
    }

    // 1. Resample to fixed grid of 100 points via linear interpolation
    final grid = List<double>.filled(resampleGridSize, 0.0);
    for (var i = 0; i < resampleGridSize; i++) {
      final tNorm = i / (resampleGridSize - 1.0); // 0.0 .. 1.0
      final origIdx = tNorm * (n - 1.0);
      final lowIdx = origIdx.floor();
      final highIdx = origIdx.ceil();
      final frac = origIdx - lowIdx;
      if (lowIdx == highIdx) {
        grid[i] = signalSamples[lowIdx];
      } else {
        grid[i] = (1.0 - frac) * signalSamples[lowIdx] + frac * signalSamples[highIdx];
      }
    }

    // 2. Numerical derivatives on the resampled grid
    final dt = durationS / (resampleGridSize - 1.0);
    if (dt <= 0.0) return null;

    // Velocity (first difference)
    final v = List<double>.filled(resampleGridSize - 1, 0.0);
    for (var i = 0; i < v.length; i++) {
      v[i] = (grid[i + 1] - grid[i]) / dt;
    }

    // Acceleration (second difference)
    final a = List<double>.filled(v.length - 1, 0.0);
    for (var i = 0; i < a.length; i++) {
      a[i] = (v[i + 1] - v[i]) / dt;
    }

    // Jerk (third difference)
    final j = List<double>.filled(a.length - 1, 0.0);
    var jerkSqSum = 0.0;
    for (var i = 0; i < j.length; i++) {
      j[i] = (a[i + 1] - a[i]) / dt;
      jerkSqSum += j[i] * j[i] * dt;
    }

    // Dimensionless jerk normalization: sqrt(0.5 * int(j^2 dt) * (T^5 / ROM^2))
    final t5 = math.pow(durationS, 5).toDouble();
    final romSq = rom * rom;
    final dimlessJerk = math.sqrt(0.5 * jerkSqSum * (t5 / romSq));

    // Clamp or return standard normalized index (typically 0.0 to 1.0)
    final normalized = 1.0 / (1.0 + (dimlessJerk / 1000.0));
    return normalized;
  }
}

