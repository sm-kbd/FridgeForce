import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

class _CameraScreenState extends State<CameraScreen> {
    late CameraController _controller;
    late Future<void> _initializeControllerFuture;
    Uint8List? _imageBytes;

    @override
        void initState() {
            super.initState();
            _controller = CameraController(widget.camera, ResolutionPreset.high);
            _initializeControllerFuture = _controller.initialize();

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
                                                fit: BoxFit.cover,
                                                child: SizedBox(
                                                    // because camera is landscape but screen is portrait
                                                    width: _controller.value.previewSize!.height,
                                                    height: _controller.value.previewSize!.width,
                                                    child: CameraPreview(_controller),
                                                    ),
                                                ),
                                            ),
                                        Positioned(
                                            bottom: MediaQuery.of(context).size.height * 0.05,
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

