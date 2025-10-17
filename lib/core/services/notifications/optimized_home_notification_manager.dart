import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/notifications/realtime_notification_service.dart';
import '../../../core/services/notifications/optimized_notification_overlay.dart';

/// Optimized home page notification initialization
/// Replaces the old polling-based system with real-time Firestore listeners
class OptimizedHomeNotificationManager {
  static final OptimizedHomeNotificationManager _instance = 
      OptimizedHomeNotificationManager._internal();
  factory OptimizedHomeNotificationManager() => _instance;
  OptimizedHomeNotificationManager._internal();

  final RealTimeNotificationService _notificationService = RealTimeNotificationService();
  final OptimizedNotificationOverlay _overlayManager = OptimizedNotificationOverlay();
  
  StreamSubscription<int>? _unreadCountSubscription;
  bool _isInitialized = false;

  /// Initialize notifications for home page
  /// This should be called in your home page initState()
  Future<void> initializeForHomePage(BuildContext context, {
    required String userId,
    required VoidCallback onUnreadCountChanged,
    required Function(int) updateUnreadCount,
  }) async {
    if (_isInitialized) return;
    
    try {
      // Initialize real-time service
      await _notificationService.initializeForUser(userId);
      
      // Initialize overlay manager with proper context
      if (context.mounted) {
        _overlayManager.initialize(context);
      }
      
      // Subscribe to unread count changes
      _unreadCountSubscription = _notificationService.unreadCountStream.listen(
        (count) {
          updateUnreadCount(count);
          onUnreadCountChanged();
        },
      );
      
      // Get initial unread count
      final initialCount = _notificationService.unreadCount;
      updateUnreadCount(initialCount);
      
      _isInitialized = true;
      debugPrint('🏠 Home page notifications initialized successfully');
      debugPrint('🔔 Popup overlay manager initialized');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize home page notifications: $e');
      rethrow;
    }
  }

  /// Dispose home page notifications
  void dispose() {
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = null;
    
    _overlayManager.dispose();
    
    _isInitialized = false;
    debugPrint('🧹 Home page notifications disposed');
  }

  /// Get current unread count (for immediate use)
  int get currentUnreadCount => _notificationService.unreadCount;

  /// Check if manager is initialized
  bool get isInitialized => _isInitialized;
}

/// Extension to easily integrate with existing home page
extension HomePageNotificationExtension on State<StatefulWidget> {
  
  /// Easy integration method for existing home pages
  /// Add this to your initState() method
  Future<void> initializeOptimizedNotifications({
    required VoidCallback onNotificationUpdate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;
    
    final manager = OptimizedHomeNotificationManager();
    
    await manager.initializeForHomePage(
      context,
      userId: user.uid,
      onUnreadCountChanged: onNotificationUpdate,
      updateUnreadCount: (count) {
        // You can update your state variable here
        // Example: _notificationCount = count;
      },
    );
  }

  /// Easy disposal method for existing home pages
  /// Add this to your dispose() method
  void disposeOptimizedNotifications() {
    OptimizedHomeNotificationManager().dispose();
  }
}