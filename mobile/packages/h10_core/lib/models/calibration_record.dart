class FingerCalibration {
  final int fingerIndex;
  final String name;
  final double openValue;
  final double closedValue;
  final double span;
  final int polarity; // 1 if closed > open, -1 if closed < open
  final bool isValid;
  final String? rejectReason;
  final double openSd;
  final double closedSd;

  const FingerCalibration({
    required this.fingerIndex,
    required this.name,
    required this.openValue,
    required this.closedValue,
    required this.span,
    required this.polarity,
    required this.isValid,
    this.rejectReason,
    required this.openSd,
    required this.closedSd,
  });

  Map<String, dynamic> toJson() => {
    'finger_index': fingerIndex,
    'name': name,
    'open_value': openValue,
    'closed_value': closedValue,
    'span': span,
    'polarity': polarity,
    'is_valid': isValid,
    'reject_reason': rejectReason,
    'open_sd': openSd,
    'closed_sd': closedSd,
  };

  factory FingerCalibration.fromJson(Map<String, dynamic> json) => FingerCalibration(
    fingerIndex: json['finger_index'] as int,
    name: json['name'] as String,
    openValue: (json['open_value'] as num).toDouble(),
    closedValue: (json['closed_value'] as num).toDouble(),
    span: (json['span'] as num).toDouble(),
    polarity: json['polarity'] as int,
    isValid: json['is_valid'] as bool,
    rejectReason: json['reject_reason'] as String?,
    openSd: (json['open_sd'] as num).toDouble(),
    closedSd: (json['closed_sd'] as num).toDouble(),
  );
}

class CalibrationRecord {
  final String id;
  final String? patientId;
  final String? deviceId;
  final DateTime capturedAt;
  final int minSpanThreshold;
  final List<FingerCalibration> fingers;
  final String status; // 'valid', 'invalid', 'drift_warning'

  const CalibrationRecord({
    required this.id,
    this.patientId,
    this.deviceId,
    required this.capturedAt,
    this.minSpanThreshold = 300,
    required this.fingers,
    required this.status,
  });

  bool get isValid => status == 'valid' && fingers.every((f) => f.isValid);

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'device_id': deviceId,
    'captured_at': capturedAt.toIso8601String(),
    'min_span_threshold': minSpanThreshold,
    'fingers': fingers.map((f) => f.toJson()).toList(),
    'status': status,
  };

  factory CalibrationRecord.fromJson(Map<String, dynamic> json) => CalibrationRecord(
    id: json['id'] as String,
    patientId: json['patient_id'] as String?,
    deviceId: json['device_id'] as String?,
    capturedAt: DateTime.parse(json['captured_at'] as String),
    minSpanThreshold: json['min_span_threshold'] as int? ?? 300,
    fingers: (json['fingers'] as List)
        .map((f) => FingerCalibration.fromJson(f as Map<String, dynamic>))
        .toList(),
    status: json['status'] as String,
  );
}

