import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../models/messaging/message_model.dart';

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

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(kSpacingMedium),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isNextMessageFromSameSender = index < messages.length - 1 &&
            messages[index + 1].senderId == message.senderId;
        final isPreviousMessageFromSameSender = index > 0 &&
            messages[index - 1].senderId == message.senderId;

        return _buildMessageBubble(
          message,
          isNextMessageFromSameSender,
          isPreviousMessageFromSameSender,
        );
      },
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isNextFromSameSender,
    bool isPreviousFromSameSender,
  ) {
    final isAdmin = message.senderRole == 'admin';
    
    return Container(
      margin: EdgeInsets.only(
        bottom: isNextFromSameSender ? 2 : kSpacingSmall,
        top: isPreviousFromSameSender ? 0 : kSpacingSmall,
      ),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin && !isPreviousFromSameSender) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: kSpacingSmall),
          ] else if (!isAdmin) ...[
            const SizedBox(width: 36), // Space for avatar alignment
          ],
          
          Flexible(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isPreviousFromSameSender && !isAdmin) ...[
                    Text(
                      message.senderName,
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message.content,
                    style: kTextStyleRegular.copyWith(
                      color: isAdmin ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isAdmin && !isPreviousFromSameSender) ...[
            const SizedBox(width: kSpacingSmall),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ] else if (isAdmin) ...[
            const SizedBox(width: 36), // Space for avatar alignment
          ],
        ],
      ),
    );
  }
}