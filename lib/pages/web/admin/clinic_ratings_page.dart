import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/clinic/clinic_rating_model.dart';
import 'package:pawsense/core/services/clinic/clinic_rating_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/widgets/shared/pagination_widget.dart';
import 'package:intl/intl.dart';

class ClinicRatingsPage extends StatefulWidget {
  const ClinicRatingsPage({Key? key}) : super(key: key ?? const PageStorageKey('clinic_ratings'));

  @override
  State<ClinicRatingsPage> createState() => _ClinicRatingsPageState();
}

class _ClinicRatingsPageState extends State<ClinicRatingsPage> with AutomaticKeepAliveClientMixin {
  ClinicRatingStats? _ratingStats;
  List<ClinicRating> _ratings = [];
  List<ClinicRating> _allRatings = []; // Store all ratings for filtering
  bool _isLoading = true;
  bool _isPaginationLoading = false;
  bool _isInitialLoad = true; // Track if this is the first load
  String? _errorMessage;
  String? _clinicId;
  StreamSubscription<ClinicRatingStats>? _statsSubscription;
  StreamSubscription<QuerySnapshot>? _ratingsSubscription;
  int _selectedFilter = 0; // 0 = All, 1-5 = Star filters
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRatings = 0;
  final int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _ratingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadClinicData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user (clinic admin)
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get clinic ID by finding clinic where userId matches current user
      final clinicsSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (clinicsSnapshot.docs.isEmpty) {
        throw Exception('No clinic associated with this account');
      }

      _clinicId = clinicsSnapshot.docs.first.id;

      // Load rating stats with stream for real-time updates
      _statsSubscription = ClinicRatingService.streamClinicRatingStats(_clinicId!)
          .listen((stats) {
        if (mounted) {
          setState(() {
            _ratingStats = stats;
          });
        }
      });

