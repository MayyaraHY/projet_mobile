import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../widgets/password_strength_indicator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showSuccessAnimation = false;
  String _selectedRole = 'buyer'; // 'buyer' | 'seller' | 'showroom'
  final _showroomLocationCtrl = TextEditingController();
  final _showroomBranchesCtrl = TextEditingController();
  List<TextEditingController> _branchLocationControllers = [];
  int _numberOfBranches = 0;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _showroomLocationCtrl.dispose();
    _showroomBranchesCtrl.dispose();
    for (var controller in _branchLocationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateBranchCount(String value) {
    final newCount = int.tryParse(value) ?? 0;
    if (newCount != _numberOfBranches && newCount >= 0 && newCount <= 50) {
      setState(() {
        // Dispose old controllers
        for (var controller in _branchLocationControllers) {
          controller.dispose();
        }
        
        // Create new controllers
        _numberOfBranches = newCount;
        _branchLocationControllers = List.generate(
          newCount,
          (index) => TextEditingController(),
        );
      });
    }
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for special character
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }
    
    return null; // Password is valid
  }

  Future<void> _signUp() async {
    // Validate password first
    final passwordError = _validatePassword(_passCtrl.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError), duration: const Duration(seconds: 4))
      );
      return;
    }
    
    if (_selectedRole != 'showroom') {
      // particular: buyer or seller
      if (_selectedRole == 'seller' && _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is required for sellers'))
        );
        return;
      }
    } else {
      // showroom: require branches and locations for each branch
      if (_showroomBranchesCtrl.text.trim().isEmpty || int.tryParse(_showroomBranchesCtrl.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number of branches is required and must be a number'))
        );
        return;
      }
      
      final branches = int.parse(_showroomBranchesCtrl.text.trim());
      if (branches <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number of branches must be at least 1'))
        );
        return;
      }
      
      // Check that all branch locations are filled
      for (int i = 0; i < _branchLocationControllers.length; i++) {
        if (_branchLocationControllers[i].text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter location for Branch ${i + 1}'))
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    // build roles
    UserRoles roles;
    String? showroomLocation;
    int? showroomBranches;
    if (_selectedRole == 'buyer') {
      roles = UserRoles(isBuyer: true, isSeller: false, isShowroom: false);
    } else if (_selectedRole == 'seller') {
      roles = UserRoles(isBuyer: false, isSeller: true, isShowroom: false);
    } else {
      roles = UserRoles(isBuyer: false, isSeller: false, isShowroom: true);
      // Combine all branch locations into a single string separated by semicolons
      final locations = _branchLocationControllers
          .map((controller) => controller.text.trim())
          .join(';');
      showroomLocation = locations;
      showroomBranches = int.tryParse(_showroomBranchesCtrl.text.trim());
    }

    final err = await auth.signUpWithEmail(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
      roles: roles,
      phoneNumber: _selectedRole == 'seller' ? _phoneCtrl.text.trim() : null,
      showroomLocation: showroomLocation,
      showroomBranches: showroomBranches,
    );
    
    setState(() => _isLoading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      // Show success animation
      setState(() => _showSuccessAnimation = true);
      _animationController.forward();
      
      // Wait for animation to complete, then navigate
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S\'inscrire')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Account type:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Buyer (particular)'),
              value: 'buyer',
              groupValue: _selectedRole,
              onChanged: (v) => setState(() => _selectedRole = v ?? 'buyer'),
            ),
            RadioListTile<String>(
              title: const Text('Seller (particular)'),
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
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              onChanged: (value) => setState(() {}), // Trigger rebuild for strength indicator
            ),
            const SizedBox(height: 8),
            PasswordStrengthIndicator(password: _passCtrl.text),
            if (_selectedRole == 'seller') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
            if (_selectedRole == 'showroom') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _showroomBranchesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Number of Branches',
                  prefixIcon: Icon(Icons.home_work),
                  helperText: 'Enter number of branches (max 50)',
                ),
                keyboardType: TextInputType.number,
                onChanged: _updateBranchCount,
              ),
              const SizedBox(height: 8),
              if (_numberOfBranches > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Branch Locations:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_numberOfBranches, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _branchLocationControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Branch ${index + 1} Location',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                  );
                }),
              ],
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signUp,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: const Text('Create Account'),
            ),
          ],
        ),
          ),
          // Success Animation Overlay
          if (_showSuccessAnimation)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
                  child: Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Account Created!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Welcome aboard!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
