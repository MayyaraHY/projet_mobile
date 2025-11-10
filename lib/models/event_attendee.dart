class EventAttendee {
  final int? id;
  final int eventId;
  final String userId;
  final String status; // 'registered', 'attended', 'cancelled'
  final DateTime registeredAt;
  
  // Additional user info (joined from users table)
  final String? userName;
  final String? userPhoto;
  final String? userAvatarEmoji;
  final int? userAvatarColor;

  EventAttendee({
    this.id,
    required this.eventId,
    required this.userId,
    this.status = 'registered',
    required this.registeredAt,
    this.userName,
    this.userPhoto,
    this.userAvatarEmoji,
    this.userAvatarColor,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'event_id': eventId,
        'user_id': userId,
        'status': status,
        'registered_at': registeredAt.millisecondsSinceEpoch,
      };

  factory EventAttendee.fromMap(Map<String, dynamic> m) => EventAttendee(
        id: m['id'] as int?,
        eventId: m['event_id'] as int,
        userId: m['user_id'] as String,
        status: m['status'] as String? ?? 'registered',
        registeredAt: DateTime.fromMillisecondsSinceEpoch(m['registered_at'] as int),
        userName: m['display_name'] as String?,
        userPhoto: m['photo_path'] as String?,
        userAvatarEmoji: m['avatar_emoji'] as String?,
        userAvatarColor: m['avatar_color'] as int?,
      );

  bool get isRegistered => status == 'registered';
  bool get hasAttended => status == 'attended';
  bool get isCancelled => status == 'cancelled';
}
