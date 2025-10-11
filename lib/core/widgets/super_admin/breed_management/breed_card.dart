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
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Breed image
          _buildBreedImage(),
          SizedBox(width: kSpacingMedium),
          
          // Breed name
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breed.name,
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Species chip
          Expanded(
            child: _buildSpeciesChip(),
          ),
          
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
          Expanded(
            child: Center(
              child: Switch(
                value: breed.isActive,
                onChanged: onStatusToggle,
                activeColor: AppColors.success,
              ),
            ),
          ),
          
          // Date added
          Expanded(
            child: Text(
              _formatDate(breed.createdAt),
              style: kTextStyleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: kIconSizeMedium),
                color: AppColors.info,
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete, size: kIconSizeMedium),
                color: AppColors.error,
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
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
    final iscat = breed.species == 'cat';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: (iscat ? Color(0xFFFF9500) : Color(0xFF007AFF)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          breed.speciesDisplayName,
          style: kTextStyleSmall.copyWith(
            color: iscat ? Color(0xFFFF9500) : Color(0xFF007AFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
