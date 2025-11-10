import 'package:flutter/material.dart';

class AvatarPickerScreen extends StatelessWidget {
  const AvatarPickerScreen({Key? key}) : super(key: key);

  static const List<String> _avatarEmojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆',
    '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌',
    '🐞', '🐢', '🐙', '🦑', '🦐', '🐠', '🐡', '🦈', '🐳', '🐬',
    '🦭', '🐊', '🦎', '🦖', '🦕', '🦩', '🦚', '🦜', '🦢', '🦤',
    '😀', '😃', '😄', '😁', '😆', '😊', '😎', '🤓', '🥳', '🤠',
    '🤡', '🤖', '👻', '👽', '👾', '🎃', '🎅', '🧙', '🧚', '🧛',
    '🌟', '⭐', '✨', '🌈', '🔥', '💎', '👑', '🎨', '🎭', '🎪',
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸',
    '🥊', '🎯', '🎮', '🎲', '🎰', '🎳', '🎺', '🎸', '🎻', '🎹',
    '🍕', '🍔', '🍟', '🌭', '🍿', '🧁', '🍰', '🎂', '🍪', '🍩',
    '🍦', '🍨', '🍧', '🍫', '🍬', '🍭', '🍮', '🍯', '🍼', '☕',
    '🌮', '🌯', '🥙', '🥗', '🥪', '🍱', '🍣', '🍤', '🍙', '🍘',
    '🚀', '🛸', '🚁', '✈️', '🚂', '🚗', '🚕', '🚙', '🚌', '🚎',
    '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚', '🚛', '🚜', '🏍️',
  ];

  static const List<Color> _avatarColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFF97316), // Orange
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFF84CC16), // Lime
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Avatar'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select an emoji and color for your avatar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _avatarEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _avatarEmojis[index];
                final color = _avatarColors[index % _avatarColors.length];
                
                return InkWell(
                  onTap: () => _showColorPicker(context, emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, String emoji) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Background Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _avatarColors.length,
            itemBuilder: (context, index) {
              final color = _avatarColors[index];
              
              return InkWell(
                onTap: () {
                  Navigator.pop(context); // Close color picker
                  Navigator.pop(context, {
                    'emoji': emoji,
                    'color': color.value,
                  }); // Return selected avatar
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
