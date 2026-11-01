class ClinicalFlag {
  final String id;
  final String patientId;
  final String type;
  final String severity; // 'info', 'review'
  final DateTime createdAt;
  final List<String> sessionIds;
  final String message;
  final Map<String, dynamic> metricValues;
  final Map<String, dynamic> thresholdUsed;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final String? ackNote;

  const ClinicalFlag({
    required this.id,
    required this.patientId,
    required this.type,
    required this.severity,
    required this.createdAt,
    this.sessionIds = const [],
    required this.message,
    required this.metricValues,
    required this.thresholdUsed,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.ackNote,
  });

  bool get isAcknowledged => acknowledgedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'type': type,
    'severity': severity,
    'created_at': createdAt.toIso8601String(),
    'session_ids': sessionIds,
    'message': message,
    'metric_values': metricValues,
    'threshold_used': thresholdUsed,
    'acknowledged_at': acknowledgedAt?.toIso8601String(),
    'acknowledged_by': acknowledgedBy,
    'ack_note': ackNote,
  };

  factory ClinicalFlag.fromJson(Map<String, dynamic> json) => ClinicalFlag(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    type: json['type'] as String,
    severity: json['severity'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    sessionIds: (json['session_ids'] as List?)?.cast<String>() ?? [],
    message: json['message'] as String,
    metricValues: json['metric_values'] as Map<String, dynamic>? ?? {},
    thresholdUsed: json['threshold_used'] as Map<String, dynamic>? ?? {},
    acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at'] as String) : null,
    acknowledgedBy: json['acknowledged_by'] as String?,
    ackNote: json['ack_note'] as String?,
  );
}
