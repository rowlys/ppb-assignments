import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class AlarmRepository {
  static const _key = 'alarms';

  Future<List<AlarmModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => AlarmModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert(AlarmModel alarm) async {
    final alarms = await loadAll();
    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      alarms[idx] = alarm;
    } else {
      alarms.add(alarm);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  Future<AlarmModel?> getById(int id) async {
    final alarms = await loadAll();
    return alarms.cast<AlarmModel?>().firstWhere(
      (a) => a?.id == id,
      orElse: () => null,
    );
  }

  Future<void> delete(int id) async {
    final alarms = await loadAll();
    alarms.removeWhere((a) => a.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
