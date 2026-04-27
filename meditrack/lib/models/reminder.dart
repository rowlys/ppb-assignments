class Reminder {
  final String id;
  final String medicationId;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; 
  final bool isEnabled;

  const Reminder({
    required this.id,
    required this.medicationId,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isEnabled = true,
  });
}