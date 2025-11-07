import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/analytics/system_analytics_models.dart';
import '../../../utils/app_colors.dart';

class DiseasesPieChart extends StatelessWidget {
  final List<DiseaseData> topDiseases;
  final bool isLoading;

  const DiseasesPieChart({
    Key? key,
    required this.topDiseases,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (topDiseases.isEmpty) {
      return _buildEmptyState();
    }

    final total = topDiseases.fold(0, (sum, disease) => sum + disease.count);

    return Container(
      height: 320,
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
          const Text(
            'Top Detected Diseases',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
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
    final colors = _getDiseaseColors();
    
    return topDiseases.take(8).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final disease = entry.value;
      final percentage = (disease.count / total * 100);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: disease.count.toDouble(),
        title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(int total) {
    final colors = _getDiseaseColors();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: topDiseases.take(8).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final disease = entry.value;
          final percentage = (disease.count / total * 100);
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
                        disease.diseaseName.length > 20
                            ? '${disease.diseaseName.substring(0, 18)}..'
                            : disease.diseaseName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${disease.count} (${percentage.toStringAsFixed(1)}%)',
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

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.coronavirus_outlined,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Disease Data Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getDiseaseColors() {
    return [
      const Color(0xFFE53935), // Red
      const Color(0xFFFB8C00), // Orange
      const Color(0xFFFDD835), // Yellow
      const Color(0xFF43A047), // Green
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFFD81B60), // Pink
    ];
  }
}
