import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../models/messaging/conversation_model.dart';

class ChatHeader extends StatelessWidget {
  final Conversation? conversation;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoPressed;
  final VoidCallback? onInfoPressed;

  const ChatHeader({
    super.key,
    this.conversation,
    this.onCallPressed,
    this.onVideoPressed,
    this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Center(
          child: Text(
            'Select a conversation to start chatting',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // User avatar and info
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              conversation!.userName.isNotEmpty
                  ? conversation!.userName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: kSpacingSmall),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation!.userName.isNotEmpty 
                      ? conversation!.userName 
                      : 'Unknown User',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active now',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              IconButton(
                onPressed: onCallPressed,
                icon: Icon(
                  Icons.phone,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Voice call',
              ),
              IconButton(
                onPressed: onVideoPressed,
                icon: Icon(
                  Icons.videocam,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Video call',
              ),
              IconButton(
                onPressed: onInfoPressed,
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Conversation info',
              ),
            ],
          ),
        ],
      ),
    );
  }
}