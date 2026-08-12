// lib/config/cloudinary_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  static String get cloudName {
    final key = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    if (key.isEmpty) {
      print('⚠️ CLOUDINARY: Cloud name not found in .env');
    }
    return key;
  }

  static String get apiKey {
    final key = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
    if (key.isEmpty) {
      print('⚠️ CLOUDINARY: API key not found in .env');
    }
    return key;
  }

  static String get apiSecret {
    final key = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
    if (key.isEmpty) {
      print('⚠️ CLOUDINARY: API secret not found in .env');
    }
    return key;
  }

  static bool get isConfigured {
    return cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
  }
}