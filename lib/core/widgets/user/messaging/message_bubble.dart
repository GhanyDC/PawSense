import 'package:flutter/material.dart';
import 'package:pawsense/core/models/messaging/message_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final String? currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = currentUserId != null && message.senderId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.local_hospital,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppColors.primary 
                    : (message.status == MessageStatus.sent && !isCurrentUser)
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                border: isCurrentUser 
                    ? null 
                    : Border.all(
                        color: (message.status == MessageStatus.sent && !isCurrentUser)
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.border,
                        width: (message.status == MessageStatus.sent && !isCurrentUser) ? 1.5 : 1,
                      ),
                boxShadow: (message.status == MessageStatus.sent && !isCurrentUser)
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser 
                          ? AppColors.white 
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: (message.status == MessageStatus.sent && !isCurrentUser)
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: isCurrentUser 
                              ? AppColors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == MessageStatus.read ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.status == MessageStatus.read 
                              ? AppColors.success.withValues(alpha: 0.8)
                              : message.status == MessageStatus.delivered
                                  ? AppColors.info.withValues(alpha: 0.8)
                                  : AppColors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}