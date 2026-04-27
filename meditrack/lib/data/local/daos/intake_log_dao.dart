import 'package:drift/drift.dart';
import '../app_database.dart';

part 'intake_log_dao.g.dart';

@DriftAccessor(tables: [IntakeLogs])
class IntakeLogDao extends DatabaseAccessor<AppDatabase>
    with _$IntakeLogDaoMixin {
  IntakeLogDao(super.db);

  Future<List<IntakeLog>> getLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(intakeLogs)
          ..where((l) =>
              l.takenAt.isBiggerOrEqualValue(start) &
              l.takenAt.isSmallerThanValue(end)))
        .get();
  }

  Future<List<IntakeLog>> getLogsForMedication(String medicationId) {
    return (select(intakeLogs)
          ..where((l) => l.medicationId.equals(medicationId))
          ..orderBy([(l) => OrderingTerm.desc(l.takenAt)]))
        .get();
  }

  Future<IntakeLog?> getTodayLogForMedication(String medicationId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(intakeLogs)
          ..where((l) =>
              l.medicationId.equals(medicationId) &
              l.takenAt.isBiggerOrEqualValue(start) &
              l.takenAt.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  Future<void> insertLog(IntakeLogsCompanion entry) {
    return into(intakeLogs).insert(entry);
  }

  Future<void> upsertLog(IntakeLogsCompanion entry) {
    return into(intakeLogs).insertOnConflictUpdate(entry);
  }

  Stream<List<IntakeLog>> watchLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(intakeLogs)
          ..where((l) =>
              l.takenAt.isBiggerOrEqualValue(start) &
              l.takenAt.isSmallerThanValue(end)))
        .watch();
  }

  Stream<List<IntakeLog>> watchAllLogs() {
    return (select(intakeLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.takenAt)]))
        .watch();
  }

  Stream<List<IntakeLog>> watchLogsForUser(String userId) {
    return (select(intakeLogs).join([
      innerJoin(medications, medications.id.equalsExp(intakeLogs.medicationId)),
    ])
          ..where(medications.userId.equals(userId))
          ..orderBy([OrderingTerm.desc(intakeLogs.takenAt)]))
        .map((row) => row.readTable(intakeLogs))
        .watch();
  }

  Future<void> deleteLog(String id) {
    return (delete(intakeLogs)..where((l) => l.id.equals(id))).go();
  }
}
