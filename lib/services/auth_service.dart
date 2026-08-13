// lib/services/auth_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== SIGN IN ====================

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

  // ==================== SIGN UP ====================

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
        emailVerified: firebaseUser.emailVerified,
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

  // ==================== SIGN OUT ====================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // ==================== UPDATE DISPLAY NAME ====================

  Future<void> updateDisplayName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await user.updateDisplayName(newName);

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': newName,
      });
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  // ==================== UPDATE PHOTO URL ====================

  Future<void> updatePhotoURL(String photoURL) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await user.updatePhotoURL(photoURL);

      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
      });
    } catch (e) {
      throw Exception('Failed to update photo: $e');
    }
  }

  // ==================== UPDATE PROFILE PICTURE (Base64) ====================

Future<void> updateProfilePicture({
  required String userId,
  required String base64Image,
}) async {
  try {
    print('📤 Updating profile picture for user: $userId');
    print('📤 Image size: ${base64Image.length ~/ 1024} KB');
    
    // Check size
    final sizeInBytes = base64Image.length;
    if (sizeInBytes > 800000) {
      throw Exception('Image too large. Please use a smaller image.');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'avatarBase64': base64Image,
    });
    
    print('✅ Profile picture updated in Firestore');
  } catch (e) {
    print('❌ Failed to update profile picture: $e');
    throw Exception('Failed to update profile picture: $e');
  }
}

  // ==================== UPDATE USER IN FIRESTORE ====================

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ==================== CHANGE PASSWORD ====================

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // ==================== SEND PASSWORD RESET EMAIL ====================

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
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

  // ==================== RESET PASSWORD DIRECTLY ====================

  Future<void> resetPasswordDirectly({
    required String email,
    required String newPassword,
  }) async {
    try {
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

  // ==================== UPDATE USER LAST SEEN ====================

  Future<void> updateUserLastSeen(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw - this is optional
    }
  }

  // ==================== DELETE ACCOUNT ====================

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
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

  // ==================== GET USER BY ID ====================

  Future<UserModel?> getUserById(String uid) async {
    return await _getUserFromFirestore(uid);
  }

  // ==================== CHECK IF EMAIL EXISTS ====================

  Future<bool> emailExists(String email) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return usersSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
