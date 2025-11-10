import 'dart:math';
import 'package:flutter/material.dart';

class AvatarGenerator {
  static final Random _random = Random();
  
  // Fun characters and animals
  static const List<String> _avatarEmojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆',
    '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌',
    '🐞', '🐢', '🐙', '🦑', '🦐', '🐠', '🐡', '🦈', '🐳', '🐬',
    '🦭', '🐊', '🦎', '🦖', '🦕', '🦩', '🦚', '🦜', '🦢', '🦤',
    '😀', '😃', '😄', '😁', '😆', '😊', '😎', '🤓', '🥳', '🤠',
    '🤡', '🤖', '👻', '👽', '👾', '🎃', '🎅', '🧙', '🧚', '🧛',
    '🌟', '⭐', '✨', '🌈', '🔥', '💎', '👑', '🎨', '🎭', '🎪',
  ];
  
  // Generate a unique avatar based on user's name or email
  static Widget generateAvatar({
    required String seed,
    double size = 100,
    String? emoji,
    int? color,
  }) {
    final bgColor = color != null ? Color(color) : _generateColorFromSeed(seed);
    final displayEmoji = emoji ?? _getEmojiFromSeed(seed);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withOpacity(0.3),
            bgColor.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: bgColor.withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayEmoji,
          style: TextStyle(
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
  
  // Generate geometric pattern avatar
  static Widget generatePatternAvatar({
    required String seed,
    double size = 100,
  }) {
    final color = _generateColorFromSeed(seed);
    final emoji = _getEmojiFromSeed(seed);
    final pattern = _getPatternFromSeed(seed);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _PatternPainter(
              color: color,
              pattern: pattern,
            ),
          ),
          Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: size * 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Get emoji from seed
  static String _getEmojiFromSeed(String seed) {
    final hash = seed.hashCode.abs();
    return _avatarEmojis[hash % _avatarEmojis.length];
  }
  
  // Generate consistent color from seed
  static Color _generateColorFromSeed(String seed) {
    final hash = seed.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF97316), // Orange
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF84CC16), // Lime
    ];
    
    return colors[hash.abs() % colors.length];
  }
  
  static int _getPatternFromSeed(String seed) {
    return seed.hashCode.abs() % 5;
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  final int pattern;
  
  _PatternPainter({required this.color, required this.pattern});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    switch (pattern) {
      case 0:
        _drawCircles(canvas, size, paint);
        break;
      case 1:
        _drawTriangles(canvas, size, paint);
        break;
      case 2:
        _drawSquares(canvas, size, paint);
        break;
      case 3:
        _drawWaves(canvas, size, paint);
        break;
      case 4:
        _drawDiamonds(canvas, size, paint);
        break;
    }
  }
  
  void _drawCircles(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.15, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), size.width * 0.1, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), size.width * 0.1, paint);
  }
  
  void _drawTriangles(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    path.moveTo(size.width / 2, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.6);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawSquares(Canvas canvas, Size size, Paint paint) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.4,
        height: size.width * 0.4,
      ),
      paint,
    );
  }
  
  void _drawWaves(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.3,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.5,
    );
    canvas.drawPath(path, paint..strokeWidth = size.width * 0.1..style = PaintingStyle.stroke);
  }
  
  void _drawDiamonds(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    path.moveTo(size.width / 2, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height / 2);
    path.lineTo(size.width / 2, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height / 2);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
