import '../database/database_helper.dart';
import '../models/rendez_vous.dart';
import '../utils/constants.dart';

class RendezVousRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Créer un nouveau rendez-vous
  Future<int> createRendezVous(RendezVous rendezVous) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      DatabaseConstants.rendezVousTable,
      rendezVous.toMap(),
    );
  }

  // Récupérer tous les rendez-vous avec jointure sur la table voitures
  Future<List<RendezVous>> getAllRendezVous() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        rdv.${DatabaseConstants.columnId},
        rdv.${DatabaseConstants.columnIdVoiture},
        rdv.${DatabaseConstants.columnIdAcheteur},
        rdv.${DatabaseConstants.columnIdVendeur},
        rdv.${DatabaseConstants.columnDateRendezVous},
        rdv.${DatabaseConstants.columnHeureRendezVous},
        rdv.${DatabaseConstants.columnLieu},
        rdv.${DatabaseConstants.columnStatut},
        rdv.${DatabaseConstants.columnNotes},
        rdv.${DatabaseConstants.columnDateCreation},
        v.${DatabaseConstants.columnMatricule} as voiture_matricule,
        v.${DatabaseConstants.columnMarque} as voiture_marque,
        v.${DatabaseConstants.columnModele} as voiture_modele,
        v.${DatabaseConstants.columnAnnee} as voiture_annee,
        v.${DatabaseConstants.columnPrix} as voiture_prix
      FROM ${DatabaseConstants.rendezVousTable} rdv
      LEFT JOIN ${DatabaseConstants.voituresTable} v 
        ON rdv.${DatabaseConstants.columnIdVoiture} = v.${DatabaseConstants.columnMatricule}
      ORDER BY rdv.${DatabaseConstants.columnDateRendezVous} DESC, 
               rdv.${DatabaseConstants.columnHeureRendezVous} DESC
    ''');

    return result.map((map) => RendezVous.fromMap(map)).toList();
  }

  // Récupérer les rendez-vous par statut
  Future<List<RendezVous>> getRendezVousByStatut(String statut) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        rdv.${DatabaseConstants.columnId},
        rdv.${DatabaseConstants.columnIdVoiture},
        rdv.${DatabaseConstants.columnIdAcheteur},
        rdv.${DatabaseConstants.columnIdVendeur},
        rdv.${DatabaseConstants.columnDateRendezVous},
        rdv.${DatabaseConstants.columnHeureRendezVous},
        rdv.${DatabaseConstants.columnLieu},
        rdv.${DatabaseConstants.columnStatut},
        rdv.${DatabaseConstants.columnNotes},
        rdv.${DatabaseConstants.columnDateCreation},
        v.${DatabaseConstants.columnMatricule} as voiture_matricule,
        v.${DatabaseConstants.columnMarque} as voiture_marque,
        v.${DatabaseConstants.columnModele} as voiture_modele,
        v.${DatabaseConstants.columnAnnee} as voiture_annee,
        v.${DatabaseConstants.columnPrix} as voiture_prix
      FROM ${DatabaseConstants.rendezVousTable} rdv
      LEFT JOIN ${DatabaseConstants.voituresTable} v 
        ON rdv.${DatabaseConstants.columnIdVoiture} = v.${DatabaseConstants.columnMatricule}
      WHERE rdv.${DatabaseConstants.columnStatut} = ?
      ORDER BY rdv.${DatabaseConstants.columnDateRendezVous} DESC, 
               rdv.${DatabaseConstants.columnHeureRendezVous} DESC
    ''', [statut]);

    return result.map((map) => RendezVous.fromMap(map)).toList();
  }

  // Récupérer un rendez-vous par ID
  Future<RendezVous?> getRendezVousById(int id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        rdv.${DatabaseConstants.columnId},
        rdv.${DatabaseConstants.columnIdVoiture},
        rdv.${DatabaseConstants.columnIdAcheteur},
        rdv.${DatabaseConstants.columnIdVendeur},
        rdv.${DatabaseConstants.columnDateRendezVous},
        rdv.${DatabaseConstants.columnHeureRendezVous},
        rdv.${DatabaseConstants.columnLieu},
        rdv.${DatabaseConstants.columnStatut},
        rdv.${DatabaseConstants.columnNotes},
        rdv.${DatabaseConstants.columnDateCreation},
        v.${DatabaseConstants.columnMatricule} as voiture_matricule,
        v.${DatabaseConstants.columnMarque} as voiture_marque,
        v.${DatabaseConstants.columnModele} as voiture_modele,
        v.${DatabaseConstants.columnAnnee} as voiture_annee,
        v.${DatabaseConstants.columnPrix} as voiture_prix
      FROM ${DatabaseConstants.rendezVousTable} rdv
      LEFT JOIN ${DatabaseConstants.voituresTable} v 
        ON rdv.${DatabaseConstants.columnIdVoiture} = v.${DatabaseConstants.columnMatricule}
      WHERE rdv.${DatabaseConstants.columnId} = ?
    ''', [id]);

    if (result.isNotEmpty) {
      return RendezVous.fromMap(result.first);
    }
    return null;
  }

  // Récupérer les rendez-vous pour une voiture spécifique
  Future<List<RendezVous>> getRendezVousByVoiture(String matriculeVoiture) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        rdv.${DatabaseConstants.columnId},
        rdv.${DatabaseConstants.columnIdVoiture},
        rdv.${DatabaseConstants.columnIdAcheteur},
        rdv.${DatabaseConstants.columnIdVendeur},
        rdv.${DatabaseConstants.columnDateRendezVous},
        rdv.${DatabaseConstants.columnHeureRendezVous},
        rdv.${DatabaseConstants.columnLieu},
        rdv.${DatabaseConstants.columnStatut},
        rdv.${DatabaseConstants.columnNotes},
        rdv.${DatabaseConstants.columnDateCreation},
        v.${DatabaseConstants.columnMatricule} as voiture_matricule,
        v.${DatabaseConstants.columnMarque} as voiture_marque,
        v.${DatabaseConstants.columnModele} as voiture_modele,
        v.${DatabaseConstants.columnAnnee} as voiture_annee,
        v.${DatabaseConstants.columnPrix} as voiture_prix
      FROM ${DatabaseConstants.rendezVousTable} rdv
      LEFT JOIN ${DatabaseConstants.voituresTable} v 
        ON rdv.${DatabaseConstants.columnIdVoiture} = v.${DatabaseConstants.columnMatricule}
      WHERE rdv.${DatabaseConstants.columnIdVoiture} = ?
      ORDER BY rdv.${DatabaseConstants.columnDateRendezVous} DESC, 
               rdv.${DatabaseConstants.columnHeureRendezVous} DESC
    ''', [matriculeVoiture]);

    return result.map((map) => RendezVous.fromMap(map)).toList();
  }

  // Mettre à jour un rendez-vous
  Future<int> updateRendezVous(RendezVous rendezVous) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.rendezVousTable,
      rendezVous.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [rendezVous.id],
    );
  }

  // Mettre à jour le statut d'un rendez-vous
  Future<int> updateStatutRendezVous(int id, String nouveauStatut) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.rendezVousTable,
      {DatabaseConstants.columnStatut: nouveauStatut},
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Supprimer un rendez-vous
  Future<int> deleteRendezVous(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.rendezVousTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Compter les rendez-vous par statut
  Future<Map<String, int>> getRendezVousCountByStatut() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT ${DatabaseConstants.columnStatut}, COUNT(*) as count
      FROM ${DatabaseConstants.rendezVousTable}
      GROUP BY ${DatabaseConstants.columnStatut}
    ''');

    Map<String, int> counts = {};
    for (var row in result) {
      counts[row[DatabaseConstants.columnStatut]] = row['count'];
    }

    return counts;
  }
}
