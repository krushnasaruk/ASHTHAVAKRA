enum RepetitionStatus { complete, interrupted, rejected }

enum RepetitionQuality { good, reduced, invalid }

class Repetition {
  final String id;
  final String sessionId;
  final int index;
  final int startMs;
  final int endMs;
  final double durationS;
  final double peak;
  final double mean;
  final double min;
  final double rom;
  final double holdS;
  final double? smoothness;
  final RepetitionQuality quality;
  final RepetitionStatus status;
  final String? rejectReason;

  const Repetition({
    required this.id,
    required this.sessionId,
    required this.index,
    required this.startMs,
    required this.endMs,
    required this.durationS,
    required this.peak,
    required this.mean,
    required this.min,
    required this.rom,
    required this.holdS,
    this.smoothness,
    this.quality = RepetitionQuality.good,
    required this.status,
    this.rejectReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'index': index,
    'start_ms': startMs,
    'end_ms': endMs,
    'duration_s': durationS,
    'peak': peak,
    'mean': mean,
    'min': min,
    'rom': rom,
    'hold_s': holdS,
    'smoothness': smoothness,
    'quality': quality.name,
    'status': status.name,
    'reject_reason': rejectReason,
  };

  factory Repetition.fromJson(Map<String, dynamic> json) => Repetition(
    id: json['id'] as String,
    sessionId: json['session_id'] as String,
    index: json['index'] as int,
    startMs: json['start_ms'] as int,
    endMs: json['end_ms'] as int,
    durationS: (json['duration_s'] as num).toDouble(),
    peak: (json['peak'] as num).toDouble(),
    mean: (json['mean'] as num).toDouble(),
    min: (json['min'] as num).toDouble(),
    rom: (json['rom'] as num).toDouble(),
    holdS: (json['hold_s'] as num).toDouble(),
    smoothness: (json['smoothness'] as num?)?.toDouble(),
    quality: RepetitionQuality.values.byName(json['quality'] as String),
    status: RepetitionStatus.values.byName(json['status'] as String),
    rejectReason: json['reject_reason'] as String?,
  );
}

