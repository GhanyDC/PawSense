# Clinic Rating System Implementation Guide

## 📊 Overview

PawSense now includes a comprehensive clinic rating system that allows users to rate veterinary clinics after completing appointments. This system ensures data integrity through Firestore transactions and provides a seamless user experience.

## 🗄️ Firestore Structure

### Collections

#### 1. `ratings` Collection
```javascript
ratings/{ratingId} {
  "clinicId": "clinic_123",
  "userId": "user_456",
  "appointmentId": "appointment_789",
  "rating": 4.5,               // Float from 1.0 to 5.0
  "comment": "Great service!",  // Optional text review
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "userName": "John Doe",       // For display purposes
  "userPhotoUrl": "https://..." // Optional user photo
}
```

**Indexes Required:**
- `clinicId` (ascending) + `createdAt` (descending)
- `userId` (ascending) + `clinicId` (ascending)
- `appointmentId` (ascending)

#### 2. `appointments` Collection (Updated)
```javascript
appointments/{appointmentId} {
  // ... existing fields ...
  "hasRated": false,           // NEW: Boolean flag
  "ratedAt": Timestamp,        // NEW: When rating was submitted
  "status": "completed"        // Must be "completed" to allow rating
}
```

#### 3. `clinics` Collection (Updated)
```javascript
clinics/{clinicId} {
  // ... existing fields ...
  "averageRating": 4.6,        // NEW: Calculated average
  "totalRatings": 25,          // NEW: Total number of ratings
  "ratingDistribution": {      // NEW: Count per star rating
    "1": 0,
    "2": 1,
    "3": 3,
    "4": 8,
    "5": 13
  },
  "lastRatedAt": Timestamp     // NEW: Last rating timestamp
}
```

## 🔄 Rating Flow

### User Journey

```
1. User completes appointment
   ↓
2. Appointment status changes to "completed"
   ↓
3. System checks hasRated = false
   ↓
4. "Rate this Clinic" button appears
   ↓
5. User taps → Rating modal opens
   ↓
6. User selects stars (1-5) and optional comment
   ↓
7. User submits rating
   ↓
8. Transaction executes:
   - Create rating document
   - Update appointment.hasRated = true
   - Recalculate clinic average rating
   ↓
9. Success message shown
   ↓
10. Rating badge appears on clinic
```

### Transaction Logic

The `submitRating()` method uses a Firestore transaction to ensure:
1. **Atomicity**: All operations succeed or all fail
2. **Consistency**: Clinic average always matches rating count
3. **Isolation**: Concurrent ratings don't corrupt data

```dart
await _firestore.runTransaction((transaction) async {
  // 1. Create rating document
  transaction.set(ratingRef, ratingData);
  
  // 2. Update appointment
  transaction.update(appointmentRef, {'hasRated': true});
  
  // 3. Recalculate clinic average
  final newAverage = ((oldAverage * oldTotal) + newRating) / newTotal;
  transaction.update(clinicRef, {
    'averageRating': newAverage,
    'totalRatings': newTotal,
    'ratingDistribution': updatedDistribution,
  });
});
```

## 📱 UI Components

### 1. RateClinicModal
**Purpose**: Collect rating from user  
**Location**: `lib/core/widgets/shared/rating/rate_clinic_modal.dart`

**Usage:**
```dart
await RateClinicModal.show(
  context: context,
  clinicId: 'clinic_123',
  clinicName: 'Happy Paws Veterinary',
  userId: currentUser.uid,
  appointmentId: 'appointment_789',
  user: currentUser,
  onRatingSubmitted: () {
    // Refresh UI
  },
);
```

**Features:**
- Interactive 5-star rating selector
- Optional comment field (500 char limit)
- Real-time rating label (Poor → Excellent)
- Loading state during submission
- Error handling with user feedback

### 2. Rating Display Widgets
**Location**: `lib/core/widgets/shared/rating/rating_display_widgets.dart`

#### ClinicRatingDisplay
Compact display for clinic cards:
```dart
ClinicRatingDisplay(
  stats: ratingStats,
  starSize: 16,
  showReviewCount: true,
)
// Output: ★ 4.5 (25)
```

#### StarRatingDisplay
Full star visualization:
```dart
StarRatingDisplay(
  rating: 4.5,
  size: 20,
)
// Output: ★★★★☆ (4.5 stars filled)
```

#### RatingBadge
Compact badge for thumbnails:
```dart
RatingBadge(
  rating: 4.5,
  reviewCount: 25,
)
// Output: [★ 4.5 (25)] in colored badge
```

#### RatingDistributionWidget
Bar chart showing distribution:
```dart
RatingDistributionWidget(
  stats: ratingStats,
)
// Output:
// 5★ ████████████████ 13
// 4★ ████████ 8
// 3★ ███ 3
// 2★ █ 1
// 1★  0
```

