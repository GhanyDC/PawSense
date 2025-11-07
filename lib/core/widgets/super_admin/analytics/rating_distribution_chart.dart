import 'package:flutter/material.dart';
import '../../../models/analytics/system_analytics_models.dart';
import '../../../utils/app_colors.dart';

class RatingDistributionChart extends StatelessWidget {
  final RatingDistribution? ratingData;
  final bool isLoading;

  const RatingDistributionChart({
    Key? key,
    this.ratingData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (ratingData == null || ratingData!.totalRatedClinics == 0) {
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
              Icon(Icons.star, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Clinic Rating Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Average Rating Card
          _buildAverageRatingCard(),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Rating Bars
          _buildRatingBars(),
          
          const SizedBox(height: 16),
          
          // Quality Summary
          _buildQualitySummary(),
        ],
      ),
    );
  }

  Widget _buildAverageRatingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.1),
            AppColors.warning.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              ratingData!.averageSystemRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average System Rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    final avgRating = ratingData!.averageSystemRating;
                    return Icon(
                      rating <= avgRating
                          ? Icons.star
                          : (rating - 0.5 <= avgRating
                              ? Icons.star_half
                              : Icons.star_border),
                      color: AppColors.warning,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ratingData!.totalRatedClinics} rated • ${ratingData!.unratedClinics} unrated',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBars() {
    final totalRated = ratingData!.totalRatedClinics;
    final sortedRatings = ratingData!.ratingBuckets.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: sortedRatings.map((entry) {
        final stars = entry.key.toInt();
        final count = entry.value;
        final percentage = totalRated > 0 ? (count / totalRated * 100) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRatingBar(
            stars: stars,
            count: count,
            percentage: percentage,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingBar({
    required int stars,
    required int count,
    required double percentage,
  }) {
    final color = _getRatingColor(stars);

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Row(
            children: [
              Text(
                '$stars',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: percentage > 10
                        ? Text(
                            '$count (${percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            '$count clinics',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySummary() {
    final highRatings = (ratingData!.ratingBuckets[5.0] ?? 0) +
        (ratingData!.ratingBuckets[4.0] ?? 0);
    final totalRated = ratingData!.totalRatedClinics;
    final highRatingPercentage = totalRated > 0 ? (highRatings / totalRated * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            highRatingPercentage >= 70
                ? Icons.check_circle
                : Icons.info_outline,
            color: highRatingPercentage >= 70 ? AppColors.success : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quality Overview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '${highRatingPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: highRatingPercentage >= 70
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      TextSpan(
                        text: ' of clinics rated 4★ or higher',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int stars) {
    switch (stars) {
      case 5:
        return AppColors.success;
      case 4:
        return AppColors.info;
      case 3:
        return AppColors.warning;
      case 2:
        return const Color(0xFFFF9800); // Orange
      case 1:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
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
              Icons.star_border,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Rating Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clinics need to receive ratings to show distribution',
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
