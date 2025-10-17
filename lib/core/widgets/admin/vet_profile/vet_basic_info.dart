import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../shared/content_container.dart';
import 'upload_logo_modal.dart';

class VetProfileBasicInfo extends StatelessWidget {
  final String clinicName;
  final String doctorName;
  final String email;
  final String phone;
  final String address;
  final String website;
  final String? logoUrl;
  final VoidCallback? onLogoUpdated;

  const VetProfileBasicInfo({
    super.key,
    required this.clinicName,
    required this.doctorName,
    required this.email,
    required this.phone,
    required this.address,
    required this.website,
    this.logoUrl,
    this.onLogoUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar / Logo
          Stack(
            children: [
              // Logo or default avatar - Circular
              logoUrl != null && logoUrl!.isNotEmpty
                  ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          logoUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      ),
                    )
                  : _buildDefaultAvatar(),
              
              // Edit/Upload button
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _showUploadLogoModal(context),
                  child: Container(
                    padding: EdgeInsets.all(kSpacingXSmall),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingMedium),

          // Clinic & Doctor Names
          Text(
            clinicName,
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            doctorName,
            style: TextStyle(
              fontSize: kFontSizeRegular,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: kSpacingMedium),

          // Contact Information
          ContactInfoTile(
            icon: Icons.email_outlined,
            text: email,
          ),
          ContactInfoTile(
            icon: Icons.phone_outlined,
            text: phone,
          ),
          ContactInfoTile(
            icon: Icons.location_on_outlined,
            text: address,
          ),
          if (website.isNotEmpty)
            ContactInfoTile(
              icon: Icons.language_outlined,
              text: website,
            ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.business,
        size: 50,
        color: AppColors.primary,
      ),
    );
  }
  
  void _showUploadLogoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UploadLogoModal(
        currentLogoUrl: logoUrl,
        onLogoUploaded: () {
          if (onLogoUpdated != null) {
            onLogoUpdated!();
          }
        },
      ),
    );
  }
}

class ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const ContactInfoTile({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon, 
        color: AppColors.textSecondary, 
        size: kIconSizeMedium,
      ),
      title: Text(
        text, 
        style: TextStyle(
          fontSize: kFontSizeSmall, 
          color: AppColors.textSecondary, 
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: kSpacingMedium + 2,
    );
  }
}
