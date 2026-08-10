import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Future<String> uploadChatImage({
    required String chatId,
    required String messageId,
    required File imageFile,
  }) async {
    try {
      final path = 'chats/$chatId/messages/$messageId/image.jpg';
      final ref = _storage.ref().child(path);

      // Upload with metadata
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'messageId': messageId,
            'chatId': chatId,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<File?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to 80%
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        final path = pathSegments.sublist(4).join('/').split('?')[0];
        await _storage.ref().child(path).delete();
      }
    } catch (e) {
      print('Warning: Failed to delete image: $e');
      // Don't throw - image already deleted from Firestore
    }
  }
}