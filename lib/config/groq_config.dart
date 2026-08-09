import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqConfig {
  static String get apiKey {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'GROQ_API_KEY not found in .env file. '
        'Please add your Groq API key to .env'
      );
    }
    return key;
  }

  static const String baseUrl = 'https://api.groq.cloud/openai/v1';
  static const String model = 'llama-3.1-70b-versatile';
  static const int maxTokens = 150;
  static const double temperature = 0.5;
}
