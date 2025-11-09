class RendezVous {
  final int? id;
  final String voitureMatricule;
  final String lieu;
  final String? notes;
  final String date; // ISO date string
  final String time; // formatted time string
  final String status; // pending, confirmed, completed, cancelled
  final String createdAt; // ISO datetime

  RendezVous({
    this.id,
    required this.voitureMatricule,
    required this.lieu,
    this.notes,
    required this.date,
    required this.time,
    this.status = 'pending', // Default status
    required this.createdAt,
  });

  // Status constants
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  static const List<String> validStatuses = [
    statusPending,
    statusConfirmed,
    statusCompleted,
    statusCancelled,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voiture_matricule': voitureMatricule,
      'lieu': lieu,
      'notes': notes,
      'date': date,
      'time': time,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory RendezVous.fromMap(Map<String, dynamic> map) {
    return RendezVous(
      id: map['id'] as int?,
      voitureMatricule: map['voiture_matricule'] as String,
      lieu: map['lieu'] as String,
      notes: map['notes'] as String?,
      date: map['date'] as String,
      time: map['time'] as String,
      status: map['status'] as String? ?? 'pending', // Default to pending if null
      createdAt: map['created_at'] as String,
    );
  }

  // Utility methods
  bool get isPending => status == statusPending;
  bool get isConfirmed => status == statusConfirmed;
  bool get isCompleted => status == statusCompleted;
  bool get isCancelled => status == statusCancelled;

  String get statusDisplayName {
    switch (status) {
      case statusPending:
        return 'En attente';
      case statusConfirmed:
        return 'Confirmé';
      case statusCompleted:
        return 'Terminé';
      case statusCancelled:
        return 'Annulé';
      default:
        return status;
    }
  }

  // Create a copy with updated status
  RendezVous copyWith({
    int? id,
    String? voitureMatricule,
    String? lieu,
    String? notes,
    String? date,
    String? time,
    String? status,
    String? createdAt,
  }) {
    return RendezVous(
      id: id ?? this.id,
      voitureMatricule: voitureMatricule ?? this.voitureMatricule,
      lieu: lieu ?? this.lieu,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
