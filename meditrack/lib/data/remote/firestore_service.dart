import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;

import '../local/app_database.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medsRef(String userId) =>
      _db.collection('users').doc(userId).collection('medications');

  CollectionReference<Map<String, dynamic>> _remindersRef(String userId) =>
      _db.collection('users').doc(userId).collection('reminders');

  CollectionReference<Map<String, dynamic>> _intakeLogsRef(String userId) =>
      _db.collection('users').doc(userId).collection('intakeLogs');

  Future<List<MedicationsCompanion>> fetchMedications(String userId) async {
    final snapshot = await _medsRef(userId)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) {
      final d = doc.data();
      return MedicationsCompanion(
        id: Value(d['id'] as String),
        userId: Value(userId),
        name: Value(d['name'] as String),
        dosage: Value(d['dosage'] as String),
        unit: Value(d['unit'] as String),
        photoUrl: Value(d['photoUrl'] as String?),
        notes: Value(d['notes'] as String?),
        isActive: const Value(true),
      );
    }).toList();
  }

  Future<void> saveMedication(String userId, Medication med) {
    return _medsRef(userId).doc(med.id).set({
      'id': med.id,
      'name': med.name,
      'dosage': med.dosage,
      'unit': med.unit,
      'photoUrl': med.photoUrl,
      'notes': med.notes,
      'isActive': med.isActive,
    });
  }

  Future<void> deactivateMedication(String userId, String medicationId) {
    return _medsRef(userId).doc(medicationId).update({'isActive': false});
  }

  Future<void> saveReminder(String userId, Reminder reminder) {
    return _remindersRef(userId).doc(reminder.id).set({
      'id': reminder.id,
      'medicationId': reminder.medicationId,
      'hour': reminder.hour,
      'minute': reminder.minute,
      'daysOfWeek': reminder.daysOfWeek,
      'isEnabled': reminder.isEnabled,
    });
  }

  Future<void> deleteReminder(String userId, String reminderId) {
    return _remindersRef(userId).doc(reminderId).delete();
  }

  Future<List<RemindersCompanion>> fetchReminders(String userId) async {
    final snapshot = await _remindersRef(userId).get();
    return snapshot.docs.map((doc) {
      final d = doc.data();
      return RemindersCompanion(
        id: Value(d['id'] as String),
        medicationId: Value(d['medicationId'] as String),
        hour: Value(d['hour'] as int),
        minute: Value(d['minute'] as int),
        daysOfWeek: Value(d['daysOfWeek'] as String),
        isEnabled: Value(d['isEnabled'] as bool),
      );
    }).toList();
  }

  Future<void> saveIntakeLog(String userId, IntakeLog log) {
    return _intakeLogsRef(userId).doc(log.id).set({
      'id': log.id,
      'medicationId': log.medicationId,
      'reminderId': log.reminderId,
      'takenAt': Timestamp.fromDate(log.takenAt),
      'status': log.status,
      'notes': log.notes,
    });
  }

  Future<List<IntakeLogsCompanion>> fetchIntakeLogs(String userId) async {
    final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)));
    final snapshot = await _intakeLogsRef(userId)
        .where('takenAt', isGreaterThanOrEqualTo: cutoff)
        .get();
    return snapshot.docs.map((doc) {
      final d = doc.data();
      return IntakeLogsCompanion(
        id: Value(d['id'] as String),
        medicationId: Value(d['medicationId'] as String),
        reminderId: Value(d['reminderId'] as String?),
        takenAt: Value((d['takenAt'] as Timestamp).toDate()),
        status: Value(d['status'] as String),
        notes: Value(d['notes'] as String?),
      );
    }).toList();
  }
}
