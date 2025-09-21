import 'package:flutter/material.dart';
import 'package:pawsense/core/services/user/user_services.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final String userName;
  final double radius;
  final bool showUnreadIndicator;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.userName,
    this.radius = 24,
    this.showUnreadIndicator = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  final UserServices _userServices = UserServices();
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload profile image if userId changed
    if (oldWidget.userId != widget.userId) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _profileImageUrl = null;
      });
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      print('🖼️ UserAvatar: Loading profile image for user: ${widget.userId}');
      final profileImageUrl = await _userServices.getProfileImageUrl(widget.userId);
      print('🖼️ UserAvatar: Retrieved profile image URL: $profileImageUrl');
      if (mounted) {
        setState(() {
          _profileImageUrl = profileImageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile image for user ${widget.userId}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _getUserInitials() {
    if (widget.userName.isEmpty) return 'U';
    
    final words = widget.userName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return widget.userName[0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.showUnreadIndicator 
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.1),
          child: _buildAvatarContent(),
        ),
        if (widget.showUnreadIndicator)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent() {
    if (_isLoading) {
      return SizedBox(
        width: widget.radius * 0.6,
        height: widget.radius * 0.6,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty && !_hasError) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to initials if image fails to load
            return _buildInitialsAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: widget.radius * 0.6,
              height: widget.radius * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          },
        ),
      );
    }

    // Fallback to initials
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Text(
      _getUserInitials(),
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: widget.showUnreadIndicator ? FontWeight.w900 : FontWeight.bold,
        fontSize: widget.radius * 0.65,
      ),
    );
  }
}