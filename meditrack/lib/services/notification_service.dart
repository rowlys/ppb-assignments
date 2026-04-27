import 'package:awesome_notifications/awesome_notifications.dart';

import '../data/local/app_database.dart';

class NotificationService {
  static const _channelKey = 'medication_reminders';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Medication Reminders',
          channelDescription: 'Reminds you to take your medications on schedule',
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
      debug: false,
    );
  }

  static Future<void> requestPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleReminder(
    Reminder reminder,
    String medicationName,
    String dosage,
    String unit,
  ) async {
    await cancelReminder(reminder.id);

    if (reminder.daysOfWeek.isEmpty) return;

    final days = reminder.daysOfWeek.split(',').map(int.parse).toList();
    for (final day in days) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _notifId(reminder.id, day),
          channelKey: _channelKey,
          title: 'Time to take $medicationName',
          body: '$dosage $unit',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          weekday: day,
          hour: reminder.hour,
          minute: reminder.minute,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    }
  }

  static Future<void> cancelReminder(String reminderId) async {
    for (int day = 1; day <= 7; day++) {
      await AwesomeNotifications().cancel(_notifId(reminderId, day));
    }
  }

  static int _notifId(String reminderId, int day) =>
      (reminderId.hashCode.abs() % 999999) * 7 + (day - 1);
}
