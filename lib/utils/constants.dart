class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'voiture_app.db';
  static const int databaseVersion = 8; // Incremented for enhanced events system
  
  // Table names
  static const String voituresTable = 'voitures';
  static const String usersTable = 'users';
  static const String ratingsTable = 'ratings';

  // Voiture columns
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
  // Owner columns
  static const String columnOwnerId = 'owner_id';
  static const String columnOwnerName = 'owner_name';

  // Users table columns
  static const String columnUserId = 'uid';
  static const String columnUserEmail = 'email';
  static const String columnUserPassword = 'password_hash';
  static const String columnUserRoles = 'roles';
  static const String columnUserDisplayName = 'display_name';
  static const String columnUserPhoto = 'photo_path';
  static const String columnUserPhone = 'phone_number';
  static const String columnUserRating = 'rating';
  static const String columnUserTotalRatings = 'total_ratings';
  static const String columnUserAvatarEmoji = 'avatar_emoji';
  static const String columnUserAvatarColor = 'avatar_color';
  // Showroom specific
  static const String columnUserShowroomLocation = 'showroom_location';
  static const String columnUserShowroomBranches = 'showroom_branches';

  // Events table (for showrooms)
  static const String eventsTable = 'events';
  static const String columnEventId = 'id';
  static const String columnEventShowroomId = 'showroom_id';
  static const String columnEventTitle = 'title';
  static const String columnEventDescription = 'description';
  static const String columnEventDate = 'date';
  static const String columnEventType = 'event_type';
  static const String columnEventLocation = 'location';
  static const String columnEventCapacity = 'capacity';
  static const String columnEventImageGallery = 'image_gallery';

  // Event attendees table (for RSVP tracking)
  static const String eventAttendeesTable = 'event_attendees';
  static const String columnAttendeeId = 'id';
  static const String columnAttendeeEventId = 'event_id';
  static const String columnAttendeeUserId = 'user_id';
  static const String columnAttendeeStatus = 'status';
  static const String columnAttendeeRegisteredAt = 'registered_at';

  // Ratings table columns
  static const String columnRatingId = 'id';
  static const String columnRatingSellerId = 'seller_id';
  static const String columnRatingRaterId = 'rater_id';
  static const String columnRatingValue = 'rating';
  static const String columnRatingComment = 'comment';
  static const String columnRatingCreatedAt = 'created_at';
}
