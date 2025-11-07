import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/admin/dashboard_service.dart';
import '../../../utils/app_colors.dart';

class AppointmentStatusPieChart extends StatelessWidget {
  final AppointmentStatusData? statusData;
  final bool isLoading;

  const AppointmentStatusPieChart({
    super.key,
    this.statusData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 40,
            offset: Offset(0, 8),
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
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.pie_chart,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Appointment Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : statusData == null || statusData!.total == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No appointments found',
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
                                  sections: _generatePieChartSections(),
                                  centerSpaceRadius: 50,
                                  sectionsSpace: 2,
                                  startDegreeOffset: -90,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildLegend(),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    if (statusData == null || statusData!.total == 0) return [];

    final pieData = statusData!.toPieChartData();
    
    return pieData.map((data) {
      final percentage = (data.value / statusData!.total * 100);
      
      return PieChartSectionData(
        color: data.color,
        value: data.value.toDouble(),
        title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    if (statusData == null || statusData!.total == 0) return SizedBox.shrink();

    final pieData = statusData!.toPieChartData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: pieData.map((data) {
        final percentage = (data.value / statusData!.total * 100);
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${data.value} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
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