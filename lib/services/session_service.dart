import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class DeviceSession {
  final String sessionId;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isCurrent;

  DeviceSession({
    required this.sessionId,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    this.ipAddress,
    required this.createdAt,
    required this.lastActiveAt,
    this.isCurrent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  factory DeviceSession.fromMap(Map<String, dynamic> map, {bool isCurrent = false}) {
    return DeviceSession(
      sessionId: map['session_id'] as String,
      userId: map['user_id'] as String,
      deviceName: map['device_name'] as String,
      deviceType: map['device_type'] as String,
      ipAddress: map['ip_address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastActiveAt: DateTime.parse(map['last_active_at'] as String),
      isCurrent: isCurrent,
    );
  }

  String getTimeAgo() {
    final difference = DateTime.now().difference(lastActiveAt);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _currentSessionId;

  String? get currentSessionId => _currentSessionId;

  // Get device information
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';
    String deviceType = 'Unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceType = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} ${iosInfo.model}';
        deviceType = 'iOS';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName;
        deviceType = 'Windows';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceName = linuxInfo.name;
        deviceType = 'Linux';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceName = macInfo.computerName;
        deviceType = 'macOS';
      }
    } catch (e) {
      // Fallback
      deviceName = Platform.operatingSystem;
      deviceType = Platform.operatingSystem;
    }

    return {
      'deviceName': deviceName,
      'deviceType': deviceType,
    };
  }

  // Create a new session
  Future<String> createSession(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final deviceInfo = await getDeviceInfo();
    
    final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final session = DeviceSession(
      sessionId: sessionId,
      userId: userId,
      deviceName: deviceInfo['deviceName']!,
      deviceType: deviceInfo['deviceType']!,
      createdAt: now,
      lastActiveAt: now,
    );

    await db.insert('device_sessions', session.toMap());
    _currentSessionId = sessionId;
    
    return sessionId;
  }

  // Update session activity
  Future<void> updateSessionActivity(String sessionId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'device_sessions',
      {'last_active_at': DateTime.now().toIso8601String()},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Get all sessions for a user
  Future<List<DeviceSession>> getUserSessions(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'device_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_active_at DESC',
    );

    return results.map((map) => DeviceSession.fromMap(
      map,
      isCurrent: map['session_id'] == _currentSessionId,
    )).toList();
  }

  // Delete a specific session (logout from device)
  Future<void> deleteSession(String sessionId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'device_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Delete all sessions except current (logout from all other devices)
  Future<void> deleteAllOtherSessions(String userId, String currentSessionId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'device_sessions',
      where: 'user_id = ? AND session_id != ?',
      whereArgs: [userId, currentSessionId],
    );
  }

  // Delete all sessions for user (complete logout)
  Future<void> deleteAllUserSessions(String userId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'device_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    _currentSessionId = null;
  }

  // Clean up old sessions (older than 30 days)
  Future<void> cleanupOldSessions() async {
    final db = await DatabaseHelper.instance.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await db.delete(
      'device_sessions',
      where: 'last_active_at < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }
}