      // Setup real-time listener for ratings (this will set _isLoading to false when data arrives)
      _setupRatingsStream();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Setup real-time stream listener for ratings
  void _setupRatingsStream() {
    if (_clinicId == null) return;

    print('🔔 Setting up real-time listener for ratings...');
    print('🔍 Clinic ID: $_clinicId');

    // Listen to ratings collection for this clinic (load all, then paginate client-side)
    _ratingsSubscription = FirebaseFirestore.instance
        .collection('ratings')
        .where('clinicId', isEqualTo: _clinicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            print('🔄 Received ratings update: ${snapshot.docs.length} ratings');
            
            // Log the first few rating IDs for debugging
            if (snapshot.docs.isNotEmpty) {
              print('📋 Sample rating IDs: ${snapshot.docs.take(3).map((d) => d.id).join(", ")}');
            }

            final allRatings = snapshot.docs.map((doc) {
              return ClinicRating.fromFirestore(doc);
            }).toList();

            setState(() {
              _allRatings = allRatings;
              _totalRatings = allRatings.length;
              _updatePaginatedRatings();
              _isLoading = false; // Set loading to false when data arrives
            });

            // Show notification if new ratings were added (but not on initial load)
            if (!_isInitialLoad && snapshot.docChanges.any((change) => change.type == DocumentChangeType.added)) {
              final newRatingsCount = snapshot.docChanges
                  .where((change) => change.type == DocumentChangeType.added)
                  .length;
              
              if (newRatingsCount > 0) {
                _showNewRatingsNotification(newRatingsCount);
              }
            }
            
            // Mark initial load as complete
            if (_isInitialLoad) {
              _isInitialLoad = false;
            }
          },
          onError: (error) {
            print('❌ Error in ratings stream: $error');
            if (mounted) {
              setState(() {
                _errorMessage = 'Error loading ratings: $error';
                _isLoading = false;
              });
            }
          },
        );
  }

  /// Update paginated ratings based on current page and filter
  void _updatePaginatedRatings() {
    // Apply filter
    List<ClinicRating> filtered = _selectedFilter == 0
        ? _allRatings
        : _allRatings.where((r) => r.rating.round() == _selectedFilter).toList();

    // Calculate pagination
    _totalRatings = filtered.length;
    _totalPages = (_totalRatings / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    // Ensure current page is valid
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }

    // Get current page items
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    
    _ratings = filtered.sublist(startIndex, endIndex);

    print('📄 Pagination: Page $_currentPage of $_totalPages (${_ratings.length} items)');
  }

  /// Handle page change
  void _onPageChanged(int page) {
    setState(() {
      _isPaginationLoading = true;
      _currentPage = page;
    });

    // Small delay to show loading state
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _updatePaginatedRatings();
          _isPaginationLoading = false;
        });
      }
    });
  }

  /// Handle filter change
  void _onFilterChanged(int filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1; // Reset to first page when filter changes
      _updatePaginatedRatings();
    });
  }

  /// Show notification when new ratings are received
  void _showNewRatingsNotification(int count) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '$count new ${count == 1 ? 'review' : 'reviews'} received',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: kSpacingLarge),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ratings & Reviews',
              style: kTextStyleHeader.copyWith(
                fontSize: 24,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage your clinic reviews from clients',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: kFontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: kFontSizeRegular,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Overview
        _buildRatingOverview(),
        
        const SizedBox(height: kSpacingLarge),
        
        // Filter Tabs
        _buildFilterTabs(),
        
        const SizedBox(height: kSpacingLarge),
        
        // Reviews List with pagination loading overlay
        Stack(
          children: [
            _buildReviewsList(),
            
            // Show loading overlay during pagination
            if (_isPaginationLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading page $_currentPage...',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Pagination
        if (_totalRatings > _itemsPerPage) ...[
          const SizedBox(height: kSpacingLarge),
          PaginationWidget(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalRatings,
            onPageChanged: _onPageChanged,
            isLoading: _isPaginationLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildRatingOverview() {
    if (_ratingStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _ratingStats!.hasRatings
          ? Row(
              children: [
                // Left side - Large rating display
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        _ratingStats!.formattedAverage,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _ratingStats!.averageRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.primary,
                            size: 28,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_ratingStats!.totalRatings} ${_ratingStats!.totalRatings == 1 ? 'review' : 'reviews'}',
                        style: TextStyle(
                          fontSize: kFontSizeRegular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 48),
                
                // Right side - Rating distribution
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      for (int stars = 5; stars >= 1; stars--)
                        _buildDistributionBar(stars),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(kSpacingLarge),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Reviews Yet',
                      style: TextStyle(
                        fontSize: kFontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your first review will appear here',
                      style: TextStyle(
                        fontSize: kFontSizeRegular,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDistributionBar(int stars) {
    final count = _ratingStats!.ratingDistribution[stars] ?? 0;
    final percentage = _ratingStats!.totalRatings > 0
        ? (count / _ratingStats!.totalRatings)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: kFontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Filled bar
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: kFontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Row(
        children: [
          _buildFilterTab('All', 0),
          for (int stars = 5; stars >= 1; stars--)
            _buildFilterTab('$stars ⭐', stars),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int filterValue) {
    final isSelected = _selectedFilter == filterValue;
    // Count from all ratings, not just current page
    final count = filterValue == 0
        ? _allRatings.length
        : _allRatings.where((r) => r.rating.round() == filterValue).length;

    return Expanded(
      child: InkWell(
        onTap: () => _onFilterChanged(filterValue),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: kFontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_ratings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(kSpacingXLarge),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No reviews found',
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _ratings.map((rating) => _buildReviewCard(rating)).toList(),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  Widget _buildReviewCard(ClinicRating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingMedium),
      padding: const EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(rating.userId),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          final userName = userData?['username'] ?? 'Anonymous User';
          final userPhotoUrl = userData?['photoUrl'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and rating
              Row(
                children: [
                  // User avatar or initial
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                        ? NetworkImage(userPhotoUrl)
                        : null,
                    child: userPhotoUrl == null || userPhotoUrl.isEmpty
                        ? _buildUserInitial(userName)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // User name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, yyyy').format(rating.createdAt),
                          style: TextStyle(
                            fontSize: kFontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Star rating
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Comment (if exists)
              if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  rating.comment!,
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInitial(String? userName) {
    final initial = userName?.isNotEmpty == true
        ? userName![0].toUpperCase()
        : 'U';
    
    return Text(
      initial,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
