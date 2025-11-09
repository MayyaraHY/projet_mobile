import '../models/rendezvous.dart';
import '../repositories/rendezvous_repository.dart';
import '../database/database_helper.dart';

class RendezVousService {
  final RendezVousRepository _repo = RendezVousRepository();

  // Méthode en français - compatibilité
  Future<RendezVous> creerRendezVous({
    required String matriculeVoiture,
    required String dateRendezVous,
    required String heureRendezVous,
    required String lieu,
    String? notes,
  }) async {
    return await createRendezVous(
      voitureMatricule: matriculeVoiture,
      date: dateRendezVous,
      time: heureRendezVous,
      lieu: lieu,
      notes: notes,
    );
  }

  Future<RendezVous> createRendezVous({
    required String voitureMatricule,
    required String date,
    required String time,
    required String lieu,
    String? notes,
  }) async {
    // Basic validation
    if (voitureMatricule.trim().isEmpty) throw Exception('Voiture matricule required');
    if (lieu.trim().isEmpty) throw Exception('Lieu requis');

    final nowIso = DateTime.now().toIso8601String();

    final r = RendezVous(
      voitureMatricule: voitureMatricule.trim(),
      lieu: lieu.trim(),
      notes: notes?.trim(),
      date: date,
      time: time,
      createdAt: nowIso,
    );

    try {
      // Verify schema before attempting insert
      final schemaValid = await DatabaseHelper.instance.verifyRendezvousSchema();
      if (!schemaValid) {
        print('Invalid schema detected, resetting database...');
        await DatabaseHelper.instance.resetDatabase();
      }

      return await _repo.insert(r);
    } catch (e) {
      // If we get a schema error, try to reset the database
      if (e.toString().contains('has no column named')) {
        print('Database schema error detected, attempting to reset database...');
        try {
          await DatabaseHelper.instance.resetDatabase();
          print('Database reset successful, retrying insert...');
          return await _repo.insert(r);
        } catch (resetError) {
          print('Database reset failed: $resetError');
          throw Exception('Database schema error. Please restart the app. Original error: $e');
        }
      }
      rethrow;
    }
  }

  Future<List<RendezVous>> getByVoiture(String matricule) async {
    return await _repo.getByVoiture(matricule);
  }

  Future<List<RendezVous>> getAll() async {
    return await _repo.getAll();
  }

  Future<bool> updateStatus(int id, String newStatus) async {
    // Validate status
    if (!RendezVous.validStatuses.contains(newStatus)) {
      throw Exception('Invalid status: $newStatus');
    }

    try {
      // Get current rendezvous
      final allRendezVous = await _repo.getAll();
      final current = allRendezVous.firstWhere((rdv) => rdv.id == id);

      // Create updated version
      final updated = current.copyWith(status: newStatus);

      // Update in database
      final result = await _repo.update(updated);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  Future<bool> update(RendezVous rendezvous) async {
    try {
      final result = await _repo.update(rendezvous);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update rendezvous: $e');
    }
  }

  Future<bool> delete(int id) async {
    final r = await _repo.delete(id);
    return r > 0;
  }
}
