// lib/providers/auth_provider.dart
import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

// Stream of Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current authenticated user
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;
  if (user == null) return null;
  return authService.getUserById(user.uid);
});

// Watch current user profile in real-time
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;
  if (user == null) return Stream.value(null);
  return authService.watchUser(user.uid);
});

// Sign up provider
final signUpProvider = FutureProvider.family<UserModel?, SignUpParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signUp(
    email: params.email,
    password: params.password,
    displayName: params.displayName,
  );
});

// Sign in provider
final signInProvider = FutureProvider.family<UserModel?, SignInParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signIn(
    email: params.email,
    password: params.password,
  );
});

// Sign out provider
final signOutProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signOut();
});

// Update profile provider
final updateProfileProvider = FutureProvider.family<void, UpdateProfileParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  await authService.updateUserProfile(
    displayName: params.displayName,
    photoURL: params.photoURL,
  );
  // Refresh current user
  ref.invalidate(currentUserStreamProvider);
});

// Parameter classes
class SignUpParams {
  final String email;
  final String password;
  final String displayName;

  SignUpParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}

class UpdateProfileParams {
  final String displayName;
  final String? photoURL;

  UpdateProfileParams({
    required this.displayName,
    this.photoURL,
  });
}