class UserRoles {
  final bool isBuyer;
  final bool isSeller;
  final bool isShowroom;

  const UserRoles({
    this.isBuyer = true,
    this.isSeller = false,
    this.isShowroom = false,
  });

  factory UserRoles.fromString(String roles) {
    final rolesList = roles.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return UserRoles(
      isBuyer: rolesList.contains('buyer'),
      isSeller: rolesList.contains('seller'),
      isShowroom: rolesList.contains('showroom'),
    );
  }

  @override
  String toString() {
    final roles = <String>[];
    if (isBuyer) roles.add('buyer');
    if (isSeller) roles.add('seller');
    if (isShowroom) roles.add('showroom');
    return roles.join(',');
  }
}

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoPath;
  final UserRoles roles;
  final String? phoneNumber;
  final double? rating;
  final int totalRatings;
  // showroom specific
  final String? showroomLocation;
  final int? showroomBranches;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoPath,
    UserRoles? roles,
    this.phoneNumber,
    this.rating,
    this.totalRatings = 0,
    this.showroomLocation,
    this.showroomBranches,
  }) : this.roles = roles ?? UserRoles();

  bool get isNewSeller => roles.isSeller && totalRatings == 0;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoPath': photoPath,
      'roles': roles.toString(),
      'phoneNumber': phoneNumber,
      'rating': rating,
      'totalRatings': totalRatings,
      'showroomLocation': showroomLocation,
      'showroomBranches': showroomBranches,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      photoPath: map['photoPath'] as String?,
      roles: UserRoles.fromString(map['roles'] as String? ?? 'buyer'),
      phoneNumber: map['phoneNumber'] as String?,
      rating: map['rating'] as double?,
      totalRatings: map['totalRatings'] as int? ?? 0,
      showroomLocation: map['showroomLocation'] as String?,
      showroomBranches: map['showroomBranches'] as int?,
    );
  }
}