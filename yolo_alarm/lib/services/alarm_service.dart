import '../models/alarm_model.dart';
import 'notification_service.dart';

class AlarmService {
  static Future<void> init() async {}

  static Future<void> scheduleNext(AlarmModel alarm) async {
    final fireTime = _nextFireTime(alarm);
    // print('[AlarmService] scheduling id=${alarm.id} at $fireTime');
    await NotificationService.scheduleAlarm(alarm, fireTime);
    // print('[AlarmService] scheduled ok');
  }

  static Future<void> cancel(int id) => NotificationService.cancel(id);

  static DateTime _nextFireTime(AlarmModel alarm) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);

    final hasRepeat = alarm.repeatDays.any((d) => d);
    if (!hasRepeat) {
      return base.isAfter(now) ? base : base.add(const Duration(days: 1));
    }

    // repeatDays index 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun | DateTime.weekday 1=Mon … 7=Sun
    for (var offset = 0; offset <= 7; offset++) {
      final candidate = base.add(Duration(days: offset));
      if (alarm.repeatDays[candidate.weekday - 1] && candidate.isAfter(now)) {
        return candidate;
      }
    }
    return base.add(const Duration(days: 1));
  }
}
