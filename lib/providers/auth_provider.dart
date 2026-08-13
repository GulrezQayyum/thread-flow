// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((firebaseUser) {
    if (firebaseUser == null) return null;
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'Anonymous',
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  });
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signIn(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // ==================== PASSWORD RESET METHODS ====================

  /// Send password reset email - FIXED: Now inside AuthController
  // Future<void> sendPasswordResetEmail({
  //   required String email,
  // }) async {
  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     final authService = ref.read(authServiceProvider);
  //     await authService.sendPasswordResetEmail(email: email);
  //     state = state.copyWith(isLoading: false);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //     rethrow;
  //   }
  // }

  /// Reset password directly (for authenticated users)
  Future<void> resetPasswordDirectly({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPasswordDirectly(
        email: email,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
