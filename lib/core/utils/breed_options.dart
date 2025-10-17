import 'package:pawsense/core/services/super_admin/pet_breeds_service.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';

/// Utility class for fetching and managing breed options for users
/// Fetches only active breeds from Firebase that are managed by super admin
class BreedOptions {
  // Cache for breeds to avoid excessive Firebase calls
  static List<PetBreed>? _cachedBreeds;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Fallback breeds in case Firebase is unavailable
  static const List<String> _fallbackDogBreeds = [
    'Mixed Breed',
    'Unknown',
  ];

  static const List<String> _fallbackCatBreeds = [
    'Mixed Breed',
    'Unknown',
  ];

  /// Get breeds for a specific pet type (fetches from Firebase)
  /// Returns only active breeds managed by the admin
  static Future<List<String>> getBreedsForPetType(String petType) async {
    try {
      // Check cache validity
      if (_cachedBreeds != null && _lastFetchTime != null) {
        final cacheAge = DateTime.now().difference(_lastFetchTime!);
        if (cacheAge < _cacheExpiry) {
          return _extractBreedNames(_cachedBreeds!, petType);
        }
      }

      // Fetch active breeds from Firebase
      final breeds = await PetBreedsService.fetchAllBreeds(
        statusFilter: 'active', // Only active breeds
        sortBy: 'name_asc',
      );

      // Update cache
      _cachedBreeds = breeds;
      _lastFetchTime = DateTime.now();

      return _extractBreedNames(breeds, petType);
    } catch (e) {
      print('⚠️ Error fetching breeds from Firebase: $e');
      print('📦 Using fallback breed list');
      
      // Return fallback breeds if Firebase fails
      return _getFallbackBreeds(petType);
    }
  }

  /// Extract breed names from PetBreed objects based on species
  static List<String> _extractBreedNames(List<PetBreed> breeds, String petType) {
    final species = petType.toLowerCase();
    
    // Filter by species (already filtered by active status from Firebase query)
    // and extract names
    final filteredBreeds = breeds
        .where((breed) => breed.species.toLowerCase() == species && breed.isActive)
        .map((breed) => breed.name)
        .toList();

    // If list is empty, return fallback breeds
    // This should only happen if no active breeds exist in database
    if (filteredBreeds.isEmpty) {
      return _getFallbackBreeds(petType);
    }

    // Return only the breeds that are active in the database
    // Do NOT add "Mixed Breed" or "Unknown" automatically
    // They should only appear if they're marked as active by admin
    return filteredBreeds;
  }

  /// Get fallback breeds when Firebase is unavailable
  static List<String> _getFallbackBreeds(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return List<String>.from(_fallbackDogBreeds);
      case 'cat':
        return List<String>.from(_fallbackCatBreeds);
      default:
        return [..._fallbackDogBreeds, ..._fallbackCatBreeds];
    }
  }

  /// Filter breeds by search query
  static List<String> filterBreeds(List<String> breeds, String query) {
    if (query.isEmpty) return breeds;
    
    return breeds
        .where((breed) => breed.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Clear the cache (useful after admin updates breeds)
  static void clearCache() {
    _cachedBreeds = null;
    _lastFetchTime = null;
  }

  /// Pre-load breeds into cache
  static Future<void> preloadBreeds() async {
    try {
      final breeds = await PetBreedsService.fetchAllBreeds(
        statusFilter: 'active',
        sortBy: 'name_asc',
      );
      _cachedBreeds = breeds;
      _lastFetchTime = DateTime.now();
      print('✅ Breeds preloaded into cache: ${breeds.length} active breeds');
    } catch (e) {
      print('⚠️ Failed to preload breeds: $e');
    }
  }
}
