import 'package:flutter/material.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';

class TestScheduleAvailabilityWidget extends StatefulWidget {
  final String clinicId;
  
  const TestScheduleAvailabilityWidget({
    super.key,
    required this.clinicId,
  });

  @override
  State<TestScheduleAvailabilityWidget> createState() => _TestScheduleAvailabilityWidgetState();
}

class _TestScheduleAvailabilityWidgetState extends State<TestScheduleAvailabilityWidget> {
  Map<String, Map<String, dynamic>>? _weeklyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailabilityData();
  }

  Future<void> _loadAvailabilityData() async {
    try {
      final data = await ClinicScheduleService.getWeeklyScheduleWithAvailability(
        widget.clinicId,
        DateTime.now(),
      );
      
      setState(() {
        _weeklyData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading availability: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 12),
              Text('Loading availability data...'),
            ],
          ),
        ),
      );
    }

    if (_weeklyData == null || _weeklyData!.isEmpty) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'No Schedule Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('No clinic schedule configured for ID: ${widget.clinicId}'),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Schedule Availability Test',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Clinic ID: ${widget.clinicId}'),
            SizedBox(height: 8),
            Text(
              'This Week\'s Availability:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ..._weeklyData!.entries.map((entry) {
              final day = entry.key;
              final data = entry.value;
              final schedule = data['schedule'];
              
              if (schedule == null) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text('$day: Closed', style: TextStyle(color: Colors.grey)),
                );
              }
              
              final totalSlots = data['totalSlots'] ?? 0;
              final availableSlots = data['availableSlots'] ?? 0;
              final utilization = data['utilization'] ?? 0;
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '$day: $availableSlots/$totalSlots slots available ($utilization% booked)',
                  style: TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadAvailabilityData,
              child: Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
}