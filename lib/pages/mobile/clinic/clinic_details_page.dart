import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';
import 'package:pawsense/pages/mobile/messaging/conversation_page.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class ClinicDetailsPage extends StatefulWidget {
  final String clinicId;

  const ClinicDetailsPage({
    Key? key,
    required this.clinicId,
  }) : super(key: key);

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  ClinicDetails? _clinicDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClinicDetails();
  }

  Future<void> _loadClinicDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final clinicDetails = await ClinicDetailsService.getClinicDetails(widget.clinicId);
      
      setState(() {
        _clinicDetails = clinicDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _clinicDetails?.clinicName ?? 'Clinic Details',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.white,
          ),
        ),
        elevation: 0,
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
      onRefresh: _loadClinicDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(kMobilePaddingMedium),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main clinic info card
            _buildClinicInfoCard(),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Contact info card
            _buildContactCard(),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Services card
            _buildServicesCard(),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Action buttons
            _buildActionButtons(),
            
            const SizedBox(height: kMobileSizedBoxLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      child: Material(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: 2,
        shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(kMobilePaddingMedium),
          child: Row(
            children: [
              // Clinic avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _clinicDetails!.isVerified ? Icons.verified : Icons.local_hospital,
                  color: _clinicDetails!.isVerified ? AppColors.success : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxLarge),
              
              // Clinic details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinic name with verification
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _clinicDetails!.clinicName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_clinicDetails!.isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _clinicDetails!.address,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      child: Material(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: 1,
        shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(kMobilePaddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Phone
              if (_clinicDetails!.phone.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _clinicDetails!.phone,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Email
              if (_clinicDetails!.email.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.email,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _clinicDetails!.email,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Operating hours
              if (_clinicDetails!.operatingHours != null && _clinicDetails!.operatingHours!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _clinicDetails!.operatingHours!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesCard() {
    if (_clinicDetails!.services.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      child: Material(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: 1,
        shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(kMobilePaddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _clinicDetails!.services.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.serviceName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      child: Material(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: 1,
        shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(kMobilePaddingMedium),
          child: Row(
            children: [
              // Message button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _messageClinic,
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Book appointment button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _bookAppointment,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Book'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
              child: Text('Go Back'),
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

  void _bookAppointment() {
    // Navigate to appointment booking page
    _showSnackBar('Booking appointment...');
    // TODO: Implement appointment booking navigation
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