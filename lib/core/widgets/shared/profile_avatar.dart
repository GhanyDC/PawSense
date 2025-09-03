import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/user_utils.dart';

class ProfileAvatar extends StatelessWidget {
  final UserModel? user;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    this.user,
    this.size = 40,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: showBorder
              ? Border.all(
                  color: borderColor ?? AppColors.primary,
                  width: borderWidth,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: user?.profileImageUrl?.isNotEmpty == true
              ? _buildProfileImage()
              : _buildInitialsAvatar(),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Image.network(
      user!.profileImageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to initials if image fails to load
        return _buildInitialsAvatar();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingAvatar();
      },
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = UserUtils.getUserInitials(user);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4, // Responsive font size based on avatar size
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
