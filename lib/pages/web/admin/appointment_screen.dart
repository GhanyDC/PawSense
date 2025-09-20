// screens/appointment_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/models/clinic/appointment_models.dart';
import '../../../core/widgets/admin/appointments/appointment_header.dart';
import '../../../core/widgets/admin/appointments/new_appointment_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_filters.dart';
import '../../../core/widgets/admin/appointments/appointment_table.dart';
import '../../../core/widgets/admin/appointments/appointment_summary.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  String searchQuery = '';
  String selectedStatus = 'All Status';

  // Sample data
  final List<Appointment> appointments = [
    Appointment(
      id: 'apt_001',
      clinicId: 'clinic_001',
      date: '2025-01-20',
      time: '09:00',
      timeSlot: '09:00-09:20',
      pet: Pet(
        id: 'pet_001',
        name: 'Max',
        type: 'Dog',
        emoji: '🐕',
        breed: 'Golden Retriever',
        age: 3,
      ),
      diseaseReason: 'Skin Allergies',
      owner: Owner(
        id: 'owner_001',
        name: 'John Smith',
        phone: '+1 (555) 123-4567',
        email: 'john.smith@email.com',
      ),
      status: AppointmentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
    Appointment(
      id: 'apt_002',
      clinicId: 'clinic_001',
      date: '2025-01-20',
      time: '10:30',
      timeSlot: '10:30-10:50',
      pet: Pet(
        id: 'pet_002',
        name: 'Luna',
        type: 'Cat',
        emoji: '🐱',
        breed: 'Persian',
        age: 2,
      ),
      diseaseReason: 'Routine Checkup',
      owner: Owner(
        id: 'owner_002',
        name: 'Sarah Johnson',
        phone: '+1 (555) 987-6543',
        email: 'sarah.johnson@email.com',
      ),
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    Appointment(
      id: 'apt_003',
      clinicId: 'clinic_001',
      date: '2025-01-21',
      time: '14:00',
      timeSlot: '14:00-14:20',
      pet: Pet(
        id: 'pet_003',
        name: 'Buddy',
        type: 'Dog',
        emoji: '🐕',
        breed: 'Labrador',
        age: 5,
      ),
      diseaseReason: 'Dental Cleaning',
      owner: Owner(
        id: 'owner_003',
        name: 'Mike Wilson',
        phone: '+1 (555) 456-7890',
        email: 'mike.wilson@email.com',
      ),
      status: AppointmentStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
    Appointment(
      id: 'apt_004',
      clinicId: 'clinic_001',
      date: '2025-01-21',
      time: '15:30',
      timeSlot: '15:30-15:50',
      pet: Pet(
        id: 'pet_004',
        name: 'Whiskers',
        type: 'Cat',
        emoji: '🐱',
        breed: 'Siamese',
        age: 4,
      ),
      diseaseReason: 'Digestive Issues',
      owner: Owner(
        id: 'owner_004',
        name: 'Emily Davis',
        phone: '+1 (555) 234-5678',
        email: 'emily.davis@email.com',
      ),
      status: AppointmentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
    Appointment(
      id: 'apt_005',
      clinicId: 'clinic_001',
      date: '2025-01-22',
      time: '16:45',
      timeSlot: '16:45-17:05',
      pet: Pet(
        id: 'pet_005',
        name: 'Rocky',
        type: 'Dog',
        emoji: '🐕',
        breed: 'German Shepherd',
        age: 4,
      ),
      diseaseReason: 'Emergency Visit',
      owner: Owner(
        id: 'owner_005',
        name: 'David Brown',
        phone: '+1 (555) 345-6789',
        email: 'david.brown@email.com',
      ),
      status: AppointmentStatus.cancelled,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now(),
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    // Filter appointments for the table only
    List<Appointment> filteredAppointments = appointments.where((appointment) {
      if (selectedStatus == 'All Status') return true;
      return appointment.status.name.toLowerCase() ==
            selectedStatus.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header uses full list
            AppointmentHeader(
              onNewAppointment: () {
                showDialog(
                  context: context,
                  builder: (_) => NewAppointmentModal(
                    onSchedule: (appointment) {
                      // for now, just show a confirmation snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scheduled ${appointment['petName']} on ${appointment['date']}')),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Summary uses full list
            AppointmentSummary(appointments: appointments),
            const SizedBox(height: 24),

            AppointmentFilters(
              searchQuery: searchQuery,
              selectedStatus: selectedStatus,
              onSearchChanged: (query) => setState(() => searchQuery = query),
              onStatusChanged: (status) => setState(() => selectedStatus = status),
            ),

            const SizedBox(height: 16),

            // Table uses filtered list
            AppointmentTable(
              appointments: filteredAppointments,
              onEdit: (appointment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit ${appointment.pet.name}')),
                );
              },
              onDelete: (appointment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete ${appointment.pet.name}')),
                );
              },
              onView: (appointment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View ${appointment.pet.name}')),
                );
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}