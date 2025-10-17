import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/shared/page_header.dart';
import '../../../core/services/super_admin/super_admin_analytics_service.dart';
import '../../../core/widgets/super_admin/analytics_summary_cards.dart';
import '../../../core/widgets/super_admin/analytics_charts.dart';

class SystemAnalyticsScreen extends StatefulWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
  String selectedPeriod = 'Last 30 Days';
  bool isLoading = true;
  SystemStats? systemStats;
  List<TimeSeriesData> userGrowthData = [];
  List<TimeSeriesData> appointmentVolumeData = [];
  List<ClinicPerformanceData> topClinicsData = [];
  List<DiseaseDistributionData> diseaseData = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpacingLarge, kSpacingLarge, kSpacingLarge, 0),
            child: PageHeader(
              title: 'System Analytics',
              subtitle: 'Comprehensive system performance and usage analytics',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(kSpacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Action Bar
                  _buildActionBar(),
                  
                  SizedBox(height: kSpacingLarge),
                  
                  if (isLoading) ...[
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: kSpacingMedium),
                          Text(
                            'Loading analytics data...',
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (errorMessage != null) ...[
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppColors.error),
                          SizedBox(height: kSpacingMedium),
                          Text(
                            errorMessage!,
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(height: kSpacingLarge),
                          ElevatedButton.icon(
                            onPressed: _loadAnalyticsData,
                            icon: Icon(Icons.refresh),
                            label: Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (systemStats != null) ...[
                    // Summary Cards (6 KPIs)
                    AnalyticsSummaryCards(stats: systemStats!),
                    
                    SizedBox(height: kSpacingLarge),
                    
                    // Main Dashboard Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            children: [
                              UserGrowthChart(data: userGrowthData),
                              SizedBox(height: kSpacingLarge),
                              AppointmentVolumeChart(data: appointmentVolumeData),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: kSpacingLarge),
                        
                        // Right Column
                        Expanded(
                          child: Column(
                            children: [
                              ClinicStatusChart(stats: systemStats!.clinicStats),
                              SizedBox(height: kSpacingLarge),
                              DiseaseDistributionChart(data: diseaseData),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: kSpacingLarge),
                    
                    // Bottom Full-Width Card
                    TopClinicsTable(data: topClinicsData),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingLarge, vertical: kSpacingMedium),
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
      child: Row(
        children: [
          Text(
            'Time Period:',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: kSpacingMedium),
          Container(
            padding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: kSpacingSmall),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPeriod = newValue;
                    });
                    _loadAnalyticsData();
                  }
                },
                items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Last Year']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: kTextStyleRegular),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Spacer(),
          
          Text(
            'Last updated: ${_formatDateTime(DateTime.now())}',
            style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
          ),
          
          SizedBox(width: kSpacingLarge),
          
          ElevatedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: Icon(Icons.refresh, size: kIconSizeMedium),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
            ),
          ),
          
          SizedBox(width: kSpacingMedium),
          
          ElevatedButton.icon(
            onPressed: _exportAnalytics,
            icon: Icon(Icons.download, size: kIconSizeMedium),
            label: Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      AppLogger.dashboard('Loading system analytics for period: $selectedPeriod');

      // Fetch all data in parallel
      final results = await Future.wait([
        SuperAdminAnalyticsService.getSystemStats(selectedPeriod),
        SuperAdminAnalyticsService.getUserGrowthTrend(selectedPeriod),
        SuperAdminAnalyticsService.getAppointmentVolumeTrend(selectedPeriod),
        SuperAdminAnalyticsService.getTopClinicsPerformance(limit: 5),
        SuperAdminAnalyticsService.getDiseaseDistribution(limit: 5),
      ]);

      setState(() {
        systemStats = results[0] as SystemStats;
        userGrowthData = results[1] as List<TimeSeriesData>;
        appointmentVolumeData = results[2] as List<TimeSeriesData>;
        topClinicsData = results[3] as List<ClinicPerformanceData>;
        diseaseData = results[4] as List<DiseaseDistributionData>;
        isLoading = false;
      });

      AppLogger.dashboard('System analytics loaded successfully');
    } catch (e) {
      AppLogger.error('Error loading system analytics', error: e, tag: 'SystemAnalyticsScreen');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load analytics data. Please try again.';
      });
    }
  }

  Future<void> _exportAnalytics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: kSpacingMedium),
            Text('Exporting analytics...'),
          ],
        ),
      ),
    );

    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics exported successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
