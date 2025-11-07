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
        ${DatabaseConstants.columnImage} TEXT
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
