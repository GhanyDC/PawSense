import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';

class HealthData {
  final String condition;
  final int count;
  final Color color;

  HealthData({
    required this.condition,
    required this.count,
    required this.color,
  });
}

class HealthSnapshot extends StatelessWidget {
  final List<HealthData> healthData;

  const HealthSnapshot({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final total = healthData.fold<int>(0, (sum, item) => sum + item.count);
    
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week Snapshot',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            total > 0 ? 'Most common detections' : 'No assessments yet',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: total > 0 ? kMobileSizedBoxMedium : kMobileSizedBoxMedium),
          
          if (total > 0) ...[
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: kMobileDonutChartSize,
                  height: kMobileDonutChartSize,
                  child: Stack(
                    children: [
                      _buildDonutChart(total),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$total',
                              style: kMobileTextStyleChartTotal.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Total',
                              style: kMobileTextStyleChartLabel.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: kMobileSizedBoxLarge),
                
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: healthData
                        .take(4)
                        .map((data) => _buildLegendItem(data))
                        .toList(),
                  ),
                ),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0),
              child: _buildEmptyState(context),
            ),
            const SizedBox(height: kMobileSizedBoxLarge), // Increased bottom spacing
          ],
        ],
      ),
    );
  }

  Widget _buildDonutChart(int total) {
    double startAngle = -90;
    
    return CustomPaint(
      size: const Size(kMobileDonutChartSize, kMobileDonutChartSize),
      painter: DonutChartPainter(
        data: healthData,
        total: total,
        startAngle: startAngle,
      ),
    );
  }

  Widget _buildLegendItem(HealthData data) {
    return Padding(
      padding: kMobileLegendPadding,
      child: Row(
        children: [
          Container(
            width: kMobileLegendDotSize,
            height: kMobileLegendDotSize,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: kMobileLegendSpacing),
          Expanded(
            child: Text(
              data.condition,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${data.count}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Added padding around the entire empty state
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80, // Slightly larger for better proportion
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assessment_outlined,
              size: 36, // Slightly larger icon
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 20), // Increased spacing between icon and text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Your First Assessment',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14, // Match the original smaller size
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4), // Back to original spacing
                Text(
                  'Take photos of your pet to start\nbuilding their health snapshot',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12, // Back to original smaller size
                    height: 1.3, // Adjusted line height
                  ),
                ),
                const SizedBox(height: 12), // Increased spacing before button
                GestureDetector(
                  onTap: () {
                    // Show pet assessment modal as bottom sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const PetAssessmentModal(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18, // Increased horizontal padding
                      vertical: 8,    // Increased vertical padding
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20), // Slightly more rounded
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ], // Added subtle shadow to button
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18, // Slightly larger icon
                        ),
                        const SizedBox(width: 8), // Increased spacing
                        Text(
                          'Start Assessment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12, // Back to original smaller size
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3, // Added letter spacing
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<HealthData> data;
  final int total;
  final double startAngle;

  DonutChartPainter({
    required this.data,
    required this.total,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.65;

    double currentAngle = startAngle * (3.14159 / 180);

    for (final item in data) {
      final sweepAngle = (item.count / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}