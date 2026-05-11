import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(alarm.targetLabel),
      trailing: Switch(
        value: alarm.isEnabled,
        onChanged: onToggle,
      ),
      onTap: onTap,
    );
  }
}
