import 'package:drift/drift.dart';
import '../app_database.dart';

part 'reminder_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.db);

  Future<List<Reminder>> getRemindersForMedication(String medicationId) {
    return (select(reminders)
          ..where((r) => r.medicationId.equals(medicationId)))
        .get();
  }

  Future<List<Reminder>> getAllEnabledReminders() {
    return (select(reminders)..where((r) => r.isEnabled.equals(true))).get();
  }

  Future<void> upsertReminder(RemindersCompanion entry) {
    return into(reminders).insertOnConflictUpdate(entry);
  }

  Stream<List<Reminder>> watchAllRemindersForUser(String userId) {
    return (select(reminders).join([
      innerJoin(medications, medications.id.equalsExp(reminders.medicationId)),
    ])
          ..where(
            medications.userId.equals(userId) &
                medications.isActive.equals(true),
          ))
        .map((row) => row.readTable(reminders))
        .watch();
  }

  Future<void> deleteReminder(String id) {
    return (delete(reminders)..where((r) => r.id.equals(id))).go();
  }

  Future<void> deleteRemindersForMedication(String medicationId) {
    return (delete(reminders)
          ..where((r) => r.medicationId.equals(medicationId)))
        .go();
  }
}
