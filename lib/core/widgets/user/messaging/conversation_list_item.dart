import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(conversation.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.20, // adjust width of delete action
        children: [
          SlidableAction(
            flex: 1, 
            onPressed: (context) => _showDeleteConfirmation(context),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            borderRadius: kMobileBorderRadiusSmallPreset, // match card corners
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: Material(
          color: AppColors.white,
          borderRadius: kMobileBorderRadiusSmallPreset,
          elevation: 1,
          shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: kMobileBorderRadiusSmallPreset,
            child: Padding(
              padding: const EdgeInsets.all(kMobilePaddingSmall),
              child: Row(
                children: [
                  // Clinic avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.local_hospital,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: kMobileSizedBoxLarge),

                  // Conversation details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.clinicName,
                          style: TextStyle(
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (conversation.lastMessage != null &&
                            conversation.lastMessage!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            conversation.lastMessage!,
                            style: TextStyle(
                              color: conversation.unreadCount > 0 
                                  ? AppColors.textPrimary.withValues(alpha: 0.8)
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Time and unread indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (conversation.lastMessageTime != null)
                        Text(
                          _formatTime(conversation.lastMessageTime!),
                          style: TextStyle(
                            color: conversation.unreadCount > 0 
                                ? AppColors.primary.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (conversation.unreadCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Icon(
                            Icons.chevron_right,
                            color: conversation.unreadCount > 0 
                                ? AppColors.primary.withValues(alpha: 0.6)
                                : AppColors.textSecondary.withValues(alpha: 0.4),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: Text(
            'Are you sure you want to delete this conversation with ${conversation.clinicName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onDelete != null) {
                  onDelete!();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
