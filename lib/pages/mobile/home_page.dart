import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/messaging/mobile_messaging_preferences_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_bottom_nav_bar.dart';
import 'package:pawsense/core/widgets/user/shared/tab_toggle.dart';
import 'package:pawsense/core/widgets/user/home/profile_header.dart';
import 'package:pawsense/core/widgets/user/home/pet_info_card.dart';
import 'package:pawsense/core/widgets/user/home/health_snapshot.dart';
import 'package:pawsense/core/widgets/user/home/nearby_clinics.dart';
import 'package:pawsense/core/widgets/user/home/services_grid.dart';
import 'package:pawsense/core/widgets/user/home/history_section.dart';
import 'package:pawsense/core/widgets/user/home/ai_history_list.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_list.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:pawsense/core/utils/data_cache.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  UserModel? _userModel;
  bool _loading = true;
  int _currentNavIndex = 0;
  int _currentTabIndex = 0;
  final GlobalKey<PetInfoCardState> _petCardKey = GlobalKey<PetInfoCardState>();
  bool _hasInitiallyLoaded = false; // Track if initial load is complete
  bool _isInternalTabSwitch = false; // Track if this is just a tab switch

  // Dynamic health data generated from AI history
  List<HealthData> _healthData = [];

  // Dynamic AI history data from database
  List<AIHistoryData> _aiHistory = [];
  bool _historyLoading = false;
  final AssessmentResultService _assessmentService = AssessmentResultService();
  final DataCache _cache = DataCache();

  // Sample appointment history data
  final List<AppointmentHistoryData> _appointmentHistory = [
    AppointmentHistoryData(
      id: 'apt_001',
      title: 'Confirmed',
      subtitle: 'Sep 20 • 11:00 AM',
      status: AppointmentStatus.confirmed,
      timestamp: DateTime.now().add(const Duration(days: 14)),
      clinicName: 'Happy Paws Vet',
    ),
    AppointmentHistoryData(
      id: 'apt_002',
      title: 'Pending',
      subtitle: 'Oct 02 • 2:30 PM',
      status: AppointmentStatus.pending,
      timestamp: DateTime.now().add(const Duration(days: 26)),
      clinicName: 'Downtown Animal Care',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    // Clean up any resources here if needed
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for query parameters to set initial tab
    final uri = GoRouterState.of(context).uri;
    final tabParam = uri.queryParameters['tab'];
    final refreshParam = uri.queryParameters['refresh'];
    
    if (tabParam == 'history') {
      if (mounted) {
        setState(() {
          _currentTabIndex = 1; // History tab index
        });
      }
    }
    
    // Only refresh pet card on initial load or when explicitly requested via refresh param
    // Don't refresh on internal tab switches
    final shouldRefresh = (!_hasInitiallyLoaded || refreshParam == 'pets') && !_isInternalTabSwitch;
    
    if (shouldRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshPetCard();
          if (!_hasInitiallyLoaded) {
            if (mounted) {
              setState(() {
                _hasInitiallyLoaded = true;
              });
            }
          }
        }
      });
    }
    
    // Reset the internal tab switch flag
    _isInternalTabSwitch = false;
    
    // Also refresh assessment history when tab is history
    if (tabParam == 'history') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _userModel != null) {
          _fetchAssessmentHistory();
        }
      });
    }
  }

  void _refreshPetCard() {
    print('DEBUG: _refreshPetCard called');
    if (mounted && _petCardKey.currentState != null) {
      print('DEBUG: Calling refreshPets with forceRefresh=false (using cache)');
      _petCardKey.currentState!.refreshPets(forceRefresh: false);
    } else {
      print('DEBUG: Pet card widget not available for refresh');
    }
  }

  // Public method to refresh pets (can be called when returning from pets page)
  void refreshPets() {
    _refreshPetCard();
  }

  // Public method to refresh assessment history (can be called after completing assessment)
  void refreshAssessmentHistory({bool forceRefresh = true}) {
    // When called externally (like after assessment), usually want fresh data
    if (_userModel != null) {
      // Invalidate cache when new assessment is added
      final cacheKey = CacheKeys.userAssessments(_userModel!.uid);
      _cache.invalidate(cacheKey);
    }
    _fetchAssessmentHistory(forceRefresh: forceRefresh);
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null) {
        // Initialize mobile messaging preferences for the user
        try {
          final preferencesService = MobileMessagingPreferencesService.instance;
          if (!preferencesService.isInitialized) {
            await preferencesService.initializeForUser(userModel.uid);
          }
        } catch (e) {
          print('Error initializing mobile messaging preferences: $e');
          // Don't block the UI for preferences initialization error
        }
        
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _loading = false;
          });
        }
        
        // Fetch assessment history after user is loaded
        _fetchAssessmentHistory();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchAssessmentHistory({bool forceRefresh = false}) async {
    if (_userModel == null) {
      print('DEBUG: User model is null, cannot fetch assessment history');
      return;
    }
    
    print('DEBUG: Fetching assessment history for user: ${_userModel!.uid}, forceRefresh: $forceRefresh');
    
    final cacheKey = CacheKeys.userAssessments(_userModel!.uid);
    
    // Try to get cached data first (unless forcing refresh)
    if (!forceRefresh) {
      final cachedAssessments = _cache.get<List<AssessmentResult>>(cacheKey);
      if (cachedAssessments != null) {
        print('DEBUG: Using cached assessments (${cachedAssessments.length} assessments)');
        
        final aiHistoryData = _convertAssessmentResultsToAIHistory(cachedAssessments);
        final healthData = _generateHealthDataFromAssessments(cachedAssessments);
        
        if (mounted) {
          setState(() {
            _aiHistory = aiHistoryData;
            _healthData = healthData;
            _historyLoading = false;
          });
        }
        return;
      }
    }
    
    // Show loading only if we don't have data yet
    final showLoading = _aiHistory.isEmpty;
    
    if (mounted && showLoading) {
      setState(() {
        _historyLoading = true;
      });
    }

    try {
      print('DEBUG: Fetching assessments from API');
      final assessmentResults = await _assessmentService.getAssessmentResultsByUserId(_userModel!.uid);
      print('DEBUG: Fetched ${assessmentResults.length} assessment results from API');
      
      // Cache the fresh data (3 minutes TTL)
      _cache.put(cacheKey, assessmentResults, ttl: const Duration(minutes: 3));
      
      final aiHistoryData = _convertAssessmentResultsToAIHistory(assessmentResults);
      print('DEBUG: Converted to ${aiHistoryData.length} AI history items');
      
      // Generate health data from assessment results
      final healthData = _generateHealthDataFromAssessments(assessmentResults);
      print('DEBUG: Generated ${healthData.length} health data items');
      
      if (mounted) {
        setState(() {
          _aiHistory = aiHistoryData;
          _healthData = healthData;
          _historyLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching assessment history: $e');
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  List<AIHistoryData> _convertAssessmentResultsToAIHistory(List<AssessmentResult> assessmentResults) {
    List<AIHistoryData> aiHistoryList = [];
    
    print('DEBUG: Converting ${assessmentResults.length} assessment results');
    
    for (final result in assessmentResults) {
      print('DEBUG: Processing assessment ${result.id} with ${result.detectionResults.length} detection results');
      
      if (result.detectionResults.isEmpty) {
        // If no detection results at all, still show the assessment
        final aiHistoryItem = AIHistoryData(
          id: result.id ?? '${result.createdAt.millisecondsSinceEpoch}',
          title: 'Assessment completed',
          subtitle: _formatTimestamp(result.createdAt),
          type: AIDetectionType.mange, // Default type
          timestamp: result.createdAt,
          confidence: 0.0,
          imageUrl: result.imageUrls.isNotEmpty ? result.imageUrls.first : null,
        );
        aiHistoryList.add(aiHistoryItem);
        print('DEBUG: Added assessment with no detection results');
        continue;
      }
      
      // Find the highest confidence detection across ALL images in this assessment
      double highestConfidence = 0.0;
      String bestDetectionLabel = '';
      String? firstImageUrl;
      
      for (final detectionResult in result.detectionResults) {
        // Use the first available image URL
        if (firstImageUrl == null && detectionResult.imageUrl.isNotEmpty) {
          firstImageUrl = detectionResult.imageUrl;
        }
        
        for (final detection in detectionResult.detections) {
          if (detection.confidence > highestConfidence) {
            highestConfidence = detection.confidence;
            bestDetectionLabel = detection.label;
          }
        }
      }
      
      // Create a single history item for the entire assessment
      final String title;
      if (bestDetectionLabel.isNotEmpty) {
        title = _formatDetectionTitle(bestDetectionLabel, highestConfidence);
        print('DEBUG: Best detection across all images: $bestDetectionLabel with confidence $highestConfidence');
      } else {
        title = 'No conditions detected';
        print('DEBUG: No detections found across all images');
      }
      
      final aiHistoryItem = AIHistoryData(
        id: result.id ?? '${result.createdAt.millisecondsSinceEpoch}',
        title: title,
        subtitle: _formatTimestamp(result.createdAt),
        type: bestDetectionLabel.isNotEmpty ? _getAIDetectionType(bestDetectionLabel) : AIDetectionType.mange,
        timestamp: result.createdAt,
        confidence: highestConfidence,
        imageUrl: firstImageUrl,
      );
      
      aiHistoryList.add(aiHistoryItem);
      print('DEBUG: Added single AI history item for assessment: ${aiHistoryItem.title}');
    }
    
    // Sort by timestamp (newest first)
    aiHistoryList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print('DEBUG: Final AI history list has ${aiHistoryList.length} items');
    return aiHistoryList;
  }

  String _formatDetectionTitle(String label, double confidence) {
    final formattedLabel = label.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    if (confidence > 0.8) {
      return '$formattedLabel detected';
    } else if (confidence > 0.6) {
      return 'Possible $formattedLabel';
    } else {
      return 'Potential $formattedLabel signs';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'Today • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours < 24) {
      return 'Today • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[timestamp.weekday - 1]} • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  AIDetectionType _getAIDetectionType(String label) {
    switch (label.toLowerCase()) {
      case 'mange':
        return AIDetectionType.mange;
      case 'ringworm':
        return AIDetectionType.ringworm;
      case 'pyoderma':
        return AIDetectionType.pyoderma;
      case 'hotspot':
      case 'hot_spot':
        return AIDetectionType.hotSpot;
      case 'fleas':
      case 'flea_allergy':
        return AIDetectionType.fleaAllergy;
      default:
        return AIDetectionType.mange; // Default fallback
    }
  }

  List<HealthData> _generateHealthDataFromAssessments(List<AssessmentResult> assessmentResults) {
    if (assessmentResults.isEmpty) return [];
    
    // Filter assessments from the last week
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentAssessments = assessmentResults
        .where((assessment) => assessment.createdAt.isAfter(oneWeekAgo))
        .toList();
    
    if (recentAssessments.isEmpty) return [];
    
    // Count detections by condition from recent assessments
    final Map<String, int> conditionCounts = {};
    
    for (final assessment in recentAssessments) {
      for (final detectionResult in assessment.detectionResults) {
        if (detectionResult.detections.isNotEmpty) {
          // Get only the highest confidence detection per image (matching our display logic)
          final sortedDetections = List<Detection>.from(detectionResult.detections);
          sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
          final highestDetection = sortedDetections.first;
          
          final condition = _formatConditionForSnapshot(highestDetection.label);
          conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
        }
      }
    }
    
    // Convert to HealthData objects with colors
    final colors = [
      const Color(0xFFFF9500), // Orange
      const Color(0xFF007AFF), // Blue
      const Color(0xFF8E44AD), // Purple
      const Color(0xFFE74C3C), // Red
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF39C12), // Orange variant
      const Color(0xFF9B59B6), // Purple variant
      const Color(0xFF1ABC9C), // Teal
    ];
    
    final healthDataList = <HealthData>[];
    int colorIndex = 0;
    
    // Sort by count (highest first) and take top conditions
    final sortedConditions = conditionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedConditions.take(6)) {
      healthDataList.add(HealthData(
        condition: entry.key,
        count: entry.value,
        color: colors[colorIndex % colors.length],
      ));
      colorIndex++;
    }
    
    return healthDataList;
  }
  
  String _formatConditionForSnapshot(String condition) {
    // Format condition names for display
    return condition
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UserAppBar(
        user: _userModel,
        onUserUpdated: (updatedUser) {
          setState(() {
            _userModel = updatedUser;
          });
        },
      ),
      body: _loading 
          ? _buildLoadingState()
          : _userModel != null 
              ? _buildHomeContent()
              : _buildErrorState(),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          if (index == 2) {
            // Navigate to alerts page
            context.push('/alerts');
          } else {
            if (mounted) {
              setState(() {
                _currentNavIndex = index;
              });
            }
            // Only refresh pet card when home tab is selected AND we're coming from a different nav index
            // This prevents unnecessary refreshes when already on home tab
            if (index == 0 && _currentNavIndex != 0) {
              _refreshPetCard();
            }
          }
        },
        onCameraPressed: _showCameraDialog,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Unable to load user data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchUser,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Tab Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal, vertical: kMobileSizedBoxXLarge),
              child: TabToggle(
                selectedIndex: _currentTabIndex,
                onTabChanged: (index) {
                  if (mounted) {
                    // Set flag to indicate this is an internal tab switch
                    _isInternalTabSwitch = true;
                    setState(() {
                      _currentTabIndex = index;
                    });
                  }
                },
                tabs: const ['Dashboard', 'History'],
              ),
            ),
            
            // Content based on selected tab
            if (_currentTabIndex == 0) ...[
              // Dashboard Tab
                Transform.translate(
                  offset: Offset(0, -kMobileSizedBoxXLarge),
                  child: Column(
                    children: [
                      ProfileHeader(
                        user: _userModel!,
                        onManagePressed: () async {
                          // Navigate to edit profile page
                          final updatedUser = await context.push('/edit-profile', extra: {
                            'user': _userModel!,
                          });
                          
                          // If user data was updated, refresh the page
                          if (updatedUser != null && updatedUser is UserModel) {
                            if (mounted) {
                              setState(() {
                                _userModel = updatedUser;
                              });
                            }
                          } else {
                            // Fallback: refresh user data from server
                            _fetchUser();
                          }
                        },
                      ),

                      PetInfoCard(
                        key: _petCardKey,
                        nextAppointmentDate: null, // No appointment
                        nextAppointmentTime: null, // No appointment
                      ),

                      // Add space between pets and health snapshot
                      const SizedBox(height: kMobileSizedBoxHuge),

                      HealthSnapshot(
                        healthData: _healthData,
                      ),

                      NearbyClinicsWidget(
                        onViewAllPressed: () {
                          // Handle view all clinics
                          print('View all clinics pressed');
                        },
                        onMessageClinic: (clinic) {
                          // Handle message clinic
                          print('Message clinic: ${clinic.name}');
                          // TODO: Navigate to messaging or contact page
                        },
                      ),

                      // Services moved below nearby clinics
                      ServicesGrid(
                        services: _getServices(),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // History Tab
              _buildHistoryContent(),
            ],
            
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return HistorySection(
      aiHistory: _aiHistory,
      appointmentHistory: _appointmentHistory,
      isHistoryLoading: _historyLoading,
      onViewAllPressed: () {
        // Handle view all history
      },
    );
  }

  List<ServiceItem> _getServices() {
    return [
      ServiceItem(
        title: 'Book Appointment',
        subtitle: 'Schedule visit',
        icon: Icons.calendar_today,
        backgroundColor: const Color(0xFF8E44AD).withValues(alpha: 0.1),
        onTap: () {
          context.push('/book-appointment');
        },
      ),
      ServiceItem(
        title: 'Emergency Hotline',
        subtitle: '24/7 support',
        icon: Icons.phone,
        backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
        onTap: () {
          context.push('/emergency-hotline');
        },
      ),
      ServiceItem(
        title: 'First Aid Guide',
        subtitle: 'Emergency tips',
        icon: Icons.medical_services,
        backgroundColor: const Color(0xFFFF9500).withValues(alpha: 0.1),
        onTap: () {
          context.push('/first-aid-guide');
        },
      ),
      ServiceItem(
        title: 'Pet Care Tips',
        subtitle: 'Daily care',
        icon: Icons.lightbulb_outline,
        backgroundColor: const Color(0xFF34C759).withValues(alpha: 0.1),
        onTap: () {
          context.push('/pet-care-tips');
        },
      ),
    ];
  }

  void _showCameraDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PetAssessmentModal(),
    );
  }
}
