import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'package:pawsense/core/services/clinic/clinic_service.dart';

class UploadLogoModal extends StatefulWidget {
  final String? currentLogoUrl;
  final VoidCallback onLogoUploaded;

  const UploadLogoModal({
    super.key,
    this.currentLogoUrl,
    required this.onLogoUploaded,
  });

  @override
  State<UploadLogoModal> createState() => _UploadLogoModalState();
}

class _UploadLogoModalState extends State<UploadLogoModal> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _uploadLogo() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Upload to Cloudinary
      final logoUrl = await _cloudinaryService.uploadImageFromBytes(
        _selectedImageBytes!,
        _selectedImageName ?? 'clinic_logo',
        folder: 'clinic_logos',
      );

      // Update clinic with logo URL
      final success = await ClinicService.updateClinicLogo(logoUrl);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logo uploaded successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onLogoUploaded();
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to update clinic logo';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading logo: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: 500,
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Clinic Logo',
                  style: TextStyle(
                    fontSize: kFontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: kSpacingMedium),

            // Current Logo
            if (widget.currentLogoUrl != null) ...[
              Text(
                'Current Logo',
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: kSpacingSmall),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      widget.currentLogoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: kSpacingMedium),
            ],

            // Image Preview or Placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: _selectedImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      child: Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 60,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: kSpacingSmall),
                        Text(
                          'Select a logo image',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: kFontSizeRegular,
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: kSpacingMedium),

            // Pick Image Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: Icon(Icons.photo_library),
                label: Text(_selectedImageBytes == null ? 'Choose Image' : 'Change Image'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: kSpacingMedium),
                  side: BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              SizedBox(height: kSpacingMedium),
              Container(
                padding: EdgeInsets.all(kSpacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    SizedBox(width: kSpacingSmall),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: kFontSizeSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: kSpacingLarge),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: kSpacingMedium),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading || _selectedImageBytes == null ? null : _uploadLogo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: kSpacingMedium),
                    ),
                    child: _isUploading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : Text('Upload Logo'),
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
