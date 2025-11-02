import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pawsense/core/services/shared/server_time_service.dart';
import 'package:pawsense/core/services/shared/time_validation_service.dart';

/// Enhanced authentication utilities with time validation and token management
/// 
/// This class provides utilities to enhance the existing AuthService with:
/// - Automatic token refresh monitoring
/// - Time validation before auth operations
/// - Time-related error detection
/// - Graceful handling of time skew issues
class AuthTimeEnhancement {
  static Timer? _tokenRefreshTimer;
  static bool _isMonitoring = false;
  
  /// Initialize auth monitoring (call after successful sign-in)
  static Future<void> initializeAuthMonitoring(FirebaseAuth auth) async {
    if (_isMonitoring) {
      debugPrint('⏰ Auth monitoring already active');
      return;
    }
    
    try {
      // Validate device time
      final timeValidation = await TimeValidationService.validateDeviceTime();
      if (!timeValidation.isValid) {
        debugPrint('⚠️ Device time skew detected during auth init: ${timeValidation.skewDuration}');
        // Don't block, but log warning for monitoring
      }
      
      // Immediately refresh token to ensure it's valid
      debugPrint('🔄 Performing initial token refresh...');
      await refreshAuthToken(auth);
      
      // Set up periodic token refresh (every 45 minutes, tokens expire after 60)
      // Reduced from 50 to 45 minutes for extra safety margin
      _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (_) async {
        debugPrint('⏰ Scheduled token refresh triggered');
        final success = await refreshAuthToken(auth);
        if (!success) {
          debugPrint('⚠️ Scheduled token refresh failed - user may need to re-authenticate');
        }
      });
      
      _isMonitoring = true;
      debugPrint('✅ Auth monitoring initialized with 45-minute refresh cycle');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize auth monitoring: $e');
    }
  }
  
  /// Stop auth monitoring (call on sign-out)
  static void stopAuthMonitoring() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    _isMonitoring = false;
    debugPrint('⏰ Auth monitoring stopped');
  }
  
  /// Refresh authentication token with enhanced time validation
  static Future<bool> refreshAuthToken(FirebaseAuth auth, {bool skipTimeValidation = false}) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user to refresh token for');
        return false;
      }
      
      // Validate time before token refresh (unless skipped)
      if (!skipTimeValidation) {
        final timeValidation = await TimeValidationService.validateDeviceTime();
        if (timeValidation.severity == TimeSkewSeverity.critical) {
          debugPrint('⚠️ Token refresh with critical time skew detected - attempting anyway for testing');
          // Don't block - allow refresh to proceed even with time skew
        }
      }
      
      // Force token refresh
      final token = await user.getIdToken(true);
      if (token != null) {
        debugPrint('✅ Auth token refreshed successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('⚠️ Token refresh failed: $e');
      
      // Handle time-related errors
      if (_isTimeRelatedError(e) || (e is FirebaseAuthException && isFirebaseAuthTimeError(e))) {
        debugPrint('⚠️ Token refresh failed due to time issue, attempting time sync...');
        try {
          await ServerTimeService.forceResync();
          await Future.delayed(const Duration(seconds: 2));
          
          // Retry once after time sync (skip time validation to avoid infinite loop)
          final user = auth.currentUser;
          if (user != null) {
            final token = await user.getIdToken(true);
            if (token != null) {
              debugPrint('✅ Token refreshed successfully after time sync');
              return true;
            }
          }
        } catch (syncError) {
          debugPrint('❌ Time sync and retry failed: $syncError');
        }
      }
      
      return false;
    }
  }
  
  /// Validate device time before authentication attempt
  /// Returns warning message if time is off, but doesn't block auth
  /// This allows users to proceed even with incorrect device time
  static Future<String?> validateTimeBeforeAuth() async {
    try {
      final result = await TimeValidationService.validateDeviceTime();
      
      if (!result.isValid) {
        debugPrint('⚠️ Time skew detected: ${result.description}');
        // Return warning message but don't block auth
        return 'Warning: ${result.description}. Some features may not work correctly.';
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ Time validation check failed: $e');
      return null; // Don't block auth if validation fails
    }
  }
  
  /// Check if an error is time-related
  static bool _isTimeRelatedError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    final timeRelatedKeywords = [
      'certificate',
      'cert',
      'ssl',
      'tls',
      'handshake',
      'time',
      'expired',
      'clock',
      'token',
      'invalid-credential',
      'network-request-failed',
      'connection timeout',
      'connection refused',
      'secureconnectionerror',
      'certificate_verify_failed',
      'certverifyexception',
      'bad certificate',
      'unable to get local issuer certificate',
      'self signed certificate',
      'certificate has expired',
    ];
    
    return timeRelatedKeywords.any((keyword) => errorString.contains(keyword));
  }
  
  /// Check if a FirebaseAuthException is time-related
  static bool isFirebaseAuthTimeError(FirebaseAuthException e) {
    final timeRelatedCodes = [
      'invalid-credential',
      'network-request-failed',
      'too-many-requests',
      'user-token-expired',
    ];
    
    final timeRelatedMessageKeywords = [
      'certificate',
      'ssl',
      'time',
      'expired',
      'clock',
    ];
    
    if (timeRelatedCodes.contains(e.code)) {
      return timeRelatedMessageKeywords.any((keyword) => 
        e.message?.toLowerCase().contains(keyword) ?? false
      );
    }
    
    return false;
  }
  
  /// Get user-friendly error message for time-related auth failures
  static String getTimeRelatedErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (error is FirebaseAuthException) {
      if (error.code == 'network-request-failed') {
        // Check if it's specifically SSL/certificate related
        if (errorString.contains('certificate') || errorString.contains('ssl') || errorString.contains('tls')) {
          return 'Connection failed due to security certificate error. This is usually caused by incorrect device time. '
                 'Go to Settings → Date & Time → Enable "Automatic date & time", then try again.';
        }
        return 'Sign-in failed due to network issues. If your internet is working, this might be caused by incorrect device time. '
               'Go to Settings → Date & Time → Enable "Automatic date & time", then try again.';
      }
      
      if (error.code == 'invalid-credential' || error.code == 'user-token-expired') {
        return 'Authentication token invalid or expired. This is often caused by incorrect device time. '
               'Go to Settings → Date & Time → Enable "Automatic date & time", then try again.';
      }
      
      if (error.code == 'too-many-requests') {
        return 'Too many failed authentication attempts. If you haven\'t made many attempts, check your device time settings. '
               'Go to Settings → Date & Time → Enable "Automatic date & time", then wait a few minutes and try again.';
      }
    }
    
    // Check for specific certificate/SSL errors in the error string
    if (errorString.contains('certificate') || errorString.contains('ssl') || errorString.contains('tls')) {
      return 'Security certificate validation failed. This is almost always caused by incorrect device time. '
             'Solution: Go to Settings → Date & Time → Enable "Automatic date & time", restart the app, then try again.';
    }
    
    return 'Sign-in failed due to a possible time-related issue. '
           'Please ensure your device time is set to automatic (Settings → Date & Time) and try again.';
  }
  
  /// Wrap sign-in attempt with time validation and enhanced error handling
  static Future<T> wrapSignInAttempt<T>(
    Future<T> Function() signInFunction, {
    required String operation,
    int maxRetries = 2,
  }) async {
    int attemptCount = 0;
    
    while (attemptCount <= maxRetries) {
      try {
        attemptCount++;
        
        // Validate time before attempting sign-in
        final timeValidation = await TimeValidationService.validateDeviceTime();
        
        // Log time skew but DON'T block (allow testing features that require time changes)
        if (timeValidation.severity == TimeSkewSeverity.critical) {
          debugPrint('⚠️ WARNING: Critical time skew detected during $operation: ${timeValidation.description}');
          debugPrint('   Continuing anyway to allow time-based feature testing');
        } else if (timeValidation.severity == TimeSkewSeverity.moderate) {
          debugPrint('⚠️ Moderate time skew during $operation: ${timeValidation.description}');
        }
        
        // Force token refresh if user exists to prevent stale tokens
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint('🔄 Forcing token refresh before $operation...');
            await user.getIdToken(true); // Force refresh
          }
        } catch (tokenError) {
          debugPrint('⚠️ Token refresh failed (may be normal for new sign-in): $tokenError');
        }
        
        // Attempt sign-in
        debugPrint('🔐 Attempting $operation (attempt $attemptCount/${maxRetries + 1})...');
        final result = await signInFunction();
        debugPrint('✅ $operation successful');
        
        return result;
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ $operation failed (attempt $attemptCount): ${e.code} - ${e.message}');
        
        // Check if error is time-related
        if (isFirebaseAuthTimeError(e) || _isTimeRelatedError(e)) {
          // Attempt time resync
          if (attemptCount < maxRetries + 1) {
            debugPrint('🔄 Time-related error detected, attempting resync and retry...');
            try {
              await ServerTimeService.forceResync();
              await Future.delayed(const Duration(seconds: 2));
              continue; // Retry
            } catch (syncError) {
              debugPrint('⚠️ Time resync failed: $syncError');
            }
          }
          
          // Out of retries - log warning but let original error propagate
          // This allows the UI to show the actual Firebase error instead of our custom message
          debugPrint('⚠️ Auth attempt failed after time-related errors - may be due to device time skew');
          debugPrint('   Original error: ${e.code} - ${e.message}');
        }
        
        // Not time-related, don't retry
        rethrow;
      } catch (e) {
        debugPrint('❌ $operation failed with unexpected error (attempt $attemptCount): $e');
        
        // Check if error might be time-related
        if (_isTimeRelatedError(e)) {
          // Attempt time resync and retry
          if (attemptCount < maxRetries + 1) {
            debugPrint('🔄 Possible time issue detected, attempting resync and retry...');
            try {
              await ServerTimeService.forceResync();
              await Future.delayed(const Duration(seconds: 2));
              continue; // Retry
            } catch (syncError) {
              debugPrint('⚠️ Time resync failed: $syncError');
            }
          }
          
          // Log warning but let original error propagate
          debugPrint('⚠️ Possible time-related error - device time may be incorrect');
          debugPrint('   Original error: $e');
        }
        
        // Not time-related, don't retry
        rethrow;
      }
    }
    
    // Should never reach here, but just in case
    throw Exception('$operation failed after $maxRetries retries');
  }
  
  /// Check current auth token validity
  static Future<bool> isTokenValid(FirebaseAuth auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return false;
      
      final token = await user.getIdToken(false); // Don't force refresh
      return token != null;
    } catch (e) {
      debugPrint('⚠️ Token validity check failed: $e');
      return false;
    }
  }
  
  /// Get time until token expiration (approximate)
  /// Firebase ID tokens expire after 1 hour
  static Future<Duration?> getTimeUntilTokenExpiration(FirebaseAuth auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return null;
      
      final tokenResult = await user.getIdTokenResult(false);
      final expirationTime = tokenResult.expirationTime;
      
      if (expirationTime != null) {
        final now = await ServerTimeService.getServerTime();
        return expirationTime.difference(now);
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ Failed to get token expiration: $e');
      return null;
    }
  }
  
  /// Log diagnostics for debugging time-related auth issues
  static Future<Map<String, dynamic>> getDiagnostics(FirebaseAuth auth) async {
    final user = auth.currentUser;
    final serverTimeDiag = ServerTimeService.getDiagnostics();
    
    final diagnostics = {
      'authState': {
        'isSignedIn': user != null,
        'uid': user?.uid,
        'email': user?.email,
        'emailVerified': user?.emailVerified,
      },
      'serverTime': serverTimeDiag,
      'monitoring': {
        'isActive': _isMonitoring,
        'hasRefreshTimer': _tokenRefreshTimer != null,
      },
    };
    
    if (user != null) {
      try {
        final tokenValid = await isTokenValid(auth);
        final timeUntilExpiration = await getTimeUntilTokenExpiration(auth);
        
        diagnostics['token'] = {
          'isValid': tokenValid,
          'minutesUntilExpiration': timeUntilExpiration?.inMinutes,
        };
      } catch (e) {
        diagnostics['token'] = {'error': e.toString()};
      }
    }
    
    return diagnostics;
  }
  
  /// Print diagnostics to console (useful for debugging)
  static Future<void> printDiagnostics(FirebaseAuth auth) async {
    final diag = await getDiagnostics(auth);
    debugPrint('🔍 Auth Time Enhancement Diagnostics:');
    debugPrint('   ${diag.toString()}');
  }
  
  /// Validate auth state before critical operations
  /// Returns true if auth is healthy, false if needs attention
  static Future<bool> validateAuthState(FirebaseAuth auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Auth validation: No user signed in');
        return false;
      }
      
      // Check token validity
      final tokenValid = await isTokenValid(auth);
      if (!tokenValid) {
        debugPrint('⚠️ Auth validation: Token invalid, attempting refresh...');
        final refreshed = await refreshAuthToken(auth);
        if (!refreshed) {
          debugPrint('❌ Auth validation: Token refresh failed');
          return false;
        }
      }
      
      // Check time accuracy
      final timeValidation = await TimeValidationService.validateDeviceTime();
      if (timeValidation.severity == TimeSkewSeverity.critical) {
        debugPrint('❌ Auth validation: Critical time skew detected');
        return false;
      }
      
      debugPrint('✅ Auth validation: All checks passed');
      return true;
    } catch (e) {
      debugPrint('❌ Auth validation failed: $e');
      return false;
    }
  }
  
  /// Check if auth recovery is needed (e.g., after time correction)
  /// Returns true if user should re-authenticate
  static Future<bool> needsReauthentication(FirebaseAuth auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return false;
      
      // Try to refresh token
      final refreshed = await refreshAuthToken(auth, skipTimeValidation: true);
      
      // If refresh fails, user needs to re-authenticate
      return !refreshed;
    } catch (e) {
      debugPrint('⚠️ Error checking auth recovery need: $e');
      return true; // Assume reauthentication needed on error
    }
  }
  
  /// Attempt to recover auth after time correction
  /// Returns true if recovery successful
  static Future<bool> attemptAuthRecovery(FirebaseAuth auth) async {
    try {
      debugPrint('🔄 Attempting auth recovery after time correction...');
      
      // Force time resync
      await ServerTimeService.forceResync();
      await Future.delayed(const Duration(seconds: 2));
      
      // Validate time is now acceptable
      final timeValidation = await TimeValidationService.validateDeviceTime();
      if (timeValidation.severity == TimeSkewSeverity.critical) {
        debugPrint('❌ Auth recovery: Time still critically incorrect');
        return false;
      }
      
      // Try to refresh token
      final refreshed = await refreshAuthToken(auth, skipTimeValidation: true);
      if (refreshed) {
        debugPrint('✅ Auth recovery successful');
        return true;
      }
      
      debugPrint('❌ Auth recovery: Token refresh failed');
      return false;
    } catch (e) {
      debugPrint('❌ Auth recovery failed: $e');
      return false;
    }
  }
}
