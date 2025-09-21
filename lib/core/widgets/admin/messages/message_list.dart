import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../models/messaging/message_model.dart';
import 'user_avatar.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final bool isLoading;
  final ScrollController? scrollController;

  const MessageList({
    super.key,
    required this.messages,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: kSpacingMedium),
            Text(
              'No messages yet',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: kSpacingSmall),
            Text(
              'Start the conversation with a friendly greeting!',
              style: kTextStyleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Build the message items once
    final messageItems = _buildMessageItems();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(kSpacingMedium),
      itemCount: messageItems.length,
      itemBuilder: (context, index) {
        return messageItems[index];
      },
    );
  }

  List<Widget> _buildMessageItems() {
    List<Widget> items = [];
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previousMessage = i > 0 ? messages[i - 1] : null;
      
      // Check if we need to show a timestamp separator
      bool hasTimestampSeparator = _shouldShowTimestamp(message, previousMessage);
      
      // Show timestamp separator
      if (hasTimestampSeparator) {
        items.add(_buildTimestampSeparator(message.timestamp));
      }
      
      final isNextMessageFromSameSender = i < messages.length - 1 &&
          messages[i + 1].senderId == message.senderId;
      
      // Modified logic: if there's a timestamp separator, treat as if previous message
      // was from a different sender (to show avatar again)
      final isPreviousMessageFromSameSender = i > 0 &&
          messages[i - 1].senderId == message.senderId &&
          !hasTimestampSeparator; // Force avatar display after timestamp separator

      items.add(_buildMessageBubble(
        message,
        isNextMessageFromSameSender,
        isPreviousMessageFromSameSender,
      ));
    }
    
    return items;
  }

  bool _shouldShowTimestamp(Message message, Message? previousMessage) {
    if (previousMessage == null) return true; // First message always shows timestamp
    
    final currentTime = message.timestamp;
    final previousTime = previousMessage.timestamp;
    
    // Show timestamp if messages are more than 10 minutes apart
    final timeDifference = currentTime.difference(previousTime).inMinutes;
    return timeDifference >= 10;
  }

  Widget _buildTimestampSeparator(DateTime timestamp) {
    return Container(
      key: ValueKey('timestamp_${timestamp.millisecondsSinceEpoch}'),
      margin: const EdgeInsets.symmetric(vertical: kSpacingMedium),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.textSecondary.withOpacity(0.2),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatTimestampSeparator(timestamp),
                style: kTextStyleSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.textSecondary.withOpacity(0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isNextFromSameSender,
    bool isPreviousFromSameSender,
  ) {
    final isAdmin = message.senderRole == 'admin';
    
    // Simplified logic: Only show avatar for user messages if the immediately previous
    // MESSAGE (not considering separators) was from a different sender
    bool shouldShowUserAvatar = !isAdmin && !isPreviousFromSameSender;
    
    return Container(
      key: ValueKey('message_${message.id}'),
      margin: EdgeInsets.only(
        bottom: isNextFromSameSender ? 2 : kSpacingSmall,
        top: isPreviousFromSameSender ? 0 : kSpacingSmall,
      ),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
              if (shouldShowUserAvatar) ...[
                UserAvatar(
                  userId: message.senderId,
                  userName: message.senderName,
                  radius: 14,
                  showUnreadIndicator: false,
                ),
                const SizedBox(width: kSpacingSmall),
              ] else if (!isAdmin) ...[
                const SizedBox(width: 36), // Space for avatar alignment
              ],
              
              Flexible(
                child: MouseRegion(
                  child: Tooltip(
                    message: _formatDetailedTime(message.timestamp),
                    preferBelow: false,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        message.content,
                        style: kTextStyleRegular.copyWith(
                          color: isAdmin ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (isAdmin && !isPreviousFromSameSender) ...[
                const SizedBox(width: kSpacingSmall),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ] else if (isAdmin) ...[
                const SizedBox(width: 36), // Space for avatar alignment
              ],
            ],
          ),
    );
  }

  // Check if we should show a date separator
  String _formatTimestampSeparator(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeString = '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    
    if (messageDate == today) {
      // Today: show just time
      return timeString;
    } else if (messageDate == yesterday) {
      // Yesterday: show "YESTERDAY AT time"
      return 'YESTERDAY AT $timeString';
    } else {
      // Older: show "MMM DD AT time"
      final months = [
        '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      final month = months[timestamp.month];
      final day = timestamp.day;
      return '$month $day AT $timeString';
    }
  }

  // Format detailed time for tooltip
  String _formatDetailedTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    
    if (messageDate == today) {
      return 'Today at $timeStr';
    } else if (messageDate == yesterday) {
      return 'Yesterday at $timeStr';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} at $timeStr';
    }
  }
}