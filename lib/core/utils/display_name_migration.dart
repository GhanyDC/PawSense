import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/user_utils.dart';

/// Utility class to help migrate existing users to have proper display names
/// This is a one-time migration helper to fix email display name issues
class DisplayNameMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Updates the display name for the currently logged-in user
  /// Call this after user login to ensure their Firebase Auth profile has proper display name
  static Future<void> updateCurrentUserDisplayName() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final userModel = UserModel.fromMap(userData);
      
      // Update Firebase Auth display name
      final displayName = UserUtils.getDisplayName(userModel);
      await firebaseUser.updateDisplayName(displayName);
      
      print('✅ Updated display name for user ${firebaseUser.uid}: $displayName');
    } catch (e) {
      print('❌ Failed to update display name: $e');
    }
  }
  
  /// Updates display names for all users in Firestore (Admin use only)
  /// This should only be called by administrators to fix existing user accounts
  static Future<void> migrateAllUsersDisplayNames() async {
    try {
      // Get all users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      
      print('🔄 Starting display name migration for ${usersSnapshot.docs.length} users...');
      
      int successful = 0;
      int failed = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data();
          final userModel = UserModel.fromMap(userData);
          
          // For this migration, we can't update Firebase Auth directly since we're not signed in as each user
          // Instead, we'll log what display name should be set for each user
          final displayName = UserUtils.getDisplayName(userModel);
          
          print('📋 User ${userModel.uid} should have display name: "$displayName"');
          print('   Email: ${userModel.email}');
          print('   Name: ${userModel.firstName ?? 'N/A'} ${userModel.lastName ?? 'N/A'}');
          print('   Username: ${userModel.username}');
          print('   ---');
          
          successful++;
        } catch (e) {
          print('❌ Failed to process user ${userDoc.id}: $e');
          failed++;
        }
      }
      
      print('✅ Migration analysis complete!');
      print('   Processed: $successful users');
      print('   Failed: $failed users');
      print('');
      print('📌 NOTE: Display names will be automatically updated when users next sign in.');
      print('   The authentication services have been updated to set display names properly.');
      
    } catch (e) {
      print('❌ Failed to migrate display names: $e');
    }
  }
  
  /// Helper method to check if current user needs display name update
  static Future<bool> currentUserNeedsDisplayNameUpdate() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return false;
      
      // Check if display name is already set and looks correct
      final currentDisplayName = firebaseUser.displayName;
      if (currentDisplayName == null || currentDisplayName.isEmpty) {
        return true;
      }
      
      // Get user data from Firestore to compare
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      final userModel = UserModel.fromMap(userData);
      final expectedDisplayName = UserUtils.getDisplayName(userModel);
      
      // If display names don't match, update is needed
      return currentDisplayName != expectedDisplayName;
      
    } catch (e) {
      return false;
    }
  }
}