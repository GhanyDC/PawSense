import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Compact horizontal disease card for Skin Disease Library
class DiseaseCard extends StatelessWidget {
  final SkinDiseaseModel disease;
  final VoidCallback onTap;

  const DiseaseCard({
    super.key,
    required this.disease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section (smaller, square)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: disease.imageUrl.isNotEmpty
                    ? _buildImage()
                    : _buildPlaceholderImage(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content section (takes remaining space)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name
                  Text(
                    disease.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Badges row
                  Row(
                    children: [
                      // AI Detection badge
                      if (disease.detectionMethod == 'ai' || disease.detectionMethod == 'both')
                        _buildBadge(
                          '✨ AI',
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary,
                        ),
                      
                      if (disease.detectionMethod == 'ai' || disease.detectionMethod == 'both')
                        const SizedBox(width: 6),
                      
                      // Severity badge
                      _buildSeverityBadge(),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Species badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getSpeciesDisplay(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Description
                  Text(
                    disease.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Check if imageUrl is a network URL or a local asset filename
    final isNetworkImage = disease.imageUrl.startsWith('http://') || 
                           disease.imageUrl.startsWith('https://');
    
    if (isNetworkImage) {
      // Use network image
      return Image.network(
        disease.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderImage();
        },
      );
    } else {
      // Use asset image - construct path from filename
      final assetPath = 'assets/img/skin_diseases/${disease.imageUrl}';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.border,
      child: Center(
        child: Icon(
          Icons.medical_information_outlined,
          size: 32,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge() {
    Color bgColor;
    Color textColor;
    String label;

    switch (disease.severity.toLowerCase()) {
      case 'low':
      case 'mild':
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        label = '● ${disease.severity[0].toUpperCase()}${disease.severity.substring(1)}';
        break;
      case 'high':
      case 'severe':
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = '● ${disease.severity[0].toUpperCase()}${disease.severity.substring(1)}';
        break;
      case 'moderate':
      default:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        label = '● ${disease.severity[0].toUpperCase()}${disease.severity.substring(1)}';
        break;
    }

    return _buildBadge(label, bgColor, textColor);
  }

  String _getSpeciesDisplay() {
    // Case-insensitive check for species
    final speciesLower = disease.species.map((s) => s.toLowerCase()).toList();
    
    // Check if it contains both cats and dogs
    final hasCat = speciesLower.any((s) => s.contains('cat'));
    final hasDog = speciesLower.any((s) => s.contains('dog'));
    
    if (hasCat && hasDog) {
      return '🐱🐶 Both';
    } else if (hasCat) {
      return '🐱 Cats';
    } else if (hasDog) {
      return '🐶 Dogs';
    } else {
      return '🐾 All';
    }
  }
}
