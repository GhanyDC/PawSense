import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Checks if a username is already taken in the 'users' collection.
  Future<bool> isUsernameTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String contactNumber,
    required DateTime dateOfBirth,
    required bool agreedToTerms,
    required String address,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    await cred.user?.sendEmailVerification();
    return cred.user?.uid;
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async =>
      await _auth.currentUser?.sendEmailVerification();

  Future<void> saveUser(UserModel user) async {
    try {
      // Always store email in lowercase
      final updatedUser = user.copyWith(email: user.email.trim().toLowerCase());
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updatedUser.toMap());
      debugPrint('User saved: ${user.uid}');
    } catch (e, stack) {
      debugPrint('Error saving user: $e\n$stack');
      rethrow;
    }
  }

  Future<void> signOut() async => _auth.signOut();

  Stream<bool> get emailVerifiedStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      if (await isEmailVerified()) {
        yield true;
        break;
      }
      yield false;
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    return cred.user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    return await _auth.fetchSignInMethodsForEmail(normalizedEmail);
  }
}
