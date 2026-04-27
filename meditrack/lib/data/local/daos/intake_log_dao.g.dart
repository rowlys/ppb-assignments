// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_log_dao.dart';

// ignore_for_file: type=lint
mixin _$IntakeLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationsTable get medications => attachedDatabase.medications;
  $IntakeLogsTable get intakeLogs => attachedDatabase.intakeLogs;
  IntakeLogDaoManager get managers => IntakeLogDaoManager(this);
}

class IntakeLogDaoManager {
  final _$IntakeLogDaoMixin _db;
  IntakeLogDaoManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db.attachedDatabase, _db.medications);
  $$IntakeLogsTableTableManager get intakeLogs =>
      $$IntakeLogsTableTableManager(_db.attachedDatabase, _db.intakeLogs);
}
