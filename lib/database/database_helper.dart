import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
        ${DatabaseConstants.columnImage} TEXT
      )
    ''');

    // Create rendezvous table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.rendezvousTable} (
        ${DatabaseConstants.columnRendezvousId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnRendezvousVoitureMatricule} TEXT NOT NULL,
        ${DatabaseConstants.columnRendezvousLieu} TEXT NOT NULL,
        ${DatabaseConstants.columnRendezvousNotes} TEXT,
        ${DatabaseConstants.columnRendezvousDate} TEXT NOT NULL,
        ${DatabaseConstants.columnRendezvousTime} TEXT NOT NULL,
        ${DatabaseConstants.columnRendezvousStatus} TEXT NOT NULL DEFAULT 'pending',
        ${DatabaseConstants.columnRendezvousCreatedAt} TEXT NOT NULL,
        FOREIGN KEY(${DatabaseConstants.columnRendezvousVoitureMatricule}) REFERENCES ${DatabaseConstants.voituresTable}(${DatabaseConstants.columnMatricule}) ON DELETE CASCADE
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

    if (oldVersion < 3) {
      // Create rendezvous table on upgrade to v3
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.rendezvousTable} (
          ${DatabaseConstants.columnRendezvousId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DatabaseConstants.columnRendezvousVoitureMatricule} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousLieu} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousNotes} TEXT,
          ${DatabaseConstants.columnRendezvousDate} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousTime} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousCreatedAt} TEXT NOT NULL,
          FOREIGN KEY(${DatabaseConstants.columnRendezvousVoitureMatricule}) REFERENCES ${DatabaseConstants.voituresTable}(${DatabaseConstants.columnMatricule}) ON DELETE CASCADE
        )
      ''');
      print('Created rendezvous table');
    }

    if (oldVersion < 4) {
      // Ensure rendezvous table exists with correct schema (fix for v4)
      // Drop and recreate the table to ensure correct schema
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.rendezvousTable}');
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.rendezvousTable} (
          ${DatabaseConstants.columnRendezvousId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DatabaseConstants.columnRendezvousVoitureMatricule} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousLieu} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousNotes} TEXT,
          ${DatabaseConstants.columnRendezvousDate} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousTime} TEXT NOT NULL,
          ${DatabaseConstants.columnRendezvousCreatedAt} TEXT NOT NULL,
          FOREIGN KEY(${DatabaseConstants.columnRendezvousVoitureMatricule}) REFERENCES ${DatabaseConstants.voituresTable}(${DatabaseConstants.columnMatricule}) ON DELETE CASCADE
        )
      ''');
      print('Recreated rendezvous table with correct schema (v4)');
    }

    if (oldVersion < 5) {
      // Add status column to rendezvous table (v5)
      try {
        await db.execute(
          'ALTER TABLE ${DatabaseConstants.rendezvousTable} ADD COLUMN ${DatabaseConstants.columnRendezvousStatus} TEXT NOT NULL DEFAULT "pending"'
        );
        print('Added status column to rendezvous table (v5)');
      } catch (e) {
        // If column already exists, recreate table to ensure consistency
        print('Column might exist, recreating table: $e');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.rendezvousTable}');
        await db.execute('''
          CREATE TABLE ${DatabaseConstants.rendezvousTable} (
            ${DatabaseConstants.columnRendezvousId} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DatabaseConstants.columnRendezvousVoitureMatricule} TEXT NOT NULL,
            ${DatabaseConstants.columnRendezvousLieu} TEXT NOT NULL,
            ${DatabaseConstants.columnRendezvousNotes} TEXT,
            ${DatabaseConstants.columnRendezvousDate} TEXT NOT NULL,
            ${DatabaseConstants.columnRendezvousTime} TEXT NOT NULL,
            ${DatabaseConstants.columnRendezvousStatus} TEXT NOT NULL DEFAULT 'pending',
            ${DatabaseConstants.columnRendezvousCreatedAt} TEXT NOT NULL,
            FOREIGN KEY(${DatabaseConstants.columnRendezvousVoitureMatricule}) REFERENCES ${DatabaseConstants.voituresTable}(${DatabaseConstants.columnMatricule}) ON DELETE CASCADE
          )
        ''');
        print('Recreated rendezvous table with status column (v5)');
      }
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

  // Reset database - delete and recreate with latest schema
  Future<void> resetDatabase() async {
    await close();
    await deleteDatabase();
    _database = await _initDB(DatabaseConstants.databaseName);
    print('Database reset and recreated with latest schema');
  }

  // Verify database schema - check if all required columns exist
  Future<bool> verifyRendezvousSchema() async {
    try {
      final db = await database;
      final result = await db.rawQuery("PRAGMA table_info(${DatabaseConstants.rendezvousTable})");

      final columnNames = result.map((row) => row['name'] as String).toSet();
      final requiredColumns = {
        DatabaseConstants.columnRendezvousId,
        DatabaseConstants.columnRendezvousVoitureMatricule,
        DatabaseConstants.columnRendezvousLieu,
        DatabaseConstants.columnRendezvousNotes,
        DatabaseConstants.columnRendezvousDate,
        DatabaseConstants.columnRendezvousTime,
        DatabaseConstants.columnRendezvousStatus,
        DatabaseConstants.columnRendezvousCreatedAt,
      };

      final missingColumns = requiredColumns.difference(columnNames);
      if (missingColumns.isNotEmpty) {
        print('Missing columns in rendezvous table: $missingColumns');
        return false;
      }

      print('Rendezvous table schema verified successfully');
      return true;
    } catch (e) {
      print('Schema verification failed: $e');
      return false;
    }
  }
}
