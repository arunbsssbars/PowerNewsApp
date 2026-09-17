import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? idToken;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.idToken,
  });

  bool get isAdmin => email.toLowerCase().trim() == AuthService.adminEmail;

  Map<String, String?> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'idToken': idToken,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] ?? '',
    email: map['email'] ?? '',
    displayName: map['displayName'] ?? '',
    photoUrl: map['photoUrl'],
    idToken: map['idToken'],
  );
}

class AuthService extends ChangeNotifier {
  static const String adminEmail = 'arunbsssbars@gmail.com';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser != null && _currentUser!.isAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('auth_user_email');
      final id = prefs.getString('auth_user_id');
      final name = prefs.getString('auth_user_name');
      final photo = prefs.getString('auth_user_photo');
      final token = prefs.getString('auth_user_token');

      if (email != null && id != null) {
        _currentUser = AppUser(
          id: id,
          email: email,
          displayName: name ?? 'Admin User',
          photoUrl: photo,
          idToken: token,
        );
        notifyListeners();
      }

      // Try silent sign-in in the background to refresh credentials
      _googleSignIn.signInSilently().then((account) async {
        if (account != null) {
          final auth = await account.authentication;
          _currentUser = AppUser(
            id: account.id,
            email: account.email,
            displayName: account.displayName ?? account.email.split('@').first,
            photoUrl: account.photoUrl,
            idToken: auth.idToken,
          );
          await _saveUserToPrefs(_currentUser!);
          notifyListeners();
        }
      }).catchError((_) {});
    } catch (e) {
      debugPrint('[AuthService] Init error: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled popup/picker
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;

      _currentUser = AppUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
      );

      await _saveUserToPrefs(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      final errStr = e.toString();
      debugPrint('[AuthService] Google Sign-In error: $errStr');

      if (errStr.contains('10') || errStr.contains('ApiException: 10') || errStr.contains('DEVELOPER_ERROR')) {
        _errorMessage = 'Google Play Services configuration error: SHA-1 fingerprint needs to be registered in Firebase/Google Cloud Console.';
      } else if (errStr.contains('network') || errStr.contains('7')) {
        _errorMessage = 'Network error connecting to Google Sign-In.';
      } else {
        _errorMessage = 'Sign-in failed: ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    _currentUser = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_photo');
    await prefs.remove('auth_user_token');

    notifyListeners();
  }

  Future<void> _saveUserToPrefs(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_email', user.email);
    await prefs.setString('auth_user_id', user.id);
    await prefs.setString('auth_user_name', user.displayName);
    if (user.photoUrl != null) await prefs.setString('auth_user_photo', user.photoUrl!);
    if (user.idToken != null) await prefs.setString('auth_user_token', user.idToken!);
  }
}
