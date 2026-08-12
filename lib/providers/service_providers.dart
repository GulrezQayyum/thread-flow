import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/groq_service.dart';
import '../services/auth_service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());
final storageServiceProvider = Provider((ref) => StorageService());
final groqServiceProvider = Provider((ref) => GroqService());  
final authServiceProvider = Provider((ref) => AuthService());