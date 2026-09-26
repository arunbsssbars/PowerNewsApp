import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String _get(String key, String fallback) {
    if (dotenv.isInitialized) {
      return dotenv.env[key] ?? fallback;
    }
    return fallback;
  }

  static String get apiKey => _get('APP_CLIENT_SECRET', _get('API_KEY', 'pwn_5a9b8c7d6e5f4g3h2i1j0'));
  static String get clientSecret => apiKey;
  static String get apiBaseUrl => _get('API_BASE_URL', 'https://powernewsapp-backend.onrender.com');
  static String get googleWebClientId => _get('GOOGLE_WEB_CLIENT_ID', '1022634770385-qfb9nj8e2b1835ss9j4tn9657m34lpil.apps.googleusercontent.com');
  static String get firebaseApiKey => _get('FIREBASE_API_KEY', 'AIzaSyDmaWHLVYGzfTlFaPmFPsoT5zyojmon60g');
  
  // Feature Flags
  static bool get enableAudioDigest => true;
  static bool get enableAiSummaries => true;
}
