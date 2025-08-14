import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../utils/app_colors.dart';
import 'view_toggle_buttons.dart';
import '../shared/search_field.dart';

class AppointmentFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedView;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onViewChanged;

  const AppointmentFilters({
    Key? key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedView,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onViewChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search Field
            Expanded(
              flex: 2,
              child: SearchField(
                hintText: 'Search appointments...',
                onChanged: onSearchChanged,
                fontSize: kFontSizeRegular - 2,
              ),
            ),
            const SizedBox(width: 12),

            // Status Dropdown
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                onChanged: (value) => onStatusChanged(value!),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
                items: const [
                  DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                ],
              ),
            ),
            
            const SizedBox(width: 12),

          // View Toggle Buttons using PeriodButton
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200], // light gray background
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                ViewToggleButton(
                  text: 'Table',
                  isSelected: selectedView == 'Table',
                  onTap: () => onViewChanged('Table'),
                ),
                const SizedBox(width: 8),
                ViewToggleButton(
                  text: 'Calendar',
                  isSelected: selectedView == 'Calendar',
                  onTap: () => onViewChanged('Calendar'),
                ),
              ],
            ),
          ),


          ],
        ),
      ),
    );
  }
}
