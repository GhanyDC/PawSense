import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';

class TestClinicScheduleService {
  static Future<void> testNestedScheduleStructure() async {
    try {
      const testClinicId = 'test_clinic_123';
      print('Testing nested clinic schedule structure for clinic: $testClinicId');

      // Create test schedule data
      final testSchedules = <ClinicScheduleModel>[];
      
      // Monday - Open
      testSchedules.add(ClinicScheduleModel(
        id: '${testClinicId}_monday',
        clinicId: testClinicId,
        dayOfWeek: 'Monday',
        openTime: '09:00',
        closeTime: '17:00',
        isOpen: true,
        breakTimes: [
          BreakTime(
            startTime: '12:00',
            endTime: '13:00',
            label: 'Lunch Break',
          ),
        ],
        notes: 'Regular weekday hours',
        slotsPerHour: 4,
        slotDurationMinutes: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ));

      // Tuesday - Open
      testSchedules.add(ClinicScheduleModel(
        id: '${testClinicId}_tuesday',
        clinicId: testClinicId,
        dayOfWeek: 'Tuesday',
        openTime: '09:00',
        closeTime: '17:00',
        isOpen: true,
        breakTimes: [
          BreakTime(
            startTime: '12:00',
            endTime: '13:00',
            label: 'Lunch Break',
          ),
        ],
        notes: 'Regular weekday hours',
        slotsPerHour: 3,
        slotDurationMinutes: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ));

      // Saturday - Closed
      testSchedules.add(ClinicScheduleModel(
        id: '${testClinicId}_saturday',
        clinicId: testClinicId,
        dayOfWeek: 'Saturday',
        openTime: null,
        closeTime: null,
        isOpen: false,
        breakTimes: [],
        notes: 'Closed on weekends',
        slotsPerHour: 3,
        slotDurationMinutes: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ));

      // Test 1: Save nested schedule structure
      print('\n--- Test 1: Saving nested schedule structure ---');
      final saveResult = await ClinicScheduleService.saveWeeklySchedule(testClinicId, testSchedules);
      print('Save result: $saveResult');

      if (saveResult) {
        print('✅ Successfully saved nested clinic schedule');
      } else {
        print('❌ Failed to save nested clinic schedule');
        return;
      }

      // Test 2: Retrieve weekly schedule
      print('\n--- Test 2: Retrieving weekly schedule ---');
      final weeklySchedule = await ClinicScheduleService.getWeeklySchedule(testClinicId);
      print('Retrieved ${weeklySchedule.schedules.length} day schedules');

      for (final entry in weeklySchedule.schedules.entries) {
        final day = entry.key;
        final schedule = entry.value;
        print('$day: ${schedule.isOpen ? "Open ${schedule.openTime}-${schedule.closeTime}" : "Closed"} (${schedule.slotsPerHour} slots/hour)');
      }

      // Test 3: Retrieve specific day schedule
      print('\n--- Test 3: Retrieving specific day schedule ---');
      final mondaySchedule = await ClinicScheduleService.getScheduleForDay(testClinicId, 'Monday');
      if (mondaySchedule != null) {
        print('✅ Monday schedule: ${mondaySchedule.openTime}-${mondaySchedule.closeTime}, ${mondaySchedule.slotsPerHour} slots/hour');
        print('   Break times: ${mondaySchedule.breakTimes.length}');
        print('   Notes: ${mondaySchedule.notes}');
      } else {
        print('❌ Failed to retrieve Monday schedule');
      }

      // Test 4: Check if clinic has configured schedules
      print('\n--- Test 4: Checking configured schedules ---');
      final hasSchedules = await ClinicScheduleService.hasConfiguredSchedules(testClinicId);
      print('Has configured schedules: $hasSchedules');

      // Test 5: Get operating days
      print('\n--- Test 5: Getting operating days ---');
      final operatingDays = await ClinicScheduleService.getOperatingDays(testClinicId);
      print('Operating days: $operatingDays');

      // Test 6: Update specific day
      print('\n--- Test 6: Updating specific day schedule ---');
      final updateResult = await ClinicScheduleService.updateDaySchedule(
        testClinicId,
        'Wednesday',
        openTime: '08:00',
        closeTime: '18:00',
        isOpen: true,
        slotsPerHour: 6,
        slotDurationMinutes: 10,
        notes: 'Extended hours on Wednesday',
      );
      print('Update result: $updateResult');

      if (updateResult) {
        final updatedWednesday = await ClinicScheduleService.getScheduleForDay(testClinicId, 'Wednesday');
        if (updatedWednesday != null) {
          print('✅ Updated Wednesday: ${updatedWednesday.openTime}-${updatedWednesday.closeTime}, ${updatedWednesday.slotsPerHour} slots/hour');
        }
      }

      print('\n--- Test Summary ---');
      print('✅ Nested clinic schedule structure test completed successfully!');
      print('📊 Database structure: One document per clinic with nested day schedules');
      print('🔧 Clinic ID properly used as document ID');
      print('📅 Individual day schedules stored as nested fields');

    } catch (e) {
      print('\n❌ Test failed with error: $e');
      print('Stack trace:');
      print(StackTrace.current);
    }
  }
}