import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetInfo {
  final String name;
  final String type;
  final IconData icon;
  final String? nextAppointment;

  PetInfo({
    required this.name,
    required this.type,
    required this.icon,
    this.nextAppointment,
  });
}

class PetInfoCard extends StatelessWidget {
  final List<PetInfo> pets;
  final String? nextAppointmentDate;
  final String? nextAppointmentTime;

  const PetInfoCard({
    super.key,
    required this.pets,
    this.nextAppointmentDate,
    this.nextAppointmentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Pets',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              if (pets.length > 2)
                TextButton(
                  onPressed: () {
                    // Handle view all pets
                  },
                  style: TextButton.styleFrom(
                    padding: kMobileButtonPadding,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: kMobileTextStyleViewAll.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          
          // Description below title
          const SizedBox(height: 4),
          const Text(
            'Essential details about your pet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Pets and appointment row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pets section - 2 columns, multiple rows
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // First row of pets
                      Row(
                        children: pets.take(2).map((pet) => 
                          Expanded(child: _buildPetIcon(pet))
                        ).toList(),
                      ),
                      // Second row of pets if there are more than 2
                      if (pets.length > 2) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: pets.skip(2).take(2).map((pet) => 
                            Expanded(child: _buildPetIcon(pet))
                          ).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // View All button below pets
                      Container(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle view all pets
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Next appointment section - always show
                Expanded(
                  flex: 3,
                  child: _buildAppointmentSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetIcon(PetInfo pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              pet.icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pet.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSection() {
    // Check if we have appointment data
    bool hasAppointment = nextAppointmentDate != null && nextAppointmentTime != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon and title in one row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: hasAppointment 
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  hasAppointment ? Icons.event_available : Icons.event_busy,
                  size: 14,
                  color: hasAppointment ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Appointments',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (hasAppointment) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                nextAppointmentDate!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nextAppointmentTime!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No Appointments\nToday',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
