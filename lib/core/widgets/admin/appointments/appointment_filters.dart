import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/breed_options.dart';
import 'view_toggle_buttons.dart';
import '../../shared/search_field.dart';

class AppointmentFilters extends StatefulWidget {
  final String searchQuery;
  final String selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedPetType;
  final String? selectedBreed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<String?> onPetTypeChanged;
  final ValueChanged<String?> onBreedChanged;
  final VoidCallback onExportData;

  const AppointmentFilters({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    this.startDate,
    this.endDate,
    this.selectedPetType,
    this.selectedBreed,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onPetTypeChanged,
    required this.onBreedChanged,
    required this.onExportData,
  });

  @override
  State<AppointmentFilters> createState() => _AppointmentFiltersState();
}

class _AppointmentFiltersState extends State<AppointmentFilters> {
  List<String> _availableBreeds = [];
  bool _isLoadingBreeds = false;

  @override
  void initState() {
    super.initState();
    // Load breeds for selected pet type
    if (widget.selectedPetType != null && widget.selectedPetType != 'All') {
      _loadBreeds(widget.selectedPetType!);
    }
  }

  @override
  void didUpdateWidget(AppointmentFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload breeds if pet type changed
    if (widget.selectedPetType != oldWidget.selectedPetType) {
      if (widget.selectedPetType != null && widget.selectedPetType != 'All') {
        _loadBreeds(widget.selectedPetType!);
      } else {
        setState(() {
          _availableBreeds = [];
        });
      }
    }
  }

  Future<void> _loadBreeds(String petType) async {
    setState(() {
      _isLoadingBreeds = true;
    });

    try {
      final breeds = await BreedOptions.getBreedsForPetType(petType);
      setState(() {
        _availableBreeds = ['All', ...breeds];
        _isLoadingBreeds = false;
      });
    } catch (e) {
      print('Error loading breeds: $e');
      setState(() {
        _availableBreeds = ['All'];
        _isLoadingBreeds = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            // First Row: Search, Status Filters, and Export Button
            Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: SearchField(
                    hintText: 'Search appointments...',
                    onChanged: widget.onSearchChanged,
                    fontSize: kFontSizeRegular - 2,
                    initialValue: widget.searchQuery,
                  ),
                ),
                const SizedBox(width: 12),

                // Status Filter Buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ViewToggleButton(
                        text: 'All',
                        isSelected: widget.selectedStatus == 'All Status',
                        onTap: () => widget.onStatusChanged('All Status'),
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        text: 'Pending',
                        isSelected: widget.selectedStatus == 'Pending',
                        onTap: () => widget.onStatusChanged('Pending'),
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        text: 'Confirmed',
                        isSelected: widget.selectedStatus == 'Confirmed',
                        onTap: () => widget.onStatusChanged('Confirmed'),
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        text: 'Completed',
                        isSelected: widget.selectedStatus == 'Completed',
                        onTap: () => widget.onStatusChanged('Completed'),
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        text: 'Cancelled',
                        isSelected: widget.selectedStatus == 'Cancelled',
                        onTap: () => widget.onStatusChanged('Cancelled'),
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        text: 'Follow-up',
                        isSelected: widget.selectedStatus == 'Follow-up',
                        onTap: () => widget.onStatusChanged('Follow-up'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Export Button
                ElevatedButton.icon(
                  onPressed: widget.onExportData,
                  icon: Icon(Icons.download_outlined, size: kIconSizeMedium),
                  label: Text('Export', style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w500,
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge, 
                      vertical: kSpacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Second Row: Date Filters, Pet Type, and Breed
            Row(
              children: [
                // Start Date Picker
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        color: AppColors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                               size: kIconSizeSmall, 
                               color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.startDate != null 
                                  ? 'From: ${_formatDate(widget.startDate!)}'
                                  : 'Start Date',
                              style: kTextStyleRegular.copyWith(
                                color: widget.startDate != null 
                                    ? AppColors.textPrimary 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (widget.startDate != null)
                            GestureDetector(
                              onTap: () => widget.onStartDateChanged(null),
                              child: Icon(Icons.clear, 
                                   size: kIconSizeSmall, 
                                   color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // End Date Picker
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        color: AppColors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                               size: kIconSizeSmall, 
                               color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.endDate != null 
                                  ? 'To: ${_formatDate(widget.endDate!)}'
                                  : 'End Date',
                              style: kTextStyleRegular.copyWith(
                                color: widget.endDate != null 
                                    ? AppColors.textPrimary 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (widget.endDate != null)
                            GestureDetector(
                              onTap: () => widget.onEndDateChanged(null),
                              child: Icon(Icons.clear, 
                                   size: kIconSizeSmall, 
                                   color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Pet Type Dropdown
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      color: AppColors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.selectedPetType,
                        hint: Text(
                          'Pet Type',
                          style: kTextStyleRegular.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, 
                                 color: AppColors.textSecondary),
                        items: ['All', 'Dog', 'Cat'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(
                                  value == 'All' ? Icons.pets :
                                  value == 'Dog' ? Icons.pets :
                                  Icons.pets,
                                  size: kIconSizeSmall,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  value,
                                  style: kTextStyleRegular.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          widget.onPetTypeChanged(newValue == 'All' ? null : newValue);
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Breed Dropdown
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      color: AppColors.white,
                    ),
                    child: _isLoadingBreeds
                        ? Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: widget.selectedBreed,
                              hint: Text(
                                widget.selectedPetType == null || widget.selectedPetType == 'All'
                                    ? 'Select Pet Type First'
                                    : 'Breed',
                                style: kTextStyleRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, 
                                       color: AppColors.textSecondary),
                              items: _availableBreeds.isEmpty
                                  ? null
                                  : _availableBreeds.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: kTextStyleRegular.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                              onChanged: (widget.selectedPetType == null || widget.selectedPetType == 'All')
                                  ? null
                                  : (String? newValue) {
                                      widget.onBreedChanged(newValue == 'All' ? null : newValue);
                                    },
                            ),
                          ),
                  ),
                ),
                
                // Clear Date Filters Button (fixed width to match export button)
                if (widget.startDate != null || widget.endDate != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120, // Fixed width to match export button
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onStartDateChanged(null);
                        widget.onEndDateChanged(null);
                      },
                      icon: Icon(Icons.clear_all, size: kIconSizeMedium),
                      label: Text('Clear', style: kTextStyleRegular.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: kSpacingLarge, 
                          vertical: kSpacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  // Spacer when no clear button to maintain alignment
                  const SizedBox(width: 132),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      widget.onStartDateChanged(picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.endDate ?? DateTime.now(),
      firstDate: widget.startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      widget.onEndDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
