import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';

class BreedCard extends StatelessWidget {
  final PetBreed breed;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onStatusToggle;

  const BreedCard({
    super.key,
    required this.breed,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadius),
      hoverColor: AppColors.primary.withValues(alpha: 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: kSpacingMedium,
          vertical: kSpacingMedium + 4,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Breed image + name column (matching header width)
            SizedBox(
              width: 60, // Fixed width for image
              child: _buildBreedImage(),
            ),
            SizedBox(width: kSpacingMedium),
            
            // Breed name
            Expanded(
              flex: 2,
              child: Text(
                breed.name,
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: kSpacingMedium),
            
            // Species chip
            Expanded(
              flex: 1,
              child: _buildSpeciesChip(),
            ),
            SizedBox(width: kSpacingMedium),
            
            // Description
            Expanded(
              flex: 3,
              child: Text(
                breed.getFormattedDescription(),
                style: kTextStyleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: kSpacingMedium),
            
            // Status toggle
            SizedBox(
              width: 100, // Fixed width for consistency
              child: Center(
                child: Switch(
                  value: breed.isActive,
                  onChanged: onStatusToggle,
                  activeColor: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: kSpacingMedium),
            
            // Date added
            SizedBox(
              width: 120, // Fixed width for dates
              child: Text(
                _formatDate(breed.createdAt),
                style: kTextStyleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: kSpacingMedium),
            
            // Actions
            SizedBox(
              width: 96, // Fixed width for action buttons
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.info,
                    onPressed: onEdit,
                    tooltip: 'Edit Breed',
                    splashRadius: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: AppColors.error,
                    onPressed: onDelete,
                    tooltip: 'Delete Breed',
                    splashRadius: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedImage() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.border,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ClipOval(
        child: breed.imageUrl.isNotEmpty
            ? Image.network(
                breed.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIcon();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                },
              )
            : _buildFallbackIcon(),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      Icons.pets,
      color: breed.species == 'cat' ? Color(0xFFFF9500) : Color(0xFF007AFF),
      size: 24,
    );
  }

  Widget _buildSpeciesChip() {
    final isCat = breed.species == 'cat';
    final chipColor = isCat ? Color(0xFFFF9500) : Color(0xFF007AFF);
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chipColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCat ? Icons.pets : Icons.pets,
              size: 14,
              color: chipColor,
            ),
            SizedBox(width: 4),
            Text(
              breed.speciesDisplayName,
              style: kTextStyleSmall.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
