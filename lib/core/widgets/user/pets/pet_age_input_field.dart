import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

enum AgeInputMode { birthdate, months }

class PetAgeInputField extends StatefulWidget {
  final TextEditingController ageController;
  final Function(int ageInMonths, DateTime? birthdate)? onAgeChanged;
  final int? initialAgeInMonths;

  const PetAgeInputField({
    super.key,
    required this.ageController,
    this.onAgeChanged,
    this.initialAgeInMonths,
  });

  @override
  State<PetAgeInputField> createState() => _PetAgeInputFieldState();
}

class _PetAgeInputFieldState extends State<PetAgeInputField> {
  AgeInputMode _inputMode = AgeInputMode.months;
  
  // Birthdate dropdown values
  String? _selectedMonth;
  String? _selectedYear;
  
  // Calculated values
  int? _calculatedAge;
  DateTime? _calculatedBirthdate;
  
  // Error states
  String? _birthdateError;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with existing age if provided
    if (widget.initialAgeInMonths != null && widget.initialAgeInMonths! > 0) {
      widget.ageController.text = widget.initialAgeInMonths.toString();
      _calculateBirthdateFromAge(widget.initialAgeInMonths!);
    }
    
    // Listen to age controller changes
    widget.ageController.addListener(_onAgeControllerChanged);
  }
  
  @override
  void dispose() {
    widget.ageController.removeListener(_onAgeControllerChanged);
    super.dispose();
  }
  
  void _onAgeControllerChanged() {
    if (_inputMode == AgeInputMode.months) {
      final age = int.tryParse(widget.ageController.text);
      if (age != null && age > 0) {
        _calculateBirthdateFromAge(age);
      }
    }
  }
  
  void _calculateAgeFromBirthdate() {
    if (_selectedMonth == null || _selectedYear == null) {
      setState(() {
        _calculatedAge = null;
        _calculatedBirthdate = null;
        _birthdateError = null;
      });
      return;
    }
    
    final month = int.parse(_selectedMonth!);
    final year = int.parse(_selectedYear!);
    final now = DateTime.now();
    final birthdate = DateTime(year, month, 1);
    
    // Check if birthdate is in the future
    if (year > now.year || (year == now.year && month > now.month)) {
      setState(() {
        _calculatedAge = null;
        _calculatedBirthdate = null;
        _birthdateError = 'Birthdate cannot be in the future';
      });
      return;
    }
    
    final ageInMonths = (now.year - year) * 12 + (now.month - month);
    
    setState(() {
      _calculatedAge = ageInMonths < 0 ? 0 : ageInMonths;
      _calculatedBirthdate = birthdate;
      _birthdateError = null;
      widget.ageController.text = _calculatedAge.toString();
    });
    
    // Notify parent
    if (widget.onAgeChanged != null && _calculatedAge != null) {
      widget.onAgeChanged!(_calculatedAge!, _calculatedBirthdate);
    }
  }
  
  void _calculateBirthdateFromAge(int ageInMonths) {
    final now = DateTime.now();
    final years = ageInMonths ~/ 12;
    final months = ageInMonths % 12;
    
    int birthYear = now.year - years;
    int birthMonth = now.month - months;
    
    if (birthMonth <= 0) {
      birthMonth += 12;
      birthYear -= 1;
    }
    
    final birthdate = DateTime(birthYear, birthMonth, 1);
    
    setState(() {
      _calculatedAge = ageInMonths;
      _calculatedBirthdate = birthdate;
      _selectedMonth = birthMonth.toString().padLeft(2, '0');
      _selectedYear = birthYear.toString();
      _birthdateError = null;
    });
    
    // Notify parent
    if (widget.onAgeChanged != null) {
      widget.onAgeChanged!(ageInMonths, birthdate);
    }
  }
  
  String _formatBirthdate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
  
  String _formatAge(int months) {
    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      } else {
        return '$years ${years == 1 ? 'year' : 'years'} $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Pet Age',
                style: kMobileTextStyleServiceTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton(
                    'Date',
                    AgeInputMode.birthdate,
                    Icons.calendar_today,
                  ),
                  _buildToggleButton(
                    'Months',
                    AgeInputMode.months,
                    Icons.timer_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: kMobileSizedBoxMedium),
        
        // Input field based on mode
        if (_inputMode == AgeInputMode.birthdate)
          _buildBirthdateInput()
        else
          _buildMonthsInput(),
        
        // Calculated value display
        if (_calculatedAge != null && _inputMode == AgeInputMode.birthdate)
          _buildCalculatedInfo(
            icon: Icons.info_outline,
            label: 'Calculated Age',
            value: _formatAge(_calculatedAge!),
            color: AppColors.primary,
          )
        else if (_calculatedBirthdate != null && _inputMode == AgeInputMode.months)
          _buildCalculatedInfo(
            icon: Icons.cake_outlined,
            label: 'Approximate Birthdate',
            value: _formatBirthdate(_calculatedBirthdate!),
            color: AppColors.info,
          ),
      ],
    );
  }
  
  Widget _buildToggleButton(String label, AgeInputMode mode, IconData icon) {
    final isSelected = _inputMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _inputMode = mode;
          
          // Recalculate when switching modes
          if (mode == AgeInputMode.birthdate) {
            final age = int.tryParse(widget.ageController.text);
            if (age != null && age > 0) {
              _calculateBirthdateFromAge(age);
            }
          } else {
            _calculateAgeFromBirthdate();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBirthdateInput() {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Generate month list
    final months = [
      {'value': '01', 'label': 'January'},
      {'value': '02', 'label': 'February'},
      {'value': '03', 'label': 'March'},
      {'value': '04', 'label': 'April'},
      {'value': '05', 'label': 'May'},
      {'value': '06', 'label': 'June'},
      {'value': '07', 'label': 'July'},
      {'value': '08', 'label': 'August'},
      {'value': '09', 'label': 'September'},
      {'value': '10', 'label': 'October'},
      {'value': '11', 'label': 'November'},
      {'value': '12', 'label': 'December'},
    ];
    
    // Generate year list (current year back to 50 years ago)
    final years = List.generate(51, (index) => (currentYear - index).toString());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Month Dropdown
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    borderSide: BorderSide(
                      color: _birthdateError != null ? Colors.red : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    borderSide: BorderSide(
                      color: _birthdateError != null ? Colors.red : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    borderSide: BorderSide(
                      color: _birthdateError != null ? Colors.red : AppColors.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                hint: const Text('Select month'),
                items: months.map((month) {
                  return DropdownMenuItem<String>(
                    value: month['value'],
                    child: Text(month['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value;
                  });
                  _calculateAgeFromBirthdate();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            // Year Dropdown
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    borderSide: BorderSide(
                      color: _birthdateError != null ? Colors.red : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    borderSide: BorderSide(
                      color: _birthdateError != null ? Colors.red : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    borderSide: BorderSide(
                      color: _birthdateError != null ? Colors.red : AppColors.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                hint: const Text('Year'),
                items: years.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                  });
                  _calculateAgeFromBirthdate();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        // Error message
        if (_birthdateError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _birthdateError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Select birthdate (month and year)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildMonthsInput() {
    return TextFormField(
      controller: widget.ageController,
      keyboardType: TextInputType.number,
      maxLength: 3,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: 'Age in Months',
        hintText: 'e.g., 24',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: kMobileBorderRadiusSmallPreset,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kMobileBorderRadiusSmallPreset,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kMobileBorderRadiusSmallPreset,
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: kMobileBorderRadiusSmallPreset,
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: kMobilePaddingCard,
        counterText: "",
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.pets,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Age is required';
        }
        final age = int.tryParse(value);
        if (age == null || age <= 0) {
          return 'Enter valid age';
        }
        if (age > 300) {
          return 'Age seems too high';
        }
        return null;
      },
    );
  }
  
  Widget _buildCalculatedInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
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
