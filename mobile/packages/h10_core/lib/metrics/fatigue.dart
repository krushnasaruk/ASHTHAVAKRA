import '../models/repetition.dart';

class FatigueResult {
  final bool isAvailable;
  final bool isFatigueDetected;
  final double? dropPct;
  final double? firstThreeMeanPeak;
  final double? lastThreeMeanPeak;
  final String? message;

  const FatigueResult({
    required this.isAvailable,
    required this.isFatigueDetected,
    this.dropPct,
    this.firstThreeMeanPeak,
    this.lastThreeMeanPeak,
    this.message,
  });
}

class FatigueCalculator {
  /// Evaluates in-session fatigue based on drop between first 3 and last 3 reps.
  /// Requires at least 6 completed repetitions.
  static FatigueResult compute({
    required List<Repetition> completedReps,
    double thresholdPct = 20.0,
  }) {
    if (completedReps.length < 6) {
      return const FatigueResult(
        isAvailable: false,
        isFatigueDetected: false,
        message: 'Requires at least 6 repetitions to evaluate fatigue trend',
      );
    }

    final firstThree = completedReps.sublist(0, 3);
    final lastThree = completedReps.sublist(completedReps.length - 3);

    final firstMean = firstThree.map((r) => r.peak).reduce((a, b) => a + b) / 3.0;
    final lastMean = lastThree.map((r) => r.peak).reduce((a, b) => a + b) / 3.0;

    if (firstMean <= 0.0) {
      return const FatigueResult(
        isAvailable: false,
        isFatigueDetected: false,
        message: 'First three repetitions had zero peak',
      );
    }

    final dropPct = ((firstMean - lastMean) / firstMean) * 100.0;
    final isDetected = dropPct >= thresholdPct;

    return FatigueResult(
      isAvailable: true,
      isFatigueDetected: isDetected,
      dropPct: dropPct,
      firstThreeMeanPeak: firstMean,
      lastThreeMeanPeak: lastMean,
      message: isDetected
          ? 'Range is dropping (${dropPct.toStringAsFixed(1)}% drop vs initial reps)'
          : 'Normal endurance maintained',
    );
  }
}
