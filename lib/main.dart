import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

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
            return MaterialApp(
                    home: CameraScreen(camera: camera),
                    );
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
    Uint8List? _imageBytes;

    final TextRecognizer _textRecognizer = TextRecognizer();
    List<Rect> _boundingBoxes = [];
    bool _isProcessing = false;
    DateTime _lastProcessed = DateTime.now();

    @override
        void initState() {
            super.initState();
            _controller = CameraController(widget.camera, ResolutionPreset.high);
            _initializeControllerFuture = _controller.initialize();
            _initializeControllerFuture.then((_) {startOcrStream();});

            SystemChrome.setSystemUIOverlayStyle(
                    SystemUiOverlayStyle(
                        statusBarColor: Colors.black, // Top bar color
                        systemNavigationBarColor: Colors.black, // Bottom bar color
                        statusBarIconBrightness: Brightness.light, // Icons on top bar (battery, time)
                        systemNavigationBarIconBrightness: Brightness.light, // Icons on bottom bar
                        ),
                    );
        }

    @override
        void dispose() {
            _controller.dispose();
            super.dispose();
            _controller.stopImageStream();
            _textRecognizer.close();
        }

    Future<void> _takePicture() async {
        try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            // Read file as bytes
            final bytes = await File(image.path).readAsBytes();

            setState(() {
                    _imageBytes = bytes;
                    });

            // Optionally delete the temp file if you don't need it
            await File(image.path).delete();
        } catch (e) {
            print("Error taking picture: $e");
        }
    }

    void startOcrStream() {
        _controller.startImageStream((CameraImage image) async {
                final now = DateTime.now();

                if (_isProcessing) return; // Prevent overlapping
                if (now.difference(_lastProcessed).inMilliseconds < 500) return; // Throttle

                _isProcessing = true;
                _lastProcessed = now;

                try {
                final inputImage = _convertToInputImage(image, _controller.description.sensorOrientation);
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

        final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

        final inputImageData = InputImageMetadata(
                size: imageSize,
                rotation: InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
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
                                            child:FittedBox(
                                                fit: BoxFit.contain,
                                                child: SizedBox(
                                                    // because camera is landscape but screen is portrait
                                                    width: _controller.value.previewSize!.height,
                                                    height: _controller.value.previewSize!.width,
                                                    child: CameraPreview(_controller),
                                                    ),
                                                ),
                                            ),
                                        Positioned.fill(
                                            child: CustomPaint(
                                                painter: OverlayPainter(
                                                    _boundingBoxes,
                                                    Size(_controller.value.previewSize!.height, _controller.value.previewSize!.width),
                                                    Size(
                                                        MediaQuery.sizeOf(context).width - (MediaQuery.of(context).padding.left + MediaQuery.of(context).padding.right),
                                                        MediaQuery.sizeOf(context).height - (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom),
                                                        ),
                                                    ),

                                                ),
                                            ),
                                        Positioned(
                                                bottom: MediaQuery.sizeOf(context).height * 0.10,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                    child: ElevatedButton(
                                                        onPressed: _takePicture,
                                                        style: ElevatedButton.styleFrom(
                                                            shape: const CircleBorder(),
                                                            padding: const EdgeInsets.all(20),
                                                            ),
                                                        child: const Icon(
                                                            Icons.camera_alt,
                                                            size: 32,
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                        if (_imageBytes != null)
                                            Positioned(
                                                    top: 40,
                                                    right: 20,
                                                    child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.memory(
                                                            _imageBytes!,
                                                            width: 100,
                                                            height: 100,
                                                            fit: BoxFit.cover,
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