## 🔧 Service Layer

### ClinicRatingService
**Location**: `lib/core/services/clinic/clinic_rating_service.dart`

#### Key Methods:

**Submit Rating:**
```dart
final success = await ClinicRatingService.submitRating(
  clinicId: 'clinic_123',
  userId: 'user_456',
  appointmentId: 'appointment_789',
  rating: 4.5,
  comment: 'Excellent care!',
  userName: 'John Doe',
  userPhotoUrl: 'https://...',
);
```

**Get Clinic Ratings:**
```dart
final ratings = await ClinicRatingService.getClinicRatings(
  clinicId: 'clinic_123',
  limit: 20,
);
```

**Get Rating Statistics:**
```dart
final stats = await ClinicRatingService.getClinicRatingStats('clinic_123');
print(stats.averageRating);    // 4.6
print(stats.totalRatings);     // 25
print(stats.displayText);      // "4.6 (25 reviews)"
```

**Stream Real-time Stats:**
```dart
StreamBuilder<ClinicRatingStats>(
  stream: ClinicRatingService.streamClinicRatingStats('clinic_123'),
  builder: (context, snapshot) {
    final stats = snapshot.data;
    return ClinicRatingDisplay(stats: stats);
  },
)
```

**Check if Can Rate:**
```dart
final canRate = await ClinicRatingService.canRateAppointment('appointment_789');
if (canRate) {
  // Show "Rate Clinic" button
}
```

**Update Rating:**
```dart
await ClinicRatingService.updateRating(
  ratingId: 'rating_123',
  userId: 'user_456',
  newRating: 5.0,
  newComment: 'Updated comment',
);
```

**Delete Rating:**
```dart
await ClinicRatingService.deleteRating(
  ratingId: 'rating_123',
  userId: 'user_456',
  isAdmin: false,
);
```

## 💻 Integration Examples

### Example 1: Show Rating Button on Completed Appointment

**In Appointment History Widget:**
```dart
// In your appointment card widget
if (appointment.status == AppointmentStatus.completed && 
    appointment.hasRated != true) {
  ElevatedButton.icon(
    onPressed: () async {
      final success = await RateClinicModal.show(
        context: context,
        clinicId: appointment.clinicId,
        clinicName: appointment.serviceName,
        userId: currentUser.uid,
        appointmentId: appointment.id!,
        user: currentUser,
        onRatingSubmitted: () {
          // Refresh appointment list
          setState(() {});
        },
      );
      
      if (success == true) {
        // Update local appointment object
        appointment = appointment.copyWith(hasRated: true);
      },
    },
    icon: Icon(Icons.star),
    label: Text('Rate this Clinic'),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
    ),
  )
}
```

### Example 2: Display Rating on Clinic Card

**In Nearby Clinics Widget:**
```dart
class ClinicCard extends StatelessWidget {
  final String clinicId;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClinicRatingStats>(
      stream: ClinicRatingService.streamClinicRatingStats(clinicId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final stats = snapshot.data!;
        
        return Card(
          child: Column(
            children: [
              // ... clinic info ...
              
              // Rating display
              ClinicRatingDisplay(
                stats: stats,
                starSize: 18,
                showReviewCount: true,
              ),
              
              // Or use badge format
              RatingBadge(
                rating: stats.averageRating,
                reviewCount: stats.totalRatings,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Example 3: Clinic Profile Page with Reviews

**Full Review Page:**
```dart
class ClinicReviewsPage extends StatefulWidget {
  final String clinicId;
  
  @override
  _ClinicReviewsPageState createState() => _ClinicReviewsPageState();
}

class _ClinicReviewsPageState extends State<ClinicReviewsPage> {
  ClinicRatingStats? _stats;
  List<ClinicRating> _ratings = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final stats = await ClinicRatingService.getClinicRatingStats(widget.clinicId);
    final ratings = await ClinicRatingService.getClinicRatings(
      clinicId: widget.clinicId,
      limit: 20,
    );
    
    setState(() {
      _stats = stats;
      _ratings = ratings;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reviews')),
      body: Column(
        children: [
          // Summary section
          if (_stats != null) ...[
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        _stats!.formattedAverage,
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      StarRatingDisplay(rating: _stats!.averageRating),
                      Text('${_stats!.totalRatings} reviews'),
                    ],
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: RatingDistributionWidget(stats: _stats!),
                  ),
                ],
              ),
            ),
            Divider(),
          ],
          
          // Individual reviews
          Expanded(
            child: ListView.builder(
              itemCount: _ratings.length,
              itemBuilder: (context, index) {
                final rating = _ratings[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: rating.userPhotoUrl != null
                        ? NetworkImage(rating.userPhotoUrl!)
                        : null,
                    child: rating.userPhotoUrl == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(rating.userName ?? 'Anonymous'),
                      SizedBox(width: 8),
                      StarRatingDisplay(
                        rating: rating.rating,
                        size: 14,
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rating.formattedDate),
                      if (rating.hasComment) ...[
                        SizedBox(height: 4),
                        Text(rating.comment!),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔐 Security Rules

Add these Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Ratings collection
    match /ratings/{ratingId} {
      // Anyone can read ratings
      allow read: if true;
      
      // Only authenticated users can create ratings
      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.rating >= 1
                    && request.resource.data.rating <= 5;
      
      // Users can update their own ratings
      allow update: if request.auth != null
                    && resource.data.userId == request.auth.uid;
      
      // Users can delete their own ratings
      allow delete: if request.auth != null
                    && (resource.data.userId == request.auth.uid
                       || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin');
    }
    
    // Prevent direct manipulation of clinic ratings
    match /clinics/{clinicId} {
      allow update: if request.auth != null
                    && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['averageRating', 'totalRatings', 'ratingDistribution'])
                       || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin');
    }
  }
}
```

## 📊 Analytics & Monitoring

### Track Rating Events

```dart
// In ClinicRatingService.submitRating()
await FirebaseAnalytics.instance.logEvent(
  name: 'rating_submitted',
  parameters: {
    'clinic_id': clinicId,
    'rating_value': rating.toInt(),
    'has_comment': comment != null && comment.isNotEmpty,
  },
);
```

### Monitor Rating Distribution

```dart
// Get rating statistics for analytics
final allClinicStats = await Future.wait(
  clinicIds.map((id) => ClinicRatingService.getClinicRatingStats(id)),
);

final averageOfAverages = allClinicStats
    .where((s) => s.hasRatings)
    .map((s) => s.averageRating)
    .reduce((a, b) => a + b) / allClinicStats.length;

print('Platform average rating: $averageOfAverages');
```

## 🧪 Testing

### Test Rating Submission

```dart
// test/rating_service_test.dart
void main() {
  group('ClinicRatingService', () {
    test('Submit rating updates appointment and clinic', () async {
      // Setup test data
      final clinicId = 'test_clinic';
      final userId = 'test_user';
      final appointmentId = 'test_appointment';
      
      // Submit rating
      final success = await ClinicRatingService.submitRating(
        clinicId: clinicId,
        userId: userId,
        appointmentId: appointmentId,
        rating: 4.5,
      );
      
      expect(success, true);
      
      // Verify appointment updated
      final appointment = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      expect(appointment.data()!['hasRated'], true);
      
      // Verify clinic stats updated
      final stats = await ClinicRatingService.getClinicRatingStats(clinicId);
      expect(stats.totalRatings, greaterThan(0));
    });
  });
}
```

## 🚀 Deployment Checklist

- [ ] Create Firestore indexes for ratings collection
- [ ] Update security rules
- [ ] Add `hasRated` field to existing appointments (migration script)
- [ ] Add rating fields to clinics collection (migration script)
- [ ] Test on staging environment
- [ ] Update API documentation
- [ ] Add analytics tracking
- [ ] Monitor error rates post-deployment

## 🔄 Migration Script

Run this to update existing documents:

```javascript
// Run in Firebase Console → Firestore → Run query
const admin = require('firebase-admin');
const db = admin.firestore();

async function migrateAppointments() {
  const snapshot = await db.collection('appointments').get();
  const batch = db.batch();
  
  snapshot.docs.forEach(doc => {
    if (!doc.data().hasOwnProperty('hasRated')) {
      batch.update(doc.ref, { hasRated: false });
    }
  });
  
  await batch.commit();
  console.log(`Migrated ${snapshot.size} appointments`);
}

async function migrateClinics() {
  const snapshot = await db.collection('clinics').get();
  const batch = db.batch();
  
  snapshot.docs.forEach(doc => {
    if (!doc.data().hasOwnProperty('averageRating')) {
      batch.update(doc.ref, {
        averageRating: 0.0,
        totalRatings: 0,
        ratingDistribution: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 }
      });
    }
  });
  
  await batch.commit();
  console.log(`Migrated ${snapshot.size} clinics`);
}

migrateAppointments();
migrateClinics();
```

## 📚 Additional Resources

- [Firestore Transactions Documentation](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Flutter Rating UI Patterns](https://api.flutter.dev/flutter/material/Icons-class.html)
- [App User Reviews Best Practices](https://developer.android.com/guide/playcore/in-app-review)

## ✅ Summary

The clinic rating system is now fully integrated into PawSense with:
- ✅ Complete data models
- ✅ Transactional service layer
- ✅ User-friendly UI components
- ✅ Real-time updates
- ✅ Security rules
- ✅ Error handling
- ✅ Documentation

Users can now rate clinics after completing appointments, and clinics will display their average ratings throughout the app!
