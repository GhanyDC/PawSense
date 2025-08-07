import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
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

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    await user?.sendEmailVerification();
  }

  Future<void> saveUser({
    required String uid,
    required String username,
    required String email,
  }) async {
    try {
      final user = UserModel(uid: uid, username: username, email: email);
      await _firestore.collection('users').doc(uid).set(user.toMap());
      debugPrint('User saved to Firestore: \\${user.toMap()}');
    } catch (e, stack) {
      debugPrint('Error saving user to Firestore: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream that emits true when the user's email is verified.
  Stream<bool> get emailVerifiedStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      final user = _auth.currentUser;
      await user?.reload();
      yield user?.emailVerified ?? false;
      if (user?.emailVerified == true) break;
    }
  }

  User? get currentUser => _auth.currentUser;
}
