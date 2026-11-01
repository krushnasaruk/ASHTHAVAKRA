import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('Metrics Tests', () {
    test('SmoothnessCalculator computes valid dimensionless jerk or reports null if < 10 samples', () {
      // Too few samples (< 10)
      final shortSamples = [10.0, 20.0, 30.0];
      final resShort = SmoothnessCalculator.computeDimensionlessJerk(
        signalSamples: shortSamples,
        durationS: 1.0,
        rom: 50.0,
      );
      expect(resShort, isNull);

      // Smooth sine wave of 50 samples
      final smoothSamples = List.generate(50, (i) => 80.0 * (i < 25 ? (i / 25.0) : (2.0 - i / 25.0)));
      final resSmooth = SmoothnessCalculator.computeDimensionlessJerk(
        signalSamples: smoothSamples,
        durationS: 2.0,
        rom: 80.0,
      );
      expect(resSmooth, isNotNull);
      expect(resSmooth!, inInclusiveRange(0.0, 1.0));
    });

    test('ConsistencyCalculator combines ROM ratio, timing CV, and smoothness', () {
      // 3 identical reps: peak 80, duration 2.0s, smoothness 0.8
      final reps = [
        const Repetition(
          id: '1', sessionId: 's', index: 0, startMs: 0, endMs: 2000,
          durationS: 2.0, peak: 80.0, mean: 40.0, min: 0.0, rom: 80.0, holdS: 0.5,
          smoothness: 0.8, quality: RepetitionQuality.good, status: RepetitionStatus.complete,
        ),
        const Repetition(
          id: '2', sessionId: 's', index: 1, startMs: 3000, endMs: 5000,
          durationS: 2.0, peak: 80.0, mean: 40.0, min: 0.0, rom: 80.0, holdS: 0.5,
          smoothness: 0.8, quality: RepetitionQuality.good, status: RepetitionStatus.complete,
        ),
        const Repetition(
          id: '3', sessionId: 's', index: 2, startMs: 6000, endMs: 8000,
          durationS: 2.0, peak: 80.0, mean: 40.0, min: 0.0, rom: 80.0, holdS: 0.5,
          smoothness: 0.8, quality: RepetitionQuality.good, status: RepetitionStatus.complete,
        ),
      ];

      final res = ConsistencyCalculator.compute(completedReps: reps, targetPeak: 80.0);
      expect(res.isAvailable, isTrue);
      expect(res.romRatio, equals(1.0)); // 80 / 80
      expect(res.timingScore, closeTo(1.0, 1e-5)); // CV is 0 -> 1 - 0 = 1.0
      expect(res.smoothScore, closeTo(0.8, 1e-5));
      // total = 100 * (0.4*1.0 + 0.3*1.0 + 0.3*0.8) = 100 * (0.4 + 0.3 + 0.24) = 94.0
      expect(res.totalScore, closeTo(94.0, 0.01));
    });

    test('ConsistencyCalculator reports unavailable if < 3 repetitions', () {
      final reps = [
        const Repetition(
          id: '1', sessionId: 's', index: 0, startMs: 0, endMs: 2000,
          durationS: 2.0, peak: 80.0, mean: 40.0, min: 0.0, rom: 80.0, holdS: 0.5,
          smoothness: 0.8, quality: RepetitionQuality.good, status: RepetitionStatus.complete,
        ),
      ];
      final res = ConsistencyCalculator.compute(completedReps: reps, targetPeak: 80.0);
      expect(res.isAvailable, isFalse);
      expect(res.missingReason, contains('at least 3 completed repetitions'));
    });

    test('FatigueCalculator requires >= 6 reps and detects > 20% drop', () {
      // 5 reps -> unavailable
      final fiveReps = List.generate(5, (i) => Repetition(
        id: '$i', sessionId: 's', index: i, startMs: i * 2000, endMs: (i + 1) * 2000,
        durationS: 2.0, peak: 80.0, mean: 40.0, min: 0.0, rom: 80.0, holdS: 0.5,
        status: RepetitionStatus.complete,
      ));
      final res5 = FatigueCalculator.compute(completedReps: fiveReps);
      expect(res5.isAvailable, isFalse);

      // 6 reps: first 3 peak 80, last 3 peak 60 (drop = (80-60)/80 = 25% > 20%)
      final sixRepsFatigue = [
        ...List.generate(3, (i) => Repetition(
          id: '$i', sessionId: 's', index: i, startMs: i * 2000, endMs: (i + 1) * 2000,
          durationS: 2.0, peak: 80.0, mean: 40.0, min: 0.0, rom: 80.0, holdS: 0.5,
          status: RepetitionStatus.complete,
        )),
        ...List.generate(3, (i) => Repetition(
          id: '${i + 3}', sessionId: 's', index: i + 3, startMs: (i + 3) * 2000, endMs: (i + 4) * 2000,
          durationS: 2.0, peak: 60.0, mean: 30.0, min: 0.0, rom: 60.0, holdS: 0.5,
          status: RepetitionStatus.complete,
        )),
      ];
      final resFatigue = FatigueCalculator.compute(completedReps: sixRepsFatigue, thresholdPct: 20.0);
      expect(resFatigue.isAvailable, isTrue);
      expect(resFatigue.isFatigueDetected, isTrue);
      expect(resFatigue.dropPct, closeTo(25.0, 0.1));
    });
  });
}
