class Patient {
  final String id;
  final String pseudonym; // e.g. "P-014"
  final String affectedHand; // 'left', 'right', 'unknown'
  final DateTime createdAt;
  final String notes;
  final String dataSource; // 'real', 'simulated'

  const Patient({
    required this.id,
    required this.pseudonym,
    required this.affectedHand,
    required this.createdAt,
    this.notes = '',
    this.dataSource = 'real',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pseudonym': pseudonym,
    'affected_hand': affectedHand,
    'created_at': createdAt.toIso8601String(),
    'notes': notes,
    'data_source': dataSource,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    pseudonym: json['pseudonym'] as String,
    affectedHand: json['affected_hand'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    notes: json['notes'] as String? ?? '',
    dataSource: json['data_source'] as String? ?? 'real',
  );
}

