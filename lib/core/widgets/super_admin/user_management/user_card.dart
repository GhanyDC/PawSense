import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onStatusToggle;

  const UserCard({
    Key? key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusToggle,
  }) : super(key: key);

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
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: kTextStyleLarge.copyWith(
                  color: _getRoleColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: kSpacingMedium),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getDisplayName(),
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),
                SizedBox(height: kSpacingSmall),
                Text(
                  user.email,
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    _buildRoleChip(),
                    SizedBox(width: kSpacingSmall),
                    Text(
                      'Joined: ${_formatDate(user.createdAt)}',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, size: kIconSizeMedium),
                    color: AppColors.info,
                    tooltip: 'Edit User',
                    padding: EdgeInsets.all(kSpacingSmall),
                    constraints: BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, size: kIconSizeMedium),
                    color: AppColors.error,
                    tooltip: 'Delete User',
                    padding: EdgeInsets.all(kSpacingSmall),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: kSpacingSmall),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isActive(),
                  onChanged: onStatusToggle,
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withOpacity(0.3),
                  inactiveThumbColor: AppColors.textTertiary,
                  inactiveTrackColor: AppColors.border,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName} ${user.lastName}';
    } else if (user.firstName != null) {
      return user.firstName!;
    } else if (user.lastName != null) {
      return user.lastName!;
    }
    return user.username;
  }

  String _getInitials() {
    final displayName = _getDisplayName();
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  Color _getRoleColor() {
    switch (user.role) {
      case 'super_admin':
        return AppColors.roleSuperAdmin;
      case 'admin':
        return AppColors.roleAdmin;
      case 'user':
        return AppColors.roleUser;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _getRoleBackgroundColor() {
    switch (user.role) {
      case 'super_admin':
        return AppColors.roleSuperAdminBg;
      case 'admin':
        return AppColors.roleAdminBg;
      case 'user':
        return AppColors.roleUserBg;
      default:
        return AppColors.border;
    }
  }

  Widget _buildStatusChip() {
    final isActive = _isActive();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.statusResolvedBg : AppColors.statusOpenBg,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: kTextStyleSmall.copyWith(
          color: isActive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRoleChip() {
    final roleColor = _getRoleColor();
    final roleBackgroundColor = _getRoleBackgroundColor();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
      decoration: BoxDecoration(
        color: roleBackgroundColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Text(
        _formatRoleName(user.role),
        style: kTextStyleSmall.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      default:
        return role.toUpperCase();
    }
  }

  bool _isActive() {
    // For now, assume all users are active since UserModel doesn't have a status field
    return true;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
