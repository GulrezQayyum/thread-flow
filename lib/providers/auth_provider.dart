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

// --- Modern AsyncNotifier for Auth Actions ---

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is data with no loading/error
    return;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    });
  }
}

// Auth Controller Provider
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

// Update profile provider
final updateProfileProvider = FutureProvider.family<void, UpdateProfileParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  await authService.updateUserProfile(
    displayName: params.displayName,
    photoURL: params.photoURL,
  );
  ref.invalidate(currentUserStreamProvider);
});

// Parameter classes
class UpdateProfileParams {
  final String displayName;
  final String? photoURL;

  UpdateProfileParams({
    required this.displayName,
    this.photoURL,
  });
}