import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';

class LocationDistributionPieChart extends StatelessWidget {
  final Map<String, int> locationDistribution;
  final bool isLoading;

  const LocationDistributionPieChart({
    Key? key,
    required this.locationDistribution,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = locationDistribution.values.fold(0, (sum, val) => sum + val);
    
    return Container(
      height: 500,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 40,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Patient Barangays',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Top Barangays with Completed Appointments',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : locationDistribution.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No location data available',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: PieChart(
                                PieChartData(
                                  sections: _generatePieChartSections(total),
                                  centerSpaceRadius: 50,
                                  sectionsSpace: 2,
                                  startDegreeOffset: -90,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildLegend(total),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(int total) {
    if (locationDistribution.isEmpty || total == 0) return [];

    final sortedEntries = locationDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = _getLocationColors();
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final location = entry.value.key;
      final count = entry.value.value;
      final percentage = (count / total * 100);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: percentage > 10 ? _buildBadge(location, color) : null,
        badgePositionPercentageOffset: 0.8,
      );
    }).toList();
  }

  Widget _buildLegend(int total) {
    final sortedEntries = locationDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final colors = _getLocationColors();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final location = entry.value.key;
          final count = entry.value.value;
          final percentage = (count / total * 100);
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.length > 20 
                            ? '${location.substring(0, 18)}...' 
                            : location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$count patients (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget? _buildBadge(String location, Color color) {
    final shortName = location.length > 10 
        ? '${location.substring(0, 8)}..' 
        : location;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        shortName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  List<Color> _getLocationColors() {
    return [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF607D8B), // Blue Grey
    ];
  }
}
