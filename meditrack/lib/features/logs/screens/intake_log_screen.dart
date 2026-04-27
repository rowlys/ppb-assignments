import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/local/app_database.dart';
import '../../auth/providers/auth_provider.dart';

class IntakeLogScreen extends StatelessWidget {
  const IntakeLogScreen({super.key});

  @override
  Widget build(BuildContext context){
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const Scaffold();

    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intake History'),
      ),
      body: StreamBuilder<List<Medication>>(
        stream: db.medicationDao.watchMedications(user.uid),
        builder: (context, medSnapshot) {
          final medMap = { for (final m in medSnapshot.data ?? []) m.id: m };

          return StreamBuilder<List<IntakeLog>>(
            stream: db.intakeLogDao.watchLogsForUser(user.uid),
            builder: (context, logSnapshot){
              final logs = logSnapshot.data ?? [];

              if (logs.isEmpty){
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No intake history yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Your taken doses will appear here',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  )
                );
              }

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));

              final grouped = <String, List<IntakeLog>>{};
              for (final log in logs) {
                final date = DateTime(log.takenAt.year, log.takenAt.month, log.takenAt.day);
                final String key;
                if (date == today) {
                  key = 'Today';
                } else if (date == yesterday) {
                  key = 'Yesterday';
                } else {
                  key = DateFormat('EEEE, MMMM d').format(log.takenAt);
                }
                grouped.putIfAbsent(key, () => []).add(log);
              }
              final dateKeys = grouped.keys.toList();


              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: dateKeys.fold<int>(0, (sum, k) => sum + 1 + grouped[k]!.length),
                itemBuilder: (context, index) {
                  // Walk through the groups to find which item this index maps to
                  int cursor = 0;
                  for (final key in dateKeys) {
                    if (index == cursor) {
                      // This index is a section header
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(key,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      );
                    }
                    cursor++;
                    final items = grouped[key]!;
                    if (index < cursor + items.length) {
                      final log = items[index - cursor];
                      final med = medMap[log.medicationId]!;
                      return _LogCard(log: log, med: med); // build next step
                    }
                    cursor += items.length;
                  }
                  return const SizedBox.shrink();
                },
              );
            }
          );
        }
      ),
    );
  } 
}


class _LogCard extends StatelessWidget {
    final IntakeLog log;
    final Medication med;

    const _LogCard({required this.log, required this.med});

    @override
    Widget build(BuildContext context) {
      final isTaken = log.status == 'taken';
      final timeStr = DateFormat('HH:mm').format(log.takenAt);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isTaken
                ? Colors.green.shade100
                : Colors.grey.shade200,
            child: Icon(
              isTaken ? Icons.check : Icons.close,
              color: isTaken ? Colors.green.shade700 : Colors.grey.shade600,
              size: 20,
            ),
          ),
          title: Text(med.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${med.dosage} ${med.unit}'),
          trailing: Text(timeStr,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }
  }