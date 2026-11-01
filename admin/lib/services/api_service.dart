import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:h10_core/h10_core.dart';

class ApiService extends ChangeNotifier {
  String baseUrl = 'http://127.0.0.1:8000';
  bool isConnected = false;
  String? lastError;

  // Local fallback data (mirroring backend seed data)
  final List<Patient> _patients = [
    Patient(
      id: 'p_014',
      pseudonym: 'P-014',
      affectedHand: 'right',
      notes: 'Post-stroke motor recovery: restoring independent grasp and release',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      dataSource: 'simulated',
    ),
    Patient(
      id: 'p_007',
      pseudonym: 'P-007',
      affectedHand: 'left',
      notes: 'Spasticity management and extension range maintenance',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      dataSource: 'simulated',
    ),
    Patient(
      id: 'p_022',
      pseudonym: 'P-022',
      affectedHand: 'right',
      notes: 'Tendon glide rehabilitation following distal radius repair',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      dataSource: 'simulated',
    ),
    Patient(
      id: 'p_031',
      pseudonym: 'P-031',
      affectedHand: 'bilateral',
      notes: 'Parkinsonian fine-motor dexterity training and tapping rhythm maintenance',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      dataSource: 'simulated',
    ),
  ];

  final Map<String, List<RehabilitationPlan>> _plans = {
    'P-014': [
      RehabilitationPlan(
        id: 'plan_014_v2',
        patientId: 'P-014',
        exerciseId: 'fist_clench',
        version: 2,
        targetReps: 12,
        targetRomMin: 70.0,
        targetRomMax: 100.0,
        holdS: 0.5,
        restS: 2.0,
        sessionsPerWeek: 5,
        stopInstruction: 'Stop immediately if sharp wrist pain occurs.',
        fatigueDropThreshold: 20.0,
        validFrom: DateTime.now().subtract(const Duration(days: 7)),
        setBy: 'Dr. Sarah Adams',
      ),
      RehabilitationPlan(
        id: 'plan_014_v1',
        patientId: 'P-014',
        exerciseId: 'fist_clench',
        version: 1,
        targetReps: 10,
        targetRomMin: 65.0,
        targetRomMax: 95.0,
        holdS: 0.5,
        restS: 2.5,
        sessionsPerWeek: 5,
        stopInstruction: 'Stop if pain exceeds 4/10.',
        fatigueDropThreshold: 20.0,
        validFrom: DateTime.now().subtract(const Duration(days: 30)),
        setBy: 'Dr. Sarah Adams',
      ),
    ],
  };

