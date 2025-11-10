import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/geolocation_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'buyer'; // buyer | seller | showroom

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInEmail() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'))
      );
      return;
    }

    setState(() => _isLoading = true);

    // Get current location
    final geoService = GeolocationService();
    final location = await geoService.getCurrentLocation();

    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text, expectedRole: _selectedRole);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      // Show login location
      if (location != null && location.shortLocation.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Logged in from ${location.shortLocation}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // On successful login, navigate to home screen and remove login screen from stack
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }


  Future<void> _useLocalAccount() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compte local'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom affiché')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final auth = Provider.of<AuthService>(context, listen: false);
              await auth.signUpLocal(name);
              Navigator.pop(context, true);
            },
            child: const Text('Créer et utiliser'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecté en mode local')));
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signInWithGoogle(expectedRole: _selectedRole);
    setState(() => _isLoading = false);
    
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signInWithFacebook(expectedRole: _selectedRole);
    setState(() => _isLoading = false);
    
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Se connecter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            const Text('Role:'),
            RadioListTile<String>(
              title: const Text('Buyer'),
              value: 'buyer',
              groupValue: _selectedRole,
              onChanged: (v) => setState(() => _selectedRole = v ?? 'buyer'),
            ),
            RadioListTile<String>(
              title: const Text('Seller'),
              value: 'seller',
              groupValue: _selectedRole,
              onChanged: (v) => setState(() => _selectedRole = v ?? 'seller'),
            ),
            RadioListTile<String>(
              title: const Text('Showroom'),
              value: 'showroom',
              groupValue: _selectedRole,
              onChanged: (v) => setState(() => _selectedRole = v ?? 'showroom'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _useLocalAccount,
              icon: const Icon(Icons.person_outline),
              label: const Text('Utiliser un compte local'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signInEmail,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Se connecter'),
            ),
            const SizedBox(height: 16),
            const Text('Ou se connecter avec:', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithFacebook,
              icon: const Icon(Icons.facebook),
              label: const Text('Facebook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: const Text('Je n\'ai pas de compte — S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
