import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/voiture_list_screen.dart';
import 'database/database_helper.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize database factory for desktop platforms BEFORE runApp
  DatabaseHelper.initializeFfi();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Gestion des Voitures',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => auth.isLoading
                  ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                  : (auth.isSignedIn ? const VoitureListScreen() : const LoginScreen()),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const VoitureListScreen(),
            },
          );
        },
      ),
    );
  }
}
