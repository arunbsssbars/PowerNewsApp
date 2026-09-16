import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiKey => dotenv.env['API_KEY'] ?? 'pwn_5a9b8c7d6e5f4g3h2i1j0';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://172.20.10.13:3000';
  
  // Feature Flags
  static bool get enableAudioDigest => true;
  static bool get enableAiSummaries => true;
}