  final Map<String, List<SessionRecord>> _sessions = {
    'P-014': [
      SessionRecord(
        id: 'sess_p14_01',
        patientId: 'P-014',
        exerciseCode: 'fist_clench',
        planVersion: 2,
        startedAt: DateTime.now().subtract(const Duration(hours: 4)),
        endedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 54)),
        durationS: 360,
        repsCompleted: 12,
        repsTarget: 12,
        meanRom: 78.4,
        maxRom: 84.1,
        meanRepDurationS: 2.1,
        holdS: 0.5,
        consistency: 86.0,
        consistencyComponents: {'rom_ratio': 0.88, 'timing_score': 0.85, 'smooth_score': 0.86},
        fatigueDropPct: 8.5,
        painAfter: 2,
        fatigueAfter: 3,
        note: 'Smooth controlled movement throughout. Patient reported slight forearm fatigue.',
        dataQuality: 'good',
        dataSource: 'simulated',
        deviceId: 'H10-SIM-01',
        firmware: '1.0.0',
        calibrationRef: 'cal_p14_01',
        clientVersion: '1.0.0',
        createdAt: DateTime.now(),
      ),
      SessionRecord(
        id: 'sess_p14_02',
        patientId: 'P-014',
        exerciseCode: 'fist_clench',
        planVersion: 2,
        startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 55)),
        durationS: 300,
        repsCompleted: 10,
        repsTarget: 12,
        meanRom: 73.2,
        maxRom: 79.0,
        meanRepDurationS: 2.3,
        holdS: 0.5,
        consistency: 79.0,
        consistencyComponents: {'rom_ratio': 0.80, 'timing_score': 0.78, 'smooth_score': 0.80},
        fatigueDropPct: 15.2,
        painAfter: 3,
        fatigueAfter: 4,
        note: 'Slight decline towards last 3 repetitions.',
        dataQuality: 'good',
        dataSource: 'simulated',
        deviceId: 'H10-SIM-01',
        firmware: '1.0.0',
        calibrationRef: 'cal_p14_01',
        clientVersion: '1.0.0',
        createdAt: DateTime.now(),
      ),
      SessionRecord(
        id: 'sess_p14_03',
        patientId: 'P-014',
        exerciseCode: 'fist_clench',
        planVersion: 2,
        startedAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
        endedAt: DateTime.now().subtract(const Duration(days: 2, hours: 4, minutes: 53)),
        durationS: 420,
        repsCompleted: 8,
        repsTarget: 12,
        meanRom: 64.1,
        maxRom: 71.0,
        meanRepDurationS: 2.6,
        holdS: 0.5,
        consistency: 68.0,
        consistencyComponents: {'rom_ratio': 0.70, 'timing_score': 0.65, 'smooth_score': 0.70},
        fatigueDropPct: 24.8,
        painAfter: 5,
        fatigueAfter: 6,
        note: 'High fatigue reported; completed 8 reps then paused.',
        dataQuality: 'good',
        dataSource: 'simulated',
        deviceId: 'H10-SIM-01',
        firmware: '1.0.0',
        calibrationRef: 'cal_p14_01',
        clientVersion: '1.0.0',
        createdAt: DateTime.now(),
      ),
    ],
  };

  final List<ClinicalFlag> _flags = [
    ClinicalFlag(
      id: 'flag_01',
      patientId: 'P-014',
      type: 'fatigue_drop_high',
      severity: 'review',
      message: 'Fatigue index dropped 24.8% (exceeded 20.0% threshold) during 8-rep session.',
      metricValues: {'drop_pct': 24.8, 'threshold': 20.0},
      thresholdUsed: {'fatigue_drop_threshold': 20.0},
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    ClinicalFlag(
      id: 'flag_02',
      patientId: 'P-014',
      type: 'pain_increase',
      severity: 'review',
      message: 'Reported pain reached 5/10 (exceeded comfort threshold of 4/10).',
      metricValues: {'pain': 5, 'threshold': 4},
      thresholdUsed: {'pain_max': 4},
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    ClinicalFlag(
      id: 'flag_03',
      patientId: 'P-007',
      type: 'repetition_incomplete_repeated',
      severity: 'review',
      message: '3 consecutive sessions with under 50% target repetitions completed.',
      metricValues: {'consecutive_count': 3},
      thresholdUsed: {'target_completion_pct': 50.0},
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<Map<String, dynamic>> _auditLog = [];

  List<Patient> get patients => _patients;
  List<ClinicalFlag> get flags => _flags;
  List<Map<String, dynamic>> get auditLog => _auditLog;

  ApiService() {
    checkHealth();
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(milliseconds: 1500));
      isConnected = (res.statusCode == 200);
      lastError = null;
    } catch (e) {
      isConnected = false;
      lastError = e.toString();
    }
    notifyListeners();
    return isConnected;
  }

  List<SessionRecord> getPatientSessions(String patientId) {
    return _sessions[patientId] ?? [];
  }

  RehabilitationPlan? getPatientActivePlan(String patientId) {
    final list = _plans[patientId];
    if (list != null && list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  List<RehabilitationPlan> getPatientPlanHistory(String patientId) {
    return _plans[patientId] ?? [];
  }

  Future<void> updatePlan({
    required String patientId,
    required String exerciseId,
    required int targetReps,
    required double targetRomMin,
    required double targetRomMax,
    required double holdS,
    required double restS,
    required int sessionsPerWeek,
    required String stopInstruction,
    required double fatigueDropThreshold,
    required String clinicianReason,
    String clinicianId = 'clin_sarah_adams',
  }) async {
    final currentList = _plans.putIfAbsent(patientId, () => []);
    final nextVersion = currentList.isNotEmpty ? currentList.first.version + 1 : 1;

    final newPlan = RehabilitationPlan(
      id: 'plan_${patientId}_v$nextVersion',
      patientId: patientId,
      exerciseId: exerciseId,
      version: nextVersion,
      targetReps: targetReps,
      targetRomMin: targetRomMin,
      targetRomMax: targetRomMax,
      holdS: holdS,
      restS: restS,
      sessionsPerWeek: sessionsPerWeek,
      stopInstruction: stopInstruction,
      fatigueDropThreshold: fatigueDropThreshold,
      validFrom: DateTime.now(),
      setBy: clinicianId,
    );

    currentList.insert(0, newPlan);

    _auditLog.insert(0, {
      'action': 'plan_updated',
      'patient_id': patientId,
      'plan_id': newPlan.id,
      'version': nextVersion,
      'clinician_id': clinicianId,
      'reason': clinicianReason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }

  Future<void> acknowledgeFlag({
    required String flagId,
    required String note,
    String clinicianId = 'clin_sarah_adams',
  }) async {
    final idx = _flags.indexWhere((f) => f.id == flagId);
    if (idx != -1) {
      final old = _flags[idx];
      _flags[idx] = ClinicalFlag(
        id: old.id,
        patientId: old.patientId,
        type: old.type,
        severity: old.severity,
        message: old.message,
        metricValues: old.metricValues,
        thresholdUsed: old.thresholdUsed,
        sessionIds: old.sessionIds,
        createdAt: old.createdAt,
        acknowledgedBy: clinicianId,
        acknowledgedAt: DateTime.now(),
        ackNote: note,
      );

      _auditLog.insert(0, {
        'action': 'flag_acknowledged',
        'flag_id': flagId,
        'patient_id': old.patientId,
        'rule': old.type,
        'clinician_id': clinicianId,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    }
  }

  String exportCsv(String patientId) {
    final sessions = getPatientSessions(patientId);
    final buf = StringBuffer();
    buf.writeln('session_id,patient_id,exercise,started_at,duration_s,reps_completed,reps_target,mean_rom,max_rom,consistency,fatigue_drop_pct,pain_after,fatigue_after,data_quality,data_source');
    for (final s in sessions) {
      buf.writeln('${s.id},${s.patientId},${s.exerciseCode},${s.startedAt.toIso8601String()},${s.durationS},${s.repsCompleted},${s.repsTarget},${s.meanRom.toStringAsFixed(1)},${s.maxRom.toStringAsFixed(1)},${s.consistency?.toStringAsFixed(1) ?? "N/A"},${s.fatigueDropPct?.toStringAsFixed(1) ?? "N/A"},${s.painAfter},${s.fatigueAfter},${s.dataQuality},${s.dataSource}');
    }
    return buf.toString();
  }
}
