import 'package:flutter/material.dart';
import '../../../models/analytics/system_analytics_models.dart';
import '../../../utils/app_colors.dart';

class BreedPopularityChart extends StatelessWidget {
  final BreedPopularity? breedData;
  final bool isLoading;

  const BreedPopularityChart({
    Key? key,
    this.breedData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (breedData == null ||
        (breedData!.topDogBreeds.isEmpty && breedData!.topCatBreeds.isEmpty)) {
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
              Icon(Icons.pets, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Most Popular Breeds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Breed Sections
          if (breedData!.topDogBreeds.isNotEmpty) ...[
            _buildBreedSection(
              title: 'Dog Breeds',
              icon: '🐕',
              breeds: breedData!.topDogBreeds,
              color: AppColors.primary,
            ),
            if (breedData!.topCatBreeds.isNotEmpty) const SizedBox(height: 24),
          ],
          
          if (breedData!.topCatBreeds.isNotEmpty) ...[
            _buildBreedSection(
              title: 'Cat Breeds',
              icon: '🐈',
              breeds: breedData!.topCatBreeds,
              color: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreedSection({
    required String title,
    required String icon,
    required Map<String, int> breeds,
    required Color color,
  }) {
    if (breeds.isEmpty) return const SizedBox.shrink();

    // Convert map to sorted list
    final breedList = breeds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxCount = breedList.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...breedList.asMap().entries.map((entry) {
          final index = entry.key;
          final breedEntry = entry.value;
          final percentage = maxCount > 0 ? (breedEntry.value / maxCount) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBreedBar(
              rank: index + 1,
              breedName: breedEntry.key,
              count: breedEntry.value,
              percentage: percentage,
              color: color,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBreedBar({
    required int rank,
    required String breedName,
    required int count,
    required double percentage,
    required Color color,
  }) {
    return Row(
      children: [
        // Rank Badge
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: rank <= 3 ? color : AppColors.border.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Breed Name
        SizedBox(
          width: 120,
          child: Text(
            breedName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        
        // Progress Bar
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: rank <= 3 ? 1.0 : 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        
        // Count
        SizedBox(
          width: 50,
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
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
              Icons.pets,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Breed Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register pets to see breed popularity',
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
