import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

const List<String> cocoLabels = [
  'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
  'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
  'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
  'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
  'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
  'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup',
  'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
  'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
  'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
  'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
  'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear',
  'hair drier', 'toothbrush',
];

const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class AlarmConfigScreen extends StatefulWidget {
  final AlarmModel? initial;

  const AlarmConfigScreen({super.key, this.initial});

  @override
  State<AlarmConfigScreen> createState() => _AlarmConfigScreenState();
}

class _AlarmConfigScreenState extends State<AlarmConfigScreen> {
  late TimeOfDay _time;
  late List<bool> _repeatDays;
  late String _targetLabel;
  late bool _mathFallback;
  late int _mathDifficulty;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _time = a != null ? TimeOfDay(hour: a.hour, minute: a.minute) : TimeOfDay.now();
    _repeatDays = a != null ? List.of(a.repeatDays) : List.filled(7, false);
    _targetLabel = a?.targetLabel ?? cocoLabels.first;
    _mathFallback = a?.mathFallbackEnabled ?? true;
    _mathDifficulty = a?.mathDifficulty ?? 1;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final alarm = AlarmModel(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      hour: _time.hour,
      minute: _time.minute,
      repeatDays: _repeatDays,
      targetLabel: _targetLabel,
      mathFallbackEnabled: _mathFallback,
      mathDifficulty: _mathDifficulty,
    );
    Navigator.pop(context, alarm);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'New Alarm' : 'Edit Alarm'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Center(
            child: TextButton(
              onPressed: _pickTime,
              child: Text(
                _time.format(context),
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Center(
            child: Text('Tap to change time', style: TextStyle(color: Colors.grey)),
          ),

          const SizedBox(height: 28),
          const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = _repeatDays[i];
              return GestureDetector(
                onTap: () => setState(() => _repeatDays[i] = !active),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: active ? primary : Colors.grey.shade200,
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),
          const Text('Scan to dismiss', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _targetLabel,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: cocoLabels
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _targetLabel = v!),
          ),

          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Math fallback'),
            subtitle: const Text('Solve a math problem if camera fails'),
            value: _mathFallback,
            onChanged: (v) => setState(() => _mathFallback = v),
            contentPadding: EdgeInsets.zero,
          ),

          if (_mathFallback) ...[
            const SizedBox(height: 8),
            const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Easy')),
                ButtonSegment(value: 2, label: Text('Medium')),
                ButtonSegment(value: 3, label: Text('Hard')),
              ],
              selected: {_mathDifficulty},
              onSelectionChanged: (s) => setState(() => _mathDifficulty = s.first),
            ),
          ],

          const SizedBox(height: 36),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
