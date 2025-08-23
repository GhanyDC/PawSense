import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import '../../../core/widgets/super_admin/user_management/user_summary_cards.dart';
import '../../../core/widgets/super_admin/user_management/user_search_and_filter.dart';
import '../../../core/widgets/super_admin/user_management/users_list.dart';
import '../../../core/widgets/shared/pagination_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  
  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();
  
  // Filters
  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    // Mock data
    _users = [
      UserModel(
        uid: '1',
        username: 'johndoe',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        role: 'user',
        profileImageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      UserModel(
        uid: '2',
        username: 'janesmith',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        role: 'admin',
        profileImageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: 15)),
      ),
      UserModel(
        uid: '3',
        username: 'bobjohnson',
        firstName: 'Bob',
        lastName: 'Johnson',
        email: 'bob.johnson@example.com',
        role: 'user',
        profileImageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: 7)),
      ),
    ];
    
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
      final matchesSearch = _searchQuery.isEmpty ||
          fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _selectedRole.isEmpty || 
          user.role == _selectedRole;
      
      // Since the UserModel doesn't have an isActive field, we'll handle status filtering differently
      // Show all users regardless of status filter since we don't have real status data
      final matchesStatus = true; // Always true since we don't have real status data
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
    
    _currentPage = 1; // Reset to first page when filters change
  }

  List<UserModel> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredUsers.length);
    return _filteredUsers.sublist(startIndex, endIndex);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onRoleFilterChanged(String? role) {
    setState(() {
      _selectedRole = role ?? '';
      _applyFilters();
    });
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status ?? '';
      _applyFilters();
    });
  }

  void _onEditUser(UserModel user) {
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit user: $fullName')),
    );
  }

  void _onDeleteUser(UserModel user) {
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete $fullName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User $fullName deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onToggleUserStatus(UserModel user) {
    // Since isActive is not available in the model, we'll just show a message
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User status toggle for $fullName (Feature not implemented)'),
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
              title: 'User Management',
              subtitle: 'Manage and monitor all users in the system',
              actions: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement add user
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Add new user functionality coming soon')),
                    );
                  },
                  icon: Icon(Icons.person_add_outlined, size: 18),
                  label: Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Summary Cards
            UserSummaryCards(
              totalUsers: _users.length,
              activeUsers: _users.length, // All users considered active since isActive not available
              inactiveUsers: 0, // No inactive users since isActive not available
              adminUsers: _users.where((u) => u.role == 'admin' || u.role == 'super_admin').length,
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Search and Filters
            UserSearchAndFilter(
              searchQuery: _searchQuery,
              selectedRole: _selectedRole,
              selectedStatus: _selectedStatus,
              onSearchChanged: _onSearchChanged,
              onRoleChanged: _onRoleFilterChanged,
              onStatusChanged: _onStatusFilterChanged,
              onExportData: () {
                // TODO: Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export functionality coming soon')),
                );
              },
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Users List
            UsersList(
              users: _paginatedUsers,
              isLoading: _isLoading,
              onEditUser: _onEditUser,
              onDeleteUser: _onDeleteUser,
              onStatusToggle: (user, status) => _onToggleUserStatus(user),
            ),
            
            if (!_isLoading && _filteredUsers.isNotEmpty) ...[
              SizedBox(height: kSpacingLarge),
              
              // Pagination
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                itemsPerPage: _itemsPerPage,
                totalItems: _filteredUsers.length,
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
