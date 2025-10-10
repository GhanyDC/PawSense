import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notifications/notification_model.dart';
import '../../widgets/user/alerts/alert_item.dart';
import '../../utils/notification_helper.dart';
import 'notification_service.dart';

/// Paginated notification service optimized for performance
/// Features:
/// - Infinite scrolling with batch loading
/// - Cache-first strategy for instant loading
/// - Background refresh for fresh data
/// - Optimistic updates for better UX
class PaginatedNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';
  static const int _pageSize = 20;
  static const String _cachePrefix = 'alerts_cache_';
  
  // In-memory cache for session
  static final Map<String, List<AlertData>> _sessionCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Pagination state per user
  static final Map<String, DocumentSnapshot?> _lastDocuments = {};
  static final Map<String, bool> _hasMoreData = {};
  
  /// Clear all caches for a user (useful for logout or refresh)
  static void clearUserCache(String userId) {
    _sessionCache.remove(userId);
    _cacheTimestamps.remove(userId);
    _lastDocuments.remove(userId);
    _hasMoreData.remove(userId);
  }
  
  /// Get cached notifications immediately, then fetch fresh data
  static Future<AlertsPageData> getNotificationsWithCache(String userId) async {
    try {
      // 1. Try to get cached data first for instant display
      final cachedAlerts = await _getCachedAlerts(userId);
      
      // 2. Start fresh data fetch in background
      final freshDataFuture = _fetchFreshNotifications(userId);
      
      // 3. Return cached data immediately if available
      if (cachedAlerts.isNotEmpty) {
        // Update with fresh data when available (don't await)
        freshDataFuture.then((freshData) {
          if (freshData.notifications.isNotEmpty) {
            _updateCache(userId, freshData.notifications);
          }
        }).catchError((e) {
          print('Background refresh failed: $e');
        });
        
        return AlertsPageData(
          notifications: cachedAlerts,
          hasMore: _hasMoreData[userId] ?? true,
          isFromCache: true,
        );
      }
      
      // 4. If no cache, wait for fresh data
      final freshData = await freshDataFuture;
      return AlertsPageData(
        notifications: freshData.notifications,
        hasMore: freshData.hasMore,
        isFromCache: false,
      );
      
    } catch (e) {
      print('Error getting notifications with cache: $e');
      return AlertsPageData(
        notifications: [],
        hasMore: false,
        isFromCache: false,
      );
    }
  }
  
  /// Load more notifications for infinite scroll
  static Future<AlertsPageData> loadMoreNotifications(String userId) async {
    try {
      final lastDoc = _lastDocuments[userId];
      if (lastDoc == null || !(_hasMoreData[userId] ?? true)) {
        return AlertsPageData(notifications: [], hasMore: false, isFromCache: false);
      }
      
      // Get more regular notifications from database
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDoc)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMoreData[userId] = false;
        return AlertsPageData(notifications: [], hasMore: false, isFromCache: false);
      }
      
      // Convert to alert data
      final newAlerts = await _convertToAlertData(snapshot.docs, userId);
      
      // Update pagination state
      _lastDocuments[userId] = snapshot.docs.last;
      _hasMoreData[userId] = snapshot.docs.length == _pageSize;
      
      // Update session cache
      final existingAlerts = _sessionCache[userId] ?? [];
      final updatedAlerts = [...existingAlerts, ...newAlerts];
      _sessionCache[userId] = updatedAlerts;
      _cacheTimestamps[userId] = DateTime.now();
      
      // Update persistent cache
      await _updatePersistentCache(userId, updatedAlerts);
      
      return AlertsPageData(
        notifications: newAlerts,
        hasMore: _hasMoreData[userId] ?? false,
        isFromCache: false,
      );
      
    } catch (e) {
      print('Error loading more notifications: $e');
      return AlertsPageData(notifications: [], hasMore: false, isFromCache: false);
    }
  }
  
  /// Refresh notifications (pull-to-refresh)
  static Future<AlertsPageData> refreshNotifications(String userId) async {
    try {
      // Clear caches
      clearUserCache(userId);
      
      // Fetch fresh data
      final freshData = await _fetchFreshNotifications(userId);
      
      // Update caches
      await _updateCache(userId, freshData.notifications);
      
      return freshData;
      
    } catch (e) {
      print('Error refreshing notifications: $e');
      return AlertsPageData(notifications: [], hasMore: false, isFromCache: false);
    }
  }
  
  /// Get cached alerts from memory or persistent storage
  static Future<List<AlertData>> _getCachedAlerts(String userId) async {
    // Check session cache first
    final sessionCacheTime = _cacheTimestamps[userId];
    if (sessionCacheTime != null && 
        DateTime.now().difference(sessionCacheTime) < _cacheExpiry) {
      final sessionAlerts = _sessionCache[userId];
      if (sessionAlerts != null && sessionAlerts.isNotEmpty) {
        return sessionAlerts;
      }
    }
    
    // Check persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$userId';
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson != null) {
        final cacheData = json.decode(cachedJson);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          final alertsList = (cacheData['alerts'] as List)
              .map((alertJson) => AlertData(
                    id: alertJson['id'],
                    title: alertJson['title'],
                    subtitle: alertJson['subtitle'],
                    type: AlertType.values.firstWhere(
                      (e) => e.toString() == alertJson['type'],
                      orElse: () => AlertType.systemUpdate,
                    ),
                    timestamp: DateTime.parse(alertJson['timestamp']),
                    isRead: alertJson['isRead'] ?? false,
                    actionUrl: alertJson['actionUrl'],
                    actionLabel: alertJson['actionLabel'],
                    metadata: alertJson['metadata']?.cast<String, dynamic>(),
                  ))
              .toList();
          
          // Store in session cache
          _sessionCache[userId] = alertsList;
          _cacheTimestamps[userId] = timestamp;
          
          return alertsList;
        }
      }
    } catch (e) {
      print('Error reading cached alerts: $e');
    }
    
    return [];
  }
  
  /// Fetch fresh notifications from server
  static Future<AlertsPageData> _fetchFreshNotifications(String userId) async {
    try {
      // Reset pagination state
      _lastDocuments.remove(userId);
      _hasMoreData[userId] = true;
      
      // Get regular notifications with pagination
      final query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      
      final snapshot = await query.get();
      
      // Convert to alert data
      final regularAlerts = await _convertToAlertData(snapshot.docs, userId);
      
      // Get virtual notifications (appointments, messages, tasks) - limited to recent ones
      final virtualAlerts = await _getVirtualNotifications(userId);
      
      // Combine and sort all notifications
      final allAlerts = [...regularAlerts, ...virtualAlerts];
      allAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Take only the most recent notifications for first load
      final limitedAlerts = allAlerts.take(_pageSize).toList();
      
      // Update pagination state
      if (snapshot.docs.isNotEmpty) {
        _lastDocuments[userId] = snapshot.docs.last;
      }
      _hasMoreData[userId] = snapshot.docs.length == _pageSize || allAlerts.length > _pageSize;
      
      return AlertsPageData(
        notifications: limitedAlerts,
        hasMore: _hasMoreData[userId] ?? false,
        isFromCache: false,
      );
      
    } catch (e) {
      print('Error fetching fresh notifications: $e');
      return AlertsPageData(notifications: [], hasMore: false, isFromCache: false);
    }
  }
  
  /// Get virtual notifications (appointments, messages, tasks) with limits
  static Future<List<AlertData>> _getVirtualNotifications(String userId) async {
    try {
      final virtualAlerts = <AlertData>[];
      
      // Get recent appointment notifications (limit 5)
      await for (final appointments in NotificationService.getAppointmentNotifications(userId).take(1)) {
        final appointmentAlerts = appointments
            .take(5) // Limit for performance
            .map((notification) => NotificationHelper.fromNotificationModel(notification))
            .toList();
        virtualAlerts.addAll(appointmentAlerts);
        break;
      }
      
      // Get recent message notifications (limit 5)
      await for (final messages in NotificationService.getMessageNotifications(userId).take(1)) {
        final messageAlerts = messages
            .take(5) // Limit for performance
            .map((notification) => NotificationHelper.fromNotificationModel(notification))
            .toList();
        virtualAlerts.addAll(messageAlerts);
        break;
      }
      
      // Get recent task notifications (limit 5)
      await for (final tasks in NotificationService.getTaskNotifications(userId).take(1)) {
        final taskAlerts = tasks
            .take(5) // Limit for performance
            .map((notification) => NotificationHelper.fromNotificationModel(notification))
            .toList();
        virtualAlerts.addAll(taskAlerts);
        break;
      }
      
      return virtualAlerts;
      
    } catch (e) {
      print('Error getting virtual notifications: $e');
      return [];
    }
  }
  
  /// Convert Firestore documents to AlertData
  static Future<List<AlertData>> _convertToAlertData(List<QueryDocumentSnapshot> docs, String userId) async {
    final alerts = <AlertData>[];
    
    // Get read states for better performance
    final readStates = await _getReadStates(userId);
    
    for (final doc in docs) {
      try {
        final notification = NotificationModel.fromFirestore(doc);
        if (notification.shouldShow) {
          // Apply read states
          final isRead = readStates[notification.id] ?? notification.isRead;
          final updatedNotification = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            message: notification.message,
            category: notification.category,
            priority: notification.priority,
            isRead: isRead,
            actionUrl: notification.actionUrl,
            actionLabel: notification.actionLabel,
            createdAt: notification.createdAt,
            sentAt: notification.sentAt,
            readAt: notification.readAt,
            expiresAt: notification.expiresAt,
            metadata: notification.metadata,
          );
          
          final alert = NotificationHelper.fromNotificationModel(updatedNotification);
          alerts.add(alert);
        }
      } catch (e) {
        print('Error converting document to alert: $e');
      }
    }
    
    return alerts;
  }
  
  /// Get read states for notifications
  static Future<Map<String, bool>> _getReadStates(String userId) async {
    try {
      final readStatesDoc = await _firestore
          .collection('user_preferences')
          .doc('notification_read_states_$userId')
          .get();
      
      if (readStatesDoc.exists) {
        final data = readStatesDoc.data() ?? {};
        return data.map((key, value) => MapEntry(key, value['isRead'] == true));
      }
    } catch (e) {
      print('Error getting read states: $e');
    }
    return {};
  }
  
  /// Update cache with new data
  static Future<void> _updateCache(String userId, List<AlertData> alerts) async {
    // Update session cache
    _sessionCache[userId] = alerts;
    _cacheTimestamps[userId] = DateTime.now();
    
    // Update persistent cache
    await _updatePersistentCache(userId, alerts);
  }
  
  /// Update persistent cache
  static Future<void> _updatePersistentCache(String userId, List<AlertData> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$userId';
      
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'alerts': alerts.map((alert) => {
          'id': alert.id,
          'title': alert.title,
          'subtitle': alert.subtitle,
          'type': alert.type.toString(),
          'timestamp': alert.timestamp.toIso8601String(),
          'isRead': alert.isRead,
          'actionUrl': alert.actionUrl,
          'actionLabel': alert.actionLabel,
          'metadata': alert.metadata,
        }).toList(),
      };
      
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Error updating persistent cache: $e');
    }
  }
  
  /// Mark notification as read with optimistic update
  static Future<void> markAsReadOptimistic(String notificationId, String userId) async {
    try {
      // Update session cache immediately
      final alerts = _sessionCache[userId];
      if (alerts != null) {
        final index = alerts.indexWhere((alert) => alert.id == notificationId);
        if (index != -1 && !alerts[index].isRead) {
          _sessionCache[userId] = List.from(alerts);
          _sessionCache[userId]![index] = AlertData(
            id: alerts[index].id,
            title: alerts[index].title,
            subtitle: alerts[index].subtitle,
            type: alerts[index].type,
            timestamp: alerts[index].timestamp,
            isRead: true, // Optimistically mark as read
            actionUrl: alerts[index].actionUrl,
            actionLabel: alerts[index].actionLabel,
            metadata: alerts[index].metadata,
          );
          
          // Update persistent cache
          await _updatePersistentCache(userId, _sessionCache[userId]!);
        }
      }
      
      // Update server in background (don't await)
      NotificationService.markAsRead(notificationId, userId: userId).catchError((e) {
        print('Error marking as read on server: $e');
        // Could revert optimistic update here if needed
      });
      
    } catch (e) {
      print('Error in optimistic mark as read: $e');
    }
  }
}

/// Data class for alerts page response
class AlertsPageData {
  final List<AlertData> notifications;
  final bool hasMore;
  final bool isFromCache;
  
  const AlertsPageData({
    required this.notifications,
    required this.hasMore,
    required this.isFromCache,
  });
}