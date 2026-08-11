import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  // Upload chat image
  Future<String> uploadChatImage({
    required String chatId,
    required String messageId,
    required File imageFile,
  }) async {
    try {
      final fileName = 'chats/$chatId/images/${messageId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref(fileName);
      
      // Upload file
      await ref.putFile(imageFile);
      
      // Get download URL
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required String chatId,
    required String messageId,
    required List<File> imageFiles,
  }) async {
    try {
      final List<String> urls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileName = 'chats/$chatId/images/${messageId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref(fileName);
        
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}