import 'package:firebase_auth/firebase_auth.dart';

/// Token manager for efficient Firebase auth token handling
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  String? _cachedToken;
  DateTime? _tokenExpiresAt;
  
  /// Get Firebase ID token with smart caching
  /// Only refreshes token when actually expired or forced
  Future<String?> getToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final now = DateTime.now();

    // Return cached token if still valid
    if (!forceRefresh && 
        _cachedToken != null && 
        _tokenExpiresAt != null && 
        _tokenExpiresAt!.isAfter(now)) {
      return _cachedToken;
    }

    try {
      // Get fresh token from Firebase
      _cachedToken = await user.getIdToken(forceRefresh);
      // Firebase tokens expire in 1 hour, cache for 55 minutes to be safe
      _tokenExpiresAt = now.add(const Duration(minutes: 55));
      print('✅ TokenManager: Token refreshed successfully');
      return _cachedToken;
    } catch (e) {
      print('⚠️ TokenManager: Failed to get token: $e');
      
      // Check if it's a network error
      final errorString = e.toString().toLowerCase();
      final isNetworkError = errorString.contains('network') || 
                            errorString.contains('unable to resolve') ||
                            errorString.contains('no address associated') ||
                            errorString.contains('connection') ||
                            errorString.contains('host unreachable') ||
                            errorString.contains('no route to host');
      
      if (isNetworkError && _cachedToken != null) {
        print('📡 TokenManager: Network error - using cached token (offline mode)');
        // Extend cache expiration since we're in offline mode
        _tokenExpiresAt = now.add(const Duration(hours: 1));
        return _cachedToken;
      }
      
      // Clear cache on non-network errors
      print('❌ TokenManager: Clearing cache due to non-network error');
      _clearCache();
      return null;
    }
  }

  /// Force refresh the token
  Future<String?> refreshToken() async {
    return await getToken(forceRefresh: true);
  }

  /// Clear cached token
  void clearToken() {
    _clearCache();
  }

  /// Check if token is cached and valid
  bool get hasValidCachedToken {
    if (_cachedToken == null || _tokenExpiresAt == null) return false;
    return _tokenExpiresAt!.isAfter(DateTime.now());
  }

  /// Get token expiry time
  DateTime? get tokenExpiresAt => _tokenExpiresAt;

  void _clearCache() {
    _cachedToken = null;
    _tokenExpiresAt = null;
  }

  /// Wrapper for API calls with automatic token refresh on 401 errors
  Future<T?> authenticatedApiCall<T>({
    required Future<T> Function(String token) apiCall,
    int maxRetries = 1,
  }) async {
    int retries = 0;
    
    while (retries <= maxRetries) {
      try {
        final token = await getToken(forceRefresh: retries > 0);
        if (token == null) return null;

        return await apiCall(token);
      } catch (e) {
        // Check if this is an auth error that warrants a retry
        if (retries < maxRetries && _isAuthError(e)) {
          retries++;
          _clearCache(); // Clear cache to force refresh on retry
          continue;
        }
        rethrow;
      }
    }
    
    return null;
  }

  bool _isAuthError(dynamic error) {
    // You can customize this based on your API error responses
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') || 
           errorString.contains('401') ||
           errorString.contains('token expired') ||
           errorString.contains('invalid token');
  }
}
