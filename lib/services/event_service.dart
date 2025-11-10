import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../models/event.dart';
import '../models/event_attendee.dart';

class EventService {
  final dbHelper = DatabaseHelper.instance;

  // ===== Event CRUD Operations =====

  Future<int> addEvent(ShowroomEvent event) async {
    final db = await dbHelper.database;
    return await db.insert(DatabaseConstants.eventsTable, event.toMap());
  }

  Future<void> updateEvent(ShowroomEvent event) async {
    final db = await dbHelper.database;
    await db.update(
      DatabaseConstants.eventsTable,
      event.toMap(),
      where: '${DatabaseConstants.columnEventId} = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(int eventId) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseConstants.eventsTable,
      where: '${DatabaseConstants.columnEventId} = ?',
      whereArgs: [eventId],
    );
  }

  Future<List<ShowroomEvent>> getEventsForShowroom(String showroomId) async {
    final db = await dbHelper.database;
    
    // Join with attendees to get count
    final rows = await db.rawQuery('''
      SELECT e.*, 
             COUNT(CASE WHEN a.${DatabaseConstants.columnAttendeeStatus} = 'registered' THEN 1 END) as attendee_count
      FROM ${DatabaseConstants.eventsTable} e
      LEFT JOIN ${DatabaseConstants.eventAttendeesTable} a 
        ON e.${DatabaseConstants.columnEventId} = a.${DatabaseConstants.columnAttendeeEventId}
      WHERE e.${DatabaseConstants.columnEventShowroomId} = ?
      GROUP BY e.${DatabaseConstants.columnEventId}
      ORDER BY e.${DatabaseConstants.columnEventDate} DESC
    ''', [showroomId]);
    
    return rows.map((r) => ShowroomEvent.fromMap(r)).toList();
  }

  Future<ShowroomEvent?> getEventById(int eventId) async {
    final db = await dbHelper.database;
    
    final rows = await db.rawQuery('''
      SELECT e.*, 
             COUNT(CASE WHEN a.${DatabaseConstants.columnAttendeeStatus} = 'registered' THEN 1 END) as attendee_count
      FROM ${DatabaseConstants.eventsTable} e
      LEFT JOIN ${DatabaseConstants.eventAttendeesTable} a 
        ON e.${DatabaseConstants.columnEventId} = a.${DatabaseConstants.columnAttendeeEventId}
      WHERE e.${DatabaseConstants.columnEventId} = ?
      GROUP BY e.${DatabaseConstants.columnEventId}
    ''', [eventId]);
    
    if (rows.isEmpty) return null;
    return ShowroomEvent.fromMap(rows.first);
  }

  Future<List<ShowroomEvent>> getAllUpcomingEvents() async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final rows = await db.rawQuery('''
      SELECT e.*, 
             COUNT(CASE WHEN a.${DatabaseConstants.columnAttendeeStatus} = 'registered' THEN 1 END) as attendee_count
      FROM ${DatabaseConstants.eventsTable} e
      LEFT JOIN ${DatabaseConstants.eventAttendeesTable} a 
        ON e.${DatabaseConstants.columnEventId} = a.${DatabaseConstants.columnAttendeeEventId}
      WHERE e.${DatabaseConstants.columnEventDate} >= ?
      GROUP BY e.${DatabaseConstants.columnEventId}
      ORDER BY e.${DatabaseConstants.columnEventDate} ASC
    ''', [now]);
    
