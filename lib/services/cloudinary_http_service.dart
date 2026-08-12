// lib/services/cloudinary_http_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/cloudinary_config.dart';

class CloudinaryHttpService {
  Future<String> uploadChatImage({
    required String chatId,
    required String messageId,
    required File imageFile,
  }) async {
    try {
      print('📤 Uploading to Cloudinary (HTTP)...');
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Upload to Cloudinary using unsigned preset
      final response = await http.post(
        Uri.parse(
          'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload'
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file': 'data:image/jpeg;base64,$base64Image',
          'upload_preset': 'ml_default',
          'folder': 'chats/$chatId',
          'public_id': messageId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['secure_url'];
        print('✅ Cloudinary upload success: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Cloudinary upload failed: ${response.body}');
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}