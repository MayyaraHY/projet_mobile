import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({Key? key, required this.password}) : super(key: key);

  PasswordStrength _calculateStrength() {
    if (password.isEmpty) return PasswordStrength.none;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    
    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    
    // Penalize common patterns
    if (password.toLowerCase().contains('password') || 
        password.toLowerCase().contains('123456') ||
        password == password.toLowerCase() ||
        password == password.toUpperCase()) {
      score = (score * 0.7).round();
    }
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength.value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strength.label,
              style: TextStyle(
                color: strength.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildRequirements(),
        ],
      ],
    );
  }

  Widget _buildRequirements() {
    final has8Chars = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement('At least 8 characters', has8Chars),
        _buildRequirement('Uppercase letter', hasUppercase),
        _buildRequirement('Lowercase letter', hasLowercase),
        _buildRequirement('Number', hasNumber),
        _buildRequirement('Special character', hasSpecial),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

enum PasswordStrength {
  none(0.0, Colors.grey, 'None'),
  weak(0.25, Colors.red, 'Weak'),
  medium(0.5, Colors.orange, 'Medium'),
  strong(0.75, Colors.blue, 'Strong'),
  veryStrong(1.0, Colors.green, 'Very Strong');

  final double value;
  final Color color;
  final String label;

  const PasswordStrength(this.value, this.color, this.label);
}
