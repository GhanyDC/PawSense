import 'package:flutter/material.dart';
import '../../../models/analytics/system_analytics_models.dart';
import '../../../utils/app_colors.dart';

class MessagingStatsCard extends StatelessWidget {
  final MessagingStats? messagingStats;
  final bool isLoading;

  const MessagingStatsCard({
    Key? key,
    this.messagingStats,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (messagingStats == null || messagingStats!.totalConversations == 0) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Messaging Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Metrics Grid
          _buildMetricsGrid(),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Activity Chart
          _buildActivityChart(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final activePercentage = messagingStats!.totalConversations > 0
        ? (messagingStats!.activeConversations / messagingStats!.totalConversations * 100)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                icon: Icons.forum,
                label: 'Total Conversations',
                value: messagingStats!.totalConversations.toString(),
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: _buildMetricItem(
                icon: Icons.chat,
                label: 'Active Conversations',
                value: messagingStats!.activeConversations.toString(),
                subtitle: '${activePercentage.toStringAsFixed(1)}% active',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                icon: Icons.message,
                label: 'Total Messages',
                value: _formatNumber(messagingStats!.totalMessages),
                color: AppColors.info,
              ),
            ),
            Expanded(
              child: _buildMetricItem(
                icon: Icons.schedule,
                label: 'Avg Response Time',
                value: _formatHours(messagingStats!.avgResponseTimeHours),
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message Volume',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: _buildVolumeBar(
                  label: 'Total',
                  value: messagingStats!.totalMessages,
                  maxValue: messagingStats!.totalMessages,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVolumeBar(
                  label: 'This Period',
                  value: messagingStats!.messagesInPeriod,
                  maxValue: messagingStats!.totalMessages,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeBar({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
    final barHeight = (150 - 70) * percentage.clamp(0.0, 1.0); // 150 total - 70 for text spacing

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          _formatNumber(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150 - 70, // Fixed height for the bar area
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes min';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hrs';
    } else {
      final days = (hours / 24).toStringAsFixed(1);
      return '$days days';
    }
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Center(
        heightFactor: 8,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Messaging Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start conversations to see messaging statistics',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
