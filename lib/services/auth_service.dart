// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toJson());

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

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // ==================== PASSWORD RESET METHODS ====================

  /// Send password reset email
  // Future<void> sendPasswordResetEmail({required String email}) async {
  //   try {
  //     await _auth.sendPasswordResetEmail(email: email);
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'user-not-found') {
  //       throw Exception('No account found with this email');
  //     } else if (e.code == 'invalid-email') {
  //       throw Exception('Please enter a valid email address');
  //     } else {
  //       throw Exception('Failed to send reset email: ${e.message}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to send reset email: $e');
  //   }
  // }

  /// Reset password directly (requires user to be authenticated)
  Future<void> resetPasswordDirectly({
    required String email,
    required String newPassword,
  }) async {
    try {
      // This sends a password reset email
      // The user must click the link to set the new password
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Please enter a valid email address');
      } else {
        throw Exception('Failed to send reset email: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
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
