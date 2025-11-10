class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'voiture_app.db';
  static const int databaseVersion = 5; // Incremented for contracts table and extra fields

  // Table names
  static const String voituresTable = 'voitures';
  static const String rendezVousTable = 'rendez_vous';

  // Voitures table columns
  static const String columnMatricule = 'matricule';
  static const String columnMarque = 'marque';
  static const String columnModele = 'modele';
  static const String columnAnnee = 'annee';
  static const String columnPuissance = 'puissance';
  static const String columnCylindres = 'cylindres';
  static const String columnCarburant = 'carburant';
  static const String columnKilometrage = 'kilometrage';
  static const String columnPrix = 'prix';
  static const String columnDescription = 'description';
  static const String columnImage = 'image';

  // RendezVous table columns
  static const String columnId = 'id';
  static const String columnIdVoiture = 'id_voiture';
  static const String columnIdAcheteur = 'id_acheteur';
  static const String columnIdVendeur = 'id_vendeur';
  static const String columnDateRendezVous = 'date_rendez_vous';
  static const String columnHeureRendezVous = 'heure_rendez_vous';
  static const String columnLieu = 'lieu';
  static const String columnStatut = 'statut';
  static const String columnNotes = 'notes';
  static const String columnDateCreation = 'date_creation';
}
