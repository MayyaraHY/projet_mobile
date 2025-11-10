// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\repositories\contract_repository.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/contract.dart';

class ContractRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<int> createContract(Contract contract) async {
    final db = await _db;
    final data = contract.toMap();
    data.remove('id');
    data['createdAt'] = DateTime.now().toIso8601String();
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('contracts', data);
  }

  Future<Contract?> getContractById(int id) async {
    final db = await _db;
    final maps = await db.query('contracts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Contract.fromMap(maps.first);
    return null;
  }

  Future<List<Contract>> getAllContracts() async {
    final db = await _db;
    final maps = await db.query('contracts', orderBy: 'createdAt DESC');
    return maps.map((m) => Contract.fromMap(m)).toList();
  }

  Future<int> updateContract(Contract contract) async {
    final db = await _db;
    final data = contract.toMap();
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('contracts', data, where: 'id = ?', whereArgs: [contract.id]);
  }

  Future<int> deleteContract(int id) async {
    final db = await _db;
    return await db.delete('contracts', where: 'id = ?', whereArgs: [id]);
  }

  // Get contracts that reference a car by matricule (search inside carSnapshot JSON or carId if applicable)
  Future<List<Contract>> getContractsByMatricule(String matricule) async {
    final db = await _db;
    // carSnapshot is stored as JSON string; look for the matricule inside it
    final pattern = '%"matricule":"$matricule"%';
    final maps = await db.rawQuery(
      'SELECT * FROM contracts WHERE carSnapshot LIKE ? OR carId = ? ORDER BY createdAt DESC',
      [pattern, int.tryParse(matricule) ?? -1],
    );
    return maps.map((m) => Contract.fromMap(m)).toList();
  }
}
