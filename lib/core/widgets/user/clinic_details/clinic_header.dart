import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';

class ClinicHeader extends StatelessWidget {
  final ClinicDetails clinic;

  const ClinicHeader({
    super.key,
    required this.clinic,
  });

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Logo/Avatar
              _buildClinicLogo(),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            clinic.clinicName,
                            style: kMobileTextStyleTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (clinic.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: kMobileSizedBoxSmall),
                    _buildInfoRow(Icons.location_on, clinic.address),
                    if (clinic.operatingHours != null) ...[
                      const SizedBox(height: 2),
                      _buildInfoRow(Icons.access_time, clinic.operatingHours!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          if (clinic.description.isNotEmpty) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              clinic.description,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          if (clinic.specialties.isNotEmpty) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: clinic.specialties.take(4).map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: kMobileTextStyleSubtitle.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildClinicLogo() {
    // Check if clinic has a logo URL
    if (clinic.logoUrl != null && clinic.logoUrl!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
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
            clinic.logoUrl!,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultLogo();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            },
          ),
        ),
      );
    }

    // Default logo if no URL
    return _buildDefaultLogo();
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.local_hospital,
        size: 30,
        color: AppColors.primary,
      ),
    );
  }
}