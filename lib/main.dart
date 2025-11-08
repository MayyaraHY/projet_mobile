import 'dart:io'; // <-- ADDED
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart'; // <-- ADDED
import 'screens/voiture_list_screen.dart';
import 'database/database_helper.dart';

void main() async { // <-- CHANGED to async
  // --- ADDED THIS BLOCK ---
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize window manager on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
    } catch (e) {
      print('Window manager initialization failed: $e');
    }
  }
  // --- END OF BLOCK ---

  // Initialize database factory for desktop platforms BEFORE runApp
  try {
    DatabaseHelper.initializeFfi();
  } catch (e) {
    print('Database initialization error: $e');
  }

  // --- ADDED THIS BLOCK for window sizing ---
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      WindowOptions windowOptions = const WindowOptions(
        size: Size(410, 850), // Phone-like dimensions
        center: true,
        title: "Car Marketplace",
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      print('Window configuration failed: $e');
    }
  }
  // --- END OF BLOCK ---
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des Voitures',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const VoitureListScreen(),
    );
  }
}