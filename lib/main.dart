import 'package:flutter/material.dart';
import 'screens/voiture_list_screen.dart';
import 'database/database_helper.dart';

void main() {
  // Initialize database factory for desktop platforms BEFORE runApp
  DatabaseHelper.initializeFfi();
  
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
