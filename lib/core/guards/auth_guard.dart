import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user/user_model.dart';
import '../models/clinic/clinic_model.dart';
import '../services/auth/token_manager.dart';
import '../services/auth/auth_time_enhancement.dart';
import '../services/admin/schedule_setup_guard.dart';

/// Authentication and authorization guard for route protection
class AuthGuard {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final TokenManager _tokenManager = TokenManager();
  
  // User caching only (token caching moved to TokenManager)
  static UserModel? _cachedUser;
  static DateTime? _userCacheExpiresAt;
  
  // Request deduplication for getCurrentUser
  static Future<UserModel?>? _getCurrentUserRequest;
  
  /// Clear cached data
  static void _clearCache() {
    _tokenManager.clearToken();
    _cachedUser = null;
    _userCacheExpiresAt = null;
    _getCurrentUserRequest = null;
    // Clear route validation cache
    _validateRouteAccessRequest = null;
    _lastValidatedRoute = null;
    _routeValidationCacheTime = null;
  }
  
  /// Check if user is authenticated and has valid token
  static Future<bool> isAuthenticated() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if token is valid (use cached token, don't force refresh)
      final token = await _tokenManager.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current authenticated user with full profile data
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final now = DateTime.now();
      
      // Debug logging
      print('AuthGuard.getCurrentUser() called at ${now.millisecondsSinceEpoch}');
      
      // Check if we have valid cached user data
      if (_cachedUser != null && 
          _userCacheExpiresAt != null && 
          _userCacheExpiresAt!.isAfter(now) &&
          _cachedUser!.uid == user.uid) {
        print('AuthGuard: Using cached user data');
        return _cachedUser;
      }
      
      // If there's already a request in progress, wait for it instead of making a new one
      if (_getCurrentUserRequest != null) {
        print('AuthGuard: Waiting for existing request');
        return await _getCurrentUserRequest!;
      }
      
      print('AuthGuard: Making new user fetch request');
      // Start a new request and cache the Future
      _getCurrentUserRequest = _fetchCurrentUser(user);
      
      try {
        final result = await _getCurrentUserRequest!;
        return result;
      } finally {
        // Clear the request Future when done
        _getCurrentUserRequest = null;
      }
    } catch (e) {
      _getCurrentUserRequest = null;
      return null;
    }
  }
  
  /// Internal method to fetch user data (separated for deduplication)
  static Future<UserModel?> _fetchCurrentUser(User user) async {
    try {
      print('AuthGuard: Fetching user data for UID: ${user.uid}');
      
      // Try to verify token (but don't block if it fails in offline mode)
      try {
        final token = await _tokenManager.getToken();
        if (token == null) {
          print('⚠️ AuthGuard: No valid token found - may be offline');
          // Continue anyway - Firestore offline persistence may still work
        }
      } catch (tokenError) {
        print('⚠️ AuthGuard: Token fetch error: $tokenError - continuing with Firestore cache');
        // Continue anyway - we'll rely on Firestore offline cache
      }
      
      // Fetch user data from Firestore (will use offline cache if available)
      print('📡 AuthGuard: Attempting Firestore fetch (may use cache)...');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()!);
        final source = doc.metadata.isFromCache ? 'cache' : 'server';
        print('✅ AuthGuard: User data loaded from $source for role: ${userData.role}');
        
        // For admin users, check Firestore approval status on session restoration
        // Skip approval validation for super admin users
        if (userData.role == 'admin') {
          print('AuthGuard: Validating clinic approval status for admin user');
          await _validateClinicApprovalStatusForSession(user.uid);
        }
        
        _cachedUser = userData;
        // Cache user data for longer in offline mode
        final cacheDuration = source == 'cache' 
          ? const Duration(hours: 1)  // Offline mode
          : const Duration(minutes: 5); // Normal mode
        _userCacheExpiresAt = DateTime.now().add(cacheDuration);
        print('📦 AuthGuard: Cached user data (expires in ${cacheDuration.inMinutes} min)');
        return _cachedUser;
      } else {
        print('❌ AuthGuard: User document not found in Firestore (doc.exists = false)');
        return null;
      }
    } catch (e) {
      print('❌ AuthGuard: Error fetching user data: $e');
      
      // If approval validation fails, sign out the user
      if (e.toString().contains('account-')) {
        print('AuthGuard: Account-related error, signing out user');
        await _auth.signOut();
        _clearCache();
        return null;
      }
      
      // Check if it's a network error
      final errorString = e.toString().toLowerCase();
      final isNetworkError = errorString.contains('network') || 
                            errorString.contains('unable to resolve') ||
                            errorString.contains('no address associated') ||
                            errorString.contains('connection') ||
                            errorString.contains('firestore');
      
      if (isNetworkError) {
        print('📡 AuthGuard: Network error detected');
        
        // Return cached user data if available (even if expired)
        if (_cachedUser != null && _cachedUser!.uid == user.uid) {
          print('✅ AuthGuard: Using stale cached user data (offline mode)');
          // Extend cache expiration since we're in offline mode
          _userCacheExpiresAt = DateTime.now().add(const Duration(hours: 1));
          return _cachedUser;
        }
        
        print('⚠️ AuthGuard: No cached user data available for offline mode');
      } else {
        print('AuthGuard: Non-network error, not using cache');
      }
      
      return null;
    }
  }

  /// Validates clinic approval status during session restoration
  /// Throws custom exceptions for approval-related issues
  static Future<void> _validateClinicApprovalStatusForSession(String userId) async {
    try {
      // Check clinic status directly from clinics collection only
      final clinicQuery = await _firestore
          .collection('clinics')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (clinicQuery.docs.isEmpty) {
        throw Exception('account-not-verified');
      }

      final clinicData = clinicQuery.docs.first.data();
      final String status = clinicData['status'] ?? 'pending';

      switch (status) {
        case 'pending':
          throw Exception('account-pending-approval');
        case 'suspended':
          throw Exception('account-suspended');
        case 'rejected':
          throw Exception('account-rejected');
        case 'approved':
          // Allow access
          break;
        default:
          throw Exception('account-pending-approval');
      }
    } catch (e) {
      // Re-throw custom exceptions, wrap others
      if (e.toString().contains('account-')) {
        rethrow;
      }
      throw Exception('account-not-verified');
    }
  }

  /// Check if user has specific role
  static Future<bool> hasRole(String role) async {
    final user = await getCurrentUser();
    return user?.role == role;
  }

  /// Check if user has any of the specified roles
  static Future<bool> hasAnyRole(List<String> roles) async {
    final user = await getCurrentUser();
    return user != null && roles.contains(user.role);
  }

  /// Check if user has admin privileges (admin or super_admin)
  static Future<bool> hasAdminPrivileges() async {
    return hasAnyRole(['admin', 'super_admin']);
  }

  /// Check if user is super admin
  static Future<bool> isSuperAdmin() async {
    return hasRole('super_admin');
  }

  /// Get user's clinic data if they have access
  static Future<Clinic?> getUserClinic(String userId) async {
    try {
      final doc = await _firestore.collection('clinics').doc(userId).get();
      if (doc.exists) {
        return Clinic.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user can access clinic data
  static Future<bool> canAccessClinic(String clinicId) async {
    final user = await getCurrentUser();
    if (user == null) return false;
    
    // Super admin can access all clinics
    if (user.role == 'super_admin') return true;
    
    // Admin can only access their own clinic
    if (user.role == 'admin') return user.uid == clinicId;
    
    return false;
  }

  /// Check if user can manage clinic services
  static Future<bool> canManageClinicServices(String clinicId) async {
    final user = await getCurrentUser();
    if (user == null) return false;
    
    // Super admin can manage all services
    if (user.role == 'super_admin') return true;
    
    // Admin can only manage their own clinic services
    if (user.role == 'admin') return user.uid == clinicId;
    
    return false;
  }

  /// Check if user can manage clinic certifications
  static Future<bool> canManageCertifications() async {
    final user = await getCurrentUser();
    if (user == null) return false;
    
    // Only super admin can manage certifications
    return user.role == 'super_admin';
  }

  // Request deduplication for validateRouteAccess
  static Future<String?>? _validateRouteAccessRequest;
  static String? _lastValidatedRoute;
  static DateTime? _routeValidationCacheTime;
  
  /// Validate route access based on authentication and role
  static Future<String?> validateRouteAccess(String routePath) async {
    // Debug logging
    print('AuthGuard.validateRouteAccess() called for: $routePath');
    
    // Public routes that don't require authentication
    if (_isPublicRoute(routePath)) {
      print('AuthGuard: Public route, skipping validation');
      return null;
    }

    final now = DateTime.now();
    
    // Check if we have recent validation for the same route (cache for 10 seconds)
    if (_lastValidatedRoute == routePath && 
        _routeValidationCacheTime != null && 
        now.difference(_routeValidationCacheTime!).inSeconds < 10) {
      print('AuthGuard: Using cached route validation');
      return null; // Route was recently validated successfully
    }
    
    // If there's already a validation in progress, wait for it instead of making a new one
    if (_validateRouteAccessRequest != null) {
      print('AuthGuard: Waiting for existing route validation');
      return await _validateRouteAccessRequest!;
    }
    
    print('AuthGuard: Performing new route validation');
    // Start a new validation request and cache the Future
    _validateRouteAccessRequest = _performRouteValidation(routePath);
    
    try {
      final result = await _validateRouteAccessRequest!;
      
      // Cache successful validation (null means access granted)
      if (result == null) {
        _lastValidatedRoute = routePath;
        _routeValidationCacheTime = now;
      }
      
      return result;
    } finally {
      // Clear the request Future when done
      _validateRouteAccessRequest = null;
    }
  }
  
  /// Internal method to perform route validation (separated for deduplication)
  static Future<String?> _performRouteValidation(String routePath) async {
    try {
      print('AuthGuard: Starting route validation for: $routePath');
      
      // Get current user (this also validates authentication)
      final user = await getCurrentUser();
      if (user == null) {
        print('AuthGuard: No authenticated user found, redirecting to login');
        return kIsWeb ? '/web_login' : '/signin';
      }

      print('AuthGuard: User authenticated - UID: ${user.uid}, Role: ${user.role}');
      
      // For admin users on web, check schedule setup status before allowing route access
      if (kIsWeb && user.role == 'admin' && !_isPublicRoute(routePath)) {
        print('AuthGuard: Checking schedule setup status for admin user with UID: ${user.uid}');
        final setupStatus = await ScheduleSetupGuard.checkScheduleSetupStatus(user.uid);
        
        print('AuthGuard: Setup Status Response:');
        print('   - needsSetup: ${setupStatus.needsSetup}');
        print('   - inProgress: ${setupStatus.inProgress}');
        print('   - clinic: ${setupStatus.clinic?.clinicName}');
        print('   - message: ${setupStatus.message}');
        
        if (setupStatus.needsSetup) {
          print('AuthGuard: Admin needs to complete schedule setup');
          
          // Only allow access to dashboard and setup-related routes
          if (!_isScheduleSetupRoute(routePath) && routePath != '/admin/dashboard') {
            print('AuthGuard: Blocking access to $routePath, redirecting to dashboard for schedule setup');
            return '/admin/dashboard';
          } else {
            print('AuthGuard: Allowing access to setup-related route: $routePath');
          }
        } else {
          print('AuthGuard: Schedule setup completed, allowing access to all routes');
        }
      }
      
      // Check role-based access
      final redirectPath = _validateRoleBasedAccess(routePath, user.role);
      
      if (redirectPath != null) {
        print('AuthGuard: Access denied for route $routePath, redirecting to: $redirectPath');
      } else {
        print('AuthGuard: Access granted for route: $routePath');
      }
      
      return redirectPath;
    } catch (e) {
      print('❌ AuthGuard: Error during route validation for $routePath: $e');
      print('❌ AuthGuard: Stack trace: ${StackTrace.current}');
      // On error, try to avoid redirecting to prevent logout loops
      // Only redirect if we can't determine the user's authentication state
      if (e.toString().contains('account-')) {
        print('AuthGuard: Account-related error, redirecting to login');
        return kIsWeb ? '/web_login' : '/signin';
      } else {
        print('AuthGuard: Network or temporary error, allowing access to prevent logout');
        return null; // Allow access on temporary errors
      }
    }
  }

  /// Check if route is public (no auth required)
  static bool _isPublicRoute(String routePath) {
    final publicRoutes = [
      '/web_login',
      '/login', // Alias for web_login
      '/admin_signup',
      '/forgot-password', // Web admin forgot password
      '/mobile-forgot-password', // Mobile OTP forgot password
      '/signin',
      '/signup',
      '/verify-email',
      '/home',
      '/faqs', // Add FAQs as a public route
      '/clinic-faqs', // Add clinic FAQs as a public route
    ];
    return publicRoutes.contains(routePath);
  }

  /// Check if route is related to schedule setup (should not block these routes)
  static bool _isScheduleSetupRoute(String routePath) {
    // Routes that are part of the schedule setup process should not be blocked
    // Also allow dashboard as it's the main setup interface
    return routePath == '/admin/dashboard' ||
           routePath == '/admin/clinic-schedule' || 
           routePath == '/admin/vet-profile';
  }

  /// Validate role-based access to routes
  static String? _validateRoleBasedAccess(String routePath, String userRole) {
    // Root path redirect
    if (routePath == '/') {
      return kIsWeb ? '/web_login' : '/signin';
    }
    
    // Admin routes
    if (routePath.startsWith('/admin/')) {
      if (userRole == 'super_admin') {
        // Super admin trying to access admin routes - redirect to super admin system analytics
        return '/super-admin/system-analytics';
      }
      if (userRole != 'admin') {
        return '/web_login';
      }
    }

    // Super admin routes
    if (routePath.startsWith('/super-admin/')) {
      if (userRole != 'super_admin') {
        // Non-super admin trying to access super admin routes - redirect to appropriate dashboard
        return userRole == 'admin' ? '/admin/dashboard' : '/web_login';
      }
    }

    // Root admin paths - redirect to appropriate dashboard
    if (routePath == '/admin' || routePath == '/super-admin') {
      final dashboardPath = userRole == 'super_admin' ? '/super-admin/system-analytics' : '/admin/dashboard';
      return dashboardPath;
    }

    // Mobile user routes - accessible to all authenticated users (including regular mobile users)
    final mobileRoutes = [
      '/home',
      '/alerts', 
      '/assessment',
      '/edit-profile',
      '/change-password',
      '/about-pawsense',
      '/messaging',
      '/ai-history',
      '/appointment-history',
      '/appointments',
      '/pets',
      '/add-pet',
      '/edit-pet',
      '/book-appointment',
      '/emergency-hotline', 
      '/first-aid-guide',
      '/pet-care-tips',
      '/faqs',
      '/clinics',
      '/clinic-details',
      '/skin-disease-library',
    ];
    
    // Check if it's a mobile route pattern (including dynamic routes)
    bool isMobileRoute = mobileRoutes.any((route) => routePath.startsWith(route)) ||
                        routePath.startsWith('/ai-history/') ||
                        routePath.startsWith('/appointment-history/') ||
                        routePath.startsWith('/alerts/') ||
                        routePath.startsWith('/appointments/');
    
    if (isMobileRoute) {
      // Mobile routes are accessible to all authenticated users
      return null; // Access granted
    }

    return null; // Access granted
  }

  /// Refresh user's Firebase token
  static Future<bool> refreshToken() async {
    try {
      final token = await _tokenManager.refreshToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear user cache (public method for cache invalidation)
  static void clearUserCache() {
    _cachedUser = null;
    _userCacheExpiresAt = null;
    _getCurrentUserRequest = null;
  }

  /// Force refresh user data from Firestore
  static Future<UserModel?> refreshUserData() async {
    clearUserCache(); // Clear existing cache
    return await getCurrentUser(); // Fetch fresh data
  }

  /// Sign out user and clear session
  static Future<void> signOut() async {
    try {
      // Stop auth token monitoring
      AuthTimeEnhancement.stopAuthMonitoring();
      
      _clearCache(); // Clear cached data on sign out
      await _auth.signOut();
    } catch (e) {
      // Handle sign out errors
    }
  }

  /// Get user's permissions based on their role
  static List<String> getUserPermissions(String role) {
    switch (role) {
      case 'super_admin':
        return [
          'manage_all_clinics',
          'manage_all_users',
          'manage_certifications',
          'system_analytics',
          'system_settings',
        ];
      case 'admin':
        return [
          'manage_own_clinic',
          'manage_own_services',
          'manage_patients',
          'manage_appointments',
          'view_analytics',
        ];
      case 'vet':
        return [
          'view_patients',
          'manage_appointments',
          'view_clinic_info',
        ];
      case 'staff':
        return [
          'view_patients',
          'schedule_appointments',
          'view_clinic_info',
        ];
      default:
        return [];
    }
  }

  /// Check if user has specific permission
  static Future<bool> hasPermission(String permission) async {
    final user = await getCurrentUser();
    if (user == null) return false;
    
    final permissions = getUserPermissions(user.role);
    return permissions.contains(permission);
  }
}
