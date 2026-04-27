class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String unit;
  final String? photoUrl;
  final String? notes;
  final bool isActive;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.unit,
    this.photoUrl,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'dosage': dosage,
    'unit': unit,
    'photoUrl': photoUrl,
    'notes': notes,
    'isActive': isActive,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String,
    unit: json['unit'] as String,
    photoUrl: json['photoUrl'] as String?,
    notes: json['notes'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}