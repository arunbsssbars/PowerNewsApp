import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? idToken;
  final bool isEmailVerified;
  final String? createdAt;
  final String authProvider; // 'google' or 'password' or 'guest'

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.idToken,
    this.isEmailVerified = false,
    this.createdAt,
    this.authProvider = 'google',
  });

  bool get isAdmin => email.toLowerCase().trim() == AuthService.adminEmail;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? idToken,
    bool? isEmailVerified,
    String? createdAt,
    String? authProvider,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      idToken: idToken ?? this.idToken,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'idToken': idToken,
    'isEmailVerified': isEmailVerified,
    'createdAt': createdAt,
    'authProvider': authProvider,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] ?? '',
    email: map['email'] ?? '',
    displayName: map['displayName'] ?? '',
    photoUrl: map['photoUrl'],
    idToken: map['idToken'],
    isEmailVerified: map['isEmailVerified'] == true,
    createdAt: map['createdAt'],
    authProvider: map['authProvider'] ?? 'google',
  );
}

class AuthService extends ChangeNotifier {
  static const String adminEmail = 'arunbsssbars@gmail.com';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser != null && _currentUser!.isAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isGuest => _isGuest;

  String get _fbApiKey => AppConfig.firebaseApiKey;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('auth_user_email');
      final id = prefs.getString('auth_user_id');
      final name = prefs.getString('auth_user_name');
      final photo = prefs.getString('auth_user_photo');
      final token = prefs.getString('auth_user_token');
      final verified = prefs.getBool('auth_user_verified') ?? false;
      final created = prefs.getString('auth_user_created');
      final provider = prefs.getString('auth_user_provider') ?? 'google';
      _isGuest = prefs.getBool('auth_is_guest') ?? false;

      if (email != null && id != null) {
        _currentUser = AppUser(
          id: id,
          email: email,
          displayName: name ?? (email.split('@').first),
          photoUrl: photo,
          idToken: token,
          isEmailVerified: verified,
          createdAt: created,
          authProvider: provider,
        );
        notifyListeners();

        // Check fresh verification status in background
        if (token != null && token.isNotEmpty && provider == 'password') {
          checkEmailVerificationStatus();
        }
      }

      // Silent Google refresh if previously signed in with Google
      if (provider == 'google') {
        _googleSignIn.signInSilently().then((account) async {
          if (account != null) {
            final auth = await account.authentication;
            _currentUser = AppUser(
              id: account.id,
              email: account.email,
              displayName: account.displayName ?? account.email.split('@').first,
              photoUrl: account.photoUrl,
              idToken: auth.idToken,
              isEmailVerified: true,
              createdAt: _currentUser?.createdAt ?? DateTime.now().toIso8601String(),
              authProvider: 'google',
            );
            await _saveUserToPrefs(_currentUser!);
            notifyListeners();
          }
        }).catchError((_) {});
      }
    } catch (e) {
      debugPrint('[AuthService] Init error: $e');
    }
  }

  // --- 1. Google Sign-In ---
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
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
        isEmailVerified: true,
        createdAt: DateTime.now().toIso8601String(),
        authProvider: 'google',
      );

      _isGuest = false;
      await _saveUserToPrefs(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      final errStr = e.toString();
      debugPrint('[AuthService] Google Sign-In error: $errStr');

      if (errStr.contains('10') || errStr.contains('DEVELOPER_ERROR')) {
        _errorMessage = 'Google Services OAuth mismatch. Ensure debug SHA-1 fingerprint is registered in Firebase.';
      } else if (errStr.contains('network') || errStr.contains('7')) {
        _errorMessage = 'Network connection failed during Google authentication.';
      } else {
        _errorMessage = 'Google Sign-In failed: $errStr';
      }

      notifyListeners();
      return false;
    }
  }

  // --- 2. Minimal Email & Password Sign-Up ---
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_fbApiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        _errorMessage = _parseFirebaseAuthError(data['error']?['message'] ?? 'Sign up failed');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final idToken = data['idToken'] as String?;
      final localId = data['localId'] as String? ?? '';

      // Update Display Name via Firebase REST API
      final cleanName = displayName.trim().isEmpty ? email.split('@').first : displayName.trim();
      if (idToken != null) {
        try {
          await http.post(
            Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_fbApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'displayName': cleanName,
              'returnSecureToken': true,
            }),
          );
        } catch (_) {}

        // Send Email Verification Button
        await sendEmailVerification(tokenOverride: idToken);
      }

      _currentUser = AppUser(
        id: localId,
        email: email.trim(),
        displayName: cleanName,
        idToken: idToken,
        isEmailVerified: false,
        createdAt: DateTime.now().toIso8601String(),
        authProvider: 'password',
      );

      _isGuest = false;
      await _saveUserToPrefs(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign-up connection error: $e';
      notifyListeners();
      return false;
    }
  }

  // --- 3. Email & Password Sign-In ---
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_fbApiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        _errorMessage = _parseFirebaseAuthError(data['error']?['message'] ?? 'Authentication failed');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final idToken = data['idToken'] as String?;
      final localId = data['localId'] as String? ?? '';
      final displayName = data['displayName'] as String? ?? email.split('@').first;

      _currentUser = AppUser(
        id: localId,
        email: email.trim(),
        displayName: displayName,
        idToken: idToken,
        isEmailVerified: false,
        createdAt: DateTime.now().toIso8601String(),
        authProvider: 'password',
      );

      _isGuest = false;
      await _saveUserToPrefs(_currentUser!);
      
      // Lookup actual verification status in background
      if (idToken != null) {
        checkEmailVerificationStatus();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login connection error: $e';
      notifyListeners();
      return false;
    }
  }

  // --- 4. Send Email Verification (Clean Button Landing) ---
  Future<bool> sendEmailVerification({String? tokenOverride}) async {
    final token = tokenOverride ?? _currentUser?.idToken;
    if (token == null || token.isEmpty) return false;

    try {
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_fbApiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'VERIFY_EMAIL',
          'idToken': token,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[AuthService] Send email verification error: $e');
      return false;
    }
  }

  // --- 5. Send Password Reset ---
  Future<bool> sendPasswordReset(String email) async {
    try {
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_fbApiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email.trim(),
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[AuthService] Password reset error: $e');
      return false;
    }
  }

  // --- 6. Check Fresh Email Verification Status ---
  Future<bool> checkEmailVerificationStatus() async {
    final token = _currentUser?.idToken;
    if (token == null || token.isEmpty) return false;

    try {
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$_fbApiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': token}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final users = data['users'] as List<dynamic>?;
        if (users != null && users.isNotEmpty) {
          final isVerified = users[0]['emailVerified'] == true;
          if (_currentUser != null && _currentUser!.isEmailVerified != isVerified) {
            _currentUser = _currentUser!.copyWith(isEmailVerified: isVerified);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('auth_user_verified', isVerified);
            notifyListeners();
          }
          return isVerified;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Check verification error: $e');
    }
    return false;
  }

  // --- 7. Update Basic Profile Details ---
  Future<bool> updateProfileDetails({
    required String displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    final token = _currentUser?.idToken;
    if (token != null && token.isNotEmpty) {
      try {
        final body = <String, dynamic>{
          'idToken': token,
          'displayName': displayName.trim(),
          'returnSecureToken': true,
        };
        if (photoUrl != null && photoUrl.isNotEmpty) {
          body['photoUrl'] = photoUrl.trim();
        }

        await http.post(
          Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_fbApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } catch (e) {
        debugPrint('[AuthService] Firebase update error (continuing local): $e');
      }
    }

    _currentUser = _currentUser!.copyWith(
      displayName: displayName.trim(),
      photoUrl: photoUrl?.trim() ?? _currentUser!.photoUrl,
    );
    await _saveUserToPrefs(_currentUser!);
    notifyListeners();
    return true;
  }

  // --- 8. Guest Mode Bypass ---
  void continueAsGuest() async {
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_guest', true);
    notifyListeners();
  }

  // --- 9. Sign Out ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    _currentUser = null;
    _errorMessage = null;
    _isGuest = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_photo');
    await prefs.remove('auth_user_token');
    await prefs.remove('auth_user_verified');
    await prefs.remove('auth_user_created');
    await prefs.remove('auth_user_provider');
    await prefs.remove('auth_is_guest');

    notifyListeners();
  }

  Future<void> _saveUserToPrefs(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_email', user.email);
    await prefs.setString('auth_user_id', user.id);
    await prefs.setString('auth_user_name', user.displayName);
    if (user.photoUrl != null) await prefs.setString('auth_user_photo', user.photoUrl!);
    if (user.idToken != null) await prefs.setString('auth_user_token', user.idToken!);
    await prefs.setBool('auth_user_verified', user.isEmailVerified);
    if (user.createdAt != null) await prefs.setString('auth_user_created', user.createdAt!);
    await prefs.setString('auth_user_provider', user.authProvider);
    await prefs.setBool('auth_is_guest', false);
  }

  String _parseFirebaseAuthError(String raw) {
    if (raw.contains('EMAIL_EXISTS')) {
      return 'An account already exists with this email address. Please sign in instead.';
    } else if (raw.contains('INVALID_LOGIN_CREDENTIALS') || raw.contains('INVALID_PASSWORD')) {
      return 'Invalid email address or password. Please check and try again.';
    } else if (raw.contains('EMAIL_NOT_FOUND')) {
      return 'No account found with this email. Please create a new account.';
    } else if (raw.contains('WEAK_PASSWORD')) {
      return 'Password should be at least 6 characters long.';
    } else if (raw.contains('INVALID_EMAIL')) {
      return 'Please enter a valid email address.';
    } else if (raw.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return 'Too many failed attempts. Please wait a moment and try again.';
    }
    return raw.replaceAll('_', ' ').toLowerCase();
  }
}
