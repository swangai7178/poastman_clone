import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/main/main_page.dart';
import 'models/project.dart';
import 'models/collection.dart';
import 'models/request_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(CollectionAdapter());
  Hive.registerAdapter(RequestModelAdapter());

  // Open boxes
  await Hive.openBox<Project>('projects');
  await Hive.openBox('history');

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