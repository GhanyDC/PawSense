import 'package:flutter/material.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/messaging/mobile_messaging_preferences_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'dart:async';

class MobileConversationListItem extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isCurrentlySelected;

  const MobileConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onDelete,
    this.isCurrentlySelected = false,
  });

  @override
  State<MobileConversationListItem> createState() => _MobileConversationListItemState();
}

class _MobileConversationListItemState extends State<MobileConversationListItem> {
  final MobileMessagingPreferencesService _preferencesService = 
      MobileMessagingPreferencesService.instance;
  
  StreamSubscription<Set<String>>? _readConversationsSubscription;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _setupReadStatusListener();
  }

  @override
  void didUpdateWidget(MobileConversationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the conversation data changed (new message), trigger a rebuild
    if (oldWidget.conversation.lastMessage != widget.conversation.lastMessage ||
        oldWidget.conversation.lastMessageTime != widget.conversation.lastMessageTime ||
        oldWidget.conversation.lastMessageSenderId != widget.conversation.lastMessageSenderId) {
      
      // Check if this should now be marked as unread due to new clinic message
      if (_currentUser != null && 
          widget.conversation.lastMessageSenderId != null &&
          widget.conversation.lastMessageSenderId != _currentUser!.uid) {
        
        // If it's currently marked as read but we have a new clinic message, mark as unread
        final isCurrentlyRead = _preferencesService.isConversationRead(widget.conversation.id);
        if (isCurrentlyRead) {
          print('🔄 Conversation ${widget.conversation.clinicName} has new clinic message, marking as unread');
          _preferencesService.markConversationAsUnread(widget.conversation.id);
        }
      }
      
      // Force rebuild
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _readConversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  void _setupReadStatusListener() {
    // Listen to changes in read conversations for UI updates
    _readConversationsSubscription = _preferencesService.readConversationsStream.listen(
      (readConversations) {
        if (mounted) {
          setState(() {
            // Trigger rebuild when read status changes
          });
        }
      },
      onError: (error) {
        print('Error in read conversations stream: $error');
      },
    );

    // Initialize service if needed
    _initializeServiceIfNeeded();
  }

  void _initializeServiceIfNeeded() async {
    if (!_preferencesService.isInitialized && _currentUser != null) {
      try {
        await _preferencesService.initializeForUser(_currentUser!.uid);
        // Trigger a rebuild after initialization
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Warning: Could not initialize mobile messaging preferences: $e');
      }
    }
  }

  void _onTap() {
    // Mark conversation as read when tapped
    _preferencesService.markConversationAsRead(widget.conversation.id);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if conversation should show as unread
    final isUnread = _isConversationUnread();
    
    return _buildConversationItem(isUnread);
  }

  /// Simple logic to determine if conversation is unread
  bool _isConversationUnread() {
    if (_currentUser == null) return false;
    
    // Check if conversation is marked as read in storage
    final isReadInStorage = _preferencesService.isConversationRead(widget.conversation.id);
    
    // Show as unread if last message was from clinic (not from current user)
    final lastMessageFromClinic = widget.conversation.lastMessageSenderId != null &&
                                 widget.conversation.lastMessageSenderId != _currentUser!.uid;
    
    final shouldBeUnread = lastMessageFromClinic && !isReadInStorage;
    
    // Debug logging for conversations that should potentially be unread
    if (lastMessageFromClinic) {
      print('📱 Conversation ${widget.conversation.clinicName}: lastSender=${widget.conversation.lastMessageSenderId}, currentUser=${_currentUser!.uid}, isRead=$isReadInStorage, shouldBeUnread=$shouldBeUnread');
    }
    
    return shouldBeUnread;
  }

  /// Build the conversation item UI
  Widget _buildConversationItem(bool isUnread) {

    return Container(
      margin: const EdgeInsets.only(bottom: kMobilePaddingSmall),
      child: Material(
        color: isUnread 
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: isUnread ? 2 : 1,
        shadowColor: isUnread 
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.textSecondary.withValues(alpha: 0.05),
        child: InkWell(
          onTap: _onTap,
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Container(
            decoration: isUnread
                ? BoxDecoration(
                    borderRadius: kMobileBorderRadiusSmallPreset,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(kMobilePaddingSmall),
            child: Row(
              children: [
                // Clinic avatar with unread indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isUnread 
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.local_hospital,
                        color: isUnread 
                            ? AppColors.primary 
                            : AppColors.primary.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: kMobileSizedBoxLarge),

                // Conversation details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.clinicName,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                          color: isUnread 
                              ? AppColors.textPrimary 
                              : AppColors.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.conversation.lastMessage ?? 'No messages yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread 
                              ? AppColors.textPrimary.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontWeight: isUnread ? FontWeight.w400 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Time and options
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.conversation.lastMessageTime != null)
                      Text(
                        _formatTime(widget.conversation.lastMessageTime!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnread 
                              ? AppColors.primary 
                              : AppColors.textSecondary,
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (widget.onDelete != null)
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(context),
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
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
            'Are you sure you want to delete this conversation with ${widget.conversation.clinicName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onDelete != null) {
                  widget.onDelete!();
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