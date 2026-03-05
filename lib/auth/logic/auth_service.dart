import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool?> isUsernameUnique(String username) async {
    if (username.isEmpty) return false;
    try {
      final doc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      return !doc.exists;
    } catch (e) {
      debugPrint('Username check error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  getEmail() {
    return _firebaseAuth.currentUser?.email;
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        default:
          message = e.message ?? 'An unknown error occurred during sign-in.';
          break;
      }
      throw Exception(
        message,
      ); // Rethrow as a generic Exception for UI to catch
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> registerWithEmailAndPassword({
    required String username,
    required String email,
    required String password
} ) async {
    try {
      UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      WriteBatch batch = _firestore.batch();

      DocumentReference userDoc = _firestore.collection('users').doc(credential.user!.uid);
      DocumentReference nameDoc = _firestore.collection('usernames').doc(username.toLowerCase());
      batch.set(userDoc, {
        'uid': credential.user!.uid,
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(nameDoc, {'uid': credential.user!.uid});
      await batch.commit();
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message =
              e.message ?? 'An unknown error occurred during registration.';
          break;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Sends a password reset email to the given email address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message =
              e.message ?? 'An unknown error occurred sending reset email.';
          break;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
