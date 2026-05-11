import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../repositories/alarm_repository.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import 'camera_scan_screen.dart';
import 'math_fallback_screen.dart';

class AlarmFiringScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmFiringScreen({super.key, required this.alarm});

  @override
  State<AlarmFiringScreen> createState() => _AlarmFiringScreenState();
}

class _AlarmFiringScreenState extends State<AlarmFiringScreen> {
  final _player = AudioPlayer();
  late final String _timeText;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timeText =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/default_ringtone.mp3'));
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    await _player.stop();
    await NotificationService.cancel(widget.alarm.id);
    if (widget.alarm.repeatDays.any((d) => d)) {
      await AlarmService.scheduleNext(widget.alarm);
    } else {
      await AlarmRepository().upsert(widget.alarm.copyWith(isEnabled: false));
    }
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _scanToDismiss() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScanScreen(targetLabel: widget.alarm.targetLabel),
      ),
    );
    if (ok == true) _dismiss();
  }

  Future<void> _mathToDismiss() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MathFallbackScreen(difficulty: widget.alarm.mathDifficulty),
      ),
    );
    if (ok == true) _dismiss();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _timeText,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Scan "${widget.alarm.targetLabel}" to dismiss',
                    style: const TextStyle(fontSize: 16, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 72),
                FilledButton.icon(
                  onPressed: _scanToDismiss,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan to dismiss'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(240, 52),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                if (widget.alarm.mathFallbackEnabled) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _mathToDismiss,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Math instead'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(240, 52),
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
