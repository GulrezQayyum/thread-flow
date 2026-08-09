import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create user');

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toJson(),
      );

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to sign in');

      // Update lastSeen
      await _firestore.collection('users').doc(user.uid).update({
        'lastSeen': DateTime.now(),
      });

      // Fetch and return user model
      return await getUserById(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Watch user profile (real-time)
  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update Firebase Auth
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Update lastSeen before signing out
        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': DateTime.now(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete Firestore user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'invalid-email':
        return 'Email format is invalid.';
      case 'user-disabled':
        return 'User account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}