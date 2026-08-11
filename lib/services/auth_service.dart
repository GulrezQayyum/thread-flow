import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up - ENSURES user document is created
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 SIGNUP: Starting signup for $email');

      // Step 1: Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create Firebase auth user');

      print('✅ SIGNUP: Firebase user created: ${user.uid}');

      // Step 2: Update display name
      await user.updateDisplayName(displayName);
      print('✅ SIGNUP: Display name updated');

      // Step 3: Create Firestore user document
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toJson(),
        SetOptions(merge: true),
      );

      print('✅ SIGNUP: Firestore user document created');

      // Step 4: Verify document was created
      final verifyDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!verifyDoc.exists) {
        throw Exception('User document was not created in Firestore');
      }

      print('✅ SIGNUP: User document verified in Firestore');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ SIGNUP AUTH ERROR: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ SIGNUP ERROR: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in - Ensures user document exists
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 SIGNIN: Starting signin for $email');

      // Step 1: Sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to sign in');

      print('✅ SIGNIN: Firebase auth successful: ${user.uid}');

      // Step 2: Update lastSeen
      await _firestore.collection('users').doc(user.uid).update({
        'lastSeen': DateTime.now(),
      }).catchError((e) {
        print('⚠️ SIGNIN: Could not update lastSeen: $e');
      });

      // Step 3: Get user document
      final userModel = await getUserById(user.uid);

      if (userModel == null) {
        print('⚠️ SIGNIN: User document not found, creating...');
        final newUser = UserModel(
          uid: user.uid,
          email: email.trim(),
          displayName: user.displayName ?? 'User',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(
          newUser.toJson(),
          SetOptions(merge: true),
        );
        print('✅ SIGNIN: Created missing user document');
        return newUser;
      }

      print('✅ SIGNIN: User found: ${userModel.displayName}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ SIGNIN AUTH ERROR: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ SIGNIN ERROR: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  /// Get user by ID with detailed debugging
  Future<UserModel?> getUserById(String uid) async {
    try {
      print('📋 GETUSER: Fetching user: $uid');

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print('❌ GETUSER: User document does NOT exist: $uid');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print('⚠️ GETUSER: Document exists but data is null: $uid');
        return null;
      }

      print('✅ GETUSER: Document found with data: $data');
      final userModel = UserModel.fromJson(data);
      print('✅ GETUSER: User model created: ${userModel.displayName}');
      return userModel;
    } catch (e) {
      print('❌ GETUSER ERROR: $e');
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Watch user profile in real-time
  Stream<UserModel?> watchUser(String uid) {
    print('👁️ WATCHUSER: Starting watch for $uid');
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        print('⚠️ WATCHUSER: Document not found: $uid');
        return null;
      }
      try {
        final userModel = UserModel.fromJson(doc.data()!);
        print('✅ WATCHUSER: Update received for ${userModel.displayName}');
        return userModel;
      } catch (e) {
        print('❌ WATCHUSER ERROR: $e');
        return null;
      }
    }).handleError((error) {
      print('❌ WATCHUSER STREAM ERROR: $error');
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

      print('✏️ UPDATE: Updating profile for ${user.uid}');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });

      print('✅ UPDATE: Profile updated');
    } catch (e) {
      print('❌ UPDATE ERROR: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final user = currentUser;
      if (user != null) {
        print('👋 SIGNOUT: Signing out ${user.uid}');

        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': DateTime.now(),
        }).catchError((e) {
          print('⚠️ SIGNOUT: Could not update lastSeen: $e');
        });
      }

      await _auth.signOut();
      print('✅ SIGNOUT: Complete');
    } catch (e) {
      print('❌ SIGNOUT ERROR: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      print('🗑️ DELETE: Deleting account ${user.uid}');

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      print('✅ DELETE: Account deleted');
    } catch (e) {
      print('❌ DELETE ERROR: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('📧 RESET: Sending reset email to $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ RESET: Email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ RESET AUTH ERROR: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ RESET ERROR: $e');
      throw Exception('Failed to send password reset: $e');
    }
  }

  /// Handle Firebase auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'weak-password' => 'Password too weak. Use 6+ chars with mixed case.',
      'email-already-in-use' => 'Email already registered.',
      'invalid-email' => 'Invalid email format.',
      'user-disabled' => 'Account has been disabled.',
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'too-many-requests' => 'Too many attempts. Try later.',
      'network-request-failed' => 'Network error. Check connection.',
      _ => 'Auth error: ${e.message}',
    };
    print('❌ AUTH EXCEPTION: $message');
    return message;
  }
}