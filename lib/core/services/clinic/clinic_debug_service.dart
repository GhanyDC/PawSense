import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility service for testing and debugging clinic data
class ClinicDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all clinics and their status for debugging
  static Future<void> debugAllClinics() async {
    try {
      print('=== CLINIC DEBUG SERVICE ===');
      
      final clinicsSnapshot = await _firestore
          .collection('clinics')
          .get();
      
      print('Total clinics in database: ${clinicsSnapshot.docs.length}');
      
      if (clinicsSnapshot.docs.isEmpty) {
        print('❌ No clinics found in database');
        print('You need to create some clinics first.');
        return;
      }
      
      for (var doc in clinicsSnapshot.docs) {
        final data = doc.data();
        print('---');
        print('Clinic ID: ${doc.id}');
        print('Clinic Name: ${data['clinicName']}');
        print('Status: ${data['status']}');
        print('Address: ${data['address']}');
        print('Phone: ${data['phone']}');
        print('Email: ${data['email']}');
      }
      
      print('=== END DEBUG ===');
      
    } catch (e) {
      print('Error in debugAllClinics: $e');
    }
  }

  /// Approve all pending clinics (for testing purposes)
  static Future<void> approveAllPendingClinics() async {
    try {
      print('=== APPROVING PENDING CLINICS ===');
      
      final clinicsSnapshot = await _firestore
          .collection('clinics')
          .where('status', isEqualTo: 'pending')
          .get();
      
      print('Found ${clinicsSnapshot.docs.length} pending clinics');
      
      for (var doc in clinicsSnapshot.docs) {
        await doc.reference.update({'status': 'approved'});
        final data = doc.data();
        print('✅ Approved clinic: ${data['clinicName']}');
      }
      
      print('=== APPROVAL COMPLETE ===');
      
    } catch (e) {
      print('Error approving clinics: $e');
    }
  }

  /// Create a sample approved clinic for testing
  static Future<void> createSampleApprovedClinic() async {
    try {
      print('=== CREATING SAMPLE APPROVED CLINIC ===');
      
      // Create a unique ID for the sample clinic
      final clinicId = 'sample_clinic_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create clinic document
      await _firestore.collection('clinics').doc(clinicId).set({
        'id': clinicId,
        'userId': clinicId,
        'clinicName': 'Happy Paws Veterinary Clinic',
        'address': '456 Pet Street, Animal City, AC 67890',
        'phone': '+1 (555) 987-6543',
        'email': 'contact@happypaws.com',
        'website': 'www.happypaws.com',
        'status': 'approved', // Directly approved
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Create clinic details
      final clinicDetailsId = 'clinic_details_$clinicId';
      await _firestore.collection('clinicDetails').doc(clinicDetailsId).set({
        'id': clinicDetailsId,
        'clinicId': clinicId,
        'clinicName': 'Happy Paws Veterinary Clinic',
        'description': 'Professional veterinary care for your beloved pets',
        'address': '456 Pet Street, Animal City, AC 67890',
        'phone': '+1 (555) 987-6543',
        'email': 'contact@happypaws.com',
        'operatingHours': 'Mon-Fri: 9AM-7PM, Sat: 9AM-5PM',
        'specialties': ['General Practice', 'Surgery', 'Dental Care'],
        'services': [],
        'certifications': [],
        'licenses': [],
        'isVerified': true,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Created sample approved clinic: Happy Paws Veterinary Clinic');
      print('=== CREATION COMPLETE ===');
      
    } catch (e) {
      print('Error creating sample clinic: $e');
    }
  }

  /// Create multiple sample approved clinics
  static Future<void> createMultipleSampleClinics() async {
    try {
      print('=== CREATING MULTIPLE SAMPLE CLINICS ===');
      
      final clinics = [
        {
          'name': 'Downtown Animal Hospital',
          'address': '123 Main Street, Downtown, DT 12345',
          'phone': '+1 (555) 111-2222',
          'email': 'info@downtownanimalhospital.com',
          'specialties': ['Emergency Care', 'Surgery', 'Radiology'],
        },
        {
          'name': 'Westside Pet Clinic',
          'address': '789 West Ave, Westside, WS 98765',
          'phone': '+1 (555) 333-4444',
          'email': 'care@westsidepets.com',
          'specialties': ['General Practice', 'Vaccinations', 'Wellness'],
        },
        {
          'name': 'City Veterinary Center',
          'address': '321 City Blvd, Central City, CC 55555',
          'phone': '+1 (555) 777-8888',
          'email': 'contact@cityvetcenter.com',
          'specialties': ['Exotic Animals', 'Dental Care', 'Dermatology'],
        },
      ];
      
      for (int i = 0; i < clinics.length; i++) {
        final clinic = clinics[i];
        final clinicId = 'sample_clinic_${DateTime.now().millisecondsSinceEpoch}_$i';
        
        // Create clinic document
        await _firestore.collection('clinics').doc(clinicId).set({
          'id': clinicId,
          'userId': clinicId,
          'clinicName': clinic['name'],
          'address': clinic['address'],
          'phone': clinic['phone'],
          'email': clinic['email'],
          'website': null,
          'status': 'approved',
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        // Create clinic details
        final clinicDetailsId = 'clinic_details_$clinicId';
        await _firestore.collection('clinicDetails').doc(clinicDetailsId).set({
          'id': clinicDetailsId,
          'clinicId': clinicId,
          'clinicName': clinic['name'],
          'description': 'Quality veterinary care for your pets',
          'address': clinic['address'],
          'phone': clinic['phone'],
          'email': clinic['email'],
          'operatingHours': 'Mon-Fri: 8AM-6PM, Sat: 9AM-4PM',
          'specialties': clinic['specialties'],
          'services': [],
          'certifications': [],
          'licenses': [],
          'isVerified': i % 2 == 0, // Alternate verified status
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        print('✅ Created clinic: ${clinic['name']}');
        
        // Small delay to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      print('=== CREATION OF MULTIPLE CLINICS COMPLETE ===');
      
    } catch (e) {
      print('Error creating multiple clinics: $e');
    }
  }
}
