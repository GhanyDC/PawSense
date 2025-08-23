import 'package:cloud_firestore/cloud_firestore.dart';
import '../../guards/auth_guard.dart';

/// Service for managing clinic services (add, update, delete, toggle)
class ClinicServicesManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Add new service with dynamic field handling
  static Future<bool> addService({
    required String serviceName,
    required String serviceDescription,
    required String estimatedPrice,
    required String duration,
    required String category,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? additionalFields,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;

      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);

        // Generate service name if empty
        String finalServiceName = serviceName.trim().isEmpty 
            ? _generateServiceNameFromDescription(serviceDescription, category)
            : serviceName;

        // Create new service with all required fields and additional fields
        final newService = {
          'id': 'service-${DateTime.now().millisecondsSinceEpoch}',
          'clinicId': currentUser.uid,
          'serviceName': finalServiceName,
          'serviceDescription': serviceDescription.trim().isEmpty 
              ? 'Professional veterinary service' 
              : serviceDescription,
          'estimatedPrice': estimatedPrice.trim().isEmpty 
              ? '0.00' 
              : estimatedPrice,
          'duration': duration.trim().isEmpty 
              ? '30 mins' 
              : duration,
          'category': category,
          'isActive': isActive ?? true,
          'isVerified': isVerified ?? false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': null,
          // Add any additional fields dynamically
          ...?additionalFields,
        };

        // Add the new service
        services.add(newService);

        await doc.reference.update({
          'services': services,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Error adding service: $e');
      return false;
    }
  }

  /// Update existing service with dynamic field handling
  static Future<bool> updateService({
    required String serviceId,
    String? serviceName,
    String? serviceDescription,
    String? estimatedPrice,
    String? duration,
    String? category,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? additionalFields,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;

      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);

        // Find and update the service
        final serviceIndex = services.indexWhere((s) => s['id'] == serviceId);
        if (serviceIndex != -1) {
          final existingService = services[serviceIndex];
          
          // Generate service name if provided name is empty
          String? finalServiceName = serviceName;
          if (serviceName != null && serviceName.trim().isEmpty && serviceDescription != null) {
            finalServiceName = _generateServiceNameFromDescription(
              serviceDescription,
              category ?? existingService['category'] ?? 'general'
            );
          }

          // Update service with provided fields
          services[serviceIndex] = {
            ...existingService, // Keep existing fields like id, clinicId, etc.
            if (finalServiceName != null) 'serviceName': finalServiceName,
            if (serviceDescription != null) 'serviceDescription': serviceDescription,
            if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
            if (duration != null) 'duration': duration,
            if (category != null) 'category': category,
            if (isActive != null) 'isActive': isActive,
            if (isVerified != null) 'isVerified': isVerified,
            'updatedAt': DateTime.now().toIso8601String(),
            // Add any additional fields dynamically
            ...?additionalFields,
          };

          await doc.reference.update({
            'services': services,
            'updatedAt': DateTime.now().toIso8601String(),
          });

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }
  
  /// Toggle service status
  static Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
        
        // Find and update the specific service
        final serviceIndex = services.indexWhere((s) => s['id'] == serviceId);
        if (serviceIndex != -1) {
          services[serviceIndex]['isActive'] = isActive;
          services[serviceIndex]['updatedAt'] = DateTime.now().toIso8601String();
          
          await doc.reference.update({
            'services': services,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling service status: $e');
      return false;
    }
  }
  
  /// Delete service
  static Future<bool> deleteService(String serviceId) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
        
        // Remove the service
        services.removeWhere((s) => s['id'] == serviceId);
        
        await doc.reference.update({
          'services': services,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }
  
  /// Fix existing services with missing required fields
  static Future<bool> fixExistingServices() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;

      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);

        // Fix each service with missing fields
        for (int i = 0; i < services.length; i++) {
          final service = services[i];
          
          // Add missing required fields and fix empty serviceName
          services[i] = {
            'id': service['id'] ?? 'service-${DateTime.now().millisecondsSinceEpoch}-$i',
            'clinicId': service['clinicId'] ?? currentUser.uid,
            'serviceName': service['serviceName']?.isEmpty == true || service['serviceName'] == null 
                ? _generateServiceNameFromDescription(service['serviceDescription'] ?? 'Unknown Service', service['category'] ?? 'other')
                : service['serviceName'],
            'serviceDescription': service['serviceDescription'] ?? 'No description',
            'estimatedPrice': service['estimatedPrice'] ?? '0.00',
            'duration': service['duration'] ?? '30 minutes',
            'category': service['category'] ?? 'other',
            'isActive': service['isActive'] ?? true, // Default to active
            'createdAt': service['createdAt'] ?? DateTime.now().toIso8601String(),
            'updatedAt': service['updatedAt'] ?? DateTime.now().toIso8601String(),
          };
        }

        await doc.reference.update({
          'services': services,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Error fixing existing services: $e');
      return false;
    }
  }

  /// Generate service name from description and category
  static String _generateServiceNameFromDescription(String description, String category) {
    // Create a service name based on description and category
    if (description.toLowerCase().contains('skin scraping') || description.toLowerCase().contains('microscopic examination')) {
      return 'Skin Scraping & Analysis';
    } else if (description.toLowerCase().contains('vaccination')) {
      return 'Vaccination Package';
    } else if (description.toLowerCase().contains('dental')) {
      return 'Dental Cleaning';
    } else if (description.toLowerCase().contains('emergency') || description.toLowerCase().contains('surgery')) {
      return 'Emergency Surgery';
    } else if (description.toLowerCase().contains('consultation')) {
      return 'General Consultation';
    } else if (description.toLowerCase().contains('grooming')) {
      return 'Pet Grooming Service';
    } else {
      // Fallback: Use category + "Service"
      final categoryName = category[0].toUpperCase() + category.substring(1);
      return '$categoryName Service';
    }
  }
  
  /// Get all services for current clinic
  static Future<List<Map<String, dynamic>>> getClinicServices({bool activeOnly = false}) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return [];

      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
        
        if (activeOnly) {
          return services.where((service) => service['isActive'] == true).toList();
        }
        
        return services;
      }
      return [];
    } catch (e) {
      print('Error getting clinic services: $e');
      return [];
    }
  }
  
  /// Get service by ID
  static Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      final services = await getClinicServices();
      
      final service = services.firstWhere(
        (s) => s['id'] == serviceId,
        orElse: () => {},
      );
      
      return service.isEmpty ? null : service;
    } catch (e) {
      print('Error getting service by ID: $e');
      return null;
    }
  }
}
