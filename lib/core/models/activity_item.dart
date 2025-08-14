import 'package:flutter/material.dart';

class ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}