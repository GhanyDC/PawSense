import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/system/legal_document_model.dart';
import '../../../services/system/legal_document_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

/// Modal for creating/editing legal documents
class EditLegalDocumentModal extends StatefulWidget {
  final LegalDocumentModel? document;

  const EditLegalDocumentModal({
    super.key,
    this.document,
  });

  @override
  State<EditLegalDocumentModal> createState() => _EditLegalDocumentModalState();
}

class _EditLegalDocumentModalState extends State<EditLegalDocumentModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _versionController = TextEditingController();
  final _changeNotesController = TextEditingController();
  final LegalDocumentService _service = LegalDocumentService();
  
  late DocumentType _selectedType;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.document != null) {
      // Edit mode
      _titleController.text = widget.document!.title;
      _contentController.text = widget.document!.content;
      _versionController.text = widget.document!.version;
      _selectedType = widget.document!.type;
      _isActive = widget.document!.isActive;
    } else {
      // Create mode
      _selectedType = DocumentType.termsAndConditions;
      _versionController.text = '1.0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _versionController.dispose();
    _changeNotesController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.document != null;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_changeNotesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide change notes'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final updatedBy = currentUser?.email ?? 'Super Admin';
      
      final document = LegalDocumentModel(
        id: widget.document?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        version: _versionController.text.trim(),
        lastUpdated: DateTime.now(),
        updatedBy: updatedBy,
        isActive: _isActive,
        type: _selectedType,
      );

      if (_isEditMode) {
        await _service.updateDocument(
          widget.document!.id,
          document,
          _changeNotesController.text.trim(),
        );
      } else {
        await _service.createDocument(
          document,
          _changeNotesController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppColors.primary,
                  size: 28,
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      _isEditMode ? 'Edit Legal Document' : 'Create Legal Document',
                      style: kTextStyleTitle.copyWith(fontSize: 22),
                    ),
                    SizedBox(height: kSpacingSmall),
                    Text(
                      _isEditMode
                          ? 'Update existing document and create version history'
                          : 'Create a new legal document for your application',
                      style: kTextStyleRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            SizedBox(height: kSpacingLarge),
            Divider(color: AppColors.border),
            SizedBox(height: kSpacingLarge),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Type
                      Text(
                        'Document Type *',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      DropdownButtonFormField<DocumentType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: kSpacingMedium,
                            vertical: kSpacingMedium,
                          ),
                        ),
                        items: DocumentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),

                      SizedBox(height: kSpacingMedium),

                      // Title
                      Text(
                        'Title *',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Terms and Conditions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: kSpacingMedium,
                            vertical: kSpacingMedium,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: kSpacingMedium),

                      // Version
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Version *',
                                  style: kTextStyleRegular.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: kSpacingSmall),
                                TextFormField(
                                  controller: _versionController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 1.0, 2.1',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: kSpacingMedium,
                                      vertical: kSpacingMedium,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Version is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(width: kSpacingMedium),
                          
                          // Active Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: kTextStyleRegular.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: kSpacingSmall),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: kSpacingMedium,
                                    vertical: kSpacingSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  ),
                                  child: Row(
                                    children: [
                                      Switch(
                                        value: _isActive,
                                        onChanged: (value) {
                                          setState(() => _isActive = value);
                                        },
                                        activeColor: AppColors.primary,
                                      ),
                                      SizedBox(width: kSpacingSmall),
                                      Text(
                                        _isActive ? 'Active' : 'Inactive',
                                        style: kTextStyleRegular.copyWith(
                                          color: _isActive
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: kSpacingMedium),

                      // Content
                      Text(
                        'Content *',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Text(
                        'Enter the full legal document text. Use plain text or basic HTML formatting.',
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 15,
                        decoration: InputDecoration(
                          hintText: 'Enter the full document content...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          contentPadding: EdgeInsets.all(kSpacingMedium),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Content is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: kSpacingMedium),

                      // Change Notes
                      Text(
                        'Change Notes *',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Text(
                        'Describe what changes were made in this version',
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      TextFormField(
                        controller: _changeNotesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'e.g., Initial version, Updated section 3, Fixed typos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          contentPadding: EdgeInsets.all(kSpacingMedium),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: kSpacingMedium),
            Divider(color: AppColors.border),
            SizedBox(height: kSpacingMedium),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: kSpacingMedium),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSave,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading
                      ? 'Saving...'
                      : (_isEditMode ? 'Update' : 'Create')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge,
                      vertical: kSpacingMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
