import 'dart:io';
import 'package:flutter/material.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/main_screen.dart';
import 'services/notification.dart';

void main() async {
  if (Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();

    // Set the global factory
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(FridgeForce());
}

const Color primaryColor = Color.fromRGBO(112, 176, 228, 1);

class FridgeForce extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Force',
      theme: ThemeData(
        primaryColor:
            primaryColor, // affects default widgets like AppBar title color
        scaffoldBackgroundColor: Colors.white, // background of Scaffold
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor, // sets AppBar background color
          foregroundColor: Colors.white, // sets text/icon color
          elevation: 4,
        ),
      ),
      home: MainScreen(),
    );
  }
}
