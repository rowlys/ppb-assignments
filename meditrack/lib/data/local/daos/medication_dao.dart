import 'package:drift/drift.dart';
import '../app_database.dart';

part 'medication_dao.g.dart';

@DriftAccessor(tables: [Medications])
class MedicationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(super.db);

  Stream<List<Medication>> watchMedications(String userId) {
    return (select(medications)
          ..where((m) => m.userId.equals(userId) & m.isActive.equals(true)))
        .watch();
  }

  Future<Medication?> getMedicationById(String id) {
    return (select(medications)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertMedication(MedicationsCompanion entry) {
    return into(medications).insert(entry);
  }

  Future<void> upsertMedication(MedicationsCompanion entry) {
    return into(medications).insertOnConflictUpdate(entry);
  }

  Future<void> updateMedication(MedicationsCompanion entry) {
    return (update(medications)
          ..where((m) => m.id.equals(entry.id.value)))
        .write(entry);
  }

  Future<void> deleteMedication(String id) {
    return (update(medications)..where((m) => m.id.equals(id)))
        .write(const MedicationsCompanion(isActive: Value(false)));
  }
}
