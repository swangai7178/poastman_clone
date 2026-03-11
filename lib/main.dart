import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wire_touch/screens/main/main_page.dart';

void main() {
  // 1. Check if we are on Desktop (Windows, macOS, Linux)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 2. Initialize FFI
    sqfliteFfiInit();
    // 3. Set the global databaseFactory to the FFI version
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const WireTouchApp());
}

class WireTouchApp extends StatelessWidget {
  const WireTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WireTouch",
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),

      home: const MainPage(),
    );
  }
}