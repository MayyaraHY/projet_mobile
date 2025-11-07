class Voiture {
  final String matricule;
  final String marque;
  final String modele;
  final int annee;
  final double puissance;
  final int cylindres;
  final String carburant;
  final double kilometrage;
  final double prix;
  final String? description;  // NEW - Optional text description
  final String? image;        // NEW - Optional image file path

  Voiture({
    required this.matricule,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.puissance,
    required this.cylindres,
    required this.carburant,
    required this.kilometrage,
    required this.prix,
    this.description,  // Optional
    this.image,        // Optional
  });

  // Convert Voiture object to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'matricule': matricule,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'puissance': puissance,
      'cylindres': cylindres,
      'carburant': carburant,
      'kilometrage': kilometrage,
      'prix': prix,
      'description': description,  // Can be null
      'image': image,              // Can be null
    };
  }

  // Create Voiture object from Map (from SQLite)
  factory Voiture.fromMap(Map<String, dynamic> map) {
    return Voiture(
      matricule: map['matricule'] as String,
      marque: map['marque'] as String,
      modele: map['modele'] as String,
      annee: map['annee'] as int,
      puissance: (map['puissance'] as num).toDouble(),
      cylindres: map['cylindres'] as int,
      carburant: map['carburant'] as String,
      kilometrage: (map['kilometrage'] as num).toDouble(),
      prix: (map['prix'] as num).toDouble(),
      description: map['description'] as String?,  // Nullable
      image: map['image'] as String?,              // Nullable
    );
  }

  // Copy with method for updating voiture
  Voiture copyWith({
    String? matricule,
    String? marque,
    String? modele,
    int? annee,
    double? puissance,
    int? cylindres,
    String? carburant,
    double? kilometrage,
    double? prix,
    String? description,
    String? image,
  }) {
    return Voiture(
      matricule: matricule ?? this.matricule,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
      puissance: puissance ?? this.puissance,
      cylindres: cylindres ?? this.cylindres,
      carburant: carburant ?? this.carburant,
      kilometrage: kilometrage ?? this.kilometrage,
      prix: prix ?? this.prix,
      description: description ?? this.description,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'Voiture{matricule: $matricule, marque: $marque, modele: $modele, '
        'annee: $annee, puissance: $puissance, cylindres: $cylindres, '
        'carburant: $carburant, kilometrage: $kilometrage, prix: $prix, '
        'description: ${description ?? "N/A"}, image: ${image ?? "N/A"}}';
  }

  // Helper method to format prix
  String get prixFormate => '${prix.toStringAsFixed(2)} TND';
  
  // Helper method to format kilometrage
  String get kilometrageFormate => '${kilometrage.toStringAsFixed(0)} km';
  
  // Check if voiture has an image
  bool get hasImage => image != null && image!.isNotEmpty;
  
  // Check if voiture has description
  bool get hasDescription => description != null && description!.isNotEmpty;
}
