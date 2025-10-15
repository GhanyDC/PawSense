import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for clinic ratings submitted by users after completing appointments
class ClinicRating {
  final String? id;
  final String clinicId;
  final String userId;
  final String appointmentId;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional user info for display purposes
  final String? userName;
  final String? userPhotoUrl;

  ClinicRating({
    this.id,
    required this.clinicId,
    required this.userId,
    required this.appointmentId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userPhotoUrl,
  });

  /// Create ClinicRating from Firestore document
  factory ClinicRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClinicRating.fromMap(data, doc.id);
  }

  /// Create ClinicRating from map with document ID
  factory ClinicRating.fromMap(Map<String, dynamic> data, String id) {
    return ClinicRating(
      id: id,
      clinicId: data['clinicId'] ?? '',
      userId: data['userId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: data['userName'],
      userPhotoUrl: data['userPhotoUrl'],
    );
  }

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'clinicId': clinicId,
      'userId': userId,
      'appointmentId': appointmentId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
    };
  }

  /// Create a copy with updated fields
  ClinicRating copyWith({
    String? id,
    String? clinicId,
    String? userId,
    String? appointmentId,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userPhotoUrl,
  }) {
    return ClinicRating(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
    );
  }

  /// Get star rating as integer (for display)
  int get starRating => rating.round();

  /// Check if rating has a comment
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Format timestamp for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

/// Aggregated rating statistics for a clinic
class ClinicRatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // star (1-5) -> count
  
  ClinicRatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  /// Create empty stats
  factory ClinicRatingStats.empty() {
    return ClinicRatingStats(
      averageRating: 0.0,
      totalRatings: 0,
      ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }

  /// Create from Firestore data
  factory ClinicRatingStats.fromMap(Map<String, dynamic> data) {
    final distributionData = data['ratingDistribution'] as Map<String, dynamic>? ?? {};
    final distribution = <int, int>{};
    
    for (int i = 1; i <= 5; i++) {
      distribution[i] = (distributionData[i.toString()] ?? 0) as int;
    }
    
    return ClinicRatingStats(
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: (data['totalRatings'] ?? 0) as int,
      ratingDistribution: distribution,
    );
  }

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    final distributionMap = <String, int>{};
    ratingDistribution.forEach((star, count) {
      distributionMap[star.toString()] = count;
    });
    
    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': distributionMap,
    };
  }

  /// Get percentage for each star rating
  double getPercentage(int star) {
    if (totalRatings == 0) return 0.0;
    final count = ratingDistribution[star] ?? 0;
    return (count / totalRatings) * 100;
  }

  /// Format average rating for display (e.g., "4.5")
  String get formattedAverage => averageRating.toStringAsFixed(1);

  /// Check if clinic has any ratings
  bool get hasRatings => totalRatings > 0;

  /// Get display text (e.g., "4.5 (25 reviews)")
  String get displayText {
    if (totalRatings == 0) return 'No reviews yet';
    return '$formattedAverage (${totalRatings} ${totalRatings == 1 ? 'review' : 'reviews'})';
  }
}
