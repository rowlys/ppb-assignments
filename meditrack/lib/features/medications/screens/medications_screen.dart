import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/local/app_database.dart';
import '../../auth/providers/auth_provider.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final db = context.read<AppDatabase>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Medications'),
      ),
      body: StreamBuilder<List<Medication>>(
        stream: db.medicationDao.watchMedications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final medications = snapshot.data ?? [];

          if (medications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No medications yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first medication',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final med = medications[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.medication,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(med.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${med.dosage} ${med.unit}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/medications/edit', extra: med),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
