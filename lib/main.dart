import 'dart:io';
import 'package:flutter/material.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/main_screen.dart';
import 'services/notification.dart';

void main() {
  if (Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();

    // Set the global factory
    databaseFactory = databaseFactoryFfi;
  }
  initNotifications();
  runApp(FridgeForce());
}

class FridgeForce extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Force',
      home: MainScreen(),
    );
  }
}
