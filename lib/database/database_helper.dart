import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  // Singleton pattern - only one instance of DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Initialize databaseFactory for desktop platforms
  static void initializeFfi() {
    if (kIsWeb) {
      // For web: sqflite doesn't work, would need different approach
      throw UnsupportedError('Web platform not supported for SQLite');
    } else {
      // For desktop: use sqflite_ffi
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      // For mobile (Android/iOS): default sqflite works automatically
    }
  }

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DatabaseConstants.databaseName);
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Create database tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.voituresTable} (
        ${DatabaseConstants.columnMatricule} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnMarque} TEXT NOT NULL,
        ${DatabaseConstants.columnModele} TEXT NOT NULL,
        ${DatabaseConstants.columnAnnee} INTEGER NOT NULL,
        ${DatabaseConstants.columnPuissance} REAL NOT NULL,
        ${DatabaseConstants.columnCylindres} INTEGER NOT NULL,
        ${DatabaseConstants.columnCarburant} TEXT NOT NULL,
        ${DatabaseConstants.columnKilometrage} REAL NOT NULL,
        ${DatabaseConstants.columnPrix} REAL NOT NULL,
        ${DatabaseConstants.columnDescription} TEXT,
        ${DatabaseConstants.columnImage} TEXT,
        ${DatabaseConstants.columnOwnerId} TEXT,
        ${DatabaseConstants.columnOwnerName} TEXT
      )
    ''');

    // Create users table for local authentication
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.usersTable} (
        ${DatabaseConstants.columnUserId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnUserEmail} TEXT UNIQUE,
        ${DatabaseConstants.columnUserPassword} TEXT,
        ${DatabaseConstants.columnUserDisplayName} TEXT NOT NULL,
        ${DatabaseConstants.columnUserPhoto} TEXT,
        ${DatabaseConstants.columnUserRoles} TEXT NOT NULL DEFAULT 'buyer',
        ${DatabaseConstants.columnUserShowroomLocation} TEXT,
        ${DatabaseConstants.columnUserShowroomBranches} INTEGER,
        ${DatabaseConstants.columnUserPhone} TEXT,
        ${DatabaseConstants.columnUserRating} REAL,
        ${DatabaseConstants.columnUserTotalRatings} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnUserAvatarEmoji} TEXT,
        ${DatabaseConstants.columnUserAvatarColor} INTEGER
      )
    ''');

    // Create ratings table for local seller ratings
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.ratingsTable} (
        ${DatabaseConstants.columnRatingId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnRatingSellerId} TEXT NOT NULL,
        ${DatabaseConstants.columnRatingRaterId} TEXT NOT NULL,
        ${DatabaseConstants.columnRatingValue} INTEGER NOT NULL,
        ${DatabaseConstants.columnRatingComment} TEXT,
        ${DatabaseConstants.columnRatingCreatedAt} INTEGER NOT NULL
      )
    ''');

    // Create events table for showrooms
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.eventsTable} (
        ${DatabaseConstants.columnEventId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnEventShowroomId} TEXT NOT NULL,
        ${DatabaseConstants.columnEventTitle} TEXT NOT NULL,
        ${DatabaseConstants.columnEventDescription} TEXT,
        ${DatabaseConstants.columnEventDate} INTEGER NOT NULL,
        ${DatabaseConstants.columnEventType} TEXT NOT NULL DEFAULT 'general',
        ${DatabaseConstants.columnEventLocation} TEXT,
        ${DatabaseConstants.columnEventCapacity} INTEGER,
        ${DatabaseConstants.columnEventImageGallery} TEXT
      )
    ''');

    // Create event attendees table for RSVP tracking
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.eventAttendeesTable} (
        ${DatabaseConstants.columnAttendeeId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnAttendeeEventId} INTEGER NOT NULL,
        ${DatabaseConstants.columnAttendeeUserId} TEXT NOT NULL,
        ${DatabaseConstants.columnAttendeeStatus} TEXT NOT NULL DEFAULT 'registered',
        ${DatabaseConstants.columnAttendeeRegisteredAt} INTEGER NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnAttendeeEventId}) REFERENCES ${DatabaseConstants.eventsTable}(${DatabaseConstants.columnEventId}) ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.columnAttendeeUserId}) REFERENCES ${DatabaseConstants.usersTable}(${DatabaseConstants.columnUserId}) ON DELETE CASCADE,
        UNIQUE(${DatabaseConstants.columnAttendeeEventId}, ${DatabaseConstants.columnAttendeeUserId})
      )
    ''');

    // Create device sessions table for multi-device management
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_sessions (
        session_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_name TEXT NOT NULL,
        device_type TEXT NOT NULL,
        ip_address TEXT,
        created_at TEXT NOT NULL,
        last_active_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable}(${DatabaseConstants.columnUserId}) ON DELETE CASCADE
      )
    ''');

    print('Database created successfully with new columns!');
  }

  // Handle database upgrades (for future versions)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add new columns to existing table
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.voituresTable} ADD COLUMN ${DatabaseConstants.columnDescription} TEXT'
      );
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.voituresTable} ADD COLUMN ${DatabaseConstants.columnImage} TEXT'
      );
      print('Added description and image columns');
    }

    // Add owner columns in version 3
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.voituresTable} ADD COLUMN ${DatabaseConstants.columnOwnerId} TEXT'
      );
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.voituresTable} ADD COLUMN ${DatabaseConstants.columnOwnerName} TEXT'
      );
      print('Added owner_id and owner_name columns');
    }
    // Add ratings table in version 4
    if (oldVersion < 4) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS ${DatabaseConstants.ratingsTable} ('
        '${DatabaseConstants.columnRatingId} INTEGER PRIMARY KEY AUTOINCREMENT, '
        '${DatabaseConstants.columnRatingSellerId} TEXT NOT NULL, '
        '${DatabaseConstants.columnRatingRaterId} TEXT NOT NULL, '
        '${DatabaseConstants.columnRatingValue} INTEGER NOT NULL, '
        '${DatabaseConstants.columnRatingComment} TEXT, '
        '${DatabaseConstants.columnRatingCreatedAt} INTEGER NOT NULL'
        ')'
      );
      print('Added ratings table');
    }
    // Add users table in version 5
    if (oldVersion < 5) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS ${DatabaseConstants.usersTable} ('
        '${DatabaseConstants.columnUserId} TEXT PRIMARY KEY, '
        '${DatabaseConstants.columnUserEmail} TEXT UNIQUE, '
        '${DatabaseConstants.columnUserPassword} TEXT NOT NULL, '
        '${DatabaseConstants.columnUserDisplayName} TEXT, '
        '${DatabaseConstants.columnUserPhoto} TEXT'
        ')'
      );
      print('Added users table');
    }
    // Add showroom fields and events table in version 6
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.usersTable} ADD COLUMN ${DatabaseConstants.columnUserShowroomLocation} TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.usersTable} ADD COLUMN ${DatabaseConstants.columnUserShowroomBranches} INTEGER');
      } catch (_) {}
      try {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS ${DatabaseConstants.eventsTable} ('
          '${DatabaseConstants.columnEventId} INTEGER PRIMARY KEY AUTOINCREMENT, '
          '${DatabaseConstants.columnEventShowroomId} TEXT NOT NULL, '
          '${DatabaseConstants.columnEventTitle} TEXT NOT NULL, '
          '${DatabaseConstants.columnEventDescription} TEXT, '
          '${DatabaseConstants.columnEventDate} INTEGER NOT NULL'
          ')'
        );
      } catch (_) {}
      print('Added showroom fields and events table');
    }
    
    // Add avatar columns and device_sessions table in version 7
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.usersTable} ADD COLUMN ${DatabaseConstants.columnUserAvatarEmoji} TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.usersTable} ADD COLUMN ${DatabaseConstants.columnUserAvatarColor} INTEGER');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS device_sessions (
            session_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            device_name TEXT NOT NULL,
            device_type TEXT NOT NULL,
            ip_address TEXT,
            created_at TEXT NOT NULL,
            last_active_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.usersTable}(${DatabaseConstants.columnUserId}) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
      print('Added avatar columns and device_sessions table');
    }
    
    // Add enhanced events system in version 8
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.eventsTable} ADD COLUMN ${DatabaseConstants.columnEventType} TEXT NOT NULL DEFAULT "general"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.eventsTable} ADD COLUMN ${DatabaseConstants.columnEventLocation} TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.eventsTable} ADD COLUMN ${DatabaseConstants.columnEventCapacity} INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseConstants.eventsTable} ADD COLUMN ${DatabaseConstants.columnEventImageGallery} TEXT');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${DatabaseConstants.eventAttendeesTable} (
            ${DatabaseConstants.columnAttendeeId} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DatabaseConstants.columnAttendeeEventId} INTEGER NOT NULL,
            ${DatabaseConstants.columnAttendeeUserId} TEXT NOT NULL,
            ${DatabaseConstants.columnAttendeeStatus} TEXT NOT NULL DEFAULT 'registered',
            ${DatabaseConstants.columnAttendeeRegisteredAt} INTEGER NOT NULL,
            FOREIGN KEY (${DatabaseConstants.columnAttendeeEventId}) REFERENCES ${DatabaseConstants.eventsTable}(${DatabaseConstants.columnEventId}) ON DELETE CASCADE,
            FOREIGN KEY (${DatabaseConstants.columnAttendeeUserId}) REFERENCES ${DatabaseConstants.usersTable}(${DatabaseConstants.columnUserId}) ON DELETE CASCADE,
            UNIQUE(${DatabaseConstants.columnAttendeeEventId}, ${DatabaseConstants.columnAttendeeUserId})
          )
        ''');
      } catch (_) {}
      print('Added enhanced events system with RSVP tracking');
    }
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  // Delete database (useful for testing)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
