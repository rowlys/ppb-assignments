import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm_model.dart';

const _channelId = 'yolo_alarm';
const _channelName = 'Alarm';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init({void Function(String payload)? onResponse}) async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: onResponse == null
          ? null
          : (r) {
              if (r.payload != null) onResponse(r.payload!);
            },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.max,
          playSound: false,
          enableVibration: true,
        ));
  }

  static Future<void> show(AlarmModel alarm) async {
    await _plugin.show(
      id: alarm.id,
      title: 'Wake up!',
      body: 'Scan "${alarm.targetLabel}" to dismiss',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: false,
          enableVibration: true,
          ongoing: true,
          autoCancel: false,
        ),
      ),
      payload: alarm.id.toString(),
    );
  }

  static Future<void> scheduleAlarm(AlarmModel alarm, DateTime fireTime) async {
    await _plugin.zonedSchedule(
      id: alarm.id,
      title: 'Wake up!',
      body: 'Scan "${alarm.targetLabel}" to dismiss',
      scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: false,
          enableVibration: true,
          ongoing: true,
          autoCancel: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: alarm.id.toString(),
    );
  }

  static Future<void> requestFullScreenPermission() async {
    try {
      await const MethodChannel('dexterous.com/flutter/local_notifications')
          .invokeMethod<bool>('requestFullScreenIntentPermission');
    } catch (_) {}
  }

  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  static Future<NotificationAppLaunchDetails?> getLaunchDetails() =>
      _plugin.getNotificationAppLaunchDetails();
}
