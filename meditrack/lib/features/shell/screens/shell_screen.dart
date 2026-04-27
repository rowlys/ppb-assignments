import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/notification_service.dart';

class ShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.requestPermission();
    _importUserData();
  }

  Future<void> _importUserData() async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;
    final db = context.read<AppDatabase>();
    final firestore = context.read<FirestoreService>();
    try {
      final results = await Future.wait([
        firestore.fetchMedications(userId),
        firestore.fetchReminders(userId),
        firestore.fetchIntakeLogs(userId),
      ]);

      final meds = results[0] as List;
      final reminders = results[1] as List;
      final logs = results[2] as List;

      final docsDir = await getApplicationDocumentsDirectory();

      for (final med in meds as List<MedicationsCompanion>) {
        await db.medicationDao.upsertMedication(med);
        final photoFile =
            File(p.join(docsDir.path, 'med_photo_${med.id.value}.jpg'));
        if (await photoFile.exists()) {
          await db.medicationDao.updateMedication(
            MedicationsCompanion(
              id: med.id,
              photoUrl: Value(photoFile.path),
            ),
          );
        }
      }
      for (final reminder in reminders as List<RemindersCompanion>) {
        await db.reminderDao.upsertReminder(reminder);
      }
      for (final log in logs as List<IntakeLogsCompanion>) {
        await db.intakeLogDao.upsertLog(log);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final location = GoRouterState.of(context).matchedLocation;
    final isAtBranchRoot = const {
      '/home',
      '/medications',
      '/reminders',
      '/logs',
      '/profile',
    }.contains(location);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isAtBranchRoot
          ? NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication),
                  label: 'Medicine',
                ),
                NavigationDestination(
                  icon: Icon(Icons.alarm_outlined),
                  selectedIcon: Icon(Icons.alarm),
                  label: 'Reminders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}
