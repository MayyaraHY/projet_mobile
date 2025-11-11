import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/insurance.dart';

class InsuranceDatabase {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('insurance.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE insurances(
            id TEXT PRIMARY KEY,
            name TEXT,
            logoUrl TEXT,
            price REAL,
            type TEXT,
            coverage TEXT,
            description TEXT,
            contact TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertInsurance(Insurance insurance) async {
    final db = await database;
    await db.insert('insurances', insurance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Insurance>> getInsurances() async {
    final db = await database;
    final result = await db.query('insurances');
    return result.map((e) => Insurance.fromMap(e)).toList();
  }

  Future<void> deleteInsurance(String id) async {
    final db = await database;
    await db.delete('insurances', where: 'id = ?', whereArgs: [id]);
  }
}
