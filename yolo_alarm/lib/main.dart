import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'repositories/alarm_repository.dart';
import 'screens/alarm_firing_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Permission.notification.request();
  await Permission.camera.request();
  await NotificationService.init(onResponse: _onNotificationResponse);
  await Permission.scheduleExactAlarm.request();

  await AlarmService.init();
  runApp(const MainApp());
}

Future<void> _onNotificationResponse(String payload) async {
  final id = int.tryParse(payload);
  if (id == null) return;
  final alarm = await AlarmRepository().getById(id);
  if (alarm == null || !alarm.isEnabled) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AlarmFiringScreen(alarm: alarm)),
      (route) => route.isFirst,
    );
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}
