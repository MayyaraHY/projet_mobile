import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'session_service.dart';

class AuthService extends ChangeNotifier {
  bool _isLoading = true;

  String? _uid;
  String? _displayName;
  String? _email;
  String? _photoPath;
  UserRoles _roles = UserRoles();
  String? _phoneNumber;
  double? _rating;
  int _totalRatings = 0;
  String? _avatarEmoji;
  int? _avatarColor;

  AuthService() {
    // Load persisted session (if any)
    _loadLocalUser().then((_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  bool get isLoading => _isLoading;
  bool get isSignedIn => _uid != null;
  bool get isLocalSignedIn => _uid != null; // all users are local now

  String? get currentUid => _uid;
  String? get currentDisplayName => _displayName;
  String? get currentEmail => _email;
  String? get currentPhotoPath => _photoPath;
  String? get currentAvatarEmoji => _avatarEmoji;
  int? get currentAvatarColor => _avatarColor;

  UserRoles get currentUserRoles => _roles;

  UserModel? get currentUser => _uid == null ? null : UserModel(
    uid: _uid!,
    displayName: _displayName ?? '',
    email: _email ?? '',
    photoPath: _photoPath,
    roles: _roles,
    phoneNumber: _phoneNumber,
    rating: _rating,
    totalRatings: _totalRatings,
  );

  Future<UserModel?> getCurrentUser() async {
    if (_uid == null) return null;
    return UserModel(
      uid: _uid!,
      displayName: _displayName ?? '',
      email: _email ?? '',
      photoPath: _photoPath,
      roles: _roles,
      phoneNumber: _phoneNumber,
      rating: _rating,
      totalRatings: _totalRatings,
    );
  }

  Future<UserModel?> getUserById(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseConstants.usersTable,
      where: '${DatabaseConstants.columnUserId} = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return null;

    final user = rows.first;
    return UserModel(
      uid: user[DatabaseConstants.columnUserId] as String,
      displayName: user[DatabaseConstants.columnUserDisplayName] as String,
      email: user[DatabaseConstants.columnUserEmail] as String,
      photoPath: user[DatabaseConstants.columnUserPhoto] as String?,
      roles: UserRoles.fromString(user[DatabaseConstants.columnUserRoles] as String? ?? 'buyer'),
      phoneNumber: user[DatabaseConstants.columnUserPhone] as String?,
      rating: (user[DatabaseConstants.columnUserRating] is num) ? (user[DatabaseConstants.columnUserRating] as num).toDouble() : null,
      totalRatings: user[DatabaseConstants.columnUserTotalRatings] as int? ?? 0,
      showroomLocation: user[DatabaseConstants.columnUserShowroomLocation] as String?,
      showroomBranches: user[DatabaseConstants.columnUserShowroomBranches] as int?,
    );
  }

  Future<void> _loadLocalUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('current_user');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _uid = map['uid'] as String?;
        _displayName = map['displayName'] as String?;
        _email = map['email'] as String?;
        _photoPath = map['photoPath'] as String?;
      }
    } catch (e) {
      // ignore
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> signUpWithEmail(String email, String password, {
    String? displayName,
    UserRoles? roles,
    String? phoneNumber,
    String? showroomLocation,
    int? showroomBranches,
  }) async {
    try {
      print('Starting sign up for email: $email');
      final db = await DatabaseHelper.instance.database;
      
      // Check if email already exists
      final existingUser = await db.query(DatabaseConstants.usersTable,
          where: '${DatabaseConstants.columnUserEmail} = ?',
          whereArgs: [email]);
          
      if (existingUser.isNotEmpty) {
        print('Email already exists: $email');
        return 'Email already registered';
      }
      
      final hashed = _hashPassword(password);
      final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        DatabaseConstants.columnUserId: uid,
        DatabaseConstants.columnUserEmail: email,
        DatabaseConstants.columnUserPassword: hashed,
        DatabaseConstants.columnUserDisplayName: displayName ?? email.split('@').first,
        DatabaseConstants.columnUserPhoto: null,
        DatabaseConstants.columnUserRoles: (roles ?? UserRoles()).toString(),
        DatabaseConstants.columnUserShowroomLocation: showroomLocation,
        DatabaseConstants.columnUserShowroomBranches: showroomBranches,
        DatabaseConstants.columnUserPhone: phoneNumber,
        DatabaseConstants.columnUserRating: null,
        DatabaseConstants.columnUserTotalRatings: 0,
      };
      
      print('Creating new user with data: $data');
      await db.insert(DatabaseConstants.usersTable, data);
      print('User created successfully');

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode({
        'uid': uid,
        'displayName': data[DatabaseConstants.columnUserDisplayName],
        'email': email,
        'photoPath': null,
      }));

      _uid = uid;
      _displayName = data[DatabaseConstants.columnUserDisplayName] as String?;
      _email = email;
      _photoPath = null;
      _roles = roles ?? UserRoles();
      _phoneNumber = phoneNumber;
      // showroom fields remain null until loaded
      
      // Create device session
      await SessionService().createSession(uid);
      
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithEmail(String email, String password, {String? expectedRole}) async {
    try {
      print('Attempting login for email: $email');
      final db = await DatabaseHelper.instance.database;
      final hashed = _hashPassword(password);
      
      // First check if the user exists
      final userRows = await db.query(DatabaseConstants.usersTable,
          where: '${DatabaseConstants.columnUserEmail} = ?',
          whereArgs: [email]);
          
      if (userRows.isEmpty) {
        print('No user found with email: $email');
        return 'Invalid credentials';
      }
      
      // Then check password
      final rows = await db.query(DatabaseConstants.usersTable,
          where: '${DatabaseConstants.columnUserEmail} = ? AND ${DatabaseConstants.columnUserPassword} = ?',
          whereArgs: [email, hashed]);
          
      print('Found ${rows.length} matching users');
      
      if (rows.isEmpty) {
        print('Password incorrect for email: $email');
        return 'Invalid credentials';
      }
      final user = rows.first;
      _uid = user[DatabaseConstants.columnUserId] as String?;
      _displayName = user[DatabaseConstants.columnUserDisplayName] as String?;
      _email = user[DatabaseConstants.columnUserEmail] as String?;
      _photoPath = user[DatabaseConstants.columnUserPhoto] as String?;
      // roles
      final rolesStr = user[DatabaseConstants.columnUserRoles] as String? ?? 'buyer';
      _roles = UserRoles.fromString(rolesStr);
      // If expectedRole is provided, check membership
      if (expectedRole != null) {
        final ok = (expectedRole == 'buyer' && _roles.isBuyer) ||
                  (expectedRole == 'seller' && _roles.isSeller) ||
                  (expectedRole == 'showroom' && _roles.isShowroom);
        if (!ok) {
          return 'Account does not have the selected role';
        }
      }
      _phoneNumber = user[DatabaseConstants.columnUserPhone] as String?;
      _rating = (user[DatabaseConstants.columnUserRating] is num) ? (user[DatabaseConstants.columnUserRating] as num).toDouble() : null;
      _totalRatings = user[DatabaseConstants.columnUserTotalRatings] as int? ?? 0;
      // showroom fields
      try {
        _displayName = _displayName ?? '';
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode({
        'uid': _uid,
        'displayName': _displayName,
        'email': _email,
        'photoPath': _photoPath,
        'roles': _roles.toString(),
        'phoneNumber': _phoneNumber,
      }));

      // Create device session
      if (_uid != null) {
        await SessionService().createSession(_uid!);
      }

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Google Sign In
  Future<String?> signInWithGoogle({String? expectedRole}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Google sign in cancelled';
      }

      final String email = googleUser.email;
      final String displayName = googleUser.displayName ?? email.split('@').first;
      final String? photoUrl = googleUser.photoUrl;
      
      // Check if user exists in database
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(DatabaseConstants.usersTable,
          where: '${DatabaseConstants.columnUserEmail} = ?',
          whereArgs: [email]);
      
      String uid;
      UserRoles roles;
      
      if (rows.isEmpty) {
        // Create new user
        uid = 'google_${DateTime.now().millisecondsSinceEpoch}';
        roles = UserRoles(isBuyer: true);
        
        final data = {
          DatabaseConstants.columnUserId: uid,
          DatabaseConstants.columnUserEmail: email,
          DatabaseConstants.columnUserPassword: '', // No password for social login
          DatabaseConstants.columnUserDisplayName: displayName,
          DatabaseConstants.columnUserPhoto: photoUrl,
          DatabaseConstants.columnUserRoles: roles.toString(),
          DatabaseConstants.columnUserShowroomLocation: null,
          DatabaseConstants.columnUserShowroomBranches: null,
          DatabaseConstants.columnUserPhone: null,
          DatabaseConstants.columnUserRating: null,
          DatabaseConstants.columnUserTotalRatings: 0,
        };
        
        await db.insert(DatabaseConstants.usersTable, data);
      } else {
        // Existing user
        final user = rows.first;
        uid = user[DatabaseConstants.columnUserId] as String;
        final rolesStr = user[DatabaseConstants.columnUserRoles] as String? ?? 'buyer';
        roles = UserRoles.fromString(rolesStr);
        
        // Check role if specified
        if (expectedRole != null) {
          final ok = (expectedRole == 'buyer' && roles.isBuyer) ||
                    (expectedRole == 'seller' && roles.isSeller) ||
                    (expectedRole == 'showroom' && roles.isShowroom);
          if (!ok) {
            return 'Account does not have the selected role';
          }
        }
      }
      
      // Set current user
      _uid = uid;
      _displayName = displayName;
      _email = email;
      _photoPath = photoUrl;
      _roles = roles;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode({
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoPath': photoUrl,
        'roles': roles.toString(),
      }));
      
      notifyListeners();
      return null;
    } catch (e) {
      print('Google sign in error: $e');
      return 'Google sign in failed: ${e.toString()}';
    }
  }

  // Facebook Sign In
  Future<String?> signInWithFacebook({String? expectedRole}) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status != LoginStatus.success) {
        return 'Facebook sign in cancelled or failed';
      }
      
