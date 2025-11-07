class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'voiture_app.db';
  static const int databaseVersion = 2; // Incremented for new columns
  
  // Table name
  static const String voituresTable = 'voitures';
  
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
}
