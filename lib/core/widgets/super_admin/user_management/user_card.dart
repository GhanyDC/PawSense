import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/super_admin/user_management/user_details_modal.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  final Function(bool) onStatusToggle;
  final Function(UserModel)? onUpdateUser;

  const UserCard({
    super.key,
    required this.user,
    this.onEdit,
    required this.onStatusToggle,
    this.onUpdateUser,
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
                style: kTextStyleRegular.copyWith(
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
              children: [
                Row(
                  children: [
                    Text(
                      _getDisplayName(),
                      style: kTextStyleRegular.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: kSpacingSmall),
                    // Role chip close to the name
                    _buildRoleChip(),
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
                Text(
                  'Joined: ${_formatDate(user.createdAt)}',
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(),
              SizedBox(height: kSpacingMedium),
              _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final userIsActive = _isActive();
    
    // Determine status based on active state and verification
    String statusText;
    Color statusColor;
    Color bgColor;
    
    if (!userIsActive) {
      statusText = 'Suspended';
      statusColor = AppColors.error;
      bgColor = AppColors.statusOpenBg;
    } else {
      statusText = 'Verified';
      statusColor = AppColors.success;
      bgColor = AppColors.statusResolvedBg;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final userIsActive = _isActive();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View/Info Icon
        Builder(
          builder: (context) => IconButton(
            onPressed: () => _showUserDetailsModal(context),
            icon: Icon(Icons.visibility_outlined, size: 18),
            color: AppColors.info,
            tooltip: 'View Details',
            padding: EdgeInsets.all(6),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
        SizedBox(width: kSpacingSmall),
        
        // Status Action Icon (Suspend/Activate)
        if (!userIsActive) ...[
          // Activate button for suspended users
          IconButton(
            onPressed: () => onStatusToggle(true),
            icon: Icon(Icons.check_circle, size: 18),
            color: AppColors.success,
            tooltip: 'Activate User',
            padding: EdgeInsets.all(6),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ] else ...[
          // Suspend button for active verified users
          IconButton(
            onPressed: () => onStatusToggle(false),
            icon: Icon(Icons.block, size: 18),
            color: AppColors.warning,
            tooltip: 'Suspend User',
            padding: EdgeInsets.all(6),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ],
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

  String _getDisplayName() {
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName} ${user.lastName}';
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

  bool _isActive() {
    // Use the UserModel's isActive field
    return user.isActive;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUserDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsModal(
        user: user,
        onUpdateUser: onUpdateUser,
        onStatusChange: (isActive, reason) {
          onStatusToggle(isActive);
        },
      ),
    );
  }
}
