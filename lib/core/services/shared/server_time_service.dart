import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for synchronizing with server time to avoid device clock dependency
/// 
/// This service calculates the offset between device time and Firestore server time,
/// allowing the app to function correctly even when the device clock is incorrect.
/// 
/// Key Features:
/// - Calculates server-device time offset
/// - Provides server-synced current time
/// - Periodic automatic resyncing
/// - Caches last known offset
/// - Validates device time accuracy
/// 
/// Usage:
/// ```dart
/// // Initialize on app startup
/// await ServerTimeService.initialize();
/// 
/// // Get server-synced time
/// final serverTime = await ServerTimeService.getServerTime();
/// 
/// // Check if device time is accurate
/// final isAccurate = await ServerTimeService.isDeviceTimeAccurate();
/// ```
class ServerTimeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Calculated offset between server and device time
  /// Positive: Server is ahead of device
  /// Negative: Device is ahead of server
  static Duration? _serverTimeOffset;
  
  /// When we last synced with server
  static DateTime? _lastSyncTime;
  
  /// How often to resync with server (default: 1 hour)
  static const Duration _resyncInterval = Duration(hours: 1);
  
  /// Maximum acceptable time skew before warning (default: 5 minutes)
  static const Duration _maxAcceptableSkew = Duration(minutes: 5);
  
  /// Timer for periodic resyncing
  static Timer? _resyncTimer;
  
  /// Collection used for time sync (temporary document)
  static const String _syncCollection = '_time_sync';
  
  /// Whether service has been initialized
  static bool _initialized = false;
  
  /// Initialize the service and perform initial sync
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⏰ ServerTimeService already initialized');
      return;
    }
    
    _initialized = true; // Mark as initialized even if sync fails
    
    try {
      debugPrint('⏰ Initializing ServerTimeService...');
      await syncWithServer().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Server time sync timed out (app will use device time)');
        },
      );
      _startPeriodicSync();
      debugPrint('✅ ServerTimeService initialized successfully');
    } catch (e) {
      debugPrint('⚠️ ServerTimeService initialization failed: $e');
      debugPrint('   App will continue using device time until sync succeeds');
      // Still start periodic sync - it will retry later when network is available
      _startPeriodicSync();
    }
  }
  
  /// Dispose of resources (call on app shutdown)
  static void dispose() {
    _resyncTimer?.cancel();
    _resyncTimer = null;
    _initialized = false;
    debugPrint('⏰ ServerTimeService disposed');
  }
  
  /// Synchronize with Firestore server to calculate time offset
  static Future<void> syncWithServer() async {
    try {
      final syncStartDevice = DateTime.now();
      
      // Create a temporary document with server timestamp
      final docRef = _firestore.collection(_syncCollection).doc();
      await docRef.set({
        'serverTimestamp': FieldValue.serverTimestamp(),
        'deviceTimestamp': Timestamp.fromDate(syncStartDevice),
      });
      
      // Read back the document to get server timestamp
      final snapshot = await docRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.data();
        final serverTimestamp = data?['serverTimestamp'] as Timestamp?;
        
        if (serverTimestamp != null) {
          final serverTime = serverTimestamp.toDate();
          final syncEndDevice = DateTime.now();
          
          // Account for round-trip time (estimate server time at midpoint)
          final roundTripTime = syncEndDevice.difference(syncStartDevice);
          final estimatedServerTimeNow = serverTime.add(roundTripTime ~/ 2);
          
          // Calculate offset
          _serverTimeOffset = estimatedServerTimeNow.difference(syncEndDevice);
          _lastSyncTime = syncEndDevice;
          
          debugPrint('✅ Server time synced');
          debugPrint('   Device time: ${syncEndDevice.toIso8601String()}');
          debugPrint('   Server time: ${estimatedServerTimeNow.toIso8601String()}');
          debugPrint('   Offset: ${_serverTimeOffset!.inSeconds} seconds');
          debugPrint('   Round-trip: ${roundTripTime.inMilliseconds}ms');
          
          // Clean up temporary document (fire and forget)
          docRef.delete().catchError((e) {
            debugPrint('⚠️ Failed to clean up sync document: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Server time sync failed: $e');
      // Don't throw - app can continue with existing offset or device time
    }
  }
  
  /// Get current server-synced time
  /// 
  /// Returns server-adjusted time if sync has been performed,
  /// otherwise returns device time as fallback
  static Future<DateTime> getServerTime() async {
    // Resync if needed
    if (_shouldResync()) {
      await syncWithServer();
    }
    
    return _calculateServerTime();
  }
  
  /// Get cached server time without triggering sync
  /// 
  /// Useful for frequent calculations where slight drift is acceptable
  /// Returns null if no sync has been performed yet
  static DateTime? getCachedServerTime() {
    if (_serverTimeOffset == null) {
      return null;
    }
    return _calculateServerTime();
  }
  
  /// Calculate server time based on current offset
  static DateTime _calculateServerTime() {
    final deviceTime = DateTime.now();
    
    if (_serverTimeOffset == null) {
      return deviceTime; // Fallback to device time if not synced
    }
    
    return deviceTime.add(_serverTimeOffset!);
  }
  
  /// Check if we should resync with server
  static bool _shouldResync() {
    if (_serverTimeOffset == null || _lastSyncTime == null) {
      return true; // Never synced
    }
    
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceLastSync > _resyncInterval;
  }
  
  /// Start periodic resyncing
  static void _startPeriodicSync() {
    _resyncTimer?.cancel(); // Cancel existing timer if any
    
    _resyncTimer = Timer.periodic(_resyncInterval, (_) async {
      debugPrint('⏰ Performing periodic server time sync...');
      await syncWithServer();
    });
  }
  
  /// Check if device time is accurate (within acceptable skew)
  static Future<bool> isDeviceTimeAccurate() async {
    try {
      // Ensure we have recent sync data
      if (_shouldResync()) {
        await syncWithServer();
      }
      
      if (_serverTimeOffset == null) {
        debugPrint('⚠️ Cannot verify time accuracy - sync failed');
        return true; // Assume accurate if we can't verify
      }
      
      final skew = _serverTimeOffset!.abs();
      final isAccurate = skew <= _maxAcceptableSkew;
      
      if (!isAccurate) {
        debugPrint('⚠️ Device time skew detected: ${skew.inMinutes} minutes');
      }
      
      return isAccurate;
    } catch (e) {
      debugPrint('⚠️ Error checking time accuracy: $e');
      return true; // Assume accurate if check fails
    }
  }
  
  /// Get the current time offset
  /// 
  /// Returns null if no sync has been performed
  static Duration? getTimeOffset() => _serverTimeOffset;
  
  /// Get the last sync time
  /// 
  /// Returns null if no sync has been performed
  static DateTime? getLastSyncTime() => _lastSyncTime;
  
  /// Get time since last sync
  /// 
  /// Returns null if no sync has been performed
  static Duration? getTimeSinceLastSync() {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!);
  }
  
  /// Check if service is initialized
  static bool isInitialized() => _initialized;
  
  /// Force an immediate resync (useful for testing or manual refresh)
  static Future<void> forceResync() async {
    debugPrint('⏰ Forcing server time resync...');
    await syncWithServer();
  }
  
  /// Get diagnostic information about time service
  static Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _initialized,
      'offsetSeconds': _serverTimeOffset?.inSeconds,
      'offsetMinutes': _serverTimeOffset?.inMinutes,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'timeSinceLastSyncMinutes': getTimeSinceLastSync()?.inMinutes,
      'deviceTime': DateTime.now().toIso8601String(),
      'estimatedServerTime': _serverTimeOffset != null 
          ? _calculateServerTime().toIso8601String() 
          : null,
      'isAccurate': _serverTimeOffset != null 
          ? _serverTimeOffset!.abs() <= _maxAcceptableSkew 
          : null,
    };
  }
  
  /// Format time offset for display
  static String formatTimeOffset() {
    if (_serverTimeOffset == null) {
      return 'Not synced';
    }
    
    final seconds = _serverTimeOffset!.inSeconds;
    final absSeconds = seconds.abs();
    
    if (absSeconds < 60) {
      return '${seconds}s';
    } else if (absSeconds < 3600) {
      return '${(seconds / 60).toStringAsFixed(1)}m';
    } else {
      return '${(seconds / 3600).toStringAsFixed(1)}h';
    }
  }
}
