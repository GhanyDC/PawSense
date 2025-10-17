import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_logger.dart';

/// Service for Super Admin system-wide analytics
class SuperAdminAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for analytics data (15 minute TTL)
  static DateTime? _lastCacheTime;
  static Map<String, dynamic>? _cachedStats;
  static const _cacheDuration = Duration(minutes: 15);

  /// Get comprehensive system statistics
  static Future<SystemStats> getSystemStats(String period) async {
    try {
      // Check cache validity
      if (_cachedStats != null && 
          _lastCacheTime != null && 
          DateTime.now().difference(_lastCacheTime!) < _cacheDuration) {
        AppLogger.dashboard('Using cached system stats');
        return SystemStats.fromCache(_cachedStats!, period);
      }

      AppLogger.dashboard('Fetching fresh system stats for period: $period');

      final dateRange = _getDateRange(period);
      final previousDateRange = _getPreviousDateRange(period);

      // Fetch all statistics in parallel
      final results = await Future.wait([
        _getUserStatistics(dateRange, previousDateRange),
        _getClinicStatistics(dateRange, previousDateRange),
        _getAppointmentStatistics(dateRange, previousDateRange),
        _getAIUsageStatistics(dateRange, previousDateRange),
        _getPetStatistics(dateRange, previousDateRange),
        _getSystemAverageRating(),
      ]);

      final stats = SystemStats(
        userStats: results[0] as UserStats,
        clinicStats: results[1] as ClinicStats,
        appointmentStats: results[2] as AppointmentStats,
        aiUsageStats: results[3] as AIUsageStats,
        petStats: results[4] as PetStats,
        averageRating: results[5] as double,
        period: period,
        lastUpdated: DateTime.now(),
      );

      // Update cache
      _cachedStats = stats.toCache();
      _lastCacheTime = DateTime.now();

      return stats;
    } catch (e) {
      AppLogger.error('Error fetching system stats', error: e, tag: 'SuperAdminAnalyticsService');
      return SystemStats.empty(period);
    }
  }

  /// Get user statistics
  static Future<UserStats> _getUserStatistics(
    DateRange dateRange,
    DateRange previousDateRange,
  ) async {
    try {
      final usersQuery = await _firestore.collection('users').get();
      
      int totalUsers = 0;
      int currentNewUsers = 0;
      int previousNewUsers = 0;
      int mobileUsers = 0;
      int adminUsers = 0;
      int suspendedUsers = 0;

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final role = data['role'] as String?;
        final status = data['accountStatus'] as String?;

        totalUsers++;

        // Count new users in current period
        if (createdAt != null && 
            !createdAt.isBefore(dateRange.start) && 
            !createdAt.isAfter(dateRange.end)) {
          currentNewUsers++;
        }

        // Count new users in previous period
        if (createdAt != null && 
            !createdAt.isBefore(previousDateRange.start) && 
            !createdAt.isAfter(previousDateRange.end)) {
          previousNewUsers++;
        }

        // Count by role
        if (role == 'user' || role == 'mobile') {
          mobileUsers++;
        } else if (role == 'admin') {
          adminUsers++;
        }

        // Count suspended
        if (status == 'suspended') {
          suspendedUsers++;
        }
      }

      final growthPercentage = _calculatePercentageChange(
        previousNewUsers,
        currentNewUsers,
      );

      return UserStats(
        totalUsers: totalUsers,
        newUsers: currentNewUsers,
        growthPercentage: growthPercentage,
        mobileUsers: mobileUsers,
        adminUsers: adminUsers,
        suspendedUsers: suspendedUsers,
      );
    } catch (e) {
      AppLogger.error('Error getting user statistics', error: e, tag: 'SuperAdminAnalyticsService');
      return UserStats.empty();
    }
  }

  /// Get clinic statistics
  static Future<ClinicStats> _getClinicStatistics(
    DateRange dateRange,
    DateRange previousDateRange,
  ) async {
    try {
      final registrationsQuery = await _firestore
          .collection('clinic_registrations')
          .get();

      int totalClinics = 0;
      int activeClinics = 0;
      int pendingClinics = 0;
      int rejectedClinics = 0;
      int suspendedClinics = 0;
      int currentNewClinics = 0;
      int previousNewClinics = 0;

      for (final doc in registrationsQuery.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        totalClinics++;

        // Count by status
        if (status == 'approved') {
          activeClinics++;
        } else if (status == 'pending') {
          pendingClinics++;
        } else if (status == 'rejected') {
          rejectedClinics++;
        } else if (status == 'suspended') {
          suspendedClinics++;
        }

        // Count new clinics in current period
        if (createdAt != null && 
            !createdAt.isBefore(dateRange.start) && 
            !createdAt.isAfter(dateRange.end)) {
          currentNewClinics++;
        }

        // Count new clinics in previous period
        if (createdAt != null && 
            !createdAt.isBefore(previousDateRange.start) && 
            !createdAt.isAfter(previousDateRange.end)) {
          previousNewClinics++;
        }
      }

      final growthPercentage = _calculatePercentageChange(
        previousNewClinics,
        currentNewClinics,
      );

      return ClinicStats(
        totalClinics: totalClinics,
        activeClinics: activeClinics,
        pendingClinics: pendingClinics,
        rejectedClinics: rejectedClinics,
        suspendedClinics: suspendedClinics,
        growthPercentage: growthPercentage,
      );
    } catch (e) {
      AppLogger.error('Error getting clinic statistics', error: e, tag: 'SuperAdminAnalyticsService');
      return ClinicStats.empty();
    }
  }

  /// Get appointment statistics
  static Future<AppointmentStats> _getAppointmentStatistics(
    DateRange dateRange,
    DateRange previousDateRange,
  ) async {
    try {
      final appointmentsQuery = await _firestore
          .collection('appointments')
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(previousDateRange.start))
          .get();

      int currentTotal = 0;
      int previousTotal = 0;
      int completedCount = 0;
      int pendingCount = 0;
      int cancelledCount = 0;

      for (final doc in appointmentsQuery.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp?)?.toDate();
        final status = data['status'] as String?;

        if (appointmentDate == null) continue;

        // Count in current period
        if (!appointmentDate.isBefore(dateRange.start) && 
            !appointmentDate.isAfter(dateRange.end)) {
          currentTotal++;

          // Count by status
          if (status == 'completed') {
            completedCount++;
          } else if (status == 'pending' || status == 'accepted') {
            pendingCount++;
          } else if (status == 'cancelled') {
            cancelledCount++;
          }
        }

        // Count in previous period
        if (!appointmentDate.isBefore(previousDateRange.start) && 
            !appointmentDate.isAfter(previousDateRange.end)) {
          previousTotal++;
        }
      }

      final growthPercentage = _calculatePercentageChange(
        previousTotal,
        currentTotal,
      );

      final completionRate = currentTotal > 0 
          ? (completedCount / currentTotal * 100) 
          : 0.0;

      return AppointmentStats(
        totalAppointments: currentTotal,
        completedAppointments: completedCount,
        pendingAppointments: pendingCount,
        cancelledAppointments: cancelledCount,
        growthPercentage: growthPercentage,
        completionRate: completionRate,
      );
    } catch (e) {
      AppLogger.error('Error getting appointment statistics', error: e, tag: 'SuperAdminAnalyticsService');
      return AppointmentStats.empty();
    }
  }

  /// Get AI usage statistics
  static Future<AIUsageStats> _getAIUsageStatistics(
    DateRange dateRange,
    DateRange previousDateRange,
  ) async {
    try {
      final assessmentsQuery = await _firestore
          .collection('assessment_results')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(previousDateRange.start))
          .get();

      int currentScans = 0;
      int previousScans = 0;
      int highConfidenceScans = 0;
      final diseaseMap = <String, int>{};

      for (final doc in assessmentsQuery.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        
        if (timestamp == null) continue;

        // Count in current period
        if (!timestamp.isBefore(dateRange.start) && 
            !timestamp.isAfter(dateRange.end)) {
          currentScans++;

          // Count high confidence scans and track diseases
          final analysisResults = data['analysisResults'] as List?;
          if (analysisResults != null && analysisResults.isNotEmpty) {
            for (final result in analysisResults) {
              if (result is Map<String, dynamic>) {
                final condition = result['condition'] as String?;
                final percentage = result['percentage'] as num?;

                if (condition != null && percentage != null) {
                  if (percentage > 70) {
                    highConfidenceScans++;
                  }
                  if (percentage > 50) {
                    diseaseMap[condition] = (diseaseMap[condition] ?? 0) + 1;
                  }
                }
              }
            }
          }
        }

        // Count in previous period
        if (!timestamp.isBefore(previousDateRange.start) && 
            !timestamp.isAfter(previousDateRange.end)) {
          previousScans++;
        }
      }

      final growthPercentage = _calculatePercentageChange(
        previousScans,
        currentScans,
      );

      final averageConfidence = currentScans > 0
          ? (highConfidenceScans / currentScans * 100)
          : 0.0;

      // Get top 5 diseases
      final sortedDiseases = diseaseMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topDiseases = sortedDiseases.take(5).map((e) => e.key).toList();

      return AIUsageStats(
        totalScans: currentScans,
        highConfidenceScans: highConfidenceScans,
        growthPercentage: growthPercentage,
        averageConfidence: averageConfidence,
        topDetectedDiseases: topDiseases,
      );
    } catch (e) {
      AppLogger.error('Error getting AI usage statistics', error: e, tag: 'SuperAdminAnalyticsService');
      return AIUsageStats.empty();
    }
  }

  /// Get pet statistics
  static Future<PetStats> _getPetStatistics(
    DateRange dateRange,
    DateRange previousDateRange,
  ) async {
    try {
      final petsQuery = await _firestore.collection('pets').get();

      int totalPets = 0;
      int currentNewPets = 0;
      int previousNewPets = 0;
      final breedMap = <String, int>{};

      for (final doc in petsQuery.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final breed = data['breed'] as String?;

        totalPets++;

        // Count new pets in current period
        if (createdAt != null && 
            !createdAt.isBefore(dateRange.start) && 
            !createdAt.isAfter(dateRange.end)) {
          currentNewPets++;
        }

        // Count new pets in previous period
        if (createdAt != null && 
            !createdAt.isBefore(previousDateRange.start) && 
            !createdAt.isAfter(previousDateRange.end)) {
          previousNewPets++;
        }

        // Track breed distribution
        if (breed != null && breed.isNotEmpty) {
          breedMap[breed] = (breedMap[breed] ?? 0) + 1;
        }
      }

      final growthPercentage = _calculatePercentageChange(
        previousNewPets,
        currentNewPets,
      );

      // Get top 5 breeds
      final sortedBreeds = breedMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topBreeds = sortedBreeds.take(5).map((e) => e.key).toList();

      return PetStats(
        totalPets: totalPets,
        newPets: currentNewPets,
        growthPercentage: growthPercentage,
        topBreeds: topBreeds,
      );
    } catch (e) {
      AppLogger.error('Error getting pet statistics', error: e, tag: 'SuperAdminAnalyticsService');
      return PetStats.empty();
    }
  }

  /// Get system average rating
  static Future<double> _getSystemAverageRating() async {
    try {
      final ratingsQuery = await _firestore
          .collection('clinicRatings')
          .get();

      if (ratingsQuery.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      int count = 0;

      for (final doc in ratingsQuery.docs) {
        final data = doc.data();
        final rating = data['rating'] as num?;
        if (rating != null) {
          totalRating += rating.toDouble();
          count++;
        }
      }

      return count > 0 ? totalRating / count : 0.0;
    } catch (e) {
      AppLogger.error('Error getting system average rating', error: e, tag: 'SuperAdminAnalyticsService');
      return 0.0;
    }
  }

  /// Get user growth trend data
  static Future<List<TimeSeriesData>> getUserGrowthTrend(String period) async {
    try {
      final usersQuery = await _firestore.collection('users').get();
      
      final dataPoints = <DateTime, int>{};
      final dateRange = _getDateRange(period);
      
      // Initialize all data points with 0
      DateTime current = dateRange.start;
      while (!current.isAfter(dateRange.end)) {
        dataPoints[DateTime(current.year, current.month, current.day)] = 0;
        current = current.add(Duration(days: 1));
      }

      // Count users by registration date
      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        if (createdAt != null && 
            !createdAt.isBefore(dateRange.start) && 
            !createdAt.isAfter(dateRange.end)) {
          final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
          dataPoints[date] = (dataPoints[date] ?? 0) + 1;
        }
      }

      // Convert to cumulative count
      int cumulative = 0;
      final sortedDates = dataPoints.keys.toList()..sort();
      
      return sortedDates.map((date) {
        cumulative += dataPoints[date] ?? 0;
        return TimeSeriesData(date: date, value: cumulative.toDouble());
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting user growth trend', error: e, tag: 'SuperAdminAnalyticsService');
      return [];
    }
  }

  /// Get appointment volume trend
  static Future<List<TimeSeriesData>> getAppointmentVolumeTrend(String period) async {
    try {
      final dateRange = _getDateRange(period);
      
      final appointmentsQuery = await _firestore
          .collection('appointments')
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .get();

      final dataPoints = <DateTime, int>{};
      
      // Initialize all data points with 0
      DateTime current = dateRange.start;
      while (!current.isAfter(dateRange.end)) {
        dataPoints[DateTime(current.year, current.month, current.day)] = 0;
        current = current.add(Duration(days: 1));
      }

      // Count appointments by date
      for (final doc in appointmentsQuery.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp?)?.toDate();
        
        if (appointmentDate != null) {
          final date = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
          dataPoints[date] = (dataPoints[date] ?? 0) + 1;
        }
      }

      final sortedDates = dataPoints.keys.toList()..sort();
      
      return sortedDates.map((date) {
        return TimeSeriesData(date: date, value: (dataPoints[date] ?? 0).toDouble());
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting appointment volume trend', error: e, tag: 'SuperAdminAnalyticsService');
      return [];
    }
  }

  /// Get clinic performance data
  static Future<List<ClinicPerformanceData>> getTopClinicsPerformance({int limit = 5}) async {
    try {
      final clinicsQuery = await _firestore.collection('clinic_registrations').get();
      final performanceList = <ClinicPerformanceData>[];

      for (final doc in clinicsQuery.docs) {
        final data = doc.data();
        final clinicId = doc.id;
        final clinicName = data['clinicName'] as String? ?? 'Unknown Clinic';
        final status = data['status'] as String?;

        if (status != 'approved') continue;

        // Get appointment count
        final appointmentsQuery = await _firestore
            .collection('appointments')
            .where('clinicId', isEqualTo: clinicId)
            .get();
        final appointmentCount = appointmentsQuery.docs.length;

        // Get average rating
        final ratingsQuery = await _firestore
            .collection('clinicRatings')
            .where('clinicId', isEqualTo: clinicId)
            .get();

        double averageRating = 0.0;
        if (ratingsQuery.docs.isNotEmpty) {
          double totalRating = 0.0;
          for (final ratingDoc in ratingsQuery.docs) {
            final ratingData = ratingDoc.data();
            final rating = ratingData['rating'] as num?;
            if (rating != null) {
              totalRating += rating.toDouble();
            }
          }
          averageRating = totalRating / ratingsQuery.docs.length;
        }

        // Calculate performance score (weighted: 70% rating, 30% appointment volume)
        final normalizedAppointments = appointmentCount / 100; // Normalize to 0-1 scale
        final performanceScore = (averageRating * 0.7) + (normalizedAppointments.clamp(0, 1) * 5 * 0.3);

        performanceList.add(ClinicPerformanceData(
          clinicName: clinicName,
          appointmentCount: appointmentCount,
          rating: averageRating,
          performanceScore: performanceScore,
        ));
      }

      // Sort by performance score and take top N
      performanceList.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
      return performanceList.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting top clinics performance', error: e, tag: 'SuperAdminAnalyticsService');
      return [];
    }
  }

  /// Get disease distribution data
  static Future<List<DiseaseDistributionData>> getDiseaseDistribution({int limit = 5}) async {
    try {
      final assessmentsQuery = await _firestore
          .collection('assessment_results')
          .get();

      final diseaseMap = <String, int>{};

      for (final doc in assessmentsQuery.docs) {
        final data = doc.data();
        final analysisResults = data['analysisResults'] as List?;

        if (analysisResults != null && analysisResults.isNotEmpty) {
          for (final result in analysisResults) {
            if (result is Map<String, dynamic>) {
              final condition = result['condition'] as String?;
              final percentage = result['percentage'] as num?;

              // Only count conditions with confidence > 50%
              if (condition != null && percentage != null && percentage > 50) {
                diseaseMap[condition] = (diseaseMap[condition] ?? 0) + 1;
              }
            }
          }
        }
      }

      // Sort by count and take top N
      final sortedDiseases = diseaseMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topDiseases = sortedDiseases.take(limit).toList();

      // Calculate total for percentage
      final total = topDiseases.fold<int>(0, (sum, entry) => sum + entry.value);

      return topDiseases.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        return DiseaseDistributionData(
          diseaseName: entry.key,
          count: entry.value,
          percentage: percentage,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting disease distribution', error: e, tag: 'SuperAdminAnalyticsService');
      return [];
    }
  }

  /// Clear analytics cache (useful for manual refresh)
  static void clearCache() {
    _cachedStats = null;
    _lastCacheTime = null;
    AppLogger.dashboard('Analytics cache cleared');
  }

  /// Helper: Calculate percentage change
  static double _calculatePercentageChange(num oldValue, num newValue) {
    if (oldValue == 0) {
      return newValue > 0 ? 100.0 : 0.0;
    }
    return ((newValue - oldValue) / oldValue * 100);
  }

  /// Helper: Get date range for period
  static DateRange _getDateRange(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period.toLowerCase()) {
      case 'last 7 days':
        startDate = now.subtract(Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        break;
      case 'last 30 days':
        startDate = now.subtract(Duration(days: 29));
        startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        break;
      case 'last 90 days':
        startDate = now.subtract(Duration(days: 89));
        startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        break;
      case 'last year':
        startDate = now.subtract(Duration(days: 364));
        startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        break;
      default:
        startDate = now.subtract(Duration(days: 29));
        startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    }

    return DateRange(start: startDate, end: endDate);
  }

  /// Helper: Get previous date range for comparison
  static DateRange _getPreviousDateRange(String period) {
    final currentRange = _getDateRange(period);
    final duration = currentRange.end.difference(currentRange.start);
    
    final previousEnd = currentRange.start.subtract(Duration(seconds: 1));
    final previousStart = previousEnd.subtract(duration);

    return DateRange(
      start: DateTime(previousStart.year, previousStart.month, previousStart.day, 0, 0, 0),
      end: DateTime(previousEnd.year, previousEnd.month, previousEnd.day, 23, 59, 59),
    );
  }
}

// Data Models

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class SystemStats {
  final UserStats userStats;
  final ClinicStats clinicStats;
  final AppointmentStats appointmentStats;
  final AIUsageStats aiUsageStats;
  final PetStats petStats;
  final double averageRating;
  final String period;
  final DateTime lastUpdated;

  SystemStats({
    required this.userStats,
    required this.clinicStats,
    required this.appointmentStats,
    required this.aiUsageStats,
    required this.petStats,
    required this.averageRating,
    required this.period,
    required this.lastUpdated,
  });

  factory SystemStats.empty(String period) {
    return SystemStats(
      userStats: UserStats.empty(),
      clinicStats: ClinicStats.empty(),
      appointmentStats: AppointmentStats.empty(),
      aiUsageStats: AIUsageStats.empty(),
      petStats: PetStats.empty(),
      averageRating: 0.0,
      period: period,
      lastUpdated: DateTime.now(),
    );
  }

  factory SystemStats.fromCache(Map<String, dynamic> cache, String period) {
    return SystemStats(
      userStats: UserStats.fromMap(cache['userStats']),
      clinicStats: ClinicStats.fromMap(cache['clinicStats']),
      appointmentStats: AppointmentStats.fromMap(cache['appointmentStats']),
      aiUsageStats: AIUsageStats.fromMap(cache['aiUsageStats']),
      petStats: PetStats.fromMap(cache['petStats']),
      averageRating: cache['averageRating'] ?? 0.0,
      period: period,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'userStats': userStats.toMap(),
      'clinicStats': clinicStats.toMap(),
      'appointmentStats': appointmentStats.toMap(),
      'aiUsageStats': aiUsageStats.toMap(),
      'petStats': petStats.toMap(),
      'averageRating': averageRating,
    };
  }
}

class UserStats {
  final int totalUsers;
  final int newUsers;
  final double growthPercentage;
  final int mobileUsers;
  final int adminUsers;
  final int suspendedUsers;

  UserStats({
    required this.totalUsers,
    required this.newUsers,
    required this.growthPercentage,
    required this.mobileUsers,
    required this.adminUsers,
    required this.suspendedUsers,
  });

  factory UserStats.empty() {
    return UserStats(
      totalUsers: 0,
      newUsers: 0,
      growthPercentage: 0.0,
      mobileUsers: 0,
      adminUsers: 0,
      suspendedUsers: 0,
    );
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalUsers: map['totalUsers'] ?? 0,
      newUsers: map['newUsers'] ?? 0,
      growthPercentage: map['growthPercentage'] ?? 0.0,
      mobileUsers: map['mobileUsers'] ?? 0,
      adminUsers: map['adminUsers'] ?? 0,
      suspendedUsers: map['suspendedUsers'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'newUsers': newUsers,
      'growthPercentage': growthPercentage,
      'mobileUsers': mobileUsers,
      'adminUsers': adminUsers,
      'suspendedUsers': suspendedUsers,
    };
  }
}

class ClinicStats {
  final int totalClinics;
  final int activeClinics;
  final int pendingClinics;
  final int rejectedClinics;
  final int suspendedClinics;
  final double growthPercentage;

  ClinicStats({
    required this.totalClinics,
    required this.activeClinics,
    required this.pendingClinics,
    required this.rejectedClinics,
    required this.suspendedClinics,
    required this.growthPercentage,
  });

  factory ClinicStats.empty() {
    return ClinicStats(
      totalClinics: 0,
      activeClinics: 0,
      pendingClinics: 0,
      rejectedClinics: 0,
      suspendedClinics: 0,
      growthPercentage: 0.0,
    );
  }

  factory ClinicStats.fromMap(Map<String, dynamic> map) {
    return ClinicStats(
      totalClinics: map['totalClinics'] ?? 0,
      activeClinics: map['activeClinics'] ?? 0,
      pendingClinics: map['pendingClinics'] ?? 0,
      rejectedClinics: map['rejectedClinics'] ?? 0,
      suspendedClinics: map['suspendedClinics'] ?? 0,
      growthPercentage: map['growthPercentage'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalClinics': totalClinics,
      'activeClinics': activeClinics,
      'pendingClinics': pendingClinics,
      'rejectedClinics': rejectedClinics,
      'suspendedClinics': suspendedClinics,
      'growthPercentage': growthPercentage,
    };
  }
}

class AppointmentStats {
  final int totalAppointments;
  final int completedAppointments;
  final int pendingAppointments;
  final int cancelledAppointments;
  final double growthPercentage;
  final double completionRate;

  AppointmentStats({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.pendingAppointments,
    required this.cancelledAppointments,
    required this.growthPercentage,
    required this.completionRate,
  });

  factory AppointmentStats.empty() {
    return AppointmentStats(
      totalAppointments: 0,
      completedAppointments: 0,
      pendingAppointments: 0,
      cancelledAppointments: 0,
      growthPercentage: 0.0,
      completionRate: 0.0,
    );
  }

  factory AppointmentStats.fromMap(Map<String, dynamic> map) {
    return AppointmentStats(
      totalAppointments: map['totalAppointments'] ?? 0,
      completedAppointments: map['completedAppointments'] ?? 0,
      pendingAppointments: map['pendingAppointments'] ?? 0,
      cancelledAppointments: map['cancelledAppointments'] ?? 0,
      growthPercentage: map['growthPercentage'] ?? 0.0,
      completionRate: map['completionRate'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAppointments': totalAppointments,
      'completedAppointments': completedAppointments,
      'pendingAppointments': pendingAppointments,
      'cancelledAppointments': cancelledAppointments,
      'growthPercentage': growthPercentage,
      'completionRate': completionRate,
    };
  }
}

class AIUsageStats {
  final int totalScans;
  final int highConfidenceScans;
  final double growthPercentage;
  final double averageConfidence;
  final List<String> topDetectedDiseases;

  AIUsageStats({
    required this.totalScans,
    required this.highConfidenceScans,
    required this.growthPercentage,
    required this.averageConfidence,
    required this.topDetectedDiseases,
  });

  factory AIUsageStats.empty() {
    return AIUsageStats(
      totalScans: 0,
      highConfidenceScans: 0,
      growthPercentage: 0.0,
      averageConfidence: 0.0,
      topDetectedDiseases: [],
    );
  }

  factory AIUsageStats.fromMap(Map<String, dynamic> map) {
    return AIUsageStats(
      totalScans: map['totalScans'] ?? 0,
      highConfidenceScans: map['highConfidenceScans'] ?? 0,
      growthPercentage: map['growthPercentage'] ?? 0.0,
      averageConfidence: map['averageConfidence'] ?? 0.0,
      topDetectedDiseases: List<String>.from(map['topDetectedDiseases'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalScans': totalScans,
      'highConfidenceScans': highConfidenceScans,
      'growthPercentage': growthPercentage,
      'averageConfidence': averageConfidence,
      'topDetectedDiseases': topDetectedDiseases,
    };
  }
}

class PetStats {
  final int totalPets;
  final int newPets;
  final double growthPercentage;
  final List<String> topBreeds;

  PetStats({
    required this.totalPets,
    required this.newPets,
    required this.growthPercentage,
    required this.topBreeds,
  });

  factory PetStats.empty() {
    return PetStats(
      totalPets: 0,
      newPets: 0,
      growthPercentage: 0.0,
      topBreeds: [],
    );
  }

  factory PetStats.fromMap(Map<String, dynamic> map) {
    return PetStats(
      totalPets: map['totalPets'] ?? 0,
      newPets: map['newPets'] ?? 0,
      growthPercentage: map['growthPercentage'] ?? 0.0,
      topBreeds: List<String>.from(map['topBreeds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPets': totalPets,
      'newPets': newPets,
      'growthPercentage': growthPercentage,
      'topBreeds': topBreeds,
    };
  }
}

class TimeSeriesData {
  final DateTime date;
  final double value;

  TimeSeriesData({required this.date, required this.value});
}

class ClinicPerformanceData {
  final String clinicName;
  final int appointmentCount;
  final double rating;
  final double performanceScore;

  ClinicPerformanceData({
    required this.clinicName,
    required this.appointmentCount,
    required this.rating,
    required this.performanceScore,
  });
}

class DiseaseDistributionData {
  final String diseaseName;
  final int count;
  final double percentage;

  DiseaseDistributionData({
    required this.diseaseName,
    required this.count,
    required this.percentage,
  });
}
