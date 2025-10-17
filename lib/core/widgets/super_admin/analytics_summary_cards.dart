import 'package:flutter/material.dart';
import 'package:pawsense/core/services/super_admin/super_admin_analytics_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

/// Summary cards widget for System Analytics dashboard
/// Displays 6 key KPIs with icons, values, and trend indicators
class AnalyticsSummaryCards extends StatelessWidget {
  final SystemStats stats;

  const AnalyticsSummaryCards({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: kSpacingLarge,
      mainAxisSpacing: kSpacingLarge,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Total Users',
          value: _formatNumber(stats.userStats.totalUsers),
          icon: Icons.people,
          color: AppColors.primary,
          trend: stats.userStats.growthPercentage,
          subtitle: '${stats.userStats.newUsers} new this period',
        ),
        _SummaryCard(
          title: 'Active Clinics',
          value: _formatNumber(stats.clinicStats.activeClinics),
          icon: Icons.local_hospital,
          color: AppColors.success,
          trend: stats.clinicStats.growthPercentage,
          subtitle: '${stats.clinicStats.pendingClinics} pending approval',
        ),
        _SummaryCard(
          title: 'Total Appointments',
          value: _formatNumber(stats.appointmentStats.totalAppointments),
          icon: Icons.calendar_today,
          color: AppColors.info,
          trend: stats.appointmentStats.growthPercentage,
          subtitle: '${stats.appointmentStats.completedAppointments} completed',
        ),
        _SummaryCard(
          title: 'AI Scans',
          value: _formatNumber(stats.aiUsageStats.totalScans),
          icon: Icons.camera_alt,
          color: AppColors.warning,
          trend: stats.aiUsageStats.growthPercentage,
          subtitle: '${stats.aiUsageStats.averageConfidence.toStringAsFixed(1)}% avg confidence',
        ),
        _SummaryCard(
          title: 'Registered Pets',
          value: _formatNumber(stats.petStats.totalPets),
          icon: Icons.pets,
          color: Color(0xFFEC4899), // Pink color for pets
          trend: stats.petStats.growthPercentage,
          subtitle: '${stats.petStats.newPets} new this period',
        ),
        _SummaryCard(
          title: 'System Rating',
          value: stats.averageRating.toStringAsFixed(1),
          icon: Icons.star,
          color: Color(0xFFF59E0B), // Amber/Gold color for rating
          trend: null, // No trend for rating
          subtitle: 'Average across all clinics',
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Individual summary card component
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final String subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header with icon and trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(kSpacingSmall),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: kIconSizeLarge,
                ),
              ),
              if (trend != null) _buildTrendIndicator(trend!),
            ],
          ),

          // Value and title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: kTextStyleTitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Subtitle
          Text(
            subtitle,
            style: kTextStyleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double percentage) {
    final isPositive = percentage >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: kTextStyleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
