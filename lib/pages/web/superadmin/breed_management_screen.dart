import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';
import 'package:pawsense/core/services/super_admin/pet_breeds_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_statistics_cards.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_search_and_filter.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_card.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/add_edit_breed_modal.dart';

class BreedManagementScreen extends StatefulWidget {
  const BreedManagementScreen({super.key});

  @override
  State<BreedManagementScreen> createState() => _BreedManagementScreenState();
}

class _BreedManagementScreenState extends State<BreedManagementScreen> {
  List<PetBreed> _filteredBreeds = [];
  Map<String, int> _statistics = {};
  
  bool _isLoading = true;
  bool _isLoadingStats = true;
  
  // Filters
  String _searchQuery = '';
  BreedSpecies _selectedSpecies = BreedSpecies.all;
  BreedStatus _selectedStatus = BreedStatus.all;
  BreedSortOption _selectedSort = BreedSortOption.nameAsc;
  String _viewMode = 'list';
  
  // Debouncing
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _loadBreeds();
    _loadStatistics();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);
    
    try {
      final breeds = await PetBreedsService.fetchAllBreeds(
        speciesFilter: _selectedSpecies == BreedSpecies.all ? null : _selectedSpecies.value,
        statusFilter: _selectedStatus == BreedStatus.all ? null : _selectedStatus.value,
        searchQuery: _searchQuery,
        sortBy: _selectedSort.value,
      );
      
      setState(() {
        _filteredBreeds = breeds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading breeds: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load breeds: $e');
    }
  }
  
  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    
    try {
      final stats = await PetBreedsService.getBreedStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() => _isLoadingStats = false);
    }
  }
  
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadBreeds();
    });
  }
  
  void _onSpeciesChanged(BreedSpecies species) {
    setState(() => _selectedSpecies = species);
    _loadBreeds();
  }
  
  void _onStatusChanged(BreedStatus status) {
    setState(() => _selectedStatus = status);
    _loadBreeds();
  }
  
  void _onSortChanged(BreedSortOption sort) {
    setState(() => _selectedSort = sort);
    _loadBreeds();
  }
  
  void _onViewModeChanged(String mode) {
    setState(() => _viewMode = mode);
  }
  
  void _showAddBreedModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditBreedModal(
        onSave: (breed) async {
          try {
            await PetBreedsService.createBreed(breed);
            Navigator.of(context).pop();
            _showSuccessSnackBar('Breed created successfully!');
            _loadBreeds();
            _loadStatistics();
          } catch (e) {
            _showErrorSnackBar(e.toString());
          }
        },
      ),
    );
  }
  
  void _showEditBreedModal(PetBreed breed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditBreedModal(
        breed: breed,
        onSave: (updatedBreed) async {
          try {
            await PetBreedsService.updateBreed(breed.id, updatedBreed);
            Navigator.of(context).pop();
            _showSuccessSnackBar('Breed updated successfully!');
            _loadBreeds();
            _loadStatistics();
          } catch (e) {
            _showErrorSnackBar(e.toString());
          }
        },
      ),
    );
  }
  
  void _showDeleteDialog(PetBreed breed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${breed.name}?'),
        content: Text('This will permanently remove this breed. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await PetBreedsService.deleteBreed(breed.id);
                _showSuccessSnackBar('Breed deleted successfully!');
                _loadBreeds();
                _loadStatistics();
              } catch (e) {
                _showErrorSnackBar('Failed to delete breed: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _toggleBreedStatus(PetBreed breed, bool isActive) async {
    try {
      await PetBreedsService.toggleBreedStatus(breed.id, isActive);
      _showSuccessSnackBar('Breed status updated!');
      _loadBreeds();
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
    }
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: kSpacingMedium),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: kSpacingMedium),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Pet Breeds Management',
            subtitle: 'Manage cat and dog breeds in the system',
            actions: [
              ElevatedButton.icon(
                onPressed: _showAddBreedModal,
                icon: Icon(Icons.add, size: kIconSizeMedium),
                label: Text('Add New Breed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: kSpacingLarge,
                    vertical: kSpacingMedium,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(kSpacingLarge),
              child: Column(
                children: [
                  // Statistics Cards
                  BreedStatisticsCards(
                    statistics: _statistics,
                    isLoading: _isLoadingStats,
                  ),
                  SizedBox(height: kSpacingLarge),
                  
                  // Search and Filters
                  BreedSearchAndFilter(
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                    selectedSpecies: _selectedSpecies,
                    onSpeciesChanged: _onSpeciesChanged,
                    selectedStatus: _selectedStatus,
                    onStatusChanged: _onStatusChanged,
                    selectedSort: _selectedSort,
                    onSortChanged: _onSortChanged,
                    viewMode: _viewMode,
                    onViewModeChanged: _onViewModeChanged,
                    onAddBreed: _showAddBreedModal,
                  ),
                  SizedBox(height: kSpacingLarge),
                  
                  // Breeds List/Grid
                  _isLoading ? _buildLoadingState() : _buildBreedsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBreedsList() {
    if (_filteredBreeds.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_viewMode == 'grid') {
      return _buildGridView();
    }
    
    return _buildListView();
  }
  
  Widget _buildListView() {
    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table header
          _buildTableHeader(),
          SizedBox(height: kSpacingMedium),
          
          // Breed cards
          ..._filteredBreeds.map((breed) => BreedCard(
            breed: breed,
            onTap: () => _showEditBreedModal(breed),
            onEdit: () => _showEditBreedModal(breed),
            onDelete: () => _showDeleteDialog(breed),
            onStatusToggle: (isActive) => _toggleBreedStatus(breed, isActive),
          )),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader() {
    return Row(
      children: [
        SizedBox(width: 48 + kSpacingMedium),
        Expanded(
          flex: 2,
          child: Text('BREED NAME', style: _headerStyle()),
        ),
        Expanded(
          child: Text('SPECIES', style: _headerStyle()),
        ),
        Expanded(
          flex: 3,
          child: Text('DESCRIPTION', style: _headerStyle()),
        ),
        Expanded(
          child: Center(child: Text('STATUS', style: _headerStyle())),
        ),
        Expanded(
          child: Center(child: Text('DATE ADDED', style: _headerStyle())),
        ),
        SizedBox(width: 100),
      ],
    );
  }
  
  TextStyle _headerStyle() {
    return kTextStyleSmall.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }
  
  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: kSpacingLarge,
        mainAxisSpacing: kSpacingLarge,
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredBreeds.length,
      itemBuilder: (context, index) {
        final breed = _filteredBreeds[index];
        return _buildGridCard(breed);
      },
    );
  }
  
  Widget _buildGridCard(PetBreed breed) {
    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.border,
            ),
            child: ClipOval(
              child: breed.imageUrl.isNotEmpty
                  ? Image.network(breed.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 40))
                  : Icon(Icons.pets, size: 40),
            ),
          ),
          SizedBox(height: kSpacingMedium),
          
          // Name
          Text(
            breed.name,
            style: kTextStyleRegular.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: kSpacingSmall),
          
          // Species chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (breed.species == 'cat' ? Color(0xFFFF9500) : Color(0xFF007AFF)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              breed.speciesDisplayName,
              style: kTextStyleSmall.copyWith(
                color: breed.species == 'cat' ? Color(0xFFFF9500) : Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Spacer(),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 20),
                color: AppColors.info,
                onPressed: () => _showEditBreedModal(breed),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20),
                color: AppColors.error,
                onPressed: () => _showDeleteDialog(breed),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(kSpacingXLarge * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: AppColors.textSecondary),
          SizedBox(height: kSpacingLarge),
          Text(
            'No breeds found',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: kSpacingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add your first breed to get started',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: kSpacingLarge),
          ElevatedButton.icon(
            onPressed: _searchQuery.isNotEmpty || _selectedSpecies != BreedSpecies.all || _selectedStatus != BreedStatus.all
                ? () {
                    setState(() {
                      _searchQuery = '';
                      _selectedSpecies = BreedSpecies.all;
                      _selectedStatus = BreedStatus.all;
                    });
                    _loadBreeds();
                  }
                : _showAddBreedModal,
            icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add),
            label: Text(_searchQuery.isNotEmpty ? 'Clear Filters' : 'Add First Breed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(kSpacingXLarge * 2),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: kSpacingMedium),
            Text(
              'Loading breeds...',
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
