import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as devtools;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as imglib;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final dateRegex = RegExp(
  r'(?:' +
      r'((\d{2}|\d{4})[-/\.\:年](\d{1,2})(?:[-/\.\:月](\d{1,2})日?)?)' + // e.g., 2025年7月21日
      r'|' +
      r'(?:\d{8})' + // e.g., 20250721
      r')',
);

final expiryKeywords = RegExp(
  r'(賞味期限|消費期限|有効期限|EXP\.?|Expiry|Expiration)',
  caseSensitive: false,
);

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.japanese,
  );
  List<Box> _boundingBoxes = [];
  bool _isProcessing = false;
  DateTime _lastProcessed = DateTime.now();

  Uint8List? _frozenCapture;
  bool _isFrozen = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initializeCamera();

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

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    setState(
      () {},
    ); // telling FutureBuilder the future it's supposed to wait on is ready
    _initializeControllerFuture?.then((_) {
      startOcrStream();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    WakelockPlus.disable();
    _textRecognizer.close();
  }

  Future<void> disposeState() async {
    _controller.dispose(); // need to re-initialize because resumePreview broken
    WakelockPlus.disable();
  }

  void _onSavePressed() {
    List<DateTime> dates = [];

    for (final box in _boundingBoxes) {
      if (box.isSelected) {
        final match = dateRegex.firstMatch(box.text)!;
        String yearStr = match.group(2)!;
        dates.add(
          DateTime(
            int.parse(yearStr.length < 4 ? "20$yearStr" : yearStr),
            match.group(3) == null ? 12 : int.parse(match.group(3)!),
            match.group(4) == null ? 31 : int.parse(match.group(4)!),
          ),
        );
      }
    }
    print("$dates");
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    await Future.delayed(Duration(milliseconds: 200));

    try {
      await _controller.stopImageStream();
      await _controller.pausePreview();

      final image = await _controller.takePicture();
      final imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();

      _isFrozen = true;
      _frozenCapture = bytes;

      await imageFile.delete();
    } catch (e) {
      devtools.log("Error taking picture: $e", name: "fridgeforce");
    }
    setState(() {
      _isCapturing = false;
    });
    await disposeState();
  }

  void _handleTap(TapDownDetails details) {
    final Offset tapPos = details.localPosition;

    for (final box in _boundingBoxes) {
      if (box.rect.contains(tapPos)) {
        print(dateRegex.firstMatch(box.text)?.group(1));
        setState(() => box.isSelected = !box.isSelected);
        break;
      }
    }
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
        final bytes = cameraImageToBytes(image);

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation:
                InputImageRotationValue.fromRawValue(
                  _controller.description.sensorOrientation,
                ) ??
                InputImageRotation.rotation0deg,
            format: Platform.isAndroid
                ? InputImageFormat.nv21
                : InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final recognizedText = await _textRecognizer.processImage(inputImage);

        List<Box> boxes = [];
        for (final block in recognizedText.blocks) {
          if (isDateTime(block.text)) {
            boxes.add(Box(block.boundingBox, block.text));
          }
        }

        setState(() => _boundingBoxes = boxes);
      } catch (e) {
        devtools.log('OCR error: $e', name: "fridgeforce");
      } finally {
        _isProcessing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If _initializeControllerFuture hasn't been set yet
    if (_initializeControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isFrozen) {
          WakelockPlus.enable();
          _initializeCamera();
          setState(() {
            _isFrozen = false;
            _boundingBoxes = [];
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: _isFrozen
            ? FloatingActionButton(
                onPressed: _onSavePressed,
                child: const Icon(Icons.save, size: 32),
              )
            : FloatingActionButton(
                onPressed: (_isCapturing || !_controller.value.isInitialized)
                    ? null
                    : () async => await _onCapturePressed(),
                child: const Icon(Icons.screenshot_monitor, size: 32),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            // Waiting for initialization or controller not ready
            if (snapshot.connectionState != ConnectionState.done ||
                !_controller.value.isInitialized ||
                _controller.value.previewSize == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final previewSize = _controller.value.previewSize!;
            final screenSize = MediaQuery.sizeOf(context);
            final scale = min(
              screenSize.width / previewSize.height,
              screenSize.height / previewSize.width,
            );

            return Stack(
              children: [
                // Camera preview or frozen image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: previewSize.height,
                      height: previewSize.width,
                      child: _isFrozen
                          ? GestureDetector(
                              onTapDown: _handleTap,
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox.expand(
                                child: _frozenCapture != null
                                    ? Image.memory(_frozenCapture!)
                                    : Container(color: Colors.black),
                              ),
                            )
                          : CameraPreview(_controller),
                    ),
                  ),
                ),
                // Bounding boxes overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: OverlayBoxPainter(
                        _boundingBoxes.map((box) {
                          final rect = Rect.fromLTWH(
                            box.rect.left * scale,
                            box.rect.top * scale,
                            box.rect.width * scale,
                            box.rect.height * scale,
                          );
                          final newBox = Box(rect, box.text)
                            ..isSelected = box.isSelected;
                          return newBox;
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class Box {
  final Rect rect;
  final text;
  bool isSelected = false;

  Box(this.rect, this.text);

  Color get borderColor => isSelected ? Colors.green : Colors.red;
}

class OverlayBoxPainter extends CustomPainter {
  final List<Box> boxes;

  OverlayBoxPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (final box in boxes) {
      paint.color = box.borderColor;
      canvas.drawRect(box.rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

///////////////////////////// UTIL FUNCTIONS ///////////////////////////////////
Uint8List cameraImageToBytes(CameraImage image) {
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }

  final bytes = allBytes.done().buffer.asUint8List();
  return bytes;
}

Future<Uint8List> prepImage(String path) async {
  imglib.Image? original = await imglib.decodeJpgFile(path);

  if (original == null) {
    throw Exception("Failed to decode image.");
  }
  imglib.Image gray = imglib.grayscale(original);
  imglib.Image contrastEnhanced = imglib.adjustColor(gray, contrast: 1.2);

  return Uint8List.fromList(imglib.encodeJpg(contrastEnhanced));
}

bool isDateTime(String s) {
  final match = dateRegex.firstMatch(s);
  if (match == null) return false;

  DateTime now = DateTime.now();
  String yearStr = match.group(2)!;
  int year = int.parse(yearStr.length < 4 ? "20$yearStr" : yearStr);
  if (year < now.year || year > now.year + 5) return false;

  print("match0 ${match.group(0)}");
  print("match1 ${match.group(1)}");
  print("match2 ${match.group(2)}");
  print("match3 ${match.group(3)}");
  print("match4 ${match.group(4)}");

  int month = match.group(3) == null ? 12 : int.parse(match.group(3)!);
  int day = match.group(4) == null ? 31 : int.parse(match.group(4)!);

  final dateTime = DateTime(year, month, day);
  return year == dateTime.year && month == dateTime.month;
}
