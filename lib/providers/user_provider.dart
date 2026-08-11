// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'service_providers.dart'; // Import from here

// Get a single user by ID (Stream)
final userStreamProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUser(userId);
});

// Get a single user by ID (Future)
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUser(userId);
});

// Get multiple users by IDs
final usersProvider = FutureProvider.family<List<UserModel>, List<String>>((ref, userIds) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUsers(userIds);
});

// Search users by email
final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, email) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.searchUsersByEmail(email);
});