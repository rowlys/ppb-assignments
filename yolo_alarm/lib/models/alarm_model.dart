class AlarmModel {
  final int id;
  final int hour;
  final int minute;
  final List<bool> repeatDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final String targetLabel;
  final bool mathFallbackEnabled;
  final int mathDifficulty; // 1=easy, 2=medium, 3=hard
  final bool isEnabled;

  const AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.targetLabel,
    this.mathFallbackEnabled = true,
    this.mathDifficulty = 1,
    this.isEnabled = true,
  });

  AlarmModel copyWith({
    int? id,
    int? hour,
    int? minute,
    List<bool>? repeatDays,
    String? targetLabel,
    bool? mathFallbackEnabled,
    int? mathDifficulty,
    bool? isEnabled,
  }) => AlarmModel(
    id: id ?? this.id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    repeatDays: repeatDays ?? List.of(this.repeatDays),
    targetLabel: targetLabel ?? this.targetLabel,
    mathFallbackEnabled: mathFallbackEnabled ?? this.mathFallbackEnabled,
    mathDifficulty: mathDifficulty ?? this.mathDifficulty,
    isEnabled: isEnabled ?? this.isEnabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'repeatDays': repeatDays,
    'targetLabel': targetLabel,
    'mathFallbackEnabled': mathFallbackEnabled,
    'mathDifficulty': mathDifficulty,
    'isEnabled': isEnabled,
  };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
    id: json['id'] as int,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    repeatDays: (json['repeatDays'] as List<dynamic>).cast<bool>(),
    targetLabel: json['targetLabel'] as String,
    mathFallbackEnabled: json['mathFallbackEnabled'] as bool? ?? true,
    mathDifficulty: json['mathDifficulty'] as int? ?? 1,
    isEnabled: json['isEnabled'] as bool? ?? true,
  );
}
