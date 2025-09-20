import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../models/messaging/conversation_model.dart';

class ConversationList extends StatefulWidget {
  final List<Conversation> conversations;
  final Conversation? selectedConversation;
  final Function(Conversation) onConversationSelected;
  final bool isLoading;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const ConversationList({
    super.key,
    required this.conversations,
    this.selectedConversation,
    required this.onConversationSelected,
    this.isLoading = false,
    this.searchQuery = '',
    required this.onSearchChanged,
  });

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  // Track which conversations have been read (persistent storage)
  final Set<String> _readConversations = <String>{};
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadReadConversations();
  }

  // Load read conversations from SharedPreferences
  Future<void> _loadReadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readConversationsJson = prefs.getStringList('read_conversations') ?? [];
      if (mounted) {
        setState(() {
          _readConversations.clear();
          _readConversations.addAll(readConversationsJson);
          _isLoadingPreferences = false;
        });
        print('📖 Loaded ${_readConversations.length} read conversations from storage: $_readConversations');
      }
    } catch (e) {
      print('❌ Error loading read conversations: $e');
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    }
  }

  // Save read conversations to SharedPreferences
  Future<void> _saveReadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_conversations', _readConversations.toList());
      print('💾 Saved ${_readConversations.length} read conversations to storage');
    } catch (e) {
      print('❌ Error saving read conversations: $e');
    }
  }

  void _markAsRead(String conversationId) {
    if (mounted) {
      setState(() {
        _readConversations.add(conversationId);
      });
      _saveReadConversations(); // Persist to storage
      print('✅ Marked conversation $conversationId as read. Total read: ${_readConversations.length}');
    }
  }

  // Optional: Method to clear all read status (for testing/debugging)
  Future<void> _clearAllReadStatus() async {
    if (mounted) {
      setState(() {
        _readConversations.clear();
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('read_conversations');
    print('🗑️ Cleared all read conversation status');
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while preferences are being loaded
    if (_isLoadingPreferences) {
      return Container(
        width: 360,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            right: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredConversations = widget.conversations.where((conv) {
      return conv.userName.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
             conv.clinicName.toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chats',
                      style: kTextStyleHeader.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Debug button to clear read status (can be removed in production)
                    IconButton(
                      icon: Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
                      onPressed: _clearAllReadStatus,
                      tooltip: 'Reset read status (Debug)',
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingSmall),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search Messenger',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Conversations list
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = filteredConversations[index];
                          return _buildConversationTile(conversation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No conversations found',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = widget.selectedConversation?.id == conversation.id;
    // Check if conversation has been read in persistent storage or is currently selected
    final isReadInStorage = _readConversations.contains(conversation.id);
    final isReallyUnread = conversation.unreadCount > 0;
    
    // For testing: simulate unread for conversations that contain "Carl" or "Drix" but respect read status
    final shouldShowAsUnread = !isReadInStorage && !isSelected && (
      isReallyUnread || 
      conversation.userName.toLowerCase().contains('carl') ||
      conversation.userName.toLowerCase().contains('drix')
    );
    
    // Debug logging
    print('📊 Conversation: ${conversation.userName}');
    print('   - ID: ${conversation.id}');
    print('   - Selected: $isSelected');
    print('   - ReadInStorage: $isReadInStorage');
    print('   - RealUnread: $isReallyUnread');
    print('   - ShowAsUnread: $shouldShowAsUnread');
    print('   - ReadConversations: $_readConversations');
    
    return Material(
      color: isSelected 
          ? AppColors.primary.withOpacity(0.1) 
          : shouldShowAsUnread 
              ? AppColors.primary.withOpacity(0.02)
              : Colors.transparent,
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          _markAsRead(conversation.id);
          // Call the parent callback
          widget.onConversationSelected(conversation);
        },
        child: Container(
          decoration: BoxDecoration(
            border: shouldShowAsUnread 
                ? Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  )
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: shouldShowAsUnread ? kSpacingMedium - 4 : kSpacingMedium,
            vertical: kSpacingSmall,
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: shouldShowAsUnread 
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.1),
                    child: Text(
                      conversation.userName.isNotEmpty
                          ? conversation.userName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: shouldShowAsUnread ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (shouldShowAsUnread)
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
              ),
              const SizedBox(width: kSpacingSmall),
              
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.userName.isNotEmpty 
                          ? conversation.userName 
                          : 'Unknown User',
                      style: kTextStyleRegular.copyWith(
                        fontWeight: shouldShowAsUnread ? FontWeight.w700 : FontWeight.w600,
                        color: shouldShowAsUnread ? AppColors.textPrimary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conversation.lastMessage != null && conversation.lastMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage!,
                        style: kTextStyleSmall.copyWith(
                          color: shouldShowAsUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: shouldShowAsUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Time and indicators
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conversation.lastMessageTime ?? conversation.updatedAt),
                    style: kTextStyleSmall.copyWith(
                      color: shouldShowAsUnread ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: shouldShowAsUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Unread count indicator
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: kTextStyleSmall.copyWith(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      // Show date format for messages older than a day
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours >= 1) {
      // Show hour:minute format for messages older than 1 hour
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inMinutes > 0) {
      // Show "X mins ago" for messages within the last hour
      return '${difference.inMinutes} mins ago';
    } else {
      // Show "Just now" for very recent messages
      return 'Just now';
    }
  }
}