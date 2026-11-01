import '../models/flag.dart';
import '../models/session.dart';
import '../models/plan.dart';
import '../models/calibration_record.dart';

class FlagGenerator {
  /// Evaluates measurements across patient history and generates rule-based clinical flags.
  static List<ClinicalFlag> evaluate({
    required String patientId,
    required RehabilitationPlan plan,
    required List<SessionRecord> sessions, // chronological
    CalibrationRecord? calibration,
  }) {
    final flags = <ClinicalFlag>[];
    final now = DateTime.now().toUtc();

    if (sessions.isEmpty) {
      return flags;
    }

    // 1. rom_below_plan: mean ROM below targetRomMin for 3 consecutive sessions
    if (sessions.length >= 3) {
      final lastThree = sessions.sublist(sessions.length - 3);
      final allBelow = lastThree.every((s) => s.meanRom < plan.targetRomMin);
      if (allBelow) {
        final meanVal = lastThree.map((s) => s.meanRom).reduce((a, b) => a + b) / 3.0;
        flags.add(ClinicalFlag(
          id: 'flag_${patientId}_rom_below_plan_${now.millisecondsSinceEpoch}',
          patientId: patientId,
          type: 'rom_below_plan',
          severity: 'review',
          createdAt: now,
          sessionIds: lastThree.map((s) => s.id).toList(),
          message: 'ROM below plan target band (${plan.targetRomMin.toStringAsFixed(0)}%) for 3 consecutive sessions (3-session mean: ${meanVal.toStringAsFixed(1)}%).',
          metricValues: {'3_session_mean_rom': meanVal},
          thresholdUsed: {'target_rom_min': plan.targetRomMin, 'consecutive_sessions': 3},
        ));
      }
    }

    // 2. in_session_fatigue: fatigue indicator triggered in >= 2 of last 3 sessions
    if (sessions.length >= 3) {
      final lastThree = sessions.sublist(sessions.length - 3);
      final fatigueCount = lastThree.where((s) => (s.fatigueDropPct ?? 0.0) >= plan.fatigueDropThreshold).length;
      if (fatigueCount >= 2) {
        flags.add(ClinicalFlag(
          id: 'flag_${patientId}_in_session_fatigue_${now.millisecondsSinceEpoch}',
          patientId: patientId,
          type: 'in_session_fatigue',
          severity: 'review',
          createdAt: now,
          sessionIds: lastThree.map((s) => s.id).toList(),
          message: 'Fatigue drop threshold (>= ${plan.fatigueDropThreshold.toStringAsFixed(0)}%) triggered in $fatigueCount of the last 3 sessions.',
          metricValues: {'fatigue_sessions_count': fatigueCount},
          thresholdUsed: {'fatigue_drop_threshold': plan.fatigueDropThreshold},
        ));
      }
    }

    // 3. pain_increase: pain rose by >= 3 points in latest session
    final latestSession = sessions.last;
    if (latestSession.painBefore != null) {
      final painDelta = latestSession.painAfter - latestSession.painBefore!;
      if (painDelta >= 3) {
        flags.add(ClinicalFlag(
          id: 'flag_${patientId}_pain_increase_${latestSession.id}',
          patientId: patientId,
          type: 'pain_increase',
          severity: 'review',
          createdAt: now,
          sessionIds: [latestSession.id],
          message: 'Reported pain rose by $painDelta points during session (before: ${latestSession.painBefore}, after: ${latestSession.painAfter}).',
          metricValues: {'pain_before': latestSession.painBefore, 'pain_after': latestSession.painAfter, 'delta': painDelta},
          thresholdUsed: {'min_pain_increase': 3},
        ));
      }
    }

    // 4. adherence_low: fewer than 50% of prescribed sessions in the last 7 days
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentWeekSessions = sessions.where((s) => s.startedAt.isAfter(sevenDaysAgo)).length;
    final prescribedWeek = plan.sessionsPerWeek;
    if (prescribedWeek > 0 && (recentWeekSessions / prescribedWeek) < 0.5) {
      final pct = (recentWeekSessions / prescribedWeek) * 100.0;
      flags.add(ClinicalFlag(
        id: 'flag_${patientId}_adherence_low_${now.millisecondsSinceEpoch}',
        patientId: patientId,
        type: 'adherence_low',
        severity: 'info',
        createdAt: now,
        sessionIds: [],
        message: 'Adherence low: completed $recentWeekSessions of $prescribedWeek prescribed sessions (${pct.toStringAsFixed(0)}% < 50%).',
        metricValues: {'completed': recentWeekSessions, 'prescribed': prescribedWeek, 'adherence_pct': pct},
        thresholdUsed: {'min_adherence_pct': 50.0},
      ));
    }

    // 5. sudden_inconsistency: consistency drops by > 20 points against 3-session average
    if (sessions.length >= 4) {
      final prevThree = sessions.sublist(sessions.length - 4, sessions.length - 1);
      final prevConsistencies = prevThree.where((s) => s.consistency != null).map((s) => s.consistency!).toList();
      if (prevConsistencies.length == 3 && latestSession.consistency != null) {
        final prevMean = prevConsistencies.reduce((a, b) => a + b) / 3.0;
        final drop = prevMean - latestSession.consistency!;
        if (drop > 20.0) {
          flags.add(ClinicalFlag(
            id: 'flag_${patientId}_sudden_inconsistency_${latestSession.id}',
            patientId: patientId,
            type: 'sudden_inconsistency',
            severity: 'review',
            createdAt: now,
            sessionIds: [latestSession.id],
            message: 'Consistency dropped suddenly by ${drop.toStringAsFixed(1)} points vs 3-session average (previous: ${prevMean.toStringAsFixed(1)}, latest: ${latestSession.consistency!.toStringAsFixed(1)}).',
            metricValues: {'prev_3_mean': prevMean, 'latest_consistency': latestSession.consistency, 'drop': drop},
            thresholdUsed: {'max_allowed_drop': 20.0},
          ));
        }
      }
    }

    // 6. data_quality_low: > 30% of last 10 sessions have reduced or invalid quality
    final recentWindow = sessions.length > 10 ? sessions.sublist(sessions.length - 10) : sessions;
    final lowQualityCount = recentWindow.where((s) => s.dataQuality != 'good').length;
    final lowQualityPct = (lowQualityCount / recentWindow.length) * 100.0;
    if (lowQualityPct > 30.0) {
      flags.add(ClinicalFlag(
        id: 'flag_${patientId}_data_quality_low_${now.millisecondsSinceEpoch}',
        patientId: patientId,
        type: 'data_quality_low',
        severity: 'info',
        createdAt: now,
        sessionIds: recentWindow.map((s) => s.id).toList(),
        message: 'Data quality reduced in ${lowQualityPct.toStringAsFixed(0)}% of recent sessions ($lowQualityCount of ${recentWindow.length}).',
        metricValues: {'low_quality_pct': lowQualityPct},
        thresholdUsed: {'threshold_pct': 30.0},
      ));
    }

    return flags;
  }
}
