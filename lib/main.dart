// language: dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/voiture_list_screen.dart';
import 'screens/contract_list_screen.dart';
import 'database/database_helper.dart';
import 'services/bad_word_service.dart';
import 'services/qr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize desktop FFI on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      DatabaseHelper.initializeFfi();
    } catch (e) {
      debugPrint('Database initialization error: $e');
    }
  }

  // Load any runtime RapidAPI key saved in Settings
  try {
    await BadWordService.loadRuntimeApiKey();
    await QrService.loadRuntimeApiKey();
  } catch (_) {}

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),
      // For testing the Contracts module directly set the home to ContractListScreen.
      // Change back to VoitureListScreen() when you're done testing.
      home: const ContractListScreen(),
      routes: {
        '/contracts': (_) => const ContractListScreen(),
      },
    );
  }
}
