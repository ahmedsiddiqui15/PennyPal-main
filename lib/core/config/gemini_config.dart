import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  GeminiConfig._();

  static const String _placeholderKey = 'YOUR_API_KEY_HERE';
  static const String _placeholderModel = 'YOUR_MODEL_NAME';
  static const String _fallbackModel = 'gemini-flash-latest';

  
  static String get envApiKey {
    final String raw = _read('AI_API_KEY');
    if (raw.isEmpty || raw == _placeholderKey) return '';
    return raw;
  }

  
  static String get defaultModel {
    final String raw = _read('AI_MODEL');
    if (raw.isEmpty || raw == _placeholderModel) return _fallbackModel;
    return raw;
  }

  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static String _read(String key) {
    if (!dotenv.isInitialized) return '';
    return dotenv.env[key]?.trim() ?? '';
  }
}
