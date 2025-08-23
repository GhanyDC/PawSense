import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import '../../../core/widgets/super_admin/clinic_management/clinic_summary_cards.dart';
import '../../../core/widgets/super_admin/clinic_management/clinic_search_and_filter.dart';
import '../../../core/widgets/super_admin/clinic_management/clinics_list.dart';
import '../../../core/widgets/shared/pagination_widget.dart';

class ClinicManagementScreen extends StatefulWidget {
  const ClinicManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClinicManagementScreen> createState() => _ClinicManagementScreenState();
}

class _ClinicManagementScreenState extends State<ClinicManagementScreen> {
  List<ClinicRegistration> _clinics = [];
  List<ClinicRegistration> _filteredClinics = [];
  bool _isLoading = true;
  
  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int get _totalPages => (_filteredClinics.length / _itemsPerPage).ceil();
  
  // Filters
  String _searchQuery = '';
  String _selectedStatus = 'All Status';

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    // Mock data
    _clinics = [
      ClinicRegistration(
        id: '1',
        clinicName: 'Happy Paws Veterinary Clinic',
        adminName: 'Dr. John Smith',
        adminId: 'admin1',
        email: 'info@happypaws.com',
        phone: '+1234567890',
        address: '123 Main Street, City, State',
        licenseNumber: 'VET-2024-001',
        status: ClinicStatus.pending,
        applicationDate: DateTime.now().subtract(Duration(days: 3)),
      ),
      ClinicRegistration(
        id: '2',
        clinicName: 'Animal Care Center',
        adminName: 'Dr. Jane Doe',
        adminId: 'admin2',
        email: 'contact@animalcare.com',
        phone: '+1234567891',
        address: '456 Oak Avenue, City, State',
        licenseNumber: 'VET-2024-002',
        status: ClinicStatus.verified,
        applicationDate: DateTime.now().subtract(Duration(days: 15)),
      ),
      ClinicRegistration(
        id: '3',
        clinicName: 'Pet Health Clinic',
        adminName: 'Dr. Mike Johnson',
        adminId: 'admin3',
        email: 'admin@pethealth.com',
        phone: '+1234567892',
        address: '789 Pine Road, City, State',
        licenseNumber: 'VET-2024-003',
        status: ClinicStatus.rejected,
        applicationDate: DateTime.now().subtract(Duration(days: 7)),
      ),
    ];
    
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _filteredClinics = _clinics.where((clinic) {
      final matchesSearch = _searchQuery.isEmpty ||
          clinic.clinicName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          clinic.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          clinic.licenseNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus.isEmpty || 
          clinic.status.toString().split('.').last == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
    
    _currentPage = 1; // Reset to first page when filters change
  }

  List<ClinicRegistration> get _paginatedClinics {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredClinics.length);
    return _filteredClinics.sublist(startIndex, endIndex);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _onViewDetails(ClinicRegistration clinic) {
    // TODO: Show clinic details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${clinic.clinicName}')),
    );
  }

  void _onApprove(ClinicRegistration clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Clinic'),
        content: Text('Are you sure you want to approve ${clinic.clinicName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Find and update the clinic in the list
                final index = _clinics.indexWhere((c) => c.id == clinic.id);
                if (index != -1) {
                  _clinics[index] = ClinicRegistration(
                    id: clinic.id,
                    clinicName: clinic.clinicName,
                    adminName: clinic.adminName,
                    adminId: clinic.adminId,
                    email: clinic.email,
                    phone: clinic.phone,
                    address: clinic.address,
                    licenseNumber: clinic.licenseNumber,
                    status: ClinicStatus.verified,
                    applicationDate: clinic.applicationDate,
                    approvedDate: DateTime.now(),
                  );
                }
                _applyFilters();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${clinic.clinicName} approved successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _onReject(ClinicRegistration clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Clinic'),
        content: Text('Are you sure you want to reject ${clinic.clinicName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _clinics.indexWhere((c) => c.id == clinic.id);
                if (index != -1) {
                  _clinics[index] = ClinicRegistration(
                    id: clinic.id,
                    clinicName: clinic.clinicName,
                    adminName: clinic.adminName,
                    adminId: clinic.adminId,
                    email: clinic.email,
                    phone: clinic.phone,
                    address: clinic.address,
                    licenseNumber: clinic.licenseNumber,
                    status: ClinicStatus.rejected,
                    applicationDate: clinic.applicationDate,
                    rejectionReason: 'Rejected by admin',
                  );
                }
                _applyFilters();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${clinic.clinicName} rejected')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _onSuspend(ClinicRegistration clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend Clinic'),
        content: Text('Are you sure you want to suspend ${clinic.clinicName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _clinics.indexWhere((c) => c.id == clinic.id);
                if (index != -1) {
                  _clinics[index] = ClinicRegistration(
                    id: clinic.id,
                    clinicName: clinic.clinicName,
                    adminName: clinic.adminName,
                    adminId: clinic.adminId,
                    email: clinic.email,
                    phone: clinic.phone,
                    address: clinic.address,
                    licenseNumber: clinic.licenseNumber,
                    status: ClinicStatus.suspended,
                    applicationDate: clinic.applicationDate,
                    suspensionReason: 'Suspended by admin',
                  );
                }
                _applyFilters();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${clinic.clinicName} suspended')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
            child: Text('Suspend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              title: 'Clinic Management',
              subtitle: 'Manage and approve clinic registrations',
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Summary Cards
            ClinicSummaryCards(
              totalClinics: _clinics.length,
              pendingClinics: _clinics.where((c) => c.status == ClinicStatus.pending).length,
              approvedClinics: _clinics.where((c) => c.status == ClinicStatus.verified).length,
              rejectedClinics: _clinics.where((c) => c.status == ClinicStatus.rejected).length,
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Search and Filters
            ClinicSearchAndFilter(
              searchQuery: _searchQuery,
              selectedStatus: _selectedStatus,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: _onStatusFilterChanged,
              onExportData: () {
                // TODO: Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export functionality coming soon')),
                );
              },
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Clinics List
            ClinicsList(
              clinics: _paginatedClinics,
              isLoading: _isLoading,
              onViewDetails: _onViewDetails,
              onApprove: _onApprove,
              onReject: _onReject,
              onSuspend: _onSuspend,
            ),
            
            if (!_isLoading && _filteredClinics.isNotEmpty) ...[
              SizedBox(height: kSpacingLarge),
              
              // Pagination
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                itemsPerPage: _itemsPerPage,
                totalItems: _filteredClinics.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                onItemsPerPageChanged: (items) => setState(() {
                  _itemsPerPage = items;
                  _currentPage = 1;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