      final userData = await FacebookAuth.instance.getUserData();
      final String email = userData['email'] ?? '';
      final String displayName = userData['name'] ?? 'Facebook User';
      final String? photoUrl = userData['picture']?['data']?['url'];
      
      if (email.isEmpty) {
        return 'Email not available from Facebook';
      }
      
      // Check if user exists in database
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(DatabaseConstants.usersTable,
          where: '${DatabaseConstants.columnUserEmail} = ?',
          whereArgs: [email]);
      
      String uid;
      UserRoles roles;
      
      if (rows.isEmpty) {
        // Create new user
        uid = 'facebook_${DateTime.now().millisecondsSinceEpoch}';
        roles = UserRoles(isBuyer: true);
        
        final data = {
          DatabaseConstants.columnUserId: uid,
          DatabaseConstants.columnUserEmail: email,
          DatabaseConstants.columnUserPassword: '', // No password for social login
          DatabaseConstants.columnUserDisplayName: displayName,
          DatabaseConstants.columnUserPhoto: photoUrl,
          DatabaseConstants.columnUserRoles: roles.toString(),
          DatabaseConstants.columnUserShowroomLocation: null,
          DatabaseConstants.columnUserShowroomBranches: null,
          DatabaseConstants.columnUserPhone: null,
          DatabaseConstants.columnUserRating: null,
          DatabaseConstants.columnUserTotalRatings: 0,
        };
        
        await db.insert(DatabaseConstants.usersTable, data);
      } else {
        // Existing user
        final user = rows.first;
        uid = user[DatabaseConstants.columnUserId] as String;
        final rolesStr = user[DatabaseConstants.columnUserRoles] as String? ?? 'buyer';
        roles = UserRoles.fromString(rolesStr);
        
        // Check role if specified
        if (expectedRole != null) {
          final ok = (expectedRole == 'buyer' && roles.isBuyer) ||
                    (expectedRole == 'seller' && roles.isSeller) ||
                    (expectedRole == 'showroom' && roles.isShowroom);
          if (!ok) {
            return 'Account does not have the selected role';
          }
        }
      }
      
