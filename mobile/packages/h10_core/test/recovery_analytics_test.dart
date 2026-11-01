import 'package:test/test.dart';
import 'package:h10_core/h10_core.dart';

void main() {
  group('Recovery Analytics & Clinical Flags Tests', () {
    test('PatientBaseline calculates median of first 3 valid real sessions', () {
      final now = DateTime.now().toUtc();
      final sessions = [
        SessionRecord(
          id: 's1', patientId: 'P-001', exerciseCode: 'fist_clench', planVersion: 1,
          startedAt: now.subtract(const Duration(days: 3)), endedAt: now.subtract(const Duration(days: 3)),
          durationS: 60, repsCompleted: 10, repsTarget: 10, meanRom: 50.0, maxRom: 60.0,
          meanRepDurationS: 2.0, holdS: 0.5, painAfter: 2, fatigueAfter: 3,
          dataQuality: 'good', dataSource: 'real', deviceId: 'dev1', firmware: '1.0',
          calibrationRef: 'cal1', clientVersion: '1.0', createdAt: now,
        ),
        SessionRecord(
          id: 's2', patientId: 'P-001', exerciseCode: 'fist_clench', planVersion: 1,
          startedAt: now.subtract(const Duration(days: 2)), endedAt: now.subtract(const Duration(days: 2)),
          durationS: 60, repsCompleted: 10, repsTarget: 10, meanRom: 60.0, maxRom: 70.0,
          meanRepDurationS: 2.2, holdS: 0.5, painAfter: 2, fatigueAfter: 3,
          dataQuality: 'good', dataSource: 'real', deviceId: 'dev1', firmware: '1.0',
          calibrationRef: 'cal1', clientVersion: '1.0', createdAt: now,
        ),
        SessionRecord(
          id: 's3', patientId: 'P-001', exerciseCode: 'fist_clench', planVersion: 1,
          startedAt: now.subtract(const Duration(days: 1)), endedAt: now.subtract(const Duration(days: 1)),
          durationS: 60, repsCompleted: 10, repsTarget: 10, meanRom: 55.0, maxRom: 65.0,
          meanRepDurationS: 2.1, holdS: 0.5, painAfter: 2, fatigueAfter: 3,
          dataQuality: 'good', dataSource: 'real', deviceId: 'dev1', firmware: '1.0',
          calibrationRef: 'cal1', clientVersion: '1.0', createdAt: now,
        ),
      ];

      final baseline = PatientBaseline.compute(
        patientId: 'P-001',
        exerciseCode: 'fist_clench',
        allSessions: sessions,
      );

      expect(baseline, isNotNull);
      // median of [50, 60, 55] is 55.0
      expect(baseline!.meanRom, equals(55.0));
      // median of [60, 70, 65] is 65.0
      expect(baseline.maxRom, equals(65.0));
      expect(baseline.sessionCount, equals(3));
    });

    test('TrendClassifier detects improving and stable trends', () {
      // 4 sessions improving: 50 -> 55 -> 60 -> 65 (+15 over baseline 50 = +30% > 10%)
      final improvingTrend = TrendClassifier.classify(
        metricName: 'mean_rom',
        baselineValue: 50.0,
        recentValues: [50.0, 55.0, 60.0, 65.0],
      );
      expect(improvingTrend.direction, equals(TrendDirection.improving));

      // 4 sessions within ±5% of 50.0: [50.5, 49.8, 51.0, 50.2]
      final stableTrend = TrendClassifier.classify(
        metricName: 'mean_rom',
        baselineValue: 50.0,
        recentValues: [50.5, 49.8, 51.0, 50.2],
      );
      expect(stableTrend.direction, equals(TrendDirection.stable));
    });

    test('TrendClassifier detects plateau', () {
      // 6 sessions with range < 5% of baseline 60.0 (range = 1.0 < 3.0), target is 80
      final plateau = TrendClassifier.checkPlateau(
        baselineRom: 60.0,
        targetRom: 80.0,
        recentRoms: [62.0, 62.5, 62.1, 62.8, 62.2, 62.9],
      );
      expect(plateau['is_plateau'], isTrue);
    });

    test('FlagGenerator generates rom_below_plan and pain_increase flags', () {
      final now = DateTime.now().toUtc();
      final plan = RehabilitationPlan(
        id: 'plan_1',
        patientId: 'P-001',
        exerciseId: 'fist_clench',
        targetReps: 10,
        targetRomMin: 70.0,
        validFrom: now.subtract(const Duration(days: 30)),
        setBy: 'Clinician A',
      );

      // 3 sessions with meanRom 55 < 70, latest has pain rose by 4 (before 2, after 6)
      final sessions = [
        SessionRecord(
          id: 's1', patientId: 'P-001', exerciseCode: 'fist_clench', planVersion: 1,
          startedAt: now.subtract(const Duration(days: 3)), endedAt: now.subtract(const Duration(days: 3)),
          durationS: 60, repsCompleted: 10, repsTarget: 10, meanRom: 55.0, maxRom: 60.0,
          meanRepDurationS: 2.0, holdS: 0.5, painAfter: 2, fatigueAfter: 3,
          dataQuality: 'good', dataSource: 'real', deviceId: 'dev1', firmware: '1.0',
          calibrationRef: 'cal1', clientVersion: '1.0', createdAt: now,
        ),
        SessionRecord(
          id: 's2', patientId: 'P-001', exerciseCode: 'fist_clench', planVersion: 1,
          startedAt: now.subtract(const Duration(days: 2)), endedAt: now.subtract(const Duration(days: 2)),
          durationS: 60, repsCompleted: 10, repsTarget: 10, meanRom: 54.0, maxRom: 60.0,
          meanRepDurationS: 2.0, holdS: 0.5, painAfter: 2, fatigueAfter: 3,
          dataQuality: 'good', dataSource: 'real', deviceId: 'dev1', firmware: '1.0',
          calibrationRef: 'cal1', clientVersion: '1.0', createdAt: now,
        ),
        SessionRecord(
          id: 's3', patientId: 'P-001', exerciseCode: 'fist_clench', planVersion: 1,
          startedAt: now.subtract(const Duration(days: 1)), endedAt: now.subtract(const Duration(days: 1)),
          durationS: 60, repsCompleted: 10, repsTarget: 10, meanRom: 53.0, maxRom: 60.0,
          meanRepDurationS: 2.0, holdS: 0.5, painBefore: 2, painAfter: 6, fatigueAfter: 3,
          dataQuality: 'good', dataSource: 'real', deviceId: 'dev1', firmware: '1.0',
          calibrationRef: 'cal1', clientVersion: '1.0', createdAt: now,
        ),
      ];

      final flags = FlagGenerator.evaluate(
        patientId: 'P-001',
        plan: plan,
        sessions: sessions,
      );

      expect(flags.any((f) => f.type == 'rom_below_plan'), isTrue);
      expect(flags.any((f) => f.type == 'pain_increase'), isTrue);
    });
  });
}
