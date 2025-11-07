import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

/// Shared styles for dashboard chart containers
class ChartContainerStyles {
  /// Standard decoration for chart containers
  static BoxDecoration containerDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.border.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppColors.primary.withOpacity(0.03),
          blurRadius: 40,
          offset: Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Build chart title with icon
  static Widget buildChartTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// Build subtitle text
  static Widget buildSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Build empty state for charts
  static Widget buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
