import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/clinic_rating_model.dart';

/// Service for managing clinic ratings
class ClinicRatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a rating for a clinic after completing an appointment
  /// 
  /// This method:
  /// 1. Creates a new rating document in the `ratings` collection
  /// 2. Updates the appointment's `hasRated` field to true
  /// 3. Recalculates and updates the clinic's average rating
  /// 
  /// Uses a transaction to ensure data consistency
  static Future<bool> submitRating({
    required String clinicId,
    required String userId,
    required String appointmentId,
    required double rating,
    String? comment,
    String? userName,
    String? userPhotoUrl,
  }) async {
    try {
      print('📊 Submitting rating for clinic: $clinicId, appointment: $appointmentId');

      // Validate rating
      if (rating < 1.0 || rating > 5.0) {
        throw Exception('Rating must be between 1.0 and 5.0');
      }

      // Check if appointment exists and is completed
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final appointmentData = appointmentDoc.data()!;
      
      // Verify appointment belongs to user
      if (appointmentData['userId'] != userId) {
        throw Exception('Unauthorized: Appointment does not belong to user');
      }

      // Verify appointment is completed
      if (appointmentData['status'] != 'completed') {
        throw Exception('Can only rate completed appointments');
      }

      // Check if already rated
      if (appointmentData['hasRated'] == true) {
        throw Exception('Appointment has already been rated');
      }

      // Use transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // ⚠️ IMPORTANT: ALL READS MUST HAPPEN BEFORE ANY WRITES IN TRANSACTIONS
        
        // 1. Read clinic data first (before any writes)
        final clinicRef = _firestore.collection('clinics').doc(clinicId);
        final clinicSnapshot = await transaction.get(clinicRef);
        
        if (!clinicSnapshot.exists) {
          throw Exception('Clinic not found');
        }

        final clinicData = clinicSnapshot.data()!;
        final currentAverage = (clinicData['averageRating'] ?? 0.0).toDouble();
        final currentTotal = (clinicData['totalRatings'] ?? 0) as int;
        
        // Get current distribution
        final distributionData = clinicData['ratingDistribution'] as Map<String, dynamic>? ?? {};
        final currentDistribution = <int, int>{};
        for (int i = 1; i <= 5; i++) {
          currentDistribution[i] = (distributionData[i.toString()] ?? 0) as int;
        }

        // Calculate new average and update distribution
        final newTotal = currentTotal + 1;
        final newAverage = ((currentAverage * currentTotal) + rating) / newTotal;
        
        // Update distribution for the submitted rating
        final ratingStars = rating.round();
        currentDistribution[ratingStars] = (currentDistribution[ratingStars] ?? 0) + 1;
        
        // Convert distribution back to string keys for Firestore
        final newDistributionMap = <String, int>{};
        currentDistribution.forEach((star, count) {
          newDistributionMap[star.toString()] = count;
        });

        // NOW START WRITES (after all reads are done)
        
        // 2. Create rating document
        final ratingRef = _firestore.collection('ratings').doc();
        final now = DateTime.now();
        
        final ratingData = ClinicRating(
          clinicId: clinicId,
          userId: userId,
          appointmentId: appointmentId,
          rating: rating,
          comment: comment,
          createdAt: now,
          updatedAt: now,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
        );

        transaction.set(ratingRef, ratingData.toMap());
        print('✅ Created rating document: ${ratingRef.id}');

        // 3. Update appointment's hasRated field
        final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
        transaction.update(appointmentRef, {
          'hasRated': true,
          'ratedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Updated appointment hasRated field');

        // 4. Update clinic with new rating stats
        transaction.update(clinicRef, {
          'averageRating': newAverage,
          'totalRatings': newTotal,
          'ratingDistribution': newDistributionMap,
          'lastRatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Updated clinic rating: $newAverage ($newTotal reviews)');
      });

      print('✅ Rating submitted successfully');
      return true;
    } catch (e) {
      print('❌ Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get all ratings for a clinic
  static Future<List<ClinicRating>> getClinicRatings({
    required String clinicId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('ratings')
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => ClinicRating.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching clinic ratings: $e');
      return [];
    }
  }

  /// Get rating statistics for a clinic
  static Future<ClinicRatingStats> getClinicRatingStats(String clinicId) async {
    try {
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .get();

      if (!clinicDoc.exists) {
        return ClinicRatingStats.empty();
      }

      final data = clinicDoc.data()!;
      return ClinicRatingStats.fromMap(data);
    } catch (e) {
      print('❌ Error fetching clinic rating stats: $e');
      return ClinicRatingStats.empty();
    }
  }

  /// Stream rating statistics for real-time updates
  static Stream<ClinicRatingStats> streamClinicRatingStats(String clinicId) {
    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return ClinicRatingStats.empty();
          }
          return ClinicRatingStats.fromMap(doc.data()!);
        });
  }

  /// Check if user can rate an appointment
  static Future<bool> canRateAppointment(String appointmentId) async {
    try {
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        return false;
      }

      final data = appointmentDoc.data()!;
      final status = data['status'] as String;
      final hasRated = data['hasRated'] as bool? ?? false;

      return status == 'completed' && !hasRated;
    } catch (e) {
      print('❌ Error checking if can rate: $e');
      return false;
    }
  }

  /// Get user's rating for a specific clinic (if exists)
  static Future<ClinicRating?> getUserRatingForClinic({
    required String userId,
    required String clinicId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: userId)
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ClinicRating.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Error fetching user rating: $e');
      return null;
    }
  }

  /// Get rating for a specific appointment
  static Future<ClinicRating?> getRatingForAppointment(String appointmentId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ClinicRating.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Error fetching appointment rating: $e');
      return null;
    }
  }

  /// Update an existing rating (if user wants to change their review)
  static Future<bool> updateRating({
    required String ratingId,
    required String userId,
    double? newRating,
    String? newComment,
  }) async {
    try {
      final ratingRef = _firestore.collection('ratings').doc(ratingId);
      final ratingDoc = await ratingRef.get();

      if (!ratingDoc.exists) {
        throw Exception('Rating not found');
      }

      final ratingData = ratingDoc.data()!;
      
      // Verify user owns this rating
      if (ratingData['userId'] != userId) {
        throw Exception('Unauthorized: Rating does not belong to user');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newComment != null) {
        updateData['comment'] = newComment;
      }

      // If rating value changed, need to recalculate clinic average
      if (newRating != null && newRating != ratingData['rating']) {
        final oldRating = (ratingData['rating'] as num).toDouble();
        final clinicId = ratingData['clinicId'] as String;

        await _firestore.runTransaction((transaction) async {
          // Update rating document
          transaction.update(ratingRef, {
            'rating': newRating,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Recalculate clinic average
          final clinicRef = _firestore.collection('clinics').doc(clinicId);
          final clinicSnapshot = await transaction.get(clinicRef);
          
          if (clinicSnapshot.exists) {
            final clinicData = clinicSnapshot.data()!;
            final currentAverage = (clinicData['averageRating'] ?? 0.0).toDouble();
            final totalRatings = (clinicData['totalRatings'] ?? 0) as int;
            
            // Calculate new average by removing old rating and adding new one
            final sumWithoutOld = currentAverage * totalRatings - oldRating;
            final newAverage = (sumWithoutOld + newRating) / totalRatings;
            
            // Update distribution
            final distributionData = clinicData['ratingDistribution'] as Map<String, dynamic>? ?? {};
            final distribution = <int, int>{};
            for (int i = 1; i <= 5; i++) {
              distribution[i] = (distributionData[i.toString()] ?? 0) as int;
            }
            
            // Remove old rating from distribution
            final oldStars = oldRating.round();
            distribution[oldStars] = (distribution[oldStars] ?? 1) - 1;
            
            // Add new rating to distribution
            final newStars = newRating.round();
            distribution[newStars] = (distribution[newStars] ?? 0) + 1;
            
            // Convert back to string keys
            final newDistributionMap = <String, int>{};
            distribution.forEach((star, count) {
              newDistributionMap[star.toString()] = count;
            });

            transaction.update(clinicRef, {
              'averageRating': newAverage,
              'ratingDistribution': newDistributionMap,
            });
          }
        });
      } else if (newComment != null) {
        // Only comment changed, simple update
        await ratingRef.update(updateData);
      }

      print('✅ Rating updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating rating: $e');
      rethrow;
    }
  }

  /// Delete a rating (admin or user-initiated)
  static Future<bool> deleteRating({
    required String ratingId,
    required String userId,
    bool isAdmin = false,
  }) async {
    try {
      final ratingRef = _firestore.collection('ratings').doc(ratingId);
      final ratingDoc = await ratingRef.get();

      if (!ratingDoc.exists) {
        throw Exception('Rating not found');
      }

      final ratingData = ratingDoc.data()!;
      
      // Verify user owns this rating (unless admin)
      if (!isAdmin && ratingData['userId'] != userId) {
        throw Exception('Unauthorized: Rating does not belong to user');
      }

      final rating = (ratingData['rating'] as num).toDouble();
      final clinicId = ratingData['clinicId'] as String;
      final appointmentId = ratingData['appointmentId'] as String;

      await _firestore.runTransaction((transaction) async {
        // Delete rating document
        transaction.delete(ratingRef);

        // Update appointment hasRated back to false
        final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
        transaction.update(appointmentRef, {
          'hasRated': false,
        });

        // Recalculate clinic average
        final clinicRef = _firestore.collection('clinics').doc(clinicId);
        final clinicSnapshot = await transaction.get(clinicRef);
        
        if (clinicSnapshot.exists) {
          final clinicData = clinicSnapshot.data()!;
          final currentAverage = (clinicData['averageRating'] ?? 0.0).toDouble();
          final currentTotal = (clinicData['totalRatings'] ?? 0) as int;
          
          final newTotal = (currentTotal - 1).clamp(0, double.infinity).toInt();
          final newAverage = newTotal > 0
              ? ((currentAverage * currentTotal) - rating) / newTotal
              : 0.0;
          
          // Update distribution
          final distributionData = clinicData['ratingDistribution'] as Map<String, dynamic>? ?? {};
          final distribution = <int, int>{};
          for (int i = 1; i <= 5; i++) {
            distribution[i] = (distributionData[i.toString()] ?? 0) as int;
          }
          
          // Remove rating from distribution
          final ratingStars = rating.round();
          distribution[ratingStars] = (distribution[ratingStars] ?? 1) - 1;
          
          // Convert back to string keys
          final newDistributionMap = <String, int>{};
          distribution.forEach((star, count) {
            newDistributionMap[star.toString()] = count;
          });

          transaction.update(clinicRef, {
            'averageRating': newAverage,
            'totalRatings': newTotal,
            'ratingDistribution': newDistributionMap,
          });
        }
      });

      print('✅ Rating deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting rating: $e');
      rethrow;
    }
  }
}
