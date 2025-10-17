import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/models/clinic/clinic_rating_model.dart';

/// Widget to display average rating with stars and review count
class ClinicRatingDisplay extends StatelessWidget {
  final ClinicRatingStats stats;
  final double starSize;
  final bool showReviewCount;
  final TextStyle? textStyle;
  final Color? starColor;

  const ClinicRatingDisplay({
    super.key,
    required this.stats,
    this.starSize = 16,
    this.showReviewCount = true,
    this.textStyle,
    this.starColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!stats.hasRatings) {
      return Text(
        'No reviews yet',
        style: textStyle ?? TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star icon
        Icon(
          Icons.star_rounded,
          size: starSize,
          color: starColor ?? AppColors.primary,
        ),
        const SizedBox(width: 4),
        
        // Rating value
        Text(
          stats.formattedAverage,
          style: textStyle ?? const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        // Review count
        if (showReviewCount) ...[
          const SizedBox(width: 4),
          Text(
            '(${stats.totalRatings})',
            style: textStyle?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.normal,
            ) ?? TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget to display full star rating (filled, half-filled, empty)
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final Color? emptyColor;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 20,
    this.color,
    this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full stars
        ...List.generate(fullStars, (index) => Icon(
          Icons.star_rounded,
          size: size,
          color: color ?? AppColors.primary,
        )),
        
        // Half star
        if (hasHalfStar)
          Icon(
            Icons.star_half_rounded,
            size: size,
            color: color ?? AppColors.primary,
          ),
        
        // Empty stars
        ...List.generate(emptyStars, (index) => Icon(
          Icons.star_outline_rounded,
          size: size,
          color: emptyColor ?? Colors.grey[300],
        )),
      ],
    );
  }
}

/// Compact badge showing just the rating number with star
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final Color? backgroundColor;
  final Color? textColor;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: textColor ?? AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.primary,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: 10,
                color: (textColor ?? AppColors.primary).withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget showing rating distribution with bars
class RatingDistributionWidget extends StatelessWidget {
  final ClinicRatingStats stats;

  const RatingDistributionWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (!stats.hasRatings) {
      return const Center(
        child: Text(
          'No ratings yet',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(5, (index) {
        final star = 5 - index; // Start from 5 stars down to 1
        final count = stats.ratingDistribution[star] ?? 0;
        final percentage = stats.getPercentage(star);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Star number
              SizedBox(
                width: 30,
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Progress bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Count
              SizedBox(
                width: 40,
                child: Text(
                  '$count',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
