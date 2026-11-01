class RehabilitationPlan {
  final String id;
  final String patientId;
  final String exerciseId;
  final int targetReps;
  final double targetRomMin;
  final double targetRomMax;
  final double holdS;
  final double restS;
  final int sessionsPerWeek;
  final String stopInstruction;
  final double fatigueDropThreshold;
  final DateTime validFrom;
  final DateTime? validTo;
  final String setBy;
  final int version;

  const RehabilitationPlan({
    required this.id,
    required this.patientId,
    required this.exerciseId,
    required this.targetReps,
    this.targetRomMin = 70.0,
    this.targetRomMax = 100.0,
    this.holdS = 0.5,
    this.restS = 2.0,
    this.sessionsPerWeek = 5,
    this.stopInstruction = 'Stop if you feel sharp pain. Rest as needed.',
    this.fatigueDropThreshold = 20.0,
    required this.validFrom,
    this.validTo,
    required this.setBy,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'exercise_id': exerciseId,
    'target_reps': targetReps,
    'target_rom_min': targetRomMin,
    'target_rom_max': targetRomMax,
    'hold_s': holdS,
    'rest_s': restS,
    'sessions_per_week': sessionsPerWeek,
    'stop_instruction': stopInstruction,
    'fatigue_drop_threshold': fatigueDropThreshold,
    'valid_from': validFrom.toIso8601String(),
    'valid_to': validTo?.toIso8601String(),
    'set_by': setBy,
    'version': version,
  };

  factory RehabilitationPlan.fromJson(Map<String, dynamic> json) => RehabilitationPlan(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    exerciseId: json['exercise_id'] as String,
    targetReps: json['target_reps'] as int,
    targetRomMin: (json['target_rom_min'] as num).toDouble(),
    targetRomMax: (json['target_rom_max'] as num).toDouble(),
    holdS: (json['hold_s'] as num).toDouble(),
    restS: (json['rest_s'] as num).toDouble(),
    sessionsPerWeek: json['sessions_per_week'] as int,
    stopInstruction: json['stop_instruction'] as String,
    fatigueDropThreshold: (json['fatigue_drop_threshold'] as num).toDouble(),
    validFrom: DateTime.parse(json['valid_from'] as String),
    validTo: json['valid_to'] != null ? DateTime.parse(json['valid_to'] as String) : null,
    setBy: json['set_by'] as String,
    version: json['version'] as int,
  );
}

