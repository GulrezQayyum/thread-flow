// lib/config/groq_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqConfig {
  static String get apiKey {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      print('⚠️ GROQ: API key not found in .env file');
      return '';
    }
    return key;
  }

  static const String baseUrl = 'https://api.groq.com/openai/v1';
  
  // ✅ CORRECT MODEL NAMES FOR GROQ:
  static const String model = 'llama-3.3-70b-versatile';  // Latest Llama 3.3
  // Alternative: 'llama-3.1-8b-instant'   // Llama 3.1 8B (Fast)
  // Alternative: 'llama-3.2-3b-preview'   // Llama 3.2 3B (Lightweight)
  // Alternative: 'llama-3.2-1b-preview'   // Llama 3.2 1B (Fastest)
  // Alternative: 'gemma2-9b-it'           // Gemma 2 9B
  
  static const int maxTokens = 100;
  static const double temperature = 0.5;

  static bool get isConfigured {
    final key = dotenv.env['GROQ_API_KEY'];
    return key != null && key.isNotEmpty;
  }
}