class RendezVous {
  final int? id;
  final String idVoiture;  // Changed to String to store matricule
  final int idAcheteur;    // Statique pour l'instant
  final int idVendeur;     // Statique pour l'instant
  final String dateRendezVous;
  final String heureRendezVous;
  final String lieu;
  final String statut; // 'en_attente', 'confirme', 'annule', 'termine'
  final String? notes;
  final DateTime dateCreation;

  // Champs joints de la table voiture
  final String? voitureMatricule;
  final String? voitureMarque;
  final String? voitureModele;
  final int? voitureAnnee;
  final double? voiturePrix;

  RendezVous({
    this.id,
    required this.idVoiture,
    required this.idAcheteur,
    required this.idVendeur,
    required this.dateRendezVous,
    required this.heureRendezVous,
    required this.lieu,
    this.statut = 'en_attente',
    this.notes,
    DateTime? dateCreation,
    // Champs joints
    this.voitureMatricule,
    this.voitureMarque,
    this.voitureModele,
    this.voitureAnnee,
    this.voiturePrix,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // Convertir depuis Map (base de données)
  factory RendezVous.fromMap(Map<String, dynamic> map) {
    return RendezVous(
      id: map['id']?.toInt(),
      idVoiture: map['id_voiture']?.toString() ?? '',
      idAcheteur: map['id_acheteur']?.toInt() ?? 0,
      idVendeur: map['id_vendeur']?.toInt() ?? 0,
      dateRendezVous: map['date_rendez_vous'] ?? '',
      heureRendezVous: map['heure_rendez_vous'] ?? '',
      lieu: map['lieu'] ?? '',
      statut: map['statut'] ?? 'en_attente',
      notes: map['notes'],
      dateCreation: DateTime.parse(map['date_creation'] ?? DateTime.now().toIso8601String()),
      // Champs joints
      voitureMatricule: map['voiture_matricule'],
      voitureMarque: map['voiture_marque'],
      voitureModele: map['voiture_modele'],
      voitureAnnee: map['voiture_annee']?.toInt(),
      voiturePrix: map['voiture_prix']?.toDouble(),
    );
  }

  // Convertir vers Map (base de données)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_voiture': idVoiture,
      'id_acheteur': idAcheteur,
      'id_vendeur': idVendeur,
      'date_rendez_vous': dateRendezVous,
      'heure_rendez_vous': heureRendezVous,
      'lieu': lieu,
      'statut': statut,
      'notes': notes,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  // Copie avec modifications
  RendezVous copyWith({
    int? id,
    String? idVoiture,
    int? idAcheteur,
    int? idVendeur,
    String? dateRendezVous,
    String? heureRendezVous,
    String? lieu,
    String? statut,
    String? notes,
    DateTime? dateCreation,
    String? voitureMatricule,
    String? voitureMarque,
    String? voitureModele,
    int? voitureAnnee,
    double? voiturePrix,
  }) {
    return RendezVous(
      id: id ?? this.id,
      idVoiture: idVoiture ?? this.idVoiture,
      idAcheteur: idAcheteur ?? this.idAcheteur,
      idVendeur: idVendeur ?? this.idVendeur,
      dateRendezVous: dateRendezVous ?? this.dateRendezVous,
      heureRendezVous: heureRendezVous ?? this.heureRendezVous,
      lieu: lieu ?? this.lieu,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      dateCreation: dateCreation ?? this.dateCreation,
      voitureMatricule: voitureMatricule ?? this.voitureMatricule,
      voitureMarque: voitureMarque ?? this.voitureMarque,
      voitureModele: voitureModele ?? this.voitureModele,
      voitureAnnee: voitureAnnee ?? this.voitureAnnee,
      voiturePrix: voiturePrix ?? this.voiturePrix,
    );
  }

  @override
  String toString() {
    return 'RendezVous{id: $id, idVoiture: $idVoiture, dateRendezVous: $dateRendezVous, heureRendezVous: $heureRendezVous, lieu: $lieu, statut: $statut}';
  }
}
