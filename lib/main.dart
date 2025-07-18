import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: CameraScreen(camera: camera));
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class OverlayPainter extends CustomPainter {
  final List<Rect> boxes;
  final Size previewSize;
  final Size screenSize;

  OverlayPainter(this.boxes, this.previewSize, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final scale = min(
      screenSize.width / previewSize.width,
      screenSize.height / previewSize.height,
    );

    // Black bar offsets
    final double offsetY = (screenSize.height - previewSize.height * scale) / 2;
    final double offsetX = (screenSize.width - previewSize.width * scale) / 2;

    for (final box in boxes) {
      final transformed = Rect.fromLTWH(
        box.left * scale + offsetX,
        box.top * scale + offsetY,
        box.width * scale,
        box.height * scale,
      );

      canvas.drawRect(transformed, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  final TextRecognizer _textRecognizer = TextRecognizer();
  List<Rect> _boundingBoxes = [];
  bool _isProcessing = false;
  DateTime _lastProcessed = DateTime.now();

  Uint8List? _frozenCapture;
  bool _isFrozen = false;
  late List<Rect> _frozenBoxes = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    _initializeControllerFuture.then((_) {
      startOcrStream();
    });

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Top bar color
        systemNavigationBarColor: Colors.black, // Bottom bar color
        statusBarIconBrightness:
            Brightness.light, // Icons on top bar (battery, time)
        systemNavigationBarIconBrightness:
            Brightness.light, // Icons on bottom bar
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    if (_controller.value.isStreamingImages) {
      _controller.stopImageStream();
    }
    _textRecognizer.close();
  }

  Future<void> _freeze() async {
    try {
      await _controller.stopImageStream();
      await _controller.pausePreview();

      final image = await _controller.takePicture();

      final bytes = await File(image.path).readAsBytes();
      if (bytes.isEmpty) {
        await _controller.resumePreview();
        setState(() {
          _isFrozen = false;
        });
        startOcrStream();
        return;
      }

      setState(() {
        _isFrozen = true;
        _frozenCapture = bytes;
        _frozenBoxes = List.from(_boundingBoxes);
      });

      await File(image.path).delete();
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  void _handleTap(TapDownDetails details) {
    print("here");
    startOcrStream();
  }

  void startOcrStream() {
    _controller.startImageStream((CameraImage image) async {
      final now = DateTime.now();

      if (_isProcessing ||
          (now.difference(_lastProcessed).inMilliseconds < 500)) {
        // Prevent overlapping and throttle
        return;
      }

      _isProcessing = true;
      _lastProcessed = now;

      try {
        final inputImage = _convertToInputImage(
          image,
          _controller.description.sensorOrientation,
        );
        final recognizedText = await _textRecognizer.processImage(inputImage);
        final text = recognizedText.text;
        print("Text is $text");

        List<Rect> boxes = [];
        for (final block in recognizedText.blocks) {
          boxes.add(block.boundingBox);
        }

        setState(() => _boundingBoxes = boxes);
      } catch (e) {
        print('OCR error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage _convertToInputImage(CameraImage image, int rotation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation:
          InputImageRotationValue.fromRawValue(rotation) ??
          InputImageRotation.rotation0deg,
      format: Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          // because camera is landscape but screen is portrait
                          width: _controller.value.previewSize!.height,
                          height: _controller.value.previewSize!.width,
                          child: _isFrozen
                              ? GestureDetector(
                                  onTapDown: _handleTap,
                                  behavior: HitTestBehavior.opaque,
                                  child: SizedBox.expand(
                                    child: Image.memory(_frozenCapture!),
                                  ),
                                )
                              : CameraPreview(_controller),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: OverlayPainter(
                            _isFrozen ? _frozenBoxes : _boundingBoxes,
                            Size(
                              _controller.value.previewSize!.height,
                              _controller.value.previewSize!.width,
                            ),
                            Size(
                              MediaQuery.sizeOf(context).width -
                                  (MediaQuery.of(context).padding.left +
                                      MediaQuery.of(context).padding.right),
                              MediaQuery.sizeOf(context).height -
                                  (MediaQuery.of(context).padding.top +
                                      MediaQuery.of(context).padding.bottom),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: MediaQuery.sizeOf(context).height * 0.10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _isFrozen
                            ? Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _freeze,
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20),
                                    ),
                                    child: const Icon(Icons.camera, size: 32),
                                  ),
                                  ElevatedButton(
                                    onPressed: _freeze,
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20),
                                    ),
                                    child: const Icon(Icons.phone, size: 32),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: _freeze,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(20),
                                ),
                                child: const Icon(
                                  Icons.screenshot_monitor,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
