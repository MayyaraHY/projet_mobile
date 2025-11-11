class Insurance {
  final String id;
  final String name;          // Nom de l'assurance (ex: COMAR, AMI, etc.)
  final String logoUrl;       // Lien du logo (image en ligne ou asset)
  final double pricePerYear;  // Prix annuel de l'assurance
  final String description;   // Brève description de l'offre
  final String type;          // Type d'assurance (auto, moto, tous risques, etc.)
  final String coverage;      // Détails de la couverture
  final String contact;       // Contact de l’assurance (email ou téléphone)

  Insurance({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.pricePerYear,
    required this.description,
    required this.type,
    required this.coverage,
    required this.contact,
  });

  // ✅ Convertir un objet Insurance en Map (pour SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'pricePerYear': pricePerYear,
      'description': description,
      'type': type,
      'coverage': coverage,
      'contact': contact,
    };
  }

  // ✅ Convertir un Map SQLite en objet Insurance
  factory Insurance.fromMap(Map<String, dynamic> map) {
    return Insurance(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logoUrl'] as String,
      pricePerYear: (map['pricePerYear'] is int)
          ? (map['pricePerYear'] as int).toDouble()
          : map['pricePerYear'] as double,
      description: map['description'] as String,
      type: map['type'] as String,
      coverage: map['coverage'] as String,
      contact: map['contact'] as String,
    );
  }
}
