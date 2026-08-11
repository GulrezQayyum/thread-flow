import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

// Pick image from gallery
final pickImageProvider = FutureProvider<File?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.pickImage();
});

// Pick image from camera
final pickImageFromCameraProvider = FutureProvider<File?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.pickImageFromCamera();
});

// Upload image to storage
final uploadImageProvider = FutureProvider.family<String, UploadImageParams>((ref, params) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.uploadChatImage(
    chatId: params.chatId,
    messageId: params.messageId,
    imageFile: params.imageFile,
  );
});

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