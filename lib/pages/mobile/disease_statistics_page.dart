import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/user/disease_statistics_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class DiseaseStatisticsPage extends StatefulWidget {
  final String? petType; // 'dog' or 'cat' to filter, null for both

  const DiseaseStatisticsPage({super.key, this.petType});

  @override
  State<DiseaseStatisticsPage> createState() => _DiseaseStatisticsPageState();
}

class _DiseaseStatisticsPageState extends State<DiseaseStatisticsPage> {
  final DiseaseStatisticsService _statisticsService = DiseaseStatisticsService();
  AreaDiseaseStatistics? _statistics;
  bool _loading = true;
  String? _error;
  String _selectedView = 'both'; // 'both', 'dogs', 'cats'

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    if (widget.petType != null) {
      _selectedView = widget.petType == 'dog' ? 'dogs' : 'cats';
    }
  }

  Future<void> _loadStatistics() async {
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

      final statistics = await _statisticsService.getMostCommonDiseaseInArea(user.address!, user.uid);

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Disease Statistics',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border.withOpacity(0.3),
          ),
        ),
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _statistics == null ||
                      (_statistics!.dogStatistics.isEmpty && _statistics!.catStatistics.isEmpty)
                  ? _buildNoDataState()
                  : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading statistics...',
            style: kMobileTextStyleSubtitle.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load statistics',
              style: kMobileTextStyleTitle.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStatistics,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.textTertiary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No disease data available',
              style: kMobileTextStyleTitle.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No disease data available in your area yet',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final statistics = _statistics!;
    final dogStats = statistics.dogStatistics;
    final catStats = statistics.catStatistics;

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Area',
                          style: kMobileTextStyleSubtitle.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statistics.location,
                          style: kMobileTextStyleTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // View Toggle
            if (dogStats.isNotEmpty && catStats.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'View:',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildViewChip('Both', 'both'),
                            const SizedBox(width: 8),
                            _buildViewChip('🐶 Dogs', 'dogs'),
                            const SizedBox(width: 8),
                            _buildViewChip('🐱 Cats', 'cats'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Statistics Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_selectedView == 'both' || _selectedView == 'dogs')
                    if (dogStats.isNotEmpty) ...[
                      _buildFullStatisticsSection(
                        dogStats,
                        '🐶 Dog Cases',
                        AppColors.primary,
                      ),
                      if (catStats.isNotEmpty && _selectedView == 'both')
                        const SizedBox(height: 24),
                    ],
                  if (_selectedView == 'both' || _selectedView == 'cats')
                    if (catStats.isNotEmpty)
                      _buildFullStatisticsSection(
                        catStats,
                        '🐱 Cat Cases',
                        const Color(0xFF9C27B0),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewChip(String label, String value) {
    final isSelected = _selectedView == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: kMobileTextStyleSubtitle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFullStatisticsSection(
    List<DiseaseStatistic> statistics,
    String title,
    Color accentColor,
  ) {
    if (statistics.isEmpty) return const SizedBox.shrink();

    final totalCases = statistics.first.totalCases;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
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
              Text(
                title,
                style: kMobileTextStyleTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCases total cases',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // All Statistics
          ...statistics.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final isLast = index == statistics.length - 1;

            return Column(
              children: [
                _buildStatisticRow(stat, accentColor),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: AppColors.border.withOpacity(0.3),
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatisticRow(DiseaseStatistic stat, Color accentColor) {
    // Calculate the index properly based on current view
    final currentStats = _selectedView == 'dogs' 
        ? (_statistics?.dogStatistics ?? [])
        : _selectedView == 'cats'
            ? (_statistics?.catStatistics ?? [])
            : [...?_statistics?.dogStatistics, ...?_statistics?.catStatistics];
    
    final index = currentStats.indexOf(stat);
    
    return Row(
      children: [
        // Rank badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#${index + 1}',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Disease info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _formatDiseaseName(stat.diseaseName),
                      style: kMobileTextStyleTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (stat.isContagious) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Contagious',
                        style: kMobileTextStyleSubtitle.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stat.percentage.toStringAsFixed(1)}% of cases',
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Case count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medical_services,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${stat.count}',
                style: kMobileTextStyleTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DiseaseStatistic> get statistics {
    if (_selectedView == 'dogs') {
      return _statistics?.dogStatistics ?? [];
    } else if (_selectedView == 'cats') {
      return _statistics?.catStatistics ?? [];
    } else {
      return [
        ...?_statistics?.dogStatistics,
        ...?_statistics?.catStatistics,
      ];
    }
  }

  String _formatDiseaseName(String diseaseName) {
    return diseaseName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
