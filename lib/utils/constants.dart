class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'voiture_app.db';
  static const int databaseVersion = 5; // Incremented to add status column

  // Table name
  static const String voituresTable = 'voitures';
  static const String rendezvousTable = 'rendezvous';

  // Column names
  static const String columnMatricule = 'matricule';
  static const String columnMarque = 'marque';
  static const String columnModele = 'modele';
  static const String columnAnnee = 'annee';
  static const String columnPuissance = 'puissance';
  static const String columnCylindres = 'cylindres';
  static const String columnCarburant = 'carburant';
  static const String columnKilometrage = 'kilometrage';
  static const String columnPrix = 'prix';
  static const String columnDescription = 'description';  // NEW
  static const String columnImage = 'image';              // NEW (file path)

  // Rendezvous columns
  static const String columnRendezvousId = 'id';
  static const String columnRendezvousVoitureMatricule = 'voiture_matricule';
  static const String columnRendezvousLieu = 'lieu';
  static const String columnRendezvousNotes = 'notes';
  static const String columnRendezvousDate = 'date';
  static const String columnRendezvousTime = 'time';
  static const String columnRendezvousStatus = 'status';
  static const String columnRendezvousCreatedAt = 'created_at';
}
