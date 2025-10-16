import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clinic/clinic_model.dart';
import '../../guards/auth_guard.dart';

/// Service for managing clinic basic information
class ClinicService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get clinic data by user ID
  static Future<Clinic?> getClinicData(String userId) async {
    try {
      final doc = await _firestore.collection('clinics').doc(userId).get();
      if (doc.exists) {
        return Clinic.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting clinic data: $e');
      return null;
    }
  }
  
  /// Update clinic basic information
  static Future<bool> updateClinicBasicInfo({
    required String clinicName,
    required String address,
    required String phone,
    required String email,
    String? website,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      // Update clinic document
      await _firestore.collection('clinics').doc(currentUser.uid).update({
        'clinicName': clinicName,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
      });
      
      // Update clinic details if exists
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'clinicName': clinicName,
          'address': address,
          'phone': phone,
          'email': email,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error updating clinic basic info: $e');
      return false;
    }
  }
  
  /// Get clinic by current user
  static Future<Clinic?> getCurrentUserClinic() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;
      
      return await getClinicData(currentUser.uid);
    } catch (e) {
      print('Error getting current user clinic: $e');
      return null;
    }
  }
  
  /// Check if clinic exists for user
  static Future<bool> clinicExists(String userId) async {
    try {
      final doc = await _firestore.collection('clinics').doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if clinic exists: $e');
      return false;
    }
  }
  
  /// Create a new clinic for the current user
  static Future<bool> createClinic({
    required String clinicName,
    required String address,
    required String phone,
    required String email,
    String? website,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      // Create clinic document
      await _firestore.collection('clinics').doc(currentUser.uid).set({
        'clinicName': clinicName,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website ?? '',
        'ownerId': currentUser.uid,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error creating clinic: $e');
      return false;
    }
  }
  
  /// Update clinic logo URL
  static Future<bool> updateClinicLogo(String logoUrl) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      // Update clinic document
      await _firestore.collection('clinics').doc(currentUser.uid).update({
        'logoUrl': logoUrl,
      });
      
      // Update clinic details if exists
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'logoUrl': logoUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error updating clinic logo: $e');
      return false;
    }
  }
}
