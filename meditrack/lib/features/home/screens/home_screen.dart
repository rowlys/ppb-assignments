import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const Scaffold();

    final db = context.read<AppDatabase>();
    final firestore = context.read<FirestoreService>();
    final today = DateTime.now();
    final todayWeekday = today.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Schedule"),
            Text(
              DateFormat('EEEE, MMMM d').format(today),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Medication>>(
        stream: db.medicationDao.watchMedications(user.uid),
        builder: (context, medSnapshot) {
          final medMap = {
            for (final m in medSnapshot.data ?? []) m.id: m,
          };

          return StreamBuilder<List<Reminder>>(
            stream: db.reminderDao.watchAllRemindersForUser(user.uid),
            builder: (context, remSnapshot) {
              final todayReminders = (remSnapshot.data ?? [])
                  .where((r) =>
                      r.isEnabled &&
                      r.daysOfWeek.isNotEmpty &&
                      r.daysOfWeek.split(',').map(int.parse).contains(todayWeekday))
                  .toList()
                ..sort((a, b) =>
                    a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));

              return StreamBuilder<List<IntakeLog>>(
                stream: db.intakeLogDao.watchLogsForDate(today),
                builder: (context, logSnapshot) {
                  final takenToday = {
                    for (final log in logSnapshot.data ?? [])
                      if (log.status == 'taken' && log.reminderId != null) log.reminderId!: log.id,
                  };

                  if (todayReminders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No reminders for today',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add reminders in the Reminders tab',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: todayReminders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final rem = todayReminders[index];
                      final med = medMap[rem.medicationId];
                      if (med == null) return const SizedBox.shrink();

                      final timeStr =
                          '${rem.hour.toString().padLeft(2, '0')}:${rem.minute.toString().padLeft(2, '0')}';
                      final isTaken = takenToday.containsKey(rem.id);

                      return _ScheduleCard(
                        med: med,
                        timeStr: timeStr,
                        isTaken: isTaken,
                        onTake: () async {
                          final id =
                              '${user.uid}_${rem.medicationId}_${DateTime.now().millisecondsSinceEpoch}';
                          final now = DateTime.now();
                          final log = IntakeLog(
                            id: id,
                            medicationId: rem.medicationId,
                            reminderId: rem.id,
                            takenAt: now,
                            status: 'taken',
                            notes: null,
                          );
                          await db.intakeLogDao.insertLog(
                            IntakeLogsCompanion(
                              id: Value(id),
                              medicationId: Value(rem.medicationId),
                              reminderId: Value(rem.id),
                              takenAt: Value(now),
                              status: const Value('taken'),
                            ),
                          );
                          firestore.saveIntakeLog(user.uid, log);
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Medication med;
  final String timeStr;
  final bool isTaken;
  final VoidCallback onTake;

  const _ScheduleCard({
    required this.med,
    required this.timeStr,
    required this.isTaken,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isTaken
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timeStr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isTaken
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${med.dosage} ${med.unit}',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isTaken)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Taken',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            else
              FilledButton.tonal(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Intake'),
                      content: Text('Have you taken ${med.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onTake();
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Take'),
              ),
          ],
        ),
      ),
    );
  }
}
