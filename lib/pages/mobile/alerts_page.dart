import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_bottom_nav_bar.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_list.dart';
import 'package:pawsense/core/utils/data_cache.dart';

// GlobalKey for accessing AlertsPage methods
final GlobalKey<_AlertsPageState> alertsPageKey = GlobalKey<_AlertsPageState>();

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  UserModel? _userModel;
  List<AlertData> _alerts = [];
  bool _loading = true;
  int _currentNavIndex = 2; // Set to 2 for alerts tab
  final DataCache _cache = DataCache();

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _loadAlerts();
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadAlerts({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedAlerts = _cache.get<List<AlertData>>(CacheKeys.alerts());
      if (cachedAlerts != null) {
        print('[AlertsPage] Using cached alerts data');
        if (mounted) {
          setState(() {
            _alerts = cachedAlerts;
            _loading = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      // Simulate loading delay only when not cached
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample alert data - based on the image provided
      final sampleAlerts = [
        AlertData(
          title: 'Appointment Approved',
          subtitle: 'Tomorrow at 11:00 AM',
          type: AlertType.appointment,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        AlertData(
          title: 'Reschedule',
          subtitle: 'Dr. Lee requested a new time',
          type: AlertType.reschedule,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        AlertData(
          title: 'Appointment Declined',
          subtitle: 'Clinic fully booked',
          type: AlertType.declined,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isRead: false,
        ),
        AlertData(
          title: 'Reappointment Needed',
          subtitle: 'Follow-up recommended',
          type: AlertType.reappointment,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          isRead: false,
        ),
        AlertData(
          title: 'System Update',
          subtitle: 'Improved accuracy for dog dermatitis',
          type: AlertType.systemUpdate,
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
          isRead: true,
        ),
      ];

      // Cache the alerts with 2-minute TTL (alerts should be relatively fresh)
      _cache.put(CacheKeys.alerts(), sampleAlerts, ttl: const Duration(minutes: 2));
      print('[AlertsPage] Cached alerts data for 2 minutes');

      if (mounted) {
        setState(() {
          _alerts = sampleAlerts;
          _loading = false;
        });
      }
    } catch (e) {
      print('[AlertsPage] Error loading alerts: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _handleAlertTap(AlertData alert) {
    // Handle alert tap - navigate to relevant page or show details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${alert.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMarkAsRead(AlertData alert) {
    if (!mounted) return;
    
    setState(() {
      final index = _alerts.indexOf(alert);
      if (index != -1) {
        _alerts[index] = AlertData(
          title: alert.title,
          subtitle: alert.subtitle,
          type: alert.type,
          timestamp: alert.timestamp,
          isRead: true,
        );
      }
    });
    
    // Update cache with modified alerts
    _cache.put(CacheKeys.alerts(), _alerts, ttl: const Duration(minutes: 2));
    print('[AlertsPage] Updated cached alerts after marking as read');
  }

  /// Invalidate alerts cache - useful when alerts are updated externally
  void invalidateAlertsCache() {
    _cache.invalidate(CacheKeys.alerts());
    print('[AlertsPage] Invalidated alerts cache');
  }

  /// Refresh alerts with force refresh option
  void refreshAlerts({bool forceRefresh = false}) {
    _loadAlerts(forceRefresh: forceRefresh);
  }

  Future<void> _handleRefresh() async {
    await _loadAlerts(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UserAppBar(
        user: _userModel,
        onUserUpdated: (updatedUser) {
          setState(() {
            _userModel = updatedUser;
          });
        },
      ),
      body: _loading 
          ? _buildLoadingState()
          : _buildAlertsContent(),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          if (index == 0) {
            // Navigate to home
            context.go('/home');
          } else if (index == 2) {
            // Already on alerts page, do nothing
          } else {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
        onCameraPressed: _showCameraDialog,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildAlertsContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AlertList(
          alerts: _alerts,
          onAlertTap: _handleAlertTap,
          onMarkAsRead: _handleMarkAsRead,
        ),
      ),
    );
  }

  void _showCameraDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PetAssessmentModal(),
    );
  }
}
