import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/medication_dao.dart';
import 'daos/reminder_dao.dart';
import 'daos/intake_log_dao.dart';

part 'app_database.g.dart';

class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get unit => text()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId =>
      text().references(Medications, #id)();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  TextColumn get daysOfWeek => text()();
  BoolColumn get isEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class IntakeLogs extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId => text().references(Medications, #id)();
  TextColumn get reminderId => text().nullable()();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Medications, Reminders, IntakeLogs],
  daos: [MedicationDao, ReminderDao, IntakeLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
  );

  Future<void> clearUserData(String userId) async {
    final userMedIds = await (select(medications)
          ..where((m) => m.userId.equals(userId)))
        .map((m) => m.id)
        .get();

    await transaction(() async {
      if (userMedIds.isNotEmpty) {
        await (delete(intakeLogs)
              ..where((l) => l.medicationId.isIn(userMedIds)))
            .go();
        await (delete(reminders)
              ..where((r) => r.medicationId.isIn(userMedIds)))
            .go();
      }
      await (delete(medications)..where((m) => m.userId.equals(userId))).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'medtracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
