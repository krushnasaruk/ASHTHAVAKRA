import 'repetition.dart';

class SessionRecord {
  final String id;
  final String patientId;
  final String exerciseCode;
  final int planVersion;
  final DateTime startedAt;
  final DateTime endedAt;
  final double durationS;
  final int repsCompleted;
  final int repsTarget;
  final int repsInterrupted;
  final double meanRom;
  final double maxRom;
  final double meanRepDurationS;
  final double? smoothness;
  final double holdS;
  final double? consistency;
  final Map<String, dynamic>? consistencyComponents;
  final double? fatigueDropPct;
  final int? painBefore;
  final int painAfter;
  final int? fatigueBefore;
  final int fatigueAfter;
  final String note;
  final String dataQuality; // 'good', 'reduced', 'invalid'
  final String dataSource;  // 'real', 'simulated'
  final String deviceId;
  final String firmware;
  final String calibrationRef;
  final String? modelVersion;
  final String clientVersion;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final String syncStatus; // 'pending', 'synced', 'conflict'
  final List<Repetition> repetitions;

  const SessionRecord({
    required this.id,
    required this.patientId,
    required this.exerciseCode,
    required this.planVersion,
    required this.startedAt,
    required this.endedAt,
    required this.durationS,
    required this.repsCompleted,
    required this.repsTarget,
    this.repsInterrupted = 0,
    required this.meanRom,
    required this.maxRom,
    required this.meanRepDurationS,
    this.smoothness,
    required this.holdS,
    this.consistency,
    this.consistencyComponents,
    this.fatigueDropPct,
    this.painBefore,
    required this.painAfter,
    this.fatigueBefore,
    required this.fatigueAfter,
    this.note = '',
    required this.dataQuality,
    required this.dataSource,
    required this.deviceId,
    required this.firmware,
    required this.calibrationRef,
    this.modelVersion,
    required this.clientVersion,
    required this.createdAt,
    this.receivedAt,
    this.syncStatus = 'pending',
    this.repetitions = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'exercise_code': exerciseCode,
    'plan_version': planVersion,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt.toIso8601String(),
    'duration_s': durationS,
    'reps_completed': repsCompleted,
    'reps_target': repsTarget,
    'reps_interrupted': repsInterrupted,
    'mean_rom': meanRom,
    'max_rom': maxRom,
    'mean_rep_duration_s': meanRepDurationS,
    'smoothness': smoothness,
    'hold_s': holdS,
    'consistency': consistency,
    'consistency_components': consistencyComponents,
    'fatigue_drop_pct': fatigueDropPct,
    'pain_before': painBefore,
    'pain_after': painAfter,
    'fatigue_before': fatigueBefore,
    'fatigue_after': fatigueAfter,
    'note': note,
    'data_quality': dataQuality,
    'data_source': dataSource,
    'device_id': deviceId,
    'firmware': firmware,
    'calibration_ref': calibrationRef,
    'model_version': modelVersion,
    'client_version': clientVersion,
    'created_at': createdAt.toIso8601String(),
    'received_at': receivedAt?.toIso8601String(),
    'sync_status': syncStatus,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    exerciseCode: json['exercise_code'] as String,
    planVersion: json['plan_version'] as int,
    startedAt: DateTime.parse(json['started_at'] as String),
    endedAt: DateTime.parse(json['ended_at'] as String),
    durationS: (json['duration_s'] as num).toDouble(),
    repsCompleted: json['reps_completed'] as int,
    repsTarget: json['reps_target'] as int,
    repsInterrupted: json['reps_interrupted'] as int? ?? 0,
    meanRom: (json['mean_rom'] as num).toDouble(),
    maxRom: (json['max_rom'] as num).toDouble(),
    meanRepDurationS: (json['mean_rep_duration_s'] as num).toDouble(),
    smoothness: (json['smoothness'] as num?)?.toDouble(),
    holdS: (json['hold_s'] as num).toDouble(),
    consistency: (json['consistency'] as num?)?.toDouble(),
    consistencyComponents: json['consistency_components'] as Map<String, dynamic>?,
    fatigueDropPct: (json['fatigue_drop_pct'] as num?)?.toDouble(),
    painBefore: json['pain_before'] as int?,
    painAfter: json['pain_after'] as int,
    fatigueBefore: json['fatigue_before'] as int?,
    fatigueAfter: json['fatigue_after'] as int,
    note: json['note'] as String? ?? '',
    dataQuality: json['data_quality'] as String,
    dataSource: json['data_source'] as String,
    deviceId: json['device_id'] as String,
    firmware: json['firmware'] as String,
    calibrationRef: json['calibration_ref'] as String,
    modelVersion: json['model_version'] as String?,
    clientVersion: json['client_version'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at'] as String) : null,
    syncStatus: json['sync_status'] as String? ?? 'pending',
  );
}
