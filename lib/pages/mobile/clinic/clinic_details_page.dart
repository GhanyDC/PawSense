import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/models/clinic/clinic_rating_model.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/services/clinic/clinic_rating_service.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_header.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_contact_info.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_services_list.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_credentials.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_schedule.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_action_buttons.dart';
import 'package:pawsense/core/widgets/shared/rating/rating_display_widgets.dart';
import 'package:pawsense/pages/mobile/messaging/conversation_page.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class ClinicDetailsPage extends StatefulWidget {
  final String clinicId;

  const ClinicDetailsPage({
    super.key,
    required this.clinicId,
  });

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  ClinicDetails? _clinicDetails;
  WeeklySchedule? _weeklySchedule;
  List<DateTime> _holidays = [];
  ClinicRatingStats? _ratingStats;
  bool _isLoading = true;
  bool _isLoadingSchedule = true;
  String? _errorMessage;
  StreamSubscription<ClinicDetails?>? _clinicSubscription;
  StreamSubscription<WeeklySchedule>? _scheduleSubscription;
  StreamSubscription<List<DateTime>>? _holidaysSubscription;
  StreamSubscription<ClinicRatingStats>? _ratingsSubscription;

  @override
  void initState() {
    super.initState();
    _loadClinicDetails();
    _loadClinicSchedule();
    _loadHolidays();
    _loadRatings();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _scheduleSubscription?.cancel();
    _holidaysSubscription?.cancel();
    _ratingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadClinicDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Cancel existing subscription if any
      _clinicSubscription?.cancel();

      // Use stream for real-time updates
      _clinicSubscription = ClinicDetailsService.streamClinicDetails(widget.clinicId)
          .listen((clinicDetails) {
        if (mounted) {
          setState(() {
            _clinicDetails = clinicDetails;
            _isLoading = false;
            _errorMessage = clinicDetails == null ? 'Clinic not found' : null;
          });
          if (clinicDetails != null) {
            print('🔄 Clinic details updated in real-time: ${clinicDetails.clinicName}');
          }
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
            _isLoading = false;
          });
          print('❌ Error streaming clinic details: $error');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadClinicSchedule() async {
    try {
      setState(() {
        _isLoadingSchedule = true;
      });

      // Cancel existing subscription if any
      _scheduleSubscription?.cancel();

      // Use stream for real-time schedule updates
      _scheduleSubscription = ClinicScheduleService.streamWeeklySchedule(widget.clinicId)
          .listen((schedule) {
        if (mounted) {
          setState(() {
            _weeklySchedule = schedule;
            _isLoadingSchedule = false;
          });
          print('✅ Clinic schedule updated in real-time for ${widget.clinicId}');
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoadingSchedule = false;
          });
          print('❌ Error streaming clinic schedule: $error');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
        });
        print('❌ Error loading clinic schedule: $e');
      }
    }
  }

  Future<void> _loadHolidays() async {
    try {
      // Cancel existing subscription if any
      _holidaysSubscription?.cancel();

      // Use stream for real-time holiday updates
      _holidaysSubscription = ClinicScheduleService.streamHolidays(widget.clinicId)
          .listen((holidays) {
        if (mounted) {
          setState(() {
            _holidays = holidays;
          });
          print('✅ Holidays updated in real-time: ${holidays.length} holiday(s)');
        }
      }, onError: (error) {
        print('❌ Error streaming holidays: $error');
      });
    } catch (e) {
      print('❌ Error loading holidays: $e');
    }
  }

  Future<void> _loadRatings() async {
    try {
      // Cancel existing subscription if any
      _ratingsSubscription?.cancel();

      // Use stream for real-time rating updates
      _ratingsSubscription = ClinicRatingService.streamClinicRatingStats(widget.clinicId)
          .listen((stats) {
        if (mounted) {
          setState(() {
            _ratingStats = stats;
          });
          print('✅ Rating stats updated: ${stats.averageRating} (${stats.totalRatings} reviews)');
        }
      }, onError: (error) {
        print('❌ Error streaming rating stats: $error');
      });
    } catch (e) {
      print('❌ Error loading rating stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _clinicDetails?.clinicName ?? 'Clinic Details',
          style: kMobileTextStyleTitle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_clinicDetails == null) {
      return _buildNotFoundState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Reload holidays on refresh (they're not streamed)
        try {
          final holidays = await ClinicScheduleService.getHolidays(widget.clinicId);
          if (mounted) {
            setState(() {
              _holidays = holidays;
            });
          }
        } catch (e) {
          print('Error refreshing holidays: $e');
        }
        
        await _loadClinicDetails();
        // Schedule stream will auto-update, no need to reload
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(kMobilePaddingMedium),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic Header
            ClinicHeader(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Clinic Ratings
            if (_ratingStats != null)
              _buildRatingsSection(_ratingStats!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Contact Information
            ClinicContactInfo(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Clinic Schedule
            if (_weeklySchedule != null && !_isLoadingSchedule) ...[
              ClinicSchedule(
                weeklySchedule: _weeklySchedule!,
                holidays: _holidays,
              ),
              const SizedBox(height: kMobileSizedBoxMedium),
            ],
            
            // Services List
            ClinicServicesList(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Credentials & Licenses
            ClinicCredentials(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Action Buttons - moved to last
            ClinicActionButtons(
              clinic: _clinicDetails!,
              onBookAppointment: _bookAppointment,
              onMessageClinic: _messageClinic,
            ),
            
            const SizedBox(height: kMobileSizedBoxLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsSection(ClinicRatingStats stats) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Clinic Ratings',
                style: kMobileTextStyleTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          if (stats.hasRatings) ...[
            Row(
              children: [
                // Large rating display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stats.formattedAverage,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/5',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StarRatingDisplay(
                      rating: stats.averageRating,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalRatings} ${stats.totalRatings == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                
                // Rating distribution
                Expanded(
                  child: RatingDistributionWidget(
                    stats: stats,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to review this clinic',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Loading clinic details...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kMobileMarginAll),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Failed to load clinic details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            ElevatedButton.icon(
              onPressed: _loadClinicDetails,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: kMobilePaddingLarge,
                  vertical: kMobilePaddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kMobileMarginAll),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Clinic Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              'The clinic you\'re looking for doesn\'t exist or has been removed.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: kMobilePaddingLarge,
                  vertical: kMobilePaddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                ),
              ),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAppointment() {
    // Navigate to appointment booking page with pre-filled clinic data
    context.push(
      '/book-appointment',
      extra: {
        'clinicId': _clinicDetails!.clinicId,
        'clinicName': _clinicDetails!.clinicName,
      },
    );
  }

  void _messageClinic() async {
    try {
      // Get current user
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        _showSnackBar('Please log in to send messages');
        return;
      }

      // Check if conversation already exists with this clinic
      final conversationsStream = MessagingService.getUserConversations();
      await for (final conversations in conversationsStream.take(1)) {
        // Look for existing conversation with this clinic
        Conversation? existingConversation;
        try {
          existingConversation = conversations.firstWhere(
            (conv) => conv.clinicId == _clinicDetails!.clinicId,
          );
        } catch (e) {
          // No existing conversation found
          existingConversation = null;
        }

        if (existingConversation != null) {
          // Navigate to existing conversation (like clicking from messages menu)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: existingConversation!,
              ),
            ),
          );
        } else {
          // Create a temporary conversation for new conversation
          final tempConversation = Conversation(
            id: 'temp_${_clinicDetails!.clinicId}_${DateTime.now().millisecondsSinceEpoch}',
            userId: currentUser.uid,
            userName: '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim(),
            clinicId: _clinicDetails!.clinicId,
            clinicName: _clinicDetails!.clinicName,
            lastMessageTime: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to conversation page with temporary conversation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: tempConversation,
              ),
            ),
          );
        }
        break; // Exit the stream after first result
      }
    } catch (e) {
      print('Error in _messageClinic: $e');
      _showSnackBar('Error loading conversation');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
        ),
      ),
    );
  }
}