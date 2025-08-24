import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/user/user_model.dart';

class UserServices {
  final _firestore = FirebaseFirestore.instance;

  // Get user by uid
  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _firestore.collection('users').where('email', isEqualTo: email.trim().toLowerCase()).limit(1).get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Stream user document
  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // List all users (use with caution for large collections)
  Future<List<UserModel>> getAllUsers() async {
    final query = await _firestore.collection('users').get();
    return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }
}
