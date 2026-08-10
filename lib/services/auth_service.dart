// lib/services/auth_service.dart - CORRECTED & COMPLETE VERSION
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user from Firebase Auth
  User? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      print('✅ Current user: ${user.uid} (${user.email})');
    }
    return user;
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 Signing up: $email');
      
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName(displayName);
      await user.reload();

      print('✅ Firebase Auth user created: ${user.uid}');

      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toJson(),
      );

      print('✅ Firestore user document created');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign up error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error during sign up: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Signing in: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      print('✅ Firebase Auth sign in successful: ${user.uid}');

      // Update lastSeen timestamp
      await _firestore.collection('users').doc(user.uid).update({
        'lastSeen': DateTime.now(),
      }).catchError((e) {
        print('⚠️ Could not update lastSeen: $e');
      });

      // Fetch and return user model
      final userModel = await getUserById(user.uid);
      print('✅ User profile fetched');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error during sign in: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  /// Get user profile by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      print('📋 Fetching user: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print('⚠️ User document not found: $uid');
        return null;
      }

      final userModel = UserModel.fromJson(doc.data()!);
      print('✅ User fetched: ${userModel.displayName}');
      return userModel;
    } catch (e) {
      print('❌ Error fetching user: $e');
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Watch user profile in real-time
  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        print('⚠️ User document deleted: $uid');
        return null;
      }
      return UserModel.fromJson(doc.data()!);
    }).handleError((error) {
      print('❌ Error watching user: $error');
    });
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      print('✏️ Updating profile: $displayName');

      // Update Firebase Auth
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });

      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final user = currentUser;
      if (user != null) {
        print('👋 Signing out: ${user.uid}');
        
        // Update lastSeen before signing out
        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': DateTime.now(),
        }).catchError((e) {
          print('⚠️ Could not update lastSeen: $e');
        });
      }

      await _auth.signOut();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      print('🗑️ Deleting account: ${user.uid}');

      // Delete Firestore user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();

      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('📧 Sending password reset to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error sending password reset: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with uppercase, lowercase, and numbers.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}