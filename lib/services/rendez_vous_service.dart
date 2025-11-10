import '../models/rendez_vous.dart';
import '../repositories/rendez_vous_repository.dart';

class RendezVousService {
  final RendezVousRepository _repository = RendezVousRepository();

  // IDs statiques pour les utilisateurs (en attendant la table users)
  static const int DEFAULT_ACHETEUR_ID = 1;
  static const int DEFAULT_VENDEUR_ID = 2;

  // Créer un nouveau rendez-vous
  Future<int> creerRendezVous({
    required String matriculeVoiture,
    required String dateRendezVous,
    required String heureRendezVous,
    required String lieu,
    String? notes,
    int? idAcheteur,
    int? idVendeur,
  }) async {
    try {
      final rendezVous = RendezVous(
        idVoiture: matriculeVoiture,
        idAcheteur: idAcheteur ?? DEFAULT_ACHETEUR_ID,
        idVendeur: idVendeur ?? DEFAULT_VENDEUR_ID,
        dateRendezVous: dateRendezVous,
        heureRendezVous: heureRendezVous,
        lieu: lieu,
        statut: 'en_attente',
        notes: notes,
      );

      return await _repository.createRendezVous(rendezVous);
    } catch (e) {
      throw Exception('Erreur lors de la création du rendez-vous: $e');
    }
  }

  // Récupérer tous les rendez-vous
  Future<List<RendezVous>> obtenirTousLesRendezVous() async {
    try {
      return await _repository.getAllRendezVous();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rendez-vous: $e');
    }
  }

  // Récupérer les rendez-vous par statut
  Future<List<RendezVous>> obtenirRendezVousParStatut(String statut) async {
    try {
      return await _repository.getRendezVousByStatut(statut);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rendez-vous par statut: $e');
    }
  }

  // Récupérer un rendez-vous par ID
  Future<RendezVous?> obtenirRendezVousParId(int id) async {
    try {
      return await _repository.getRendezVousById(id);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rendez-vous: $e');
    }
  }

  // Récupérer les rendez-vous pour une voiture
  Future<List<RendezVous>> obtenirRendezVousParVoiture(String matricule) async {
    try {
      return await _repository.getRendezVousByVoiture(matricule);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rendez-vous pour la voiture: $e');
    }
  }

  // Mettre à jour un rendez-vous
  Future<void> modifierRendezVous(RendezVous rendezVous) async {
    try {
      await _repository.updateRendezVous(rendezVous);
    } catch (e) {
      throw Exception('Erreur lors de la modification du rendez-vous: $e');
    }
  }

  // Confirmer un rendez-vous
  Future<void> confirmerRendezVous(int id) async {
    try {
      await _repository.updateStatutRendezVous(id, 'confirme');
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du rendez-vous: $e');
    }
  }

  // Annuler un rendez-vous
  Future<void> annulerRendezVous(int id) async {
    try {
      await _repository.updateStatutRendezVous(id, 'annule');
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du rendez-vous: $e');
    }
  }

  // Terminer un rendez-vous
  Future<void> terminerRendezVous(int id) async {
    try {
      await _repository.updateStatutRendezVous(id, 'termine');
    } catch (e) {
      throw Exception('Erreur lors de la finalisation du rendez-vous: $e');
    }
  }

  // Supprimer un rendez-vous
  Future<void> supprimerRendezVous(int id) async {
    try {
      await _repository.deleteRendezVous(id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du rendez-vous: $e');
    }
  }

  // Obtenir les statistiques des rendez-vous
  Future<Map<String, int>> obtenirStatistiquesRendezVous() async {
    try {
      return await _repository.getRendezVousCountByStatut();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // Valider les données d'un rendez-vous
  String? validerRendezVous({
    required String dateRendezVous,
    required String heureRendezVous,
    required String lieu,
  }) {
    if (dateRendezVous.isEmpty) {
      return 'La date du rendez-vous est obligatoire';
    }

    if (heureRendezVous.isEmpty) {
      return 'L\'heure du rendez-vous est obligatoire';
    }

    if (lieu.isEmpty) {
      return 'Le lieu du rendez-vous est obligatoire';
    }

    // Vérifier que la date n'est pas dans le passé
    try {
      final DateTime dateRdv = DateTime.parse(dateRendezVous);
      final DateTime maintenant = DateTime.now();

      if (dateRdv.isBefore(DateTime(maintenant.year, maintenant.month, maintenant.day))) {
        return 'La date du rendez-vous ne peut pas être dans le passé';
      }
    } catch (e) {
      return 'Format de date invalide';
    }

    return null; // Aucune erreur
  }

  // Obtenir la couleur du statut
  static String getCouleurStatut(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return 'orange';
      case 'confirme':
        return 'green';
      case 'annule':
        return 'red';
      case 'termine':
        return 'blue';
      default:
        return 'grey';
    }
  }

  // Obtenir le libellé du statut
  static String getLibelleStatut(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'confirme':
        return 'Confirmé';
      case 'annule':
        return 'Annulé';
      case 'termine':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }
}
