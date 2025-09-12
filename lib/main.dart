import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/main_screen.dart';
import 'dart:io';

void main() {
  if (Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();

    // Set the global factory
    databaseFactory = databaseFactoryFfi;
  }
  runApp(FridgeForce());
}

class FridgeForce extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Force',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}