      // Set current user
      _uid = uid;
      _displayName = displayName;
      _email = email;
      _photoPath = photoUrl;
      _roles = roles;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode({
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoPath': photoUrl,
        'roles': roles.toString(),
      }));
      
      notifyListeners();
      return null;
    } catch (e) {
      print('Facebook sign in error: $e');
      return 'Facebook sign in failed: ${e.toString()}';
    }
  }

  // Local-only quick signup (no email/password)
  Future<String?> signUpLocal(String displayName) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        DatabaseConstants.columnUserId: uid,
        DatabaseConstants.columnUserEmail: null,
        DatabaseConstants.columnUserPassword: '',
        DatabaseConstants.columnUserDisplayName: displayName,
        DatabaseConstants.columnUserPhoto: null,
      };
      await db.insert(DatabaseConstants.usersTable, data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode({
        'uid': uid,
        'displayName': displayName,
        'email': null,
        'photoPath': null,
      }));

      _uid = uid;
      _displayName = displayName;
      _email = null;
      _photoPath = null;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    // Delete current session
    final currentSession = SessionService().currentSessionId;
    if (currentSession != null) {
      await SessionService().deleteSession(currentSession);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _uid = null;
    _displayName = null;
    _email = null;
    _photoPath = null;
    notifyListeners();
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      if (_uid == null) return 'No user signed in';
      final db = await DatabaseHelper.instance.database;
      final hashed = _hashPassword(newPassword);
      await db.update(DatabaseConstants.usersTable, {DatabaseConstants.columnUserPassword: hashed},
          where: '${DatabaseConstants.columnUserId} = ?', whereArgs: [_uid]);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDisplayName(String displayName) async {
    try {
      if (_uid == null) return 'No user signed in';
      final db = await DatabaseHelper.instance.database;
      await db.update(DatabaseConstants.usersTable, {DatabaseConstants.columnUserDisplayName: displayName},
          where: '${DatabaseConstants.columnUserId} = ?', whereArgs: [_uid]);
      _displayName = displayName;

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('current_user');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map['displayName'] = displayName;
        await prefs.setString('current_user', jsonEncode(map));
      }

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfilePictureFromImagePicker() async {
    try {
      if (_uid == null) return 'No user signed in';
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return 'No image selected';

      final file = File(picked.path);
      final appDir = await getApplicationDocumentsDirectory();
      final destPath = p.join(appDir.path, 'profile_${_uid}.jpg');
      await file.copy(destPath);

      final db = await DatabaseHelper.instance.database;
      await db.update(DatabaseConstants.usersTable, {DatabaseConstants.columnUserPhoto: destPath},
          where: '${DatabaseConstants.columnUserId} = ?', whereArgs: [_uid]);

      _photoPath = destPath;
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('current_user');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map['photoPath'] = destPath;
        await prefs.setString('current_user', jsonEncode(map));
      }

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAccount() async {
    try {
      if (_uid == null) return 'No user signed in';
      
      final db = await DatabaseHelper.instance.database;
      final userId = _uid!;
      
      // Delete user's profile photo if exists
      if (_photoPath != null) {
        final file = File(_photoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Delete all user sessions
      await SessionService().deleteAllUserSessions(userId);
      
      // Delete user from database
      await db.delete(
        DatabaseConstants.usersTable,
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [userId],
      );
      
      // Clear local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      
      // Reset state
      _uid = null;
      _displayName = null;
      _email = null;
      _photoPath = null;
      _roles = UserRoles();
      _phoneNumber = null;
      _rating = null;
      _totalRatings = 0;
      
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateCustomAvatar(String emoji, int colorValue) async {
    try {
      if (_uid == null) return 'No user signed in';
      
      final db = await DatabaseHelper.instance.database;
      await db.update(
        DatabaseConstants.usersTable,
        {
          DatabaseConstants.columnUserAvatarEmoji: emoji,
          DatabaseConstants.columnUserAvatarColor: colorValue,
        },
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [_uid],
      );

      _avatarEmoji = emoji;
      _avatarColor = colorValue;

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('current_user');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map['avatarEmoji'] = emoji;
        map['avatarColor'] = colorValue;
        await prefs.setString('current_user', jsonEncode(map));
      }

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
