// lib/providers/storage_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_storage_service.dart';
import 'service_providers.dart';

// Cloudinary service provider
final cloudinaryServiceProvider = Provider((ref) => CloudinaryStorageService());

// ==================== IMAGE PICKERS ====================

// Pick image from gallery
final pickImageProvider = FutureProvider<File?>((ref) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (image == null) return null;
    print('📷 Image picked from gallery');
    return File(image.path);
  } catch (e) {
    print('❌ Pick image error: $e');
    return null;
  }
});

// Pick image from camera
final pickImageFromCameraProvider = FutureProvider<File?>((ref) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (image == null) return null;
    print('📷 Image picked from camera');
    return File(image.path);
  } catch (e) {
    print('❌ Pick camera error: $e');
    return null;
  }
});

// ==================== IMAGE UPLOAD ====================

// Upload image to Cloudinary
final uploadImageProvider = FutureProvider.family<String, UploadImageParams>((ref, params) async {
  final cloudinary = ref.watch(cloudinaryServiceProvider);
  return cloudinary.uploadChatImage(
    chatId: params.chatId,
    messageId: params.messageId,
    imageFile: XFile(params.imageFile.path),
  );
});

// ==================== IMAGE DATA (For Firestore stored images) ====================

// Get image from Firestore (if using base64 storage) - ADD THIS
final getImageProvider = FutureProvider.family<String?, GetImageParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getImageData(params.chatId, params.messageId);
});

// ==================== PARAMETER CLASSES ====================

class UploadImageParams {
  final String chatId;
  final String messageId;
  final File imageFile;

  UploadImageParams({
    required this.chatId,
    required this.messageId,
    required this.imageFile,
  });
}

class GetImageParams {
  final String chatId;
  final String messageId;

  GetImageParams({
    required this.chatId,
    required this.messageId,
  });
}