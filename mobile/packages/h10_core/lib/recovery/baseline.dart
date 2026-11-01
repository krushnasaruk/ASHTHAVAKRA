import '../models/session.dart';

class PatientBaseline {
  final String patientId;
  final String exerciseCode;
  final double meanRom;
  final double maxRom;
  final double? consistency;
  final double meanDurationS;
  final double? smoothness;
  final int sessionCount;
  final DateTime establishedAt;

  const PatientBaseline({
    required this.patientId,
    required this.exerciseCode,
    required this.meanRom,
    required this.maxRom,
    this.consistency,
    required this.meanDurationS,
    this.smoothness,
    required this.sessionCount,
    required this.establishedAt,
  });

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'exercise_code': exerciseCode,
    'mean_rom': meanRom,
    'max_rom': maxRom,
    'consistency': consistency,
    'mean_duration_s': meanDurationS,
    'smoothness': smoothness,
    'session_count': sessionCount,
    'established_at': establishedAt.toIso8601String(),
  };

  static double _median(List<double> list) {
    if (list.isEmpty) return 0.0;
    final sorted = List<double>.from(list)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  /// Calculates baseline from initial valid non-simulated sessions.
  static PatientBaseline? compute({
    required String patientId,
    required String exerciseCode,
    required List<SessionRecord> allSessions,
  }) {
    // Filter to valid, non-simulated sessions for this exercise
    final validSessions = allSessions.where((s) =>
        s.patientId == patientId &&
        s.exerciseCode == exerciseCode &&
        s.dataQuality == 'good' &&
        s.dataSource == 'real'
    ).toList();

    // Sort chronologically
    validSessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    if (validSessions.isEmpty) return null;

    // Take up to first 3 sessions
    final baselineSessions = validSessions.take(3).toList();
    final meanRoms = baselineSessions.map((s) => s.meanRom).toList();
    final maxRoms = baselineSessions.map((s) => s.maxRom).toList();
    final durations = baselineSessions.map((s) => s.meanRepDurationS).toList();
    
    final consistencies = baselineSessions.where((s) => s.consistency != null).map((s) => s.consistency!).toList();
    final smoothnesses = baselineSessions.where((s) => s.smoothness != null).map((s) => s.smoothness!).toList();

    return PatientBaseline(
      patientId: patientId,
      exerciseCode: exerciseCode,
      meanRom: _median(meanRoms),
      maxRom: _median(maxRoms),
      consistency: consistencies.isNotEmpty ? _median(consistencies) : null,
      meanDurationS: _median(durations),
      smoothness: smoothnesses.isNotEmpty ? _median(smoothnesses) : null,
      sessionCount: baselineSessions.length,
      establishedAt: baselineSessions.last.endedAt,
    );
  }
}

