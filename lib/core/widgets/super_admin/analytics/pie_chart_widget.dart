import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Data model for pie chart sections
class PieChartDataSection {
  final String label;
  final double value;
  final Color color;
  final String? displayValue; // Optional custom display value

  const PieChartDataSection({
    required this.label,
    required this.value,
    required this.color,
    this.displayValue,
  });
}

/// Reusable Pie Chart Widget for analytics
class AnalyticsPieChart extends StatefulWidget {
  final String title;
  final List<PieChartDataSection> data;
  final bool isLoading;
  final double? height;
  final bool showPercentages;
  final bool showLegend;

  const AnalyticsPieChart({
    super.key,
    required this.title,
    required this.data,
    this.isLoading = false,
    this.height = 300,
    this.showPercentages = true,
    this.showLegend = true,
  });

  @override
  State<AnalyticsPieChart> createState() => _AnalyticsPieChartState();
}

class _AnalyticsPieChartState extends State<AnalyticsPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
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
          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Chart Content
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : widget.data.isEmpty
                    ? _buildEmptyState()
                    : Row(
                        children: [
                          // Pie Chart
                          Expanded(
                            flex: widget.showLegend ? 2 : 1,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _buildPieChartSections(),
                              ),
                            ),
                          ),

                          // Legend
                          if (widget.showLegend && widget.data.isNotEmpty) ...[
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildLegend(),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No data available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = widget.data.fold<double>(0, (sum, item) => sum + item.value);
    
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final double percentage = total > 0 ? (data.value / total) * 100 : 0;
      
      return PieChartSectionData(
        color: data.color,
        value: data.value,
        title: widget.showPercentages 
            ? '${percentage.toStringAsFixed(1)}%'
            : data.displayValue ?? data.value.toStringAsFixed(0),
        radius: isTouched ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black26,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final total = widget.data.fold<double>(0, (sum, item) => sum + item.value);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.data.map((data) {
        final percentage = total > 0 ? (data.value / total) * 100 : 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${data.displayValue ?? data.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
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
    );
  }
}