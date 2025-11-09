import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/rendezvous.dart';
import '../utils/constants.dart';

class RendezVousRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<RendezVous> insert(RendezVous r) async {
    final db = await _databaseHelper.database;
    final id = await db.insert(
      DatabaseConstants.rendezvousTable,
      r.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return RendezVous(
      id: id,
      voitureMatricule: r.voitureMatricule,
      lieu: r.lieu,
      notes: r.notes,
      date: r.date,
      time: r.time,
      createdAt: r.createdAt,
    );
  }

  Future<List<RendezVous>> getAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(DatabaseConstants.rendezvousTable, orderBy: '${DatabaseConstants.columnRendezvousCreatedAt} DESC');
    return maps.map((m) => RendezVous.fromMap(m)).toList();
  }

  Future<List<RendezVous>> getByVoiture(String matricule) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.rendezvousTable,
      where: '${DatabaseConstants.columnRendezvousVoitureMatricule} = ?',
      whereArgs: [matricule],
      orderBy: '${DatabaseConstants.columnRendezvousCreatedAt} DESC',
    );
    return maps.map((m) => RendezVous.fromMap(m)).toList();
  }

  Future<int> update(RendezVous rendezvous) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.rendezvousTable,
      rendezvous.toMap()..remove('id'),
      where: '${DatabaseConstants.columnRendezvousId} = ?',
      whereArgs: [rendezvous.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.rendezvousTable,
      where: '${DatabaseConstants.columnRendezvousId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.rendezvousTable);
  }
}

