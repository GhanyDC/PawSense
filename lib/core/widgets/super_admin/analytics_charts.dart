import 'package:flutter/material.dart';
import 'package:pawsense/core/services/super_admin/super_admin_analytics_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:intl/intl.dart';

/// User growth trend chart widget
class UserGrowthChart extends StatelessWidget {
  final List<TimeSeriesData> data;

  const UserGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No user growth data available');
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'User Growth Trend',
            Icons.trending_up,
            AppColors.primary,
          ),
          SizedBox(height: kSpacingLarge),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final barHeight = (maxValue > minValue
                        ? ((point.value - minValue) / (maxValue - minValue)) * 180
                        : 100).toDouble();
                    final width = (constraints.maxWidth / data.length) - 4;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: '${point.value.toInt()} users\n${DateFormat('MMM d').format(point.date)}',
                            child: Container(
                              width: width,
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          if (index % (data.length ~/ 5).clamp(1, data.length) == 0)
                            Text(
                              DateFormat('MMM d').format(point.date),
                              style: kTextStyleSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: AppColors.textTertiary),
            SizedBox(height: kSpacingMedium),
            Text(
              message,
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clinic status distribution pie chart
class ClinicStatusChart extends StatelessWidget {
  final ClinicStats stats;

  const ClinicStatusChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalClinics;
    if (total == 0) {
      return _buildEmptyState('No clinic data available');
    }

    final segments = [
      _ChartSegment('Active', stats.activeClinics, AppColors.success),
      _ChartSegment('Pending', stats.pendingClinics, AppColors.warning),
      _ChartSegment('Rejected', stats.rejectedClinics, AppColors.error),
      _ChartSegment('Suspended', stats.suspendedClinics, AppColors.textSecondary),
    ].where((s) => s.value > 0).toList();

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Clinic Status Distribution',
            Icons.local_hospital,
            AppColors.success,
          ),
          SizedBox(height: kSpacingLarge),
          Row(
            children: [
              // Pie chart representation using stacked bars
              Expanded(
                child: Column(
                  children: segments.map((segment) {
                    final percentage = (segment.value / total * 100);
                    return Padding(
                      padding: EdgeInsets.only(bottom: kSpacingSmall),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              segment.label,
                              style: kTextStyleSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(width: kSpacingMedium),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage / 100,
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: segment.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: kSpacingMedium),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${segment.value} (${percentage.toStringAsFixed(1)}%)',
                              style: kTextStyleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, size: 48, color: AppColors.textTertiary),
            SizedBox(height: kSpacingMedium),
            Text(
              message,
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Appointment volume trend chart
class AppointmentVolumeChart extends StatelessWidget {
  final List<TimeSeriesData> data;

  const AppointmentVolumeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No appointment data available');
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Appointment Volume Trend',
            Icons.calendar_today,
            AppColors.info,
          ),
          SizedBox(height: kSpacingLarge),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final barHeight = (maxValue > 0
                        ? (point.value / maxValue) * 180
                        : 0).toDouble();
                    final width = (constraints.maxWidth / data.length) - 4;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: '${point.value.toInt()} appointments\n${DateFormat('MMM d').format(point.date)}',
                            child: Container(
                              width: width,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          if (index % (data.length ~/ 5).clamp(1, data.length) == 0)
                            Text(
                              DateFormat('MMM d').format(point.date),
                              style: kTextStyleSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: AppColors.textTertiary),
            SizedBox(height: kSpacingMedium),
            Text(
              message,
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disease distribution chart
class DiseaseDistributionChart extends StatelessWidget {
  final List<DiseaseDistributionData> data;

  const DiseaseDistributionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No disease data available');
    }

    final colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.info,
      AppColors.success,
      AppColors.primary,
    ];

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Top Detected Diseases',
            Icons.medical_services,
            AppColors.error,
          ),
          SizedBox(height: kSpacingLarge),
          Column(
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final disease = entry.value;
              final color = colors[index % colors.length];

              return Padding(
                padding: EdgeInsets.only(bottom: kSpacingMedium),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: kSpacingMedium),
                    Expanded(
                      flex: 2,
                      child: Text(
                        disease.diseaseName,
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: kSpacingMedium),
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: disease.percentage / 100,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: kSpacingMedium),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${disease.count} (${disease.percentage.toStringAsFixed(1)}%)',
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 48, color: AppColors.textTertiary),
            SizedBox(height: kSpacingMedium),
            Text(
              message,
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top clinics performance table
class TopClinicsTable extends StatelessWidget {
  final List<ClinicPerformanceData> data;

  const TopClinicsTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No clinic performance data available');
    }

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Top Performing Clinics',
            Icons.emoji_events,
            Color(0xFFF59E0B),
          ),
          SizedBox(height: kSpacingLarge),
          Table(
            columnWidths: {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.border, width: 1),
            ),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusSmall)),
                ),
                children: [
                  _tableHeader('#'),
                  _tableHeader('Clinic Name'),
                  _tableHeader('Appointments'),
                  _tableHeader('Rating'),
                  _tableHeader('Score'),
                ],
              ),
              // Data rows
              ...data.asMap().entries.map((entry) {
                final index = entry.key;
                final clinic = entry.value;
                return TableRow(
                  children: [
                    _tableCell('${index + 1}'),
                    _tableCell(clinic.clinicName),
                    _tableCell(clinic.appointmentCount.toString()),
                    _tableCellWithIcon(
                      clinic.rating.toStringAsFixed(1),
                      Icons.star,
                      Color(0xFFF59E0B),
                    ),
                    _tableCellWithBadge(
                      clinic.performanceScore.toStringAsFixed(1),
                      _getPerformanceColor(clinic.performanceScore),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(kSpacingSmall),
      child: Text(
        text,
        style: kTextStyleSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(kSpacingSmall),
      child: Text(
        text,
        style: kTextStyleSmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _tableCellWithIcon(String text, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.all(kSpacingSmall),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: kTextStyleSmall.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _tableCellWithBadge(String text, Color color) {
    return Padding(
      padding: EdgeInsets.all(kSpacingSmall),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: kTextStyleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getPerformanceColor(double score) {
    if (score >= 4.0) return AppColors.success;
    if (score >= 3.0) return AppColors.info;
    if (score >= 2.0) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: _cardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 48, color: AppColors.textTertiary),
            SizedBox(height: kSpacingMedium),
            Text(
              message,
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper classes and functions

class _ChartSegment {
  final String label;
  final int value;
  final Color color;

  _ChartSegment(this.label, this.value, this.color);
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
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
  );
}

Widget _buildChartHeader(String title, IconData icon, Color color) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(kSpacingSmall),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        ),
        child: Icon(icon, color: color, size: kIconSizeMedium),
      ),
      SizedBox(width: kSpacingMedium),
      Text(
        title,
        style: kTextStyleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
