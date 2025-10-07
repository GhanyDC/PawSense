import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

/// Species toggle component (Cats/Dogs) for Skin Disease Library
class SpeciesToggle extends StatelessWidget {
  final String selectedSpecies;
  final Function(String) onSpeciesChanged;

  const SpeciesToggle({
    super.key,
    required this.selectedSpecies,
    required this.onSpeciesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: 16,
      ),
      child: Row(
        children: [
          _buildSpeciesButton('cat', '🐱 Cats'),
          const SizedBox(width: 12),
          _buildSpeciesButton('dog', '🐶 Dogs'),
        ],
      ),
    );
  }

  Widget _buildSpeciesButton(String species, String label) {
    final isSelected = selectedSpecies == species;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onSpeciesChanged(species),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: kMobileCardShadowSmall,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
