import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/user/disease_statistics_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class AreaStatisticsCard extends StatefulWidget {
  const AreaStatisticsCard({super.key});

  @override
  State<AreaStatisticsCard> createState() => AreaStatisticsCardState();
}

class AreaStatisticsCardState extends State<AreaStatisticsCard> {
  final DiseaseStatisticsService _statisticsService = DiseaseStatisticsService();
  AreaDiseaseStatistics? _statistics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Public method to refresh statistics (can be called from parent widget)
  Future<void> refreshStatistics() async {
    await _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null || user.address == null || user.address!.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'No address set';
          });
        }
        return;
      }

      final statistics = await _statisticsService.getMostCommonDiseaseInArea(user.address!);

      if (mounted) {
        setState(() {
          _statistics = statistics;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load statistics';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: kMobileMarginCard,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area Statistics',
                      style: kMobileTextStyleTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Most common disease in your area',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: AppColors.border.withOpacity(0.3),
          ),

          const SizedBox(height: 16),

          // Content
          if (_loading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_statistics == null || 
                   (_statistics!.dogStatistic == null && _statistics!.catStatistic == null))
            _buildNoDataState()
          else
            _buildStatisticsContent(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading statistics...',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load statistics',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.textTertiary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No disease data available in your area yet',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    final statistics = _statistics!;
    final dogStat = statistics.dogStatistic;
    final catStat = statistics.catStatistic;
    
    return Column(
      children: [
        // Dog statistics
        if (dogStat != null) ...[
          _buildSpeciesStatistic(dogStat, '🐶', AppColors.primary),
          if (catStat != null) const SizedBox(height: 16),
        ],
        
        // Cat statistics
        if (catStat != null) ...[
          _buildSpeciesStatistic(catStat, '🐱', const Color(0xFF9C27B0)), // Purple for cats
        ],
      ],
    );
  }

  Widget _buildSpeciesStatistic(DiseaseStatistic statistic, String emoji, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Species header
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              '${statistic.species}s',
              style: kMobileTextStyleTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Disease name and location
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDiseaseName(statistic.diseaseName),
                      style: kMobileTextStyleTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'in ${statistic.location}',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Statistics row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.medical_information,
                label: 'Cases',
                value: '${statistic.count}',
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.percent,
                label: 'Prevalence',
                value: '${statistic.percentage.toStringAsFixed(1)}%',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.assessment,
                label: 'Total',
                value: '${statistic.totalCases}',
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Info message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Based on ${statistic.totalCases} ${statistic.species.toLowerCase()} assessments',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: kMobileTextStyleTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: kMobileTextStyleSubtitle.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDiseaseName(String diseaseName) {
    // Convert disease name to title case and remove underscores
    return diseaseName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
