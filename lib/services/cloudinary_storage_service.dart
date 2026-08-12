import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Make sure you use XFile
import '../config/cloudinary_config.dart';

class CloudinaryStorageService {
  Future<String> uploadChatImage({
    required String chatId,
    required String messageId,
    required XFile imageFile, // Changed from File to XFile
  }) async {
    try {
      print('📤 Uploading to Cloudinary...');
      
      // XFile handles web and mobile bytes safely without dart:io File crashes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('📤 Image encoded, size: ${base64Image.length} chars');
      
      // Upload to Cloudinary
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