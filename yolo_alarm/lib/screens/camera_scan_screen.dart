import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScanScreen extends StatefulWidget {
  final String targetLabel;

  const CameraScanScreen({super.key, required this.targetLabel});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final FlutterVision _vision = FlutterVision();

  CameraController? _camera;
  List<Map<String, dynamic>> _detections = [];
  bool _modelReady = false;
  bool _processing = false;
  bool _disposed = false;
  String _status = 'Requesting camera permission...';

  bool get _testMode => widget.targetLabel.isEmpty;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _disposed = true;
    try {
      _camera?.stopImageStream();
    } catch (_) {}
    _camera?.dispose();
    _closeModelWhenIdle();
    super.dispose();
  }

  Future<void> _closeModelWhenIdle() async {
    while (_processing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _vision.closeYoloModel();
  }

  Future<void> _start() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _status = 'Camera permission denied.');
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _status = 'Opening camera...');

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = 'No cameras available.');
      return;
    }

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _camera = CameraController(back, ResolutionPreset.medium, enableAudio: false);
    await _camera!.initialize();

    await _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _status = 'Loading YOLO model...');

    await _vision.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/yolov8n_float32.tflite',
      modelVersion: 'yolov8',
      quantization: false,
      numThreads: 2,
      useGpu: false,
    );

    if (!mounted) return;
    setState(() {
      _modelReady = true;
      _status = _testMode ? 'Model loaded — detecting all objects' : 'Scanning for "${widget.targetLabel}"...';
    });

    _camera!.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || !_modelReady || _disposed) return;
    _processing = true;

    final results = await _vision.yoloOnFrame(
      bytesList: image.planes.map((p) => p.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );

    if (_disposed) {
      _processing = false;
      return;
    }

    if (mounted) setState(() => _detections = results);

    if (!_testMode) {
      final hit = results.any((d) =>
        d['tag'] == widget.targetLabel &&
        (d['box'][4] as double) >= 0.65,
      );
      if (hit) {
        _disposed = true;
        try {
          await _camera!.stopImageStream();
        } catch (_) {}
        if (mounted) Navigator.pop(context, true);
      }
    }

    _processing = false;
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady = _camera != null && _camera!.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Text(_testMode ? 'YOLO Test' : 'Scan: ${widget.targetLabel}'),
      ),
      body: cameraReady
          ? Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _camera!.value.previewSize!.height,
                      height: _camera!.value.previewSize!.width,
                      child: CameraPreview(_camera!),
                    ),
                  ),
                ),
                CustomPaint(
                  painter: _BoxPainter(
                    detections: _detections,
                    previewSize: _camera!.value.previewSize!,
                    target: widget.targetLabel,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _DetectionBanner(
                    detections: _detections,
                    status: _status,
                  ),
                ),
              ],
            )
          : Center(child: Text(_status)),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size previewSize;
  final String target;

  const _BoxPainter({
    required this.detections,
    required this.previewSize,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final tag = det['tag'] as String;
      final box = det['box'] as List<dynamic>;
      final conf = (box[4] as double);

      final isTarget = target.isNotEmpty && tag == target;
      final color = isTarget ? Colors.greenAccent : Colors.orangeAccent;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final left = (box[0] as double) * size.width;
      final top = (box[1] as double) * size.height;
      final right = (box[2] as double) * size.width;
      final bottom = (box[3] as double) * size.height;

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      final tp = TextPainter(
        text: TextSpan(
          text: ' $tag ${(conf * 100).toStringAsFixed(0)}% ',
          style: TextStyle(
            color: color,
            fontSize: 12,
            backgroundColor: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left, top > 18 ? top - 18 : top + 2));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.detections != detections;
}

class _DetectionBanner extends StatelessWidget {
  final List<Map<String, dynamic>> detections;
  final String status;

  const _DetectionBanner({required this.detections, required this.status});

  @override
  Widget build(BuildContext context) {
    final text = detections.isEmpty
        ? status
        : detections
            .map((d) {
              final box = d['box'] as List<dynamic>;
              final conf = ((box[4] as double) * 100).toStringAsFixed(0);
              return '${d['tag']} $conf%';
            })
            .join('  ·  ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
