import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../repositories/alarm_repository.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../widgets/alarm_card.dart';
import 'alarm_config_screen.dart';
import 'alarm_firing_screen.dart';
import 'camera_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repo = AlarmRepository();
  List<AlarmModel> _alarms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkNotificationLaunch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestFullScreenPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final alarms = await _repo.loadAll();
    if (mounted) setState(() => _alarms = alarms);
  }

  Future<void> _checkNotificationLaunch() async {
    final details = await NotificationService.getLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    final payload = details?.notificationResponse?.payload;
    final id = int.tryParse(payload ?? '');
    if (id == null) return;
    final alarm = await _repo.getById(id);
    if (alarm == null || !alarm.isEnabled || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AlarmFiringScreen(alarm: alarm)),
    );
  }

  Future<void> _openConfig({AlarmModel? alarm}) async {
    final result = await Navigator.push<AlarmModel>(
      context,
      MaterialPageRoute(builder: (_) => AlarmConfigScreen(initial: alarm)),
    );
    if (result != null) {
      if (alarm != null) await AlarmService.cancel(alarm.id);
      await _repo.upsert(result);
      if (result.isEnabled) {
        try { await AlarmService.scheduleNext(result); } catch (_) {}
      }
      await _load();
    }
  }

  Future<void> _toggle(AlarmModel alarm, bool enabled) async {
    final updated = alarm.copyWith(isEnabled: enabled);
    await _repo.upsert(updated);
    try {
      if (enabled) {
        await AlarmService.scheduleNext(updated);
      } else {
        await AlarmService.cancel(alarm.id);
      }
    } catch (_) {}
    await _load();
  }

  Future<void> _delete(int id) async {
    try { await AlarmService.cancel(id); } catch (_) {}
    await _repo.delete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),

        // Untuk testing camera YOLO
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Test YOLO',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CameraScanScreen(targetLabel: ''),
              ),
            ),
          ),
        ],
      ),

      body: _alarms.isEmpty
          ? const Center(child: Text('No alarms yet'))
          : ListView.separated(
              itemCount: _alarms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final alarm = _alarms[i];
                return Dismissible(
                  key: ValueKey(alarm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(alarm.id),
                  child: AlarmCard(
                    alarm: alarm,
                    onTap: () => _openConfig(alarm: alarm),
                    onToggle: (v) => _toggle(alarm, v),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openConfig(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
