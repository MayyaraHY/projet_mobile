class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final double sellerScore; // average rating for sellers

  AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.sellerScore = 0.0,
  });

  AppUser copyWith({double? sellerScore}) => AppUser(
        uid: uid,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        sellerScore: sellerScore ?? this.sellerScore,
      );
}
