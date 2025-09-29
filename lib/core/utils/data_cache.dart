/// Cache entry with data, timestamp, and expiry
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration? ttl; // Time to live
  
  CacheEntry(this.data, this.timestamp, this.ttl);
  
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }
  
  bool get isValid => !isExpired;
}

/// Simple in-memory cache for frequently accessed data
/// Helps maintain preloaded data and only refresh when needed
class DataCache {
  static final DataCache _instance = DataCache._internal();
  factory DataCache() => _instance;
  DataCache._internal();

  final Map<String, CacheEntry> _cache = {};

  /// Store data in cache with optional TTL
  void put<T>(String key, T data, {Duration? ttl}) {
    _cache[key] = CacheEntry<T>(data, DateTime.now(), ttl);
    print('DEBUG: Cache PUT - $key (TTL: $ttl)');
  }

  /// Get data from cache if valid
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      print('DEBUG: Cache MISS - $key (not found)');
      return null;
    }
    
    if (entry.isExpired) {
      print('DEBUG: Cache EXPIRED - $key (removing)');
      _cache.remove(key);
      return null;
    }
    
    print('DEBUG: Cache HIT - $key');
    return entry.data as T?;
  }

  /// Check if cache has valid data for key
  bool hasValid(String key) {
    final entry = _cache[key];
    return entry != null && entry.isValid;
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    print('DEBUG: Cache INVALIDATED - $key');
  }

  /// Invalidate all cache entries matching pattern
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    print('DEBUG: Cache INVALIDATED PATTERN - $pattern (${keysToRemove.length} entries)');
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    print('DEBUG: Cache CLEARED - all entries');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final validEntries = _cache.values.where((entry) => entry.isValid).length;
    final expiredEntries = _cache.values.where((entry) => entry.isExpired).length;
    
    return {
      'total': _cache.length,
      'valid': validEntries,
      'expired': expiredEntries,
      'keys': _cache.keys.toList(),
    };
  }

  /// Clean up expired entries
  void cleanup() {
    final keysToRemove = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    print('DEBUG: Cache CLEANUP - removed ${keysToRemove.length} expired entries');
  }
}

/// Cache key generator for consistent keys
class CacheKeys {
  static String userPets(String userId) => 'user_pets_$userId';
  static String userAssessments(String userId) => 'user_assessments_$userId';
  static String userProfile(String userId) => 'user_profile_$userId';
  static String clinics() => 'clinics_list';
  static String healthData(String userId) => 'health_data_$userId';
  static String alerts() => 'alerts_list';
  
  // Pattern matchers for invalidation
  static String userDataPattern(String userId) => userId;
  static String allPetsPattern() => 'user_pets_';
  static String allAssessmentsPattern() => 'user_assessments_';
}