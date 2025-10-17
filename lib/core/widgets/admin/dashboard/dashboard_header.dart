import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import 'period_button.dart';

class DashboardHeader extends StatelessWidget {
  final String selectedPeriod;
  final String? userName;
  final Function(String) onPeriodChanged;

  const DashboardHeader({
    super.key,
    required this.selectedPeriod,
    this.userName,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildHeaderInfo(),
        Spacer(),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    // Build welcome message with dynamic name
    String welcomeMessage = 'Welcome back';
    if (userName != null && userName!.isNotEmpty) {
      welcomeMessage = 'Welcome back, $userName';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              'Dashboard',
              style: kTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
        SizedBox(height: 4),
        Text(
          welcomeMessage,
          style: TextStyle(
            fontSize: kFontSizeRegular,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Monitor your clinic\'s performance and recent activity',
          style: TextStyle(
            fontSize: kFontSizeRegular-2,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            PeriodButton(
              text: 'Daily',
              isSelected: selectedPeriod == 'Daily',
              onTap: () => onPeriodChanged('Daily'),
            ),
            PeriodButton(
              text: 'Weekly',
              isSelected: selectedPeriod == 'Weekly',
              onTap: () => onPeriodChanged('Weekly'),
            ),
            PeriodButton(
              text: 'Monthly',
              isSelected: selectedPeriod == 'Monthly',
              onTap: () => onPeriodChanged('Monthly'),
            ),
          ],
        ),
      ),
    );
  }
}
