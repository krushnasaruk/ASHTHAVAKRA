import 'dart:math' as math;
import '../models/repetition.dart';

class ConsistencyResult {
  final double? totalScore; // 0.0 - 100.0 or null
  final double? romRatio;
  final double? timingScore;
  final double? smoothScore;
  final bool isAvailable;
  final String? missingReason;

  const ConsistencyResult({
    this.totalScore,
    this.romRatio,
    this.timingScore,
    this.smoothScore,
    required this.isAvailable,
    this.missingReason,
  });

  Map<String, dynamic> toJson() => {
    'total_score': totalScore,
    'rom_ratio': romRatio,
    'timing_score': timingScore,
    'smooth_score': smoothScore,
    'is_available': isAvailable,
    'missing_reason': missingReason,
    'disclaimer': 'experimental, requires physiotherapist review',
  };
}

class ConsistencyCalculator {
  /// Computes experimental consistency score across completed repetitions in a session.
  static ConsistencyResult compute({
    required List<Repetition> completedReps,
    required double targetPeak,
  }) {
    if (completedReps.isEmpty) {
      return const ConsistencyResult(
        isAvailable: false,
        missingReason: 'No completed repetitions in session',
      );
    }

    if (completedReps.length < 3) {
      return const ConsistencyResult(
        isAvailable: false,
        missingReason: 'Requires at least 3 completed repetitions for timing CV',
      );
    }

    // 1. ROM ratio
    final meanPeak = completedReps.map((r) => r.peak).reduce((a, b) => a + b) / completedReps.length;
    final romRatio = math.min(meanPeak / (targetPeak > 0 ? targetPeak : 70.0), 1.0);

    // 2. Timing CV
    final durations = completedReps.map((r) => r.durationS).toList();
    final meanDuration = durations.reduce((a, b) => a + b) / durations.length;
    if (meanDuration <= 0.0) {
      return const ConsistencyResult(
        isAvailable: false,
        missingReason: 'Invalid repetition durations',
      );
    }
    final varDuration = durations.map((d) => math.pow(d - meanDuration, 2)).reduce((a, b) => a + b) / durations.length;
    final sdDuration = math.sqrt(varDuration);
    final cv = sdDuration / meanDuration;
    final timingScore = 1.0 - math.min(cv, 1.0);

    // 3. Smoothness score
    final validSmoothnesses = completedReps.where((r) => r.smoothness != null).map((r) => r.smoothness!).toList();
    if (validSmoothnesses.isEmpty) {
      return ConsistencyResult(
        isAvailable: false,
        romRatio: romRatio,
        timingScore: timingScore,
        missingReason: 'Smoothness metrics unavailable for repetitions',
      );
    }
    final meanSmoothness = validSmoothnesses.reduce((a, b) => a + b) / validSmoothnesses.length;
    final smoothScore = math.min(math.max(0.0, meanSmoothness), 1.0);

    // Total Consistency Score
    final total = 100.0 * (0.4 * romRatio + 0.3 * timingScore + 0.3 * smoothScore);

    return ConsistencyResult(
      totalScore: total,
      romRatio: romRatio,
      timingScore: timingScore,
      smoothScore: smoothScore,
      isAvailable: true,
    );
  }
}
