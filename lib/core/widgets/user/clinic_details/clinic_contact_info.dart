import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';

class ClinicContactInfo extends StatelessWidget {
  final ClinicDetails clinic;

  const ClinicContactInfo({
    Key? key,
    required this.clinic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: kMobileTextStyleTitle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Contact items in column
          Column(
            children: [
              _buildContactItem(
                icon: Icons.phone,
                label: 'Contact Number',
                value: clinic.phone,
                onTap: () => _makePhoneCall(clinic.phone),
                color: AppColors.primary,
                isFullWidth: true,
              ),
              const SizedBox(height: kMobileSizedBoxMedium),
              _buildContactItem(
                icon: Icons.email,
                label: 'Email',
                value: clinic.email,
                onTap: () => _sendEmail(clinic.email),
                color: AppColors.info,
                isFullWidth: true,
              ),
            ],
          ),
          
          // Website (if available)
          if (clinic.socialMedia != null && clinic.socialMedia!['website'] != null) ...[
            const SizedBox(height: kMobileSizedBoxSmall),
            _buildContactItem(
              icon: Icons.language,
              label: 'Website',
              value: clinic.socialMedia!['website']!,
              onTap: () => _openWebsite(clinic.socialMedia!['website']!),
              color: AppColors.success,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    required Color color,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: kMobileBorderRadiusButtonPreset,
      child: Container(
        padding: const EdgeInsets.all(kMobilePaddingSmall),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: kMobileBorderRadiusButtonPreset,
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: isFullWidth ? Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: kMobileSizedBoxMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: color,
              size: 16,
            ),
          ],
        ) : Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _truncateText(value, isFullWidth ? 30 : 15),
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void _makePhoneCall(String phone) {
    // Show phone number in a dialog or copy to clipboard
    print('Phone call functionality: $phone');
  }

  void _sendEmail(String email) {
    // Show email in a dialog or copy to clipboard
    print('Email functionality: $email');
  }

  void _openWebsite(String website) {
    // Show website URL in a dialog or copy to clipboard
    print('Website functionality: $website');
  }
}