import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicScheduleModel {
  final String id;
  final String clinicId;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String? openTime; // 24-hour format: "09:00"
  final String? closeTime; // 24-hour format: "17:00"
  final bool isOpen; // true if clinic is open on this day
  final List<BreakTime> breakTimes; // lunch breaks, etc.
  final String? notes; // special notes for this day
  final int slotsPerHour; // configurable slots per hour (e.g., 3 slots/hour)
  final int slotDurationMinutes; // duration of each slot in minutes (default: 20 minutes for 3 slots/hour)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ClinicScheduleModel({
    required this.id,
    required this.clinicId,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    required this.isOpen,
    this.breakTimes = const [],
    this.notes,
    this.slotsPerHour = 3, // default 3 slots per hour
    this.slotDurationMinutes = 20, // default 20 minutes per slot
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Create from Firestore document
  factory ClinicScheduleModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ClinicScheduleModel(
      id: id,
      clinicId: data['clinicId'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? '',
      openTime: data['openTime'],
      closeTime: data['closeTime'],
      isOpen: data['isOpen'] ?? false,
      breakTimes: (data['breakTimes'] as List<dynamic>?)
          ?.map((breakTime) => BreakTime.fromMap(breakTime))
          .toList() ?? [],
      notes: data['notes'],
      slotsPerHour: data['slotsPerHour'] ?? 3,
      slotDurationMinutes: data['slotDurationMinutes'] ?? 20,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'clinicId': clinicId,
      'dayOfWeek': dayOfWeek,
      'openTime': openTime,
      'closeTime': closeTime,
      'isOpen': isOpen,
      'breakTimes': breakTimes.map((breakTime) => breakTime.toMap()).toList(),
      'notes': notes,
      'slotsPerHour': slotsPerHour,
      'slotDurationMinutes': slotDurationMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create copy with updated fields
  ClinicScheduleModel copyWith({
    String? id,
    String? clinicId,
    String? dayOfWeek,
    String? openTime,
    String? closeTime,
    bool? isOpen,
    List<BreakTime>? breakTimes,
    String? notes,
    int? slotsPerHour,
    int? slotDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ClinicScheduleModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isOpen: isOpen ?? this.isOpen,
      breakTimes: breakTimes ?? this.breakTimes,
      notes: notes ?? this.notes,
      slotsPerHour: slotsPerHour ?? this.slotsPerHour,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Check if clinic is open at specific time
  bool isOpenAt(DateTime dateTime) {
    if (!isOpen || openTime == null || closeTime == null) return false;
    
    final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    // Check if time is within operating hours
    if (timeString.compareTo(openTime!) < 0 || timeString.compareTo(closeTime!) > 0) {
      return false;
    }
    
    // Check if time is during break times
    for (final breakTime in breakTimes) {
      if (breakTime.isTimeInBreak(timeString)) {
        return false;
      }
    }
    
    return true;
  }

  // Get available time slots for this day based on configured slots per hour
  List<String> getAvailableTimeSlots() {
    if (!isOpen || openTime == null || closeTime == null) return [];
    
    final slots = <String>[];
    final startHour = int.parse(openTime!.split(':')[0]);
    final startMinute = int.parse(openTime!.split(':')[1]);
    final endHour = int.parse(closeTime!.split(':')[0]);
    final endMinute = int.parse(closeTime!.split(':')[1]);
    
    DateTime current = DateTime(2024, 1, 1, startHour, startMinute);
    final end = DateTime(2024, 1, 1, endHour, endMinute);
    
    while (current.isBefore(end)) {
      final timeString = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
      
      // Check if this time slot is not during a break
      bool isDuringBreak = false;
      for (final breakTime in breakTimes) {
        if (breakTime.isTimeInBreak(timeString)) {
          isDuringBreak = true;
          break;
        }
      }
      
      if (!isDuringBreak) {
        slots.add(timeString);
      }
      
      current = current.add(Duration(minutes: slotDurationMinutes));
    }
    
    return slots;
  }

  // Get total capacity (maximum appointments) for this day
  int getTotalCapacity() {
    if (!isOpen || openTime == null || closeTime == null) return 0;
    
    final startHour = int.parse(openTime!.split(':')[0]);
    final startMinute = int.parse(openTime!.split(':')[1]);
    final endHour = int.parse(closeTime!.split(':')[0]);
    final endMinute = int.parse(closeTime!.split(':')[1]);
    
    final totalMinutes = (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
    
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
    return (workingMinutes / slotDurationMinutes).floor();
  }

  // Get slots per hour information
  String getSlotsPerHourInfo() {
    return '$slotsPerHour slots/hour (${slotDurationMinutes}min each)';
  }
}

// Break time model for lunch breaks, etc.
class BreakTime {
  final String startTime; // "12:00"
  final String endTime; // "13:00"
  final String? label; // "Lunch Break"

  BreakTime({
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory BreakTime.fromMap(Map<String, dynamic> data) {
    return BreakTime(
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      label: data['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
    };
  }

  // Check if given time is within this break period
  bool isTimeInBreak(String timeString) {
    return timeString.compareTo(startTime) >= 0 && timeString.compareTo(endTime) <= 0;
  }
}

// Helper class for managing weekly schedules
class WeeklySchedule {
  final Map<String, ClinicScheduleModel> schedules;

  WeeklySchedule({required this.schedules});

  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  factory WeeklySchedule.fromScheduleList(List<ClinicScheduleModel> scheduleList) {
    final Map<String, ClinicScheduleModel> scheduleMap = {};
    
    for (final schedule in scheduleList) {
      scheduleMap[schedule.dayOfWeek] = schedule;
    }
    
    return WeeklySchedule(schedules: scheduleMap);
  }

  // Get schedule for specific day
  ClinicScheduleModel? getScheduleForDay(String dayOfWeek) {
    return schedules[dayOfWeek];
  }

  // Check if clinic is open on specific day
  bool isOpenOnDay(String dayOfWeek) {
    final schedule = schedules[dayOfWeek];
    return schedule?.isOpen ?? false;
  }

  // Get all open days
  List<String> getOpenDays() {
    return schedules.entries
        .where((entry) => entry.value.isOpen)
        .map((entry) => entry.key)
        .toList();
  }

  // Get operating hours summary
  String getOperatingHoursSummary() {
    final openDays = getOpenDays();
    if (openDays.isEmpty) return 'Closed';
    
    final summaries = <String>[];
    for (final day in openDays) {
      final schedule = schedules[day]!;
      if (schedule.openTime != null && schedule.closeTime != null) {
        summaries.add('$day: ${schedule.openTime} - ${schedule.closeTime}');
      }
    }
    
    return summaries.join('\n');
  }
}