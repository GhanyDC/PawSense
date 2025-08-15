import 'package:flutter/material.dart';
import '../../core/widgets/notifications/notification_header.dart';
import '../../core/widgets/notifications/notification_tabs.dart';
import '../../core/widgets/notifications/notification_item.dart';
import '../../core/utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType _selectedTab = NotificationType.all;
  
  // TODO: Replace with actual data from your notification service
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'New Appointment Request',
      'description': 'Max (Golden Retriever) - Skin condition examination requested for tomorrow 2:00 PM',
      'timestamp': DateTime.now().subtract(Duration(minutes: 2)),
      'isEmergency': false,
      'isUnread': true,
      'requiresAction': true,
      'icon': Icons.calendar_today,
      'iconColor': Colors.blue,
      'actionButtonText': 'Approve',
      'type': NotificationType.appointments,
      'details': {
        'Patient': 'Max',
        'Owner': 'John Smith',
        'Time': '2024-01-16 14:00',
      },
    },
    {
      'id': '2',
      'title': 'Emergency Appointment',
      'description': 'Rocky (German Shepherd) - Possible poisoning, owner requesting immediate consultation',
      'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
      'isEmergency': true,
      'isUnread': true,
      'requiresAction': true,
      'icon': Icons.warning,
      'iconColor': Colors.red,
      'actionButtonText': 'Emergency Response',
      'type': NotificationType.appointments,
      'details': {
        'Patient': 'Rocky',
        'Owner': 'David Brown',
      },
    },
  ];

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedTab == NotificationType.all) {
      return notifications;
    } else if (_selectedTab == NotificationType.unread) {
      return notifications.where((n) => n['isUnread'] == true).toList();
    } else {
      return notifications.where((n) => n['type'] == _selectedTab).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n['isUnread']).length;
    final actionRequired = notifications.where((n) => n['requiresAction']).length;

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotificationHeader(
            unreadCount: unreadCount,
            actionRequired: actionRequired,
            onMarkAllRead: () {
              setState(() {
                for (var notification in notifications) {
                  notification['isUnread'] = false;
                }
              });
            },
            onSettings: () {
              // TODO: Navigate to notification settings
            },
          ),
          NotificationTabs(
            selectedTab: _selectedTab,
            onTabSelected: (tab) {
              setState(() {
                _selectedTab = tab;
              });
            },
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _getFilteredNotifications().length,
              itemBuilder: (context, index) {
                final notification = _getFilteredNotifications()[index];
                return NotificationItem(
                  title: notification['title'],
                  description: notification['description'],
                  timestamp: notification['timestamp'],
                  isEmergency: notification['isEmergency'],
                  isUnread: notification['isUnread'],
                  requiresAction: notification['requiresAction'],
                  icon: notification['icon'],
                  iconColor: notification['iconColor'],
                  actionButtonText: notification['actionButtonText'],
                  details: notification['details']?.cast<String, String>(),
                  onMarkRead: () {
                    setState(() {
                      notification['isUnread'] = false;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      notifications.removeWhere((n) => n['id'] == notification['id']);
                    });
                  },
                  onAction: () {
                    // TODO: Implement action handling based on notification type
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
