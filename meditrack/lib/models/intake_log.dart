enum IntakeStatus { taken, skipped }

class IntakeLog {
  final String id;
  final String medicationId;
  final DateTime takenAt;
  final IntakeStatus status;
  final String? notes;

  const IntakeLog({
    required this.id,
    required this.medicationId,
    required this.takenAt,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'takenAt': takenAt.toIso8601String(),
    'status': status.name,
    'notes': notes,
  };

  factory IntakeLog.fromJson(Map<String, dynamic> json) => IntakeLog(
    id: json['id'] as String,
    medicationId: json['medicationId'] as String,
    takenAt: DateTime.parse(json['takenAt'] as String),
    status: IntakeStatus.values.byName(json['status'] as String),
    notes: json['notes'] as String?,
  );
}