import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/messaging/mobile_conversation_list_item.dart';
import 'package:pawsense/core/services/messaging/mobile_messaging_preferences_service.dart';
import 'clinic_selection_page.dart';
import 'conversation_page.dart';
import 'dart:async';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final MobileMessagingPreferencesService _mobilePreferencesService = MobileMessagingPreferencesService.instance;
  UserModel? _userModel;
  bool _loading = true;
  StreamSubscription<Set<String>>? _readConversationsSubscription;
  StreamSubscription<bool>? _dataChangedSubscription;
  List<Conversation> _previousConversations = []; // Track previous conversations for comparison
  Set<String> _processedMessageKeys = {}; // Track processed messages to prevent duplicates
  
  // Filter states
  String _selectedFilter = 'All'; // 'All', 'Unread', 'Read'
  String? _currentlySelectedConversationId; // Track currently open conversation (admin pattern)

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initializePreferences();
  }

  @override
  void dispose() {
    _readConversationsSubscription?.cancel();
    _dataChangedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (mounted) {
        setState(() {
          _userModel = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _initializePreferences() async {
    if (!mounted) return;
    
    try {
      // Ensure preferences service is initialized for current user
      final user = await AuthGuard.getCurrentUser();
      if (user != null && !_mobilePreferencesService.isInitialized) {
        await _mobilePreferencesService.initializeForUser(user.uid);
      }
    } catch (e) {
      print('Error initializing mobile messaging preferences: $e');
    }
    
    // Listen to real-time data changes
    _dataChangedSubscription = _mobilePreferencesService.dataChangedStream.listen(
      (changed) {
        if (mounted && changed) {
          setState(() {
            // Trigger UI rebuild when data changes
          });
        }
      },
      onError: (error) {
        print('Error in data changed stream: $error');
      },
    );

    // Listen to changes in read conversations
    _readConversationsSubscription = _mobilePreferencesService.readConversationsStream.listen(
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

    // Initialize with current user if available
    if (!_mobilePreferencesService.isInitialized) {
      try {
        final user = await AuthGuard.getCurrentUser();
        if (mounted && user != null) {
          await _mobilePreferencesService.initializeForUser(user.uid);
        } else {
          print('Warning: Could not initialize mobile messaging preferences - no user');
        }
      } catch (e) {
        print('Warning: Could not initialize mobile messaging preferences: $e');
      }
    }
  }

  void _checkForNewMessages(List<Conversation> oldConversations, List<Conversation> newConversations) {
    // Skip processing if this is the first load (oldConversations is empty)
    if (oldConversations.isEmpty) {
      print('📱 First load - skipping new message detection');
      return;
    }

    // Create map for easier comparison
    final oldConversationMap = {for (var conv in oldConversations) conv.id: conv};

    for (final newConv in newConversations) {
      final oldConv = oldConversationMap[newConv.id];
      
      // Check if this is a new message from clinic
      final lastMessageFromClinic = _userModel != null && 
                                   newConv.lastMessageSenderId != _userModel!.uid &&
                                   newConv.lastMessageSenderId != null;
      
      if (lastMessageFromClinic) {
        final isCurrentlySelected = _currentlySelectedConversationId == newConv.id;
        
        // Only process if conversation exists in old list (not a completely new conversation)
        // New conversations should be handled differently
        if (oldConv != null) {
          // Check if the last message time has changed (new message)
          final oldTime = oldConv.lastMessageTime;
          final newTime = newConv.lastMessageTime;
          
          bool hasNewerMessage = false;
          if (newTime != null && oldTime != null && newTime.isAfter(oldTime)) {
            hasNewerMessage = true;
          }
          
          // Also check if the message content changed AND it's from clinic
          bool hasNewContent = oldConv.lastMessage != newConv.lastMessage;
          
          if ((hasNewerMessage || hasNewContent) && !isCurrentlySelected) {
            // Create a unique key for this message to prevent duplicate processing
            final messageKey = '${newConv.id}_${newTime?.millisecondsSinceEpoch}_${newConv.lastMessage?.hashCode}';
            
            if (!_processedMessageKeys.contains(messageKey)) {
              print('🆕 New clinic message detected: ${newConv.clinicName}');
              print('🆕 Message key: $messageKey');
              print('🆕 Old time: ${oldTime}');
              print('🆕 New time: ${newTime}');
              print('🆕 Old message: ${oldConv.lastMessage}');
              print('🆕 New message: ${newConv.lastMessage}');
              print('🆕 Sender ID: ${newConv.lastMessageSenderId}');
              
              _mobilePreferencesService.markNewMessageFromClinic(newConv.id, 1);
              print('🆕 New clinic message marked as unread via markNewMessageFromClinic');
              
              // Mark this message as processed
              _processedMessageKeys.add(messageKey);
              
              // Clean up old processed keys (keep only last 50 to prevent memory buildup)
              if (_processedMessageKeys.length > 50) {
                final keysList = _processedMessageKeys.toList();
                _processedMessageKeys = keysList.sublist(keysList.length - 50).toSet();
              }
              
              // Force rebuild of the conversation list
              setState(() {});
            } else {
              print('🔄 Message already processed, skipping: ${newConv.clinicName}');
            }
          }
        }
      }
    }

    // Update the previous conversations for next comparison
    _previousConversations = List.from(newConversations);
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _userModel = updatedUser;
    });
  }

  /// Filter conversations based on selected filter (using admin logic)
  List<Conversation> _filterConversations(List<Conversation> conversations) {
    switch (_selectedFilter) {
      case 'Unread':
        return conversations.where((conv) {
          final isReadInStorage = _mobilePreferencesService.isConversationRead(conv.id);
          
          // Only show as unread if last message was from clinic (not from current user)
          final lastMessageFromClinic = _userModel != null && 
                                       conv.lastMessageSenderId != _userModel!.uid &&
                                       conv.lastMessageSenderId != null;
          
          return lastMessageFromClinic && !isReadInStorage;
        }).toList();
      case 'Read':
        return conversations.where((conv) {
          final isReadInStorage = _mobilePreferencesService.isConversationRead(conv.id);
          
          // Show as read if: marked as read in storage OR last message was from user OR no messages
          final lastMessageFromClinic = _userModel != null && 
                                       conv.lastMessageSenderId != _userModel!.uid &&
                                       conv.lastMessageSenderId != null;
          
          return isReadInStorage || !lastMessageFromClinic;
        }).toList();
      default:
        return conversations;
    }
  }

  /// Build filter chip for conversation filtering
  Widget _buildFilterChip(String filter, int count) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            if (count > 0 && (filter == 'All' || filter == 'Unread')) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    // Check if we came from services grid
    final uri = GoRouterState.of(context).uri;
    final source = uri.queryParameters['source'];
    final fromServices = source == 'services';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: fromServices 
        ? AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Messages',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : UserAppBar(
            user: _userModel,
            onUserUpdated: _onUserUpdated,
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToClinicSelection(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Header with enhanced unread UI
          Container(
            padding: const EdgeInsets.fromLTRB(kMobilePaddingMedium,kMobilePaddingMedium,kMobilePaddingMedium,0),
            color: AppColors.background,
            child: StreamBuilder<List<Conversation>>(
              stream: MessagingService.getUserConversations(),
              builder: (context, snapshot) {
                final allConversations = snapshot.data ?? [];
                
                // Sync conversation data with server for real-time updates
                if (_mobilePreferencesService.isInitialized) {
                  for (final conv in allConversations) {
                    if (_mobilePreferencesService.hasConversationDataChanged(conv.id, conv.unreadCount)) {
                      _mobilePreferencesService.syncConversationData(conv.id, conv.unreadCount);
                    }
                  }
                }

                final unreadConversationsCount = allConversations.where((conv) {
                  final isReadInStorage = _mobilePreferencesService.isConversationRead(conv.id);
                  
                  // Only count as unread if last message was from clinic
                  final lastMessageFromClinic = _userModel != null && 
                                               conv.lastMessageSenderId != _userModel!.uid &&
                                               conv.lastMessageSenderId != null;
                  
                  return lastMessageFromClinic && !isReadInStorage;
                }).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with settings
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Messages',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 16
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Filter chips
                    const SizedBox(height: kMobileSizedBoxMedium),
                    Row(
                      children: [
                        _buildFilterChip('All', allConversations.length),
                        const SizedBox(width: kMobileSizedBoxSmall),
                        _buildFilterChip('Unread', unreadConversationsCount),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Conversations list
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: MessagingService.getUserConversations(),
              builder: (context, snapshot) {
                print('MessagingPage StreamBuilder state: ${snapshot.connectionState}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        Text(
                          'Error loading conversations',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxSmall),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Force rebuild to retry
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          child: const Text('Retry', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxSmall),
                        Text(
                          'Start a conversation with a vet clinic',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxXLarge),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToClinicSelection(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Message', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allConversations = snapshot.data!;
                
                // Check for new messages when conversations update (only when we have stable data)
                if (snapshot.connectionState == ConnectionState.active) {
                  if (_previousConversations.isNotEmpty) {
                    _checkForNewMessages(_previousConversations, allConversations);
                  }
                  // Update the previous conversations for next comparison
                  _previousConversations = List.from(allConversations);
                }
                
                final filteredConversations = _filterConversations(allConversations);

                // Show empty state with filter context
                if (filteredConversations.isEmpty) {
                  String emptyMessage;
                  String emptySubtitle;
                  IconData emptyIcon;
                  
                  switch (_selectedFilter) {
                    case 'Unread':
                      emptyMessage = 'No unread messages';
                      emptySubtitle = 'All conversations have been read';
                      emptyIcon = Icons.check_circle_outline;
                      break;
                    case 'Read':
                      emptyMessage = 'No read messages';
                      emptySubtitle = 'You have unread conversations waiting';
                      emptyIcon = Icons.mark_email_unread;
                      break;
                    default:
                      emptyMessage = 'No conversations yet';
                      emptySubtitle = 'Start a conversation with a vet clinic';
                      emptyIcon = Icons.chat_bubble_outline;
                  }
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          emptyIcon,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxSmall),
                        Text(
                          emptySubtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (_selectedFilter == 'All') ...[
                          const SizedBox(height: kMobileSizedBoxXLarge),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToClinicSelection(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Message', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

              return ListView.separated(
                padding: const EdgeInsets.all(kMobilePaddingMedium),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    final isCurrentlySelected = _currentlySelectedConversationId == conversation.id;
                    return MobileConversationListItem(
                      conversation: conversation,
                      isCurrentlySelected: isCurrentlySelected, // Pass admin-style selection state
                      onTap: () => _navigateToConversation(conversation),
                      onDelete: () => _deleteConversation(conversation),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: kMobileSizedBoxMedium),
                );

              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToConversation(Conversation conversation) {
    // Track the currently selected conversation (admin pattern)
    setState(() {
      _currentlySelectedConversationId = conversation.id;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(conversation: conversation),
      ),
    ).then((_) {
      // Clear selection when returning from conversation (admin pattern)
      if (mounted) {
        setState(() {
          _currentlySelectedConversationId = null;
        });
      }
    });
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    try {
      await MessagingService.deleteConversationAndMessages(conversation.id);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation with ${conversation.clinicName} deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToClinicSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClinicSelectionPage(),
      ),
    );

    // If a conversation was created (user sent a message), the StreamBuilder should automatically refresh
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation started successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}