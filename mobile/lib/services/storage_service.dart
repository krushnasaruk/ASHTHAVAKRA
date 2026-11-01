import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:h10_core/h10_core.dart';

/// Offline-first local storage service managing sessions, repetitions, plans, and calibrations.
class StorageService extends ChangeNotifier {
  final List<SessionRecord> _sessions = [];
  final List<ClinicalFlag> _flags = [];
  CalibrationRecord? _activeCalibration;
  RehabilitationPlan? _activePlan;
  final String patientId = 'P-014'; // Default research pseudonym

  StorageService() {
    _initDefaults();
  }

  void _initDefaults() {
    // Default rehabilitation plan
    _activePlan = RehabilitationPlan(
      id: 'plan_default_014',
      patientId: patientId,
      exerciseId: 'fist_clench',
      targetReps: 10,
      targetRomMin: 70.0,
      targetRomMax: 100.0,
      holdS: 0.5,
      restS: 2.0,
      sessionsPerWeek: 5,
      stopInstruction: 'Stop if you feel sharp pain. Rest as needed.',
      fatigueDropThreshold: 20.0,
      validFrom: DateTime.now().subtract(const Duration(days: 7)),
      setBy: 'Dr. Physiotherapist Lead',
      version: 1,
    );
  }

  List<SessionRecord> get sessions => List.unmodifiable(_sessions);
  List<ClinicalFlag> get flags => List.unmodifiable(_flags);
  CalibrationRecord? get activeCalibration => _activeCalibration;
  RehabilitationPlan get activePlan => _activePlan!;

  int get pendingSyncCount => _sessions.where((s) => s.syncStatus == 'pending').length;

  Future<void> saveSession(SessionRecord session) async {
    // Insert at front
    _sessions.insert(0, session);

    // Evaluate clinical flags immediately on-device
    final newFlags = FlagGenerator.evaluate(
      patientId: patientId,
      plan: _activePlan!,
      sessions: _sessions.reversed.toList(),
      calibration: _activeCalibration,
    );
    _flags.clear();
    _flags.addAll(newFlags);

    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }

  Future<void> saveCalibration(CalibrationRecord calibration) async {
    _activeCalibration = calibration;
    notifyListeners();
  }

  void markSessionSynced(String sessionId) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      _sessions[idx] = SessionRecord(
        id: s.id,
        patientId: s.patientId,
        exerciseCode: s.exerciseCode,
        planVersion: s.planVersion,
        startedAt: s.startedAt,
        endedAt: s.endedAt,
        durationS: s.durationS,
        repsCompleted: s.repsCompleted,
        repsTarget: s.repsTarget,
        repsInterrupted: s.repsInterrupted,
        meanRom: s.meanRom,
        maxRom: s.maxRom,
        meanRepDurationS: s.meanRepDurationS,
        smoothness: s.smoothness,
        holdS: s.holdS,
        consistency: s.consistency,
        consistencyComponents: s.consistencyComponents,
        fatigueDropPct: s.fatigueDropPct,
        painBefore: s.painBefore,
        painAfter: s.painAfter,
        fatigueBefore: s.fatigueBefore,
        fatigueAfter: s.fatigueAfter,
        note: s.note,
        dataQuality: s.dataQuality,
        dataSource: s.dataSource,
        deviceId: s.deviceId,
        firmware: s.firmware,
        calibrationRef: s.calibrationRef,
        modelVersion: s.modelVersion,
        clientVersion: s.clientVersion,
        createdAt: s.createdAt,
        receivedAt: DateTime.now(),
        syncStatus: 'synced',
        repetitions: s.repetitions,
      );
      notifyListeners();
    }
  }

  void markSessionConflict(String sessionId) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      _sessions[idx] = SessionRecord(
        id: s.id,
        patientId: s.patientId,
        exerciseCode: s.exerciseCode,
        planVersion: s.planVersion,
        startedAt: s.startedAt,
        endedAt: s.endedAt,
        durationS: s.durationS,
        repsCompleted: s.repsCompleted,
        repsTarget: s.repsTarget,
        meanRom: s.meanRom,
        maxRom: s.maxRom,
        meanRepDurationS: s.meanRepDurationS,
        painAfter: s.painAfter,
        fatigueAfter: s.fatigueAfter,
        dataQuality: s.dataQuality,
        dataSource: s.dataSource,
        deviceId: s.deviceId,
        firmware: s.firmware,
        calibrationRef: s.calibrationRef,
        clientVersion: s.clientVersion,
        createdAt: s.createdAt,
        syncStatus: 'conflict',
        holdS: s.holdS,
      );
      notifyListeners();
    }
  }

  String exportCsv() {
    final buffer = StringBuffer();
    buffer.writeln('session_id,patient_id,exercise_code,started_at,duration_s,reps_completed,reps_target,mean_rom,max_rom,consistency,pain_after,fatigue_after,data_quality,data_source');
    for (final s in _sessions) {
      buffer.writeln('${s.id},${s.patientId},${s.exerciseCode},${s.startedAt.toIso8601String()},${s.durationS},${s.repsCompleted},${s.repsTarget},${s.meanRom},${s.maxRom},${s.consistency ?? ''},${s.painAfter},${s.fatigueAfter},${s.dataQuality},${s.dataSource}');
    }
    return buffer.toString();
  }

  String exportJson() {
    return jsonEncode(_sessions.map((s) => s.toJson()).toList());
  }

  void clearAllData() {
    _sessions.clear();
    _flags.clear();
    _activeCalibration = null;
    notifyListeners();
  }
}
