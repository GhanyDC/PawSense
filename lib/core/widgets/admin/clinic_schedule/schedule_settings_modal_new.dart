import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class ScheduleSettingsModal extends StatefulWidget {
  final void Function(Map<String, dynamic> settings)? onSave;
  final String? clinicId;

  const ScheduleSettingsModal({
    super.key,
    this.onSave,
    this.clinicId,
  });

  @override
  State<ScheduleSettingsModal> createState() => _ScheduleSettingsModalState();
}

class _ScheduleSettingsModalState extends State<ScheduleSettingsModal> {
  late Future<WeeklySchedule> _weeklyScheduleFuture;
  final Map<String, bool> _isOpenMap = {};
  final Map<String, TimeOfDay?> _openTimeMap = {};
  final Map<String, TimeOfDay?> _closeTimeMap = {};
  final Map<String, List<BreakTime>> _breakTimesMap = {};
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, int> _slotsPerHourMap = {}; // New: slots per hour configuration
  final Map<String, int> _slotDurationMap = {}; // New: slot duration in minutes
  
  // Holiday management
  final List<DateTime> _specialHolidays = [];
  final TextEditingController _holidayController = TextEditingController();
  
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSchedule();
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    _holidayController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    for (final day in WeeklySchedule.daysOfWeek) {
      _notesControllers[day] = TextEditingController();
      _breakTimesMap[day] = [];
      _slotsPerHourMap[day] = 3; // Default 3 slots per hour
      _slotDurationMap[day] = 20; // Default 20 minutes per slot
    }
  }

  void _loadSchedule() {
    if (widget.clinicId == null) {
      // Use default clinic ID or handle appropriately
      _weeklyScheduleFuture = Future.value(WeeklySchedule(schedules: {}));
      return;
    }
    
    _weeklyScheduleFuture = ClinicScheduleService.getWeeklySchedule(widget.clinicId!);
    _weeklyScheduleFuture.then((schedule) {
      for (final day in WeeklySchedule.daysOfWeek) {
        final daySchedule = schedule.getScheduleForDay(day);
        if (daySchedule != null) {
          _isOpenMap[day] = daySchedule.isOpen;
          _openTimeMap[day] = daySchedule.openTime != null 
              ? _parseTimeString(daySchedule.openTime!) 
              : null;
          _closeTimeMap[day] = daySchedule.closeTime != null 
              ? _parseTimeString(daySchedule.closeTime!) 
              : null;
          _breakTimesMap[day] = List.from(daySchedule.breakTimes);
          _notesControllers[day]?.text = daySchedule.notes ?? '';
          _slotsPerHourMap[day] = daySchedule.slotsPerHour;
          _slotDurationMap[day] = daySchedule.slotDurationMinutes;
        } else {
          _isOpenMap[day] = day != 'Saturday' && day != 'Sunday';
          _openTimeMap[day] = const TimeOfDay(hour: 9, minute: 0);
          _closeTimeMap[day] = const TimeOfDay(hour: 17, minute: 0);
          _breakTimesMap[day] = [];
          _slotsPerHourMap[day] = 3; // Default 3 slots per hour
          _slotDurationMap[day] = 20; // Default 20 minutes
        }
      }
      setState(() {});
    });
    
    // Load holidays separately
    _loadHolidays();
  }

  void _loadHolidays() async {
    if (widget.clinicId == null) return;
    
    try {
      final holidays = await ClinicScheduleService.getHolidays(widget.clinicId!);
      setState(() {
        _specialHolidays.clear();
        _specialHolidays.addAll(holidays);
      });
      print('Loaded ${holidays.length} special holidays');
    } catch (e) {
      print('Error loading holidays: $e');
    }
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Validation functions
  bool _isOpenTimeBeforeCloseTime(String day) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    
    if (openTime == null || closeTime == null) return true;
    
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    
    return openMinutes < closeMinutes;
  }

  bool _isBreakTimeValid(BreakTime breakTime) {
    final startParts = breakTime.startTime.split(':');
    final endParts = breakTime.endTime.split(':');
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return startMinutes < endMinutes;
  }

  bool _isBreakTimeWithinOperatingHours(String day, BreakTime breakTime) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    
    if (openTime == null || closeTime == null) return false;
    
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    
    final startParts = breakTime.startTime.split(':');
    final endParts = breakTime.endTime.split(':');
    
    final breakStartMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final breakEndMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return breakStartMinutes >= openMinutes && breakEndMinutes <= closeMinutes;
  }

  String? _validateSchedule() {
    for (final day in WeeklySchedule.daysOfWeek) {
      if (_isOpenMap[day] == true) {
        if (_openTimeMap[day] == null || _closeTimeMap[day] == null) {
          return 'Please set both opening and closing times for $day';
        }
        
        if (!_isOpenTimeBeforeCloseTime(day)) {
          return 'Opening time must be before closing time for $day';
        }
        
        final breakTimes = _breakTimesMap[day] ?? [];
        for (final breakTime in breakTimes) {
          if (!_isBreakTimeValid(breakTime)) {
            return 'Break time start must be before end time for $day (${breakTime.label ?? 'Break'})';
          }
          
          if (!_isBreakTimeWithinOperatingHours(day, breakTime)) {
            return 'Break time must be within operating hours for $day (${breakTime.label ?? 'Break'})';
          }
        }
      }
    }
    return null;
  }

  Future<void> _selectHoliday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Holiday Date',
    );

    if (picked != null) {
      setState(() {
        if (!_specialHolidays.contains(picked)) {
          _specialHolidays.add(picked);
        }
      });
    }
  }

  void _removeHoliday(DateTime date) {
    setState(() {
      _specialHolidays.remove(date);
    });
  }

  // Calculate total capacity for a day
  int _calculateDayCapacity(String day) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    final slotsPerHour = _slotsPerHourMap[day] ?? 3;
    final breakTimes = _breakTimesMap[day] ?? [];
    
    if (openTime == null || closeTime == null) return 0;
    
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    final totalMinutes = closeMinutes - openMinutes;
    
    // Subtract break time minutes
    int breakMinutes = 0;
    for (final breakTime in breakTimes) {
      final breakStart = breakTime.startTime.split(':');
      final breakEnd = breakTime.endTime.split(':');
      final breakStartMinutes = int.parse(breakStart[0]) * 60 + int.parse(breakStart[1]);
      final breakEndMinutes = int.parse(breakEnd[0]) * 60 + int.parse(breakEnd[1]);
      breakMinutes += (breakEndMinutes - breakStartMinutes);
    }
    
    final workingMinutes = totalMinutes - breakMinutes;
    final workingHours = workingMinutes / 60;
    return (workingHours * slotsPerHour).floor();
  }

  // Updated save schedule with slots per hour
  Future<void> _saveSchedule() async {
    // Validate schedule before saving
    final validationError = _validateSchedule();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    if (widget.clinicId == null) {
      setState(() {
        _errorMessage = 'Clinic ID is required to save schedule';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final schedules = <ClinicScheduleModel>[];
      
      for (final day in WeeklySchedule.daysOfWeek) {
        final schedule = ClinicScheduleModel(
          id: '${widget.clinicId}_${day.toLowerCase()}',
          clinicId: widget.clinicId!,
          dayOfWeek: day,
          openTime: _openTimeMap[day] != null ? _formatTimeOfDay(_openTimeMap[day]!) : null,
          closeTime: _closeTimeMap[day] != null ? _formatTimeOfDay(_closeTimeMap[day]!) : null,
          isOpen: _isOpenMap[day] ?? false,
          breakTimes: _breakTimesMap[day] ?? [],
          notes: _notesControllers[day]?.text.trim().isEmpty == true 
              ? null 
              : _notesControllers[day]?.text.trim(),
          slotsPerHour: _slotsPerHourMap[day] ?? 3,
          slotDurationMinutes: _slotDurationMap[day] ?? 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        schedules.add(schedule);
      }
      
      final success = await ClinicScheduleService.saveWeeklySchedule(widget.clinicId!, schedules);
      
      // Save holidays separately
      final holidaySuccess = await ClinicScheduleService.saveHolidays(widget.clinicId!, _specialHolidays);
      
      if (success && holidaySuccess) {
        setState(() {
          _successMessage = 'Schedule and holidays saved successfully!';
        });
        
        // Call the onSave callback if provided
        widget.onSave?.call({
          'schedules': schedules.map((s) => s.toFirestore()).toList(),
          'holidays': _specialHolidays.map((d) => d.toIso8601String()).toList(),
        });
        
        // Close modal after short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else if (success && !holidaySuccess) {
        setState(() {
          _successMessage = 'Schedule saved successfully! (Warning: Holidays may not have been saved)';
        });
        
        // Still call the callback
        widget.onSave?.call({
          'schedules': schedules.map((s) => s.toFirestore()).toList(),
          'holidays': _specialHolidays.map((d) => d.toIso8601String()).toList(),
        });
        
        // Close modal after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to save schedule. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Operating Days Section with clickable chips
  Widget _buildOperatingDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operating Days',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C5F2D),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select which days your clinic is open:',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WeeklySchedule.daysOfWeek.map((day) {
            final isOpen = _isOpenMap[day] ?? false;
            return FilterChip(
              label: Text(
                day,
                style: TextStyle(
                  color: isOpen ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isOpen,
              onSelected: (selected) {
                setState(() {
                  _isOpenMap[day] = selected;
                  if (!selected) {
                    // Clear times and breaks when day is closed
                    _openTimeMap[day] = null;
                    _closeTimeMap[day] = null;
                    _breakTimesMap[day] = [];
                    _notesControllers[day]?.clear();
                  } else {
                    // Set default times when day is opened
                    _openTimeMap[day] = const TimeOfDay(hour: 9, minute: 0);
                    _closeTimeMap[day] = const TimeOfDay(hour: 17, minute: 0);
                  }
                });
              },
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              backgroundColor: AppColors.background,
              side: BorderSide(
                color: isOpen ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Time Settings Section
  Widget _buildTimeSettingsSection() {
    final openDays = WeeklySchedule.daysOfWeek.where((day) => _isOpenMap[day] == true).toList();
    
    if (openDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Please select at least one operating day to set opening hours.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operating Hours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C5F2D),
          ),
        ),
        const SizedBox(height: 16),
        ...openDays.map((day) => _buildDayTimeSettings(day)),
      ],
    );
  }

  Widget _buildDayTimeSettings(String day) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    final breakTimes = _breakTimesMap[day] ?? [];
    final hasTimeError = !_isOpenTimeBeforeCloseTime(day);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Text(
              day,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Time validation error
            if (hasTimeError)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Opening time must be before closing time',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            // Open and close time pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: openTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _openTimeMap[day] = time;
                              _errorMessage = null; // Clear error when time is changed
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasTimeError ? Colors.red.shade300 : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                openTime?.format(context) ?? 'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: openTime != null ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Close Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: closeTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _closeTimeMap[day] = time;
                              _errorMessage = null; // Clear error when time is changed
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasTimeError ? Colors.red.shade300 : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                closeTime?.format(context) ?? 'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: closeTime != null ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Slots per hour configuration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgsecond.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Appointment Capacity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Slots per Hour',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _slotsPerHourMap[day] ?? 3,
                                  isExpanded: true,
                                  items: [1, 2, 3, 4, 5, 6].map((slots) {
                                    return DropdownMenuItem<int>(
                                      value: slots,
                                      child: Text(
                                        '$slots slots per hour',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _slotsPerHourMap[day] = value;
                                        // Calculate duration automatically for backend compatibility
                                        _slotDurationMap[day] = (60 / value).round();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Capacity',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${_calculateDayCapacity(day)} appointments',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Break times section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Break Times',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addBreakTime(day),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2C5F2D),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            
            if (breakTimes.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...breakTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final breakTime = entry.value;
                final isBreakValid = _isBreakTimeValid(breakTime);
                final isWithinHours = _isBreakTimeWithinOperatingHours(day, breakTime);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (!isBreakValid || !isWithinHours) 
                        ? Colors.red.shade50 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (!isBreakValid || !isWithinHours) 
                          ? Colors.red.shade200 
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.coffee, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${breakTime.startTime} - ${breakTime.endTime}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (breakTime.label != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    breakTime.label!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeBreakTime(day, index),
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 16,
                            color: Colors.red.shade400,
                            tooltip: 'Remove break time',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          ),
                        ],
                      ),
                      // Break time validation errors
                      if (!isBreakValid || !isWithinHours) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                !isBreakValid 
                                    ? 'Break start time must be before end time'
                                    : 'Break time must be within operating hours',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Holiday Management Section
  Widget _buildHolidaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Holidays',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C5F2D),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add special holidays when your clinic will be closed:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // Add holiday button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _selectHoliday(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Holiday Date'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2C5F2D),
              side: const BorderSide(color: Color(0xFF2C5F2D)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Holiday list
        if (_specialHolidays.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled Holidays:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ..._specialHolidays.map((date) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_busy, color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _removeHoliday(date),
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 16,
                          color: Colors.red.shade400,
                          tooltip: 'Remove holiday',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'No special holidays added',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _addBreakTime(String day) {
    showDialog(
      context: context,
      builder: (context) => _AddBreakTimeDialog(
        day: day,
        openTime: _openTimeMap[day],
        closeTime: _closeTimeMap[day],
        onAdd: (breakTime) {
          // Validate break time before adding
          if (!_isBreakTimeValid(breakTime)) {
            setState(() {
              _errorMessage = 'Break start time must be before end time';
            });
            return;
          }
          
          if (!_isBreakTimeWithinOperatingHours(day, breakTime)) {
            setState(() {
              _errorMessage = 'Break time must be within operating hours';
            });
            return;
          }
          
          setState(() {
            _breakTimesMap[day]?.add(breakTime);
            _errorMessage = null;
          });
        },
      ),
    );
  }

  void _removeBreakTime(String day, int index) {
    setState(() {
      _breakTimesMap[day]?.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Clinic Schedule Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5F2D),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Success/Error Messages
            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Schedule Settings
            Expanded(
              child: FutureBuilder<WeeklySchedule>(
                future: _weeklyScheduleFuture,
                builder: (context, snapshot) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Operating Days Section
                        _buildOperatingDaysSection(),
                        const SizedBox(height: 24),
                        
                        // Time Settings Section
                        _buildTimeSettingsSection(),
                        const SizedBox(height: 24),
                        
                        // Holiday Management Section
                        _buildHolidaySection(),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Action Buttons
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text('Save Schedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for adding break times with validation
class _AddBreakTimeDialog extends StatefulWidget {
  final String day;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final Function(BreakTime) onAdd;
  
  const _AddBreakTimeDialog({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.onAdd,
  });

  @override
  State<_AddBreakTimeDialog> createState() => _AddBreakTimeDialogState();
}

class _AddBreakTimeDialogState extends State<_AddBreakTimeDialog> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _labelController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isValidBreakTime() {
    if (_startTime == null || _endTime == null) return false;
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    // Check if start is before end
    if (startMinutes >= endMinutes) {
      _errorMessage = 'Break start time must be before end time';
      return false;
    }
    
    // Check if within operating hours
    if (widget.openTime != null && widget.closeTime != null) {
      final operatingStartMinutes = widget.openTime!.hour * 60 + widget.openTime!.minute;
      final operatingEndMinutes = widget.closeTime!.hour * 60 + widget.closeTime!.minute;
      
      if (startMinutes < operatingStartMinutes || endMinutes > operatingEndMinutes) {
        _errorMessage = 'Break time must be within operating hours (${widget.openTime!.format(context)} - ${widget.closeTime!.format(context)})';
        return false;
      }
    }
    
    _errorMessage = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.coffee, color: Color(0xFF2C5F2D)),
          const SizedBox(width: 8),
          Text('Add Break Time - ${widget.day}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // Operating hours info
          if (widget.openTime != null && widget.closeTime != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Operating hours: ${widget.openTime!.format(context)} - ${widget.closeTime!.format(context)}',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // Start time picker
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime ?? widget.openTime ?? const TimeOfDay(hour: 12, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                  _isValidBreakTime(); // Validate on change
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _startTime?.format(context) ?? 'Select start time',
                    style: TextStyle(
                      color: _startTime != null ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  const Icon(Icons.access_time),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // End time picker
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime ?? widget.closeTime ?? const TimeOfDay(hour: 13, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                  _isValidBreakTime(); // Validate on change
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _endTime?.format(context) ?? 'Select end time',
                    style: TextStyle(
                      color: _endTime != null ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  const Icon(Icons.access_time),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Label field
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'e.g., Lunch Break',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _startTime != null && _endTime != null && _isValidBreakTime()
              ? () {
                  final breakTime = BreakTime(
                    startTime: _formatTimeOfDay(_startTime!),
                    endTime: _formatTimeOfDay(_endTime!),
                    label: _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
                  );
                  widget.onAdd(breakTime);
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}