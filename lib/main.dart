import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/insurance_service.dart';
import 'screens/admin/InsuranceListAdmin.dart';
import 'screens/client/insurance_list_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable SQLite FFI on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Crée le service et charge les assurances depuis SQLite
  final insuranceService = InsuranceService();
  await insuranceService.loadFromDB();

  runApp(
    ChangeNotifierProvider(
      create: (_) => insuranceService,
      child: const KarhabtiApp(),
    ),
  );
}

class KarhabtiApp extends StatelessWidget {
  const KarhabtiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karhabti Assurance',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF036074)),
      ),
      home: RoleSelectorScreen(service: context.read<InsuranceService>()),
    );
  }
}

class RoleSelectorScreen extends StatelessWidget {
  final InsuranceService service;

  const RoleSelectorScreen({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Karhabti Assurance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF036074),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, size: 70, color: Color(0xFF036074)),
              const SizedBox(height: 25),
              const Text(
                "Bienvenue sur Karhabti",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF036074),
                ),
              ),
              const SizedBox(height: 45),

              // 🟩 Espace Administrateur
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InsuranceListAdmin(service: service),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                label: const Text(
                  "Espace Administrateur",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF036074),
                  minimumSize: const Size(260, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🟦 Espace Client
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InsuranceListClient(service: service),
                    ),
                  );
                },
                icon: const Icon(Icons.person, color: Colors.white),
                label: const Text(
                  "Espace Client",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  minimumSize: const Size(260, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
