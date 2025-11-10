import '../models/voiture.dart';
import '../repositories/voiture_repository.dart';

class VoitureService {
  final VoitureRepository _repository = VoitureRepository();

  // Ajouter une nouvelle voiture avec validation
  Future<Voiture> createVoiture({
    required String matricule,
    required String marque,
    required String modele,
    required int annee,
    required double puissance,
    required int cylindres,
    required String carburant,
    required double kilometrage,
    required double prix,
    String? description,  // NEW - Optional
    String? image,        // NEW - Optional (file path)
  }) async {
    // Normalize matricule early
    final normalizedMatricule = matricule.toUpperCase().trim();

    // Validation (use normalized matricule)
    _validateVoiture(
      matricule: normalizedMatricule,
      marque: marque,
      modele: modele,
      annee: annee,
      puissance: puissance,
      cylindres: cylindres,
      carburant: carburant,
      kilometrage: kilometrage,
      prix: prix,
    );

    // Vérifier si le matricule existe déjà (use normalized)
    final existing = await _repository.getVoitureByMatricule(normalizedMatricule);
    if (existing != null) {
      throw Exception('Une voiture avec le matricule $normalizedMatricule existe déjà');
    }

    final voiture = Voiture(
      matricule: normalizedMatricule,
      marque: marque.trim(),
      modele: modele.trim(),
      annee: annee,
      puissance: puissance,
      cylindres: cylindres,
      carburant: carburant.trim(),
      kilometrage: kilometrage,
      prix: prix,
      description: description?.trim(),  // Optional
      image: image?.trim(),              // Optional
    );

    try {
      return await _repository.insert(voiture);
    } catch (e) {
      // Convert common DB errors into friendlier messages
      final msg = e.toString();
      if (msg.contains('UNIQUE') || msg.toLowerCase().contains('unique') || msg.contains('CONSTRAINT')) {
        throw Exception('Une voiture avec le matricule $normalizedMatricule existe déjà');
      }
      // rethrow other errors
      rethrow;
    }
  }

  // Obtenir toutes les voitures
  Future<List<Voiture>> getAllVoitures() async {
    return await _repository.getAllVoitures();
  }

  // Obtenir une voiture par matricule
  Future<Voiture?> getVoitureByMatricule(String matricule) async {
    if (matricule.trim().isEmpty) {
      throw Exception('Le matricule ne peut pas être vide');
    }
    return await _repository.getVoitureByMatricule(matricule.toUpperCase().trim());
  }

  // Rechercher des voitures
  Future<List<Voiture>> searchVoitures(String query) async {
    if (query.trim().isEmpty) {
      return await getAllVoitures();
    }
    return await _repository.searchVoitures(query.trim());
  }

  // Obtenir des voitures par marque
  Future<List<Voiture>> getVoituresByMarque(String marque) async {
    if (marque.trim().isEmpty) {
      throw Exception('La marque ne peut pas être vide');
    }
    return await _repository.getVoituresByMarque(marque.trim());
  }

  // Obtenir des voitures par type de carburant
  Future<List<Voiture>> getVoituresByCarburant(String carburant) async {
    if (carburant.trim().isEmpty) {
      throw Exception('Le type de carburant ne peut pas être vide');
    }
    return await _repository.getVoituresByCarburant(carburant.trim());
  }

  // Filtrer des voitures par prix maximum
  Future<List<Voiture>> getVoituresByPrixMax(double prixMax) async {
    if (prixMax <= 0) {
      throw Exception('Le prix maximum doit être supérieur à 0');
    }
    return await _repository.getVoituresByPrixMax(prixMax);
  }

  // Mettre à jour une voiture
  Future<bool> updateVoiture(Voiture voiture) async {
    _validateVoiture(
      matricule: voiture.matricule,
      marque: voiture.marque,
      modele: voiture.modele,
      annee: voiture.annee,
      puissance: voiture.puissance,
      cylindres: voiture.cylindres,
      carburant: voiture.carburant,
      kilometrage: voiture.kilometrage,
      prix: voiture.prix,
    );

    final result = await _repository.update(voiture);
    return result > 0;
  }

  // Supprimer une voiture
  Future<bool> deleteVoiture(String matricule) async {
    if (matricule.trim().isEmpty) {
      throw Exception('Le matricule ne peut pas être vide');
    }
    
    final result = await _repository.delete(matricule.toUpperCase().trim());
    return result > 0;
  }

  // Supprimer toutes les voitures
  Future<bool> deleteAllVoitures() async {
    final result = await _repository.deleteAll();
    return result > 0;
  }

  // Obtenir le nombre total de voitures
  Future<int> getVoituresCount() async {
    return await _repository.getCount();
  }

  // Obtenir le prix moyen des voitures
  Future<double> getAveragePrix() async {
    return await _repository.getAveragePrix();
  }

  // Validation des données
  void _validateVoiture({
    required String matricule,
    required String marque,
    required String modele,
    required int annee,
    required double puissance,
    required int cylindres,
    required String carburant,
    required double kilometrage,
    required double prix,
  }) {
    if (matricule.trim().isEmpty) {
      throw Exception('Le matricule ne peut pas être vide');
    }

    if (marque.trim().isEmpty) {
      throw Exception('La marque ne peut pas être vide');
    }

    if (modele.trim().isEmpty) {
      throw Exception('Le modèle ne peut pas être vide');
    }

    final currentYear = DateTime.now().year;
    if (annee < 1900 || annee > currentYear + 1) {
      throw Exception('L\'année doit être entre 1900 et ${currentYear + 1}');
    }

    if (puissance <= 0) {
      throw Exception('La puissance doit être supérieure à 0');
    }

    if (cylindres <= 0) {
      throw Exception('Le nombre de cylindres doit être supérieur à 0');
    }

    if (carburant.trim().isEmpty) {
      throw Exception('Le type de carburant ne peut pas être vide');
    }

    if (kilometrage < 0) {
      throw Exception('Le kilométrage ne peut pas être négatif');
    }

    if (prix <= 0) {
      throw Exception('Le prix doit être supérieur à 0');
    }
  }

  // Liste des types de carburant disponibles
  List<String> getCarburantTypes() {
    return ['Essence', 'Diesel', 'Électrique', 'Hybride', 'GPL'];
  }
}
