import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      print('✅ Firebase initialized');

      // Enable Firestore offline persistence
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        print('✅ Firestore offline persistence enabled');
      } catch (e) {
        print('⚠️ Could not enable offline persistence: $e');
      }

      // Set Firebase Auth language
      FirebaseAuth.instance.setLanguageCode('en');

      print('✅ Firebase Auth configured');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }
}