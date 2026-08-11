import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class ImageCompressionService {
  static const int maxSizeBytes = 900000; // ~900KB (under 1MB limit)
  static const double maxWidth = 800.0;   // Changed to double
  static const double maxHeight = 800.0;  // Changed to double
  static const int quality = 70;

  /// Compress image to stay under 1MB
  static Future<File> compressImage(File imageFile) async {
    try {
      // Get original size
      final originalSize = await imageFile.length();
      print('📷 Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

      // If already small enough, return original
      if (originalSize < maxSizeBytes) {
        print('📷 Image already small enough, skipping compression');
        return imageFile;
      }

      // Get temp directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth.toInt(),   // Convert to int for compressAndGetFile
        minHeight: maxHeight.toInt(), // Convert to int for compressAndGetFile
      );

      if (result == null) {
        print('⚠️ Compression failed, using original');
        return imageFile;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      print('📷 Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');

      return compressedFile;
    } catch (e) {
      print('❌ Compression error: $e');
      return imageFile; // Return original on error
    }
  }

  /// Pick and compress image from gallery
  static Future<File?> pickAndCompressImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,      // Now double ✓
        maxHeight: maxHeight,    // Now double ✓
        imageQuality: quality,   // int ✓
      );

      if (image == null) return null;
      
      final file = File(image.path);
      return await compressImage(file);
    } catch (e) {
      print('❌ Pick image error: $e');
      return null;
    }
  }

  /// Pick and compress image from camera
  static Future<File?> pickAndCompressImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,      // Now double ✓
        maxHeight: maxHeight,    // Now double ✓
        imageQuality: quality,   // int ✓
      );

      if (image == null) return null;
      
      final file = File(image.path);
      return await compressImage(file);
    } catch (e) {
      print('❌ Pick camera image error: $e');
      return null;
    }
  }
}