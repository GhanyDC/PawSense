import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class BreedStatisticsCards extends StatelessWidget {
  final Map<String, int> statistics;
  final bool isLoading;

  const BreedStatisticsCards({
    super.key,
    required this.statistics,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Breeds',
            statistics['total']?.toString() ?? '0',
            Icons.pets,
            AppColors.primary,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Cat Breeds',
            statistics['catBreeds']?.toString() ?? '0',
            Icons.pets,
            Color(0xFFFF9500), // Orange
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Dog Breeds',
            statistics['dogBreeds']?.toString() ?? '0',
            Icons.pets,
            Color(0xFF007AFF), // Blue
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Recently Added',
            statistics['recentlyAdded']?.toString() ?? '0',
            Icons.add_circle_outline,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: kIconSizeLarge,
                ),
              ),
              Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingMedium),
          Text(
            title,
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: kSpacingSmall / 2),
          Text(
            value,
            style: kTextStyleHeader.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < 3 ? kSpacingLarge : 0,
            ),
            padding: EdgeInsets.all(kSpacingLarge),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(height: kSpacingMedium),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
