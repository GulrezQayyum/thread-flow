// lib/providers/auth_provider.dart
import 'dart:io';
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

// ==================== FIX: currentUserStreamProvider ====================
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;

    // Fetch full user data from Firestore including avatarBase64
    final userModel = await authService.getUserById(firebaseUser.uid);

    // If user exists in Firestore, return it (with avatarBase64)
    if (userModel != null) {
      return userModel;
    }

    // Fallback: create from Firebase auth data
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'Anonymous',
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      emailVerified: firebaseUser.emailVerified,
    );
  });
});

// ==================== AUTH STATE ====================

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

// ==================== AUTH CONTROLLER ====================

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  // ==================== AUTHENTICATION ====================

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

  // ==================== PROFILE MANAGEMENT ====================

  Future<void> updateDisplayName(String newName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateDisplayName(newName);

      final user = authService.currentUser;
      if (user != null) {
        final updatedUser = await authService.getUserById(user.uid);
        state = state.copyWith(user: updatedUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updatePhotoURL(String photoURL) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updatePhotoURL(photoURL);

      final user = authService.currentUser;
      if (user != null) {
        final updatedUser = await authService.getUserById(user.uid);
        state = state.copyWith(user: updatedUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update Profile Picture (Base64)

  Future<void> updateProfilePicture({required String base64Image}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      await authService.updateProfilePicture(
        userId: user.uid,
        base64Image: base64Image,
      );

      // Force refresh user data
      final updatedUser = await authService.getUserById(user.uid);
      state = state.copyWith(user: updatedUser, isLoading: false);

      // Invalidate the stream to force rebuild
      ref.invalidate(currentUserStreamProvider);

      print('✅ Avatar updated and cached cleared');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
  // ==================== PASSWORD MANAGEMENT ====================

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

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

  // ==================== ACCOUNT MANAGEMENT ====================

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateLastSeen() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null) {
        await authService.updateUserLastSeen(user.uid);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> refreshUser() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null) {
        final updatedUser = await authService.getUserById(user.uid);
        state = state.copyWith(user: updatedUser);
      }
    } catch (e) {
      // Silent fail
    }
  }
}
