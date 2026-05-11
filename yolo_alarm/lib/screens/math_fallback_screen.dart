import 'dart:math';
import 'package:flutter/material.dart';

class MathFallbackScreen extends StatefulWidget {
  final int difficulty; // 1=easy, 2=medium, 3=hard

  const MathFallbackScreen({super.key, required this.difficulty});

  @override
  State<MathFallbackScreen> createState() => _MathFallbackScreenState();
}

class _MathFallbackScreenState extends State<MathFallbackScreen> {
  late String _question;
  late int _answer;
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate() {
    final rng = Random();
    switch (widget.difficulty) {
      case 1:
        final a = rng.nextInt(20) + 1;
        final b = rng.nextInt(20) + 1;
        if (rng.nextBool()) {
          _question = '$a + $b = ?';
          _answer = a + b;
        } else {
          final big = a >= b ? a : b;
          final small = a >= b ? b : a;
          _question = '$big − $small = ?';
          _answer = big - small;
        }
      case 2:
        final a = rng.nextInt(11) + 2;
        final b = rng.nextInt(11) + 2;
        _question = '$a × $b = ?';
        _answer = a * b;
      case 3:
      default:
        final a = rng.nextInt(20) + 10;
        final b = rng.nextInt(10) + 2;
        final c = rng.nextInt(9) + 2;
        _question = '($a + $b) × $c = ?';
        _answer = (a + b) * c;
    }
  }

  void _submit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == null) {
      setState(() => _error = 'Enter a whole number');
      return;
    }
    if (input == _answer) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'Incorrect — try again';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Solve to dismiss')),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _question,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Answer',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