    return rows.map((r) => ShowroomEvent.fromMap(r)).toList();
  }

  // ===== RSVP Operations =====

  Future<bool> registerForEvent(int eventId, String userId) async {
    final db = await dbHelper.database;
    
    // Check if event is full
    final event = await getEventById(eventId);
    if (event == null) return false;
    if (event.isFull) return false;
    
    // Check if already registered
    final existing = await isUserRegistered(eventId, userId);
    if (existing) return false;
    
    try {
      await db.insert(
        DatabaseConstants.eventAttendeesTable,
        {
          DatabaseConstants.columnAttendeeEventId: eventId,
          DatabaseConstants.columnAttendeeUserId: userId,
          DatabaseConstants.columnAttendeeStatus: 'registered',
          DatabaseConstants.columnAttendeeRegisteredAt: DateTime.now().millisecondsSinceEpoch,
        },
      );
      return true;
    } catch (e) {
      print('Error registering for event: $e');
      return false;
    }
  }

  Future<bool> cancelRegistration(int eventId, String userId) async {
    final db = await dbHelper.database;
    
    final result = await db.update(
      DatabaseConstants.eventAttendeesTable,
      {DatabaseConstants.columnAttendeeStatus: 'cancelled'},
      where: '${DatabaseConstants.columnAttendeeEventId} = ? AND ${DatabaseConstants.columnAttendeeUserId} = ?',
      whereArgs: [eventId, userId],
    );
    
    return result > 0;
  }

  Future<bool> markAsAttended(int eventId, String userId) async {
    final db = await dbHelper.database;
    
    final result = await db.update(
      DatabaseConstants.eventAttendeesTable,
      {DatabaseConstants.columnAttendeeStatus: 'attended'},
      where: '${DatabaseConstants.columnAttendeeEventId} = ? AND ${DatabaseConstants.columnAttendeeUserId} = ?',
      whereArgs: [eventId, userId],
    );
    
    return result > 0;
  }

  Future<bool> isUserRegistered(int eventId, String userId) async {
    final db = await dbHelper.database;
    
    final rows = await db.query(
      DatabaseConstants.eventAttendeesTable,
      where: '${DatabaseConstants.columnAttendeeEventId} = ? AND ${DatabaseConstants.columnAttendeeUserId} = ? AND ${DatabaseConstants.columnAttendeeStatus} = ?',
      whereArgs: [eventId, userId, 'registered'],
    );
    
    return rows.isNotEmpty;
  }

  Future<List<EventAttendee>> getEventAttendees(int eventId, {String? status}) async {
    final db = await dbHelper.database;
    
    // Join with users table to get user info
    String whereClause = 'a.${DatabaseConstants.columnAttendeeEventId} = ?';
    List<dynamic> whereArgs = [eventId];
    
    if (status != null) {
      whereClause += ' AND a.${DatabaseConstants.columnAttendeeStatus} = ?';
      whereArgs.add(status);
    }
    
    final rows = await db.rawQuery('''
      SELECT a.*, 
             u.${DatabaseConstants.columnUserDisplayName} as display_name,
             u.${DatabaseConstants.columnUserPhoto} as photo_path,
             u.${DatabaseConstants.columnUserAvatarEmoji} as avatar_emoji,
             u.${DatabaseConstants.columnUserAvatarColor} as avatar_color
      FROM ${DatabaseConstants.eventAttendeesTable} a
      LEFT JOIN ${DatabaseConstants.usersTable} u 
        ON a.${DatabaseConstants.columnAttendeeUserId} = u.${DatabaseConstants.columnUserId}
      WHERE $whereClause
      ORDER BY a.${DatabaseConstants.columnAttendeeRegisteredAt} ASC
    ''', whereArgs);
    
    return rows.map((r) => EventAttendee.fromMap(r)).toList();
  }

  Future<List<ShowroomEvent>> getUserRegisteredEvents(String userId) async {
    final db = await dbHelper.database;
    
    final rows = await db.rawQuery('''
      SELECT e.*, 
             COUNT(CASE WHEN a2.${DatabaseConstants.columnAttendeeStatus} = 'registered' THEN 1 END) as attendee_count
      FROM ${DatabaseConstants.eventsTable} e
      INNER JOIN ${DatabaseConstants.eventAttendeesTable} a 
        ON e.${DatabaseConstants.columnEventId} = a.${DatabaseConstants.columnAttendeeEventId}
      LEFT JOIN ${DatabaseConstants.eventAttendeesTable} a2 
        ON e.${DatabaseConstants.columnEventId} = a2.${DatabaseConstants.columnAttendeeEventId}
      WHERE a.${DatabaseConstants.columnAttendeeUserId} = ? 
        AND a.${DatabaseConstants.columnAttendeeStatus} = 'registered'
      GROUP BY e.${DatabaseConstants.columnEventId}
      ORDER BY e.${DatabaseConstants.columnEventDate} ASC
    ''', [userId]);
    
    return rows.map((r) => ShowroomEvent.fromMap(r)).toList();
  }

  // Get event statistics
  Future<Map<String, int>> getEventStats(int eventId) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(CASE WHEN ${DatabaseConstants.columnAttendeeStatus} = 'registered' THEN 1 END) as registered,
        COUNT(CASE WHEN ${DatabaseConstants.columnAttendeeStatus} = 'attended' THEN 1 END) as attended,
        COUNT(CASE WHEN ${DatabaseConstants.columnAttendeeStatus} = 'cancelled' THEN 1 END) as cancelled
      FROM ${DatabaseConstants.eventAttendeesTable}
      WHERE ${DatabaseConstants.columnAttendeeEventId} = ?
    ''', [eventId]);
    
    if (result.isEmpty) {
      return {'registered': 0, 'attended': 0, 'cancelled': 0};
    }
    
    final row = result.first;
    return {
      'registered': row['registered'] as int,
      'attended': row['attended'] as int,
      'cancelled': row['cancelled'] as int,
    };
  }
}
