import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/voiture.dart';
import '../utils/constants.dart';

class VoitureRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // CREATE - Ajouter une nouvelle voiture
  Future<Voiture> insert(Voiture voiture) async {
    final db = await _databaseHelper.database;
    
    try {
      await db.insert(
        DatabaseConstants.voituresTable,
        voiture.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail, // Fail if matricule already exists
      );
      print('Voiture ajoutée: ${voiture.matricule}');
      return voiture;
    } catch (e) {
      print('Erreur lors de l\'ajout de la voiture: $e');
      rethrow;
    }
  }

  // READ - Obtenir toutes les voitures
  Future<List<Voiture>> getAllVoitures() async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.voituresTable,
      orderBy: '${DatabaseConstants.columnAnnee} DESC', // Order by year, newest first
    );

  return List.generate(maps.length, (i) => Voiture.fromMap(maps[i]));
  }

  // READ - Obtenir une voiture par matricule
  Future<Voiture?> getVoitureByMatricule(String matricule) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.voituresTable,
      where: '${DatabaseConstants.columnMatricule} = ?',
      whereArgs: [matricule],
    );

    if (maps.isNotEmpty) {
      return Voiture.fromMap(maps.first);
    }
    return null;
  }

  // READ - Rechercher des voitures par marque
  Future<List<Voiture>> getVoituresByMarque(String marque) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.voituresTable,
      where: '${DatabaseConstants.columnMarque} LIKE ?',
      whereArgs: ['%$marque%'],
      orderBy: '${DatabaseConstants.columnAnnee} DESC',
    );

    return List.generate(maps.length, (i) => Voiture.fromMap(maps[i]));
  }

  // READ - Rechercher des voitures par type de carburant
  Future<List<Voiture>> getVoituresByCarburant(String carburant) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.voituresTable,
      where: '${DatabaseConstants.columnCarburant} = ?',
      whereArgs: [carburant],
      orderBy: '${DatabaseConstants.columnPrix} ASC',
    );

    return List.generate(maps.length, (i) => Voiture.fromMap(maps[i]));
  }

  // READ - Rechercher des voitures par prix maximum
  Future<List<Voiture>> getVoituresByPrixMax(double prixMax) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.voituresTable,
      where: '${DatabaseConstants.columnPrix} <= ?',
      whereArgs: [prixMax],
      orderBy: '${DatabaseConstants.columnPrix} ASC',
    );

    return List.generate(maps.length, (i) => Voiture.fromMap(maps[i]));
  }

  // READ - Recherche avancée (marque, modèle, ou matricule)
  Future<List<Voiture>> searchVoitures(String query) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.voituresTable,
      where: '''
        ${DatabaseConstants.columnMarque} LIKE ? OR 
        ${DatabaseConstants.columnModele} LIKE ? OR 
        ${DatabaseConstants.columnMatricule} LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: '${DatabaseConstants.columnAnnee} DESC',
    );

    return List.generate(maps.length, (i) => Voiture.fromMap(maps[i]));
  }

  // UPDATE - Mettre à jour une voiture
  Future<int> update(Voiture voiture) async {
    final db = await _databaseHelper.database;
    
    try {
      final result = await db.update(
        DatabaseConstants.voituresTable,
        voiture.toMap(),
        where: '${DatabaseConstants.columnMatricule} = ?',
        whereArgs: [voiture.matricule],
      );
      print('Voiture mise à jour: ${voiture.matricule}');
      return result;
    } catch (e) {
      print('Erreur lors de la mise à jour de la voiture: $e');
      rethrow;
    }
  }

  // DELETE - Supprimer une voiture par matricule
  Future<int> delete(String matricule) async {
    final db = await _databaseHelper.database;
    
    try {
      final result = await db.delete(
        DatabaseConstants.voituresTable,
        where: '${DatabaseConstants.columnMatricule} = ?',
        whereArgs: [matricule],
      );
      print('Voiture supprimée: $matricule');
      return result;
    } catch (e) {
      print('Erreur lors de la suppression de la voiture: $e');
      rethrow;
    }
  }

  // DELETE - Supprimer toutes les voitures
  Future<int> deleteAll() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.voituresTable);
  }

  // COUNT - Compter le nombre total de voitures
  Future<int> getCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.voituresTable}'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // STATISTICS - Obtenir le prix moyen
  Future<double> getAveragePrix() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT AVG(${DatabaseConstants.columnPrix}) as avg FROM ${DatabaseConstants.voituresTable}'
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }
}
