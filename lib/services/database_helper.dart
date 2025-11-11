import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/insurance.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('insurance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE insurances(
        id TEXT PRIMARY KEY,
        name TEXT,
        logoUrl TEXT,
        pricePerYear REAL,
        type TEXT,
        coverage TEXT,
        description TEXT,
        contact TEXT
      )
    ''');
  }

  Future<void> insertInsurance(Insurance insurance) async {
    final db = await database;
    await db.insert('insurances', insurance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Insurance>> getAllInsurances() async {
    final db = await database;
    final maps = await db.query('insurances');

    return List.generate(maps.length, (i) => Insurance.fromMap(maps[i]));
  }

  Future<void> updateInsurance(Insurance insurance) async {
    final db = await database;
    await db.update('insurances', insurance.toMap(),
        where: 'id = ?', whereArgs: [insurance.id]);
  }

  Future<void> deleteInsurance(String id) async {
    final db = await database;
    await db.delete('insurances', where: 'id = ?', whereArgs: [id]);
  }
}
