// Vet Profile Services - Modular Architecture
// 
// This file provides easy access to all the specialized vet profile services
// 
// Usage Examples:
// 
// For new development, import specific services:
// import 'package:pawsense/core/services/vet_profile_services.dart';
// final profile = await ProfileManagementService.getVetProfile();
// 
// For backward compatibility:
// import 'package:pawsense/core/services/vet_profile_services.dart';
// final profile = await VetProfileLegacyService.getVetProfile();

// Core specialized services
export 'profile_management_service.dart';
export '../clinic/clinic_service.dart';
export '../clinic/clinic_details_service.dart';
export '../clinic/clinic_services_management_service.dart';
export 'specialization_service.dart';

/// Service collection class for organized access to all vet profile services
class VetProfileServices {
  /// Get all available service names for debugging
  static List<String> get availableServices => [
    'ProfileManagementService',
    'ClinicService', 
    'ClinicDetailsService',
    'ClinicServicesManagementService',
    'SpecializationService',
  ];
  
  /// Print service architecture info
  static void printArchitectureInfo() {
    print('=== VET PROFILE SERVICES ARCHITECTURE ===');
    print('');
    print('Specialized Services:');
    for (final service in availableServices) {
      print('- $service');
    }
    print('');
    print('See README/VET_PROFILE_REFACTORING_SUMMARY.md for detailed documentation');
    print('==========================================');
  }
}
