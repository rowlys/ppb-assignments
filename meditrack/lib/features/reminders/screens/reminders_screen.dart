import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final db = context.read<AppDatabase>();
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: Text('Reminders')),
      body: StreamBuilder<List<Medication>>(
        stream: db.medicationDao.watchMedications(user.uid),
        builder: (context, medSnapshot) {
          final medications = medSnapshot.data ?? [];
          final medMap = {for (final m in medications) m.id: m.name};

          return StreamBuilder<List<Reminder>>(
            stream: db.reminderDao.watchAllRemindersForUser(user.uid),
            builder: (context, remSnapshot) {
              if (remSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reminders = remSnapshot.data ?? [];

              if (reminders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_off_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No reminders yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Tap + to add a reminder',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rem = reminders[index];
                  final medName = medMap[rem.medicationId] ?? 'Unknown';
                  final time =
                      '${rem.hour.toString().padLeft(2, '0')}:${rem.minute.toString().padLeft(2, '0')}';
                  final days = _formatDays(rem.daysOfWeek);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(Icons.alarm,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer),
                      ),
                      title: Text(medName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$time  •  $days'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () async {
                          await NotificationService.cancelReminder(rem.id);
                          await Future.wait([
                            firestore.deleteReminder(user.uid, rem.id),
                            db.reminderDao.deleteReminder(rem.id),
                          ]);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final medications =
              await db.medicationDao.watchMedications(user.uid).first;
          if (!context.mounted) return;
          if (medications.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Add a medication first before creating a reminder.')),
            );
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _ReminderSheet(
              medications: medications,
              userId: user.uid,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDays(String daysOfWeek) {
    const names = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final days = daysOfWeek.split(',').map(int.parse).toList()..sort();
    if (days.length == 7) return 'Every day';
    return days.map((d) => names[d] ?? '').join(', ');
  }
}

class _ReminderSheet extends StatefulWidget {
  final List<Medication> medications;
  final String userId;

  const _ReminderSheet({required this.medications, required this.userId});

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late String _selectedMedId;
  TimeOfDay _selectedTime = TimeOfDay.now();
  final Set<int> _selectedDays = {};
  bool _isLoading = false;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selectedMedId = widget.medications.first.id;
  }

  Future<void> _save() async {
    if (_selectedDays.isEmpty) return;
    setState(() => _isLoading = true);

    final db = context.read<AppDatabase>();
    final firestore = context.read<FirestoreService>();
    final daysString = (_selectedDays.toList()..sort()).join(',');
    final id = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await db.reminderDao.upsertReminder(
        RemindersCompanion(
          id: Value(id),
          medicationId: Value(_selectedMedId),
          hour: Value(_selectedTime.hour),
          minute: Value(_selectedTime.minute),
          daysOfWeek: Value(daysString),
          isEnabled: const Value(true),
        ),
      );

      final med = widget.medications.firstWhere((m) => m.id == _selectedMedId);
      final reminder = Reminder(
        id: id,
        medicationId: _selectedMedId,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        daysOfWeek: daysString,
        isEnabled: true,
      );
      await Future.wait([
        NotificationService.scheduleReminder(
            reminder, med.name, med.dosage, med.unit),
        firestore.saveReminder(widget.userId, reminder),
      ]);

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Reminder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedMedId,
            decoration: const InputDecoration(
              labelText: 'Medication',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.medication_outlined),
            ),
            items: widget.medications
                .map((m) =>
                    DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMedId = v!),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
              child: Text(_selectedTime.format(context)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Days', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              return FilterChip(
                label: Text(_dayNames[i]),
                selected: _selectedDays.contains(day),
                onSelected: (v) => setState(() {
                  if (v) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                }),
              );
            }),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_isLoading || _selectedDays.isEmpty) ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Reminder'),
          ),
        ],
      ),
    );
  }
}
