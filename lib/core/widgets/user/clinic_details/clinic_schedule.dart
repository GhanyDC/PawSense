import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';

class ClinicSchedule extends StatelessWidget {
  final WeeklySchedule weeklySchedule;
  final List<DateTime> holidays;

  const ClinicSchedule({
    super.key,
    required this.weeklySchedule,
    this.holidays = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.access_time,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Clinic Schedule',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Holiday notice if today is a holiday
          if (_isTodayHoliday()) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clinic is closed today for holiday',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Days of the week
          ...WeeklySchedule.daysOfWeek.map((day) {
            final schedule = weeklySchedule.schedules[day];
            return _buildScheduleRow(day, schedule);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String day, ClinicScheduleModel? schedule) {
    final isToday = _isToday(day);
    final dateForDay = _getDateForDay(day);
    final isHoliday = _isDateHoliday(dateForDay);
    final isOpen = (schedule?.isOpen ?? false) && !isHoliday;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isToday 
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          // Day name with flexible width
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(
                  day.substring(0, 3), // Show only first 3 letters (Mon, Tue, etc)
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Schedule time or status
          Expanded(
            flex: 5,
            child: Row(
              children: [
                if (isOpen && schedule != null) ...[
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${_formatTime(schedule.openTime)} - ${_formatTime(schedule.closeTime)}',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isHoliday ? AppColors.warning : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isHoliday ? 'Holiday' : 'Closed',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: isHoliday 
                            ? AppColors.warning 
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isHoliday 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isTodayHoliday() {
    final today = DateTime.now();
    return holidays.any((holiday) =>
        holiday.year == today.year &&
        holiday.month == today.month &&
        holiday.day == today.day);
  }

  /// Get the actual date for a day name in the current week
  DateTime _getDateForDay(String day) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    
    final dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    
    final targetWeekday = dayMap[day] ?? 1;
    final daysToAdd = targetWeekday - currentWeekday;
    
    return DateTime(now.year, now.month, now.day + daysToAdd);
  }

  /// Check if a specific date is a holiday
  bool _isDateHoliday(DateTime date) {
    return holidays.any((holiday) =>
        holiday.year == date.year &&
        holiday.month == date.month &&
        holiday.day == date.day);
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    
    final dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    
    return dayMap[day] == weekday;
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    
    try {
      // Parse 24-hour format (e.g., "09:00" or "17:00")
      final parts = time.split(':');
      if (parts.length != 2) return time;
      
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      
      // Convert to 12-hour format
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time;
    }
  }
}
