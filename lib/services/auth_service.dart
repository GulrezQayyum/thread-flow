import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== EMAIL/PASSWORD AUTH ====================

  // Sign Up
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = result.user;
      if (firebaseUser == null) return null;

      await firebaseUser.updateDisplayName(displayName);

      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(
        userModel.toJson(),
      );

      return userModel;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign In
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = result.user;
      if (firebaseUser == null) return null;

      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Direct Password Reset - Updates password directly
  Future<void> resetPasswordDirectly({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First, sign in with current credentials to verify
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: currentPassword,
      );
      
      final User? firebaseUser = result.user;
      if (firebaseUser == null) {
        throw Exception('User not found');
      }
      
      // Update the password
      await firebaseUser.updatePassword(newPassword);
      
      // Sign out after password change
      await _auth.signOut();
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'user-not-found') {
        throw Exception('User not found with this email');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again before changing password');
      } else {
        throw Exception('Failed to reset password: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // Admin Reset - Reset password without current password (requires admin access)
  Future<void> adminResetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // This requires Firebase Admin SDK - not available in client
      // For client-side, we use the current password method above
      throw Exception('Admin reset not available in client. Use resetPasswordDirectly.');
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // ==================== USER HELPERS ====================

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }
}