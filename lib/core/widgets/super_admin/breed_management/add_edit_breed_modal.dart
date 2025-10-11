import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';

class AddEditBreedModal extends StatefulWidget {
  final PetBreed? breed;
  final Function(PetBreed) onSave;

  const AddEditBreedModal({
    super.key,
    this.breed,
    required this.onSave,
  });

  @override
  State<AddEditBreedModal> createState() => _AddEditBreedModalState();
}

class _AddEditBreedModalState extends State<AddEditBreedModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _lifespanController = TextEditingController();
  final List<TextEditingController> _healthIssuesControllers = [];
  
  String _selectedSpecies = 'dog';
  String _selectedSize = SizeCategory.medium;
  String _selectedCoat = CoatType.short;
  bool _isActive = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.breed != null) {
      _nameController.text = widget.breed!.name;
      _descriptionController.text = widget.breed!.description;
      _imageUrlController.text = widget.breed!.imageUrl;
      _lifespanController.text = widget.breed!.averageLifespan;
      _selectedSpecies = widget.breed!.species;
      _selectedSize = widget.breed!.sizeCategory.isEmpty 
          ? SizeCategory.medium 
          : widget.breed!.sizeCategory;
      _selectedCoat = widget.breed!.coatType.isEmpty 
          ? CoatType.short 
          : widget.breed!.coatType;
      _isActive = widget.breed!.isActive;
      
      // Initialize health issues
      for (final issue in widget.breed!.commonHealthIssues) {
        final controller = TextEditingController(text: issue);
        _healthIssuesControllers.add(controller);
      }
    }
    
    // Always have at least one empty health issue field
    if (_healthIssuesControllers.isEmpty) {
      _addHealthIssueField();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _lifespanController.dispose();
    for (final controller in _healthIssuesControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _addHealthIssueField() {
    setState(() {
      _healthIssuesControllers.add(TextEditingController());
    });
  }
  
  void _removeHealthIssueField(int index) {
    setState(() {
      _healthIssuesControllers[index].dispose();
      _healthIssuesControllers.removeAt(index);
    });
  }
  
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Get current user ID
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      final userId = currentUser?.uid ?? '';
      
      // Collect health issues (non-empty only)
      final healthIssues = _healthIssuesControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      final breed = PetBreed(
        id: widget.breed?.id ?? '',
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        commonHealthIssues: healthIssues,
        averageLifespan: _lifespanController.text.trim(),
        sizeCategory: _selectedSize,
        coatType: _selectedCoat,
        status: _isActive ? 'active' : 'inactive',
        createdAt: widget.breed?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.breed?.createdBy ?? userId,
      );
      
      await widget.onSave(breed);
    } catch (e) {
      setState(() => _isSaving = false);
      rethrow;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(kSpacingLarge),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kBorderRadius),
                  topRight: Radius.circular(kBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.pets, color: AppColors.primary, size: 24),
                  SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.breed == null ? 'Add New Breed' : 'Edit Breed',
                          style: kTextStyleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fill in the details below',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(kSpacingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breed Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Breed Name',
                        hint: 'e.g., Labrador Retriever',
                        required: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Breed name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Breed name must be at least 3 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Breed name must be less than 50 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: kSpacingLarge),
                      
                      // Species (Radio buttons)
                      Text(
                        'Species *',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Cat'),
                              value: 'cat',
                              groupValue: _selectedSpecies,
                              onChanged: (value) {
                                setState(() => _selectedSpecies = value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Dog'),
                              value: 'dog',
                              groupValue: _selectedSpecies,
                              onChanged: (value) {
                                setState(() => _selectedSpecies = value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: kSpacingLarge),
                      
                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Brief description of the breed',
                        maxLines: 3,
                        maxLength: 200,
                        validator: (value) {
                          if (value != null && value.length > 200) {
                            return 'Description must be less than 200 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: kSpacingLarge),
                      
                      // Image URL
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'Breed Image URL',
                        hint: 'https://example.com/image.jpg',
                        prefixIcon: Icons.image,
                      ),
                      SizedBox(height: kSpacingLarge),
                      
                      // Row: Lifespan, Size, Coat
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _lifespanController,
                              label: 'Average Lifespan',
                              hint: '12-15 years',
                            ),
                          ),
                          SizedBox(width: kSpacingMedium),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Size Category',
                              value: _selectedSize,
                              items: SizeCategory.all,
                              onChanged: (value) {
                                setState(() => _selectedSize = value!);
                              },
                              getDisplayName: SizeCategory.getDisplayName,
                            ),
                          ),
                          SizedBox(width: kSpacingMedium),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Coat Type',
                              value: _selectedCoat,
                              items: CoatType.all,
                              onChanged: (value) {
                                setState(() => _selectedCoat = value!);
                              },
                              getDisplayName: CoatType.getDisplayName,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: kSpacingLarge),
                      
                      // Common Health Issues
                      Text(
                        'Common Health Issues',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      ..._healthIssuesControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: kSpacingSmall),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Hip Dysplasia',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: AppColors.error),
                                onPressed: () => _removeHealthIssueField(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      TextButton.icon(
                        onPressed: _addHealthIssueField,
                        icon: Icon(Icons.add),
                        label: Text('Add Health Issue'),
                      ),
                      SizedBox(height: kSpacingLarge),
                      
                      // Status toggle
                      Row(
                        children: [
                          Text(
                            'Status:',
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: kSpacingMedium),
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() => _isActive = value);
                            },
                            activeColor: AppColors.success,
                          ),
                          SizedBox(width: kSpacingSmall),
                          Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: kTextStyleRegular.copyWith(
                              color: _isActive ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer buttons
            Container(
              padding: EdgeInsets.all(kSpacingLarge),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: kSpacingMedium),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingXLarge,
                        vertical: kSpacingMedium,
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Save Breed'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: kTextStyleRegular.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: kTextStyleRegular.copyWith(color: AppColors.error),
              ),
          ],
        ),
        SizedBox(height: kSpacingSmall),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: maxLength != null ? (_) => setState(() {}) : null,
        ),
      ],
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) getDisplayName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: kSpacingSmall),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(getDisplayName(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
