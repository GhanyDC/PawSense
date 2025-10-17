# Clinic Ratings & Reviews Page Implementation

## Overview
Created a new admin page that allows clinic owners to view and manage their ratings and reviews from patients. The page displays rating statistics, distribution charts, and individual review cards in real-time.

## Files Created

### 1. `/lib/pages/web/admin/clinic_ratings_page.dart`
Full-featured ratings dashboard for clinic administrators.

**Features:**
- Real-time rating statistics via Firestore streams
- Large average rating display with stars
- Rating distribution visualization (5-star breakdown)
- Filter tabs (All, 5⭐, 4⭐, 3⭐, 2⭐, 1⭐)
- Individual review cards with user info and comments
- Empty states for clinics with no reviews
- Responsive layout optimized for web dashboard

## Integration Points

### 2. `/lib/core/services/optimization/role_manager.dart`
Added rating route to admin navigation menu.

**Change:**
```dart
RouteInfo('/admin/ratings', 'Ratings & Reviews', Icons.star_outline),
```

Positioned between "Vet Profile & Services" and "Messages" for logical grouping.

### 3. `/lib/core/config/app_router.dart`
Added route configuration and navigation.

**Changes:**
- Import: `import 'package:pawsense/pages/web/admin/clinic_ratings_page.dart';`
- Route:
```dart
GoRoute(
  path: '/admin/ratings',
  builder: (context, state) => const ClinicRatingsPage(),
  pageBuilder: (context, state) => NoTransitionPage(
    child: const ClinicRatingsPage(),
  ),
),
```

## Page Features

### Header Section
```
┌────────────────────────────────────────────┐
│ ⭐ Ratings & Reviews                        │
│    View and manage your clinic reviews     │
└────────────────────────────────────────────┘
```

### Rating Overview Card
Shows comprehensive clinic rating statistics:

**With Ratings:**
```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│  4.5         5 ████████████████████████████  (42)       │
│  ⭐⭐⭐⭐⭐    4 ████████████████             (28)       │
│  42 reviews  3 ████                         (7)        │
│              2 █                            (2)        │
│              1 █                            (1)        │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

**Without Ratings:**
```
┌─────────────────────────────────────────────┐
│              ⭐                              │
│         No Reviews Yet                      │
│  Your first review will appear here         │
└─────────────────────────────────────────────┘
```

### Filter Tabs
```
┌──────────────────────────────────────────────────┐
│ [ All (42) ] [ 5⭐ (20) ] [ 4⭐ (15) ] [ 3⭐ (5) ] │
│ [ 2⭐ (1) ] [ 1⭐ (1) ]                            │
└──────────────────────────────────────────────────┘
```

### Review Cards
```
┌─────────────────────────────────────────────────┐
│ 👤 John Doe                          ⭐ 5.0    │
│    Oct 15, 2025                                 │
│                                                  │
│ Great service! The vet was very caring and      │
│ professional. Highly recommend this clinic.     │
└─────────────────────────────────────────────────┘
```

## Technical Implementation

### Data Loading
```dart
Future<void> _loadClinicData() async {
  // 1. Get current user (admin)
  final currentUser = await AuthGuard.getCurrentUser();
  
  // 2. Find clinic by userId
  final clinicsSnapshot = await FirebaseFirestore.instance
      .collection('clinics')
      .where('userId', isEqualTo: currentUser.uid)
      .limit(1)
      .get();
  
  _clinicId = clinicsSnapshot.docs.first.id;
  
  // 3. Stream rating stats for real-time updates
  _statsSubscription = ClinicRatingService.streamClinicRatingStats(_clinicId!)
      .listen((stats) {
    setState(() {
      _ratingStats = stats;
    });
  });
  
  // 4. Load all reviews
  await _loadRatings();
}
```

### Real-Time Updates
- Uses Firestore streams for rating statistics
- Auto-updates when new ratings are submitted
- No manual refresh required
- Efficient single-document stream subscription

### Filtering Logic
```dart
List<ClinicRating> get _filteredRatings {
  if (_selectedFilter == 0) {
    return _ratings; // All ratings
  }
  // Filter by star count
  return _ratings.where((r) => r.rating.round() == _selectedFilter).toList();
}
```

### Distribution Bar Calculation
```dart
Widget _buildDistributionBar(int stars) {
  final count = _ratingStats!.ratingDistribution[stars] ?? 0;
  final percentage = _ratingStats!.totalRatings > 0
      ? (count / _ratingStats!.totalRatings)
      : 0.0;
  
  // Renders bar with calculated width
  return FractionallySizedBox(
    widthFactor: percentage,
    child: Container(...),
  );
}
```

## User Experience

### Loading States
1. **Initial Load**: Spinner with "Loading..." message
2. **Empty State**: Encouraging message for first review
3. **No Filter Results**: "No reviews found" message
4. **Error State**: Error icon with retry button

### Navigation Access
- Accessible from admin side navigation menu
- Icon: Star outline (⭐)
- Label: "Ratings & Reviews"
- Position: 6th item in menu

### Responsive Design
- Single column layout optimized for web dashboard
- Cards use full width with appropriate padding
- Spacing constants from `constants.dart`
- Consistent with other admin pages

## Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│ Admin logs in → Page loads                                    │
└──────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│ Get user → Query clinics collection for userId               │
└──────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│ Stream rating stats from clinics/{clinicId}                  │
│ - averageRating: 4.5                                          │
│ - totalRatings: 42                                            │
│ - ratingDistribution: {5: 20, 4: 15, 3: 5, 2: 1, 1: 1}      │
└──────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│ Load reviews from ratings collection                         │
│ where clinicId == current clinic                             │
└──────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│ Display stats, filters, and review cards                     │
│ Update automatically when new ratings come in                │
└──────────────────────────────────────────────────────────────┘
```

## Dependencies

### Existing Services Used
- `ClinicRatingService` - Rating CRUD and streaming
- `AuthGuard` - User authentication
- `FirebaseFirestore` - Clinic lookup

### Packages
- `intl` - Date formatting (DateFormat)
- `cloud_firestore` - Firestore queries

### Models
- `ClinicRating` - Individual rating data
- `ClinicRatingStats` - Aggregated statistics
- `UserModel` - Current user info

## Error Handling

### Authentication Errors
```dart
if (currentUser == null) {
  throw Exception('User not authenticated');
}
```

### No Clinic Found
```dart
if (clinicsSnapshot.docs.isEmpty) {
  throw Exception('No clinic associated with this account');
}
```

### Stream Errors
```dart
_statsSubscription = ClinicRatingService.streamClinicRatingStats(_clinicId!)
    .listen((stats) { ... }, 
    onError: (error) {
      print('Error streaming rating stats: $error');
    });
```

## UI Components

### Review Card Elements
1. **User Avatar**: Circle with user initial or photo
2. **User Name**: Bold text, defaults to "Anonymous User"
3. **Date**: Formatted as "MMM d, yyyy"
4. **Rating Badge**: Colored pill with star icon and number
5. **Comment**: Optional, displayed below header if present

### Distribution Bar
- **Background**: Light gray, full width
- **Filled portion**: Primary color, width = percentage
- **Height**: 8px, rounded corners
- **Label**: Star count + icon + count number

### Filter Tab States
- **Inactive**: White background, primary text
- **Active**: Primary background, white text
- **Badge**: Shows count for each filter
- **Hover**: Smooth transitions

## Future Enhancements

### 1. **Reply to Reviews**
Allow clinic to respond to user reviews:
```dart
String? clinicResponse;
DateTime? responseDate;
String? respondedBy; // Staff member name
```

### 2. **Sort Options**
Add sorting dropdown:
- Most Recent
- Highest Rating
- Lowest Rating
- Most Helpful

### 3. **Export Reviews**
Download reviews as PDF or CSV:
```dart
void _exportReviews() {
  // Generate PDF with all reviews
}
```

### 4. **Rating Trends**
Show rating trend over time:
```dart
LineChart(
  // Plot average rating by month
)
```

### 5. **Response Rate**
Track how quickly clinic responds:
```dart
double get responseRate => _respondedCount / _totalCount;
Duration get averageResponseTime => ...;
```

### 6. **Flag Inappropriate Reviews**
Report system for inappropriate content:
```dart
void _flagReview(String reviewId, String reason) {
  // Submit flag to moderation queue
}
```

## Testing Checklist

### Page Access
- [ ] Admin can access page from side navigation
- [ ] Route loads correctly without errors
- [ ] Auth guard prevents unauthorized access

### Data Display
- [ ] Rating statistics display correctly
- [ ] Distribution bars show accurate percentages
- [ ] Reviews load and display properly
- [ ] User avatars/initials render correctly
- [ ] Dates format correctly

### Filtering
- [ ] "All" filter shows all reviews
- [ ] Star filters work correctly (5, 4, 3, 2, 1)
- [ ] Badge counts are accurate
- [ ] Active state highlights correctly

### Real-Time Updates
- [ ] Stats update when new rating submitted
- [ ] No manual refresh needed
- [ ] Stream stays connected during session
- [ ] Proper cleanup on page navigation

### Edge Cases
- [ ] Handles clinic with 0 ratings
- [ ] Handles reviews without comments
- [ ] Handles anonymous users
- [ ] Handles missing user photos
- [ ] Handles long comments (text wrapping)

### Error Handling
- [ ] Shows error if clinic not found
- [ ] Shows error if user not authenticated
- [ ] Gracefully handles Firestore errors
- [ ] Provides helpful error messages

## Performance Considerations

### Optimization Strategies
1. **Pagination**: Currently loads 100 reviews (can add infinite scroll)
2. **Stream**: Only subscribes to rating stats document, not individual reviews
3. **Lazy Loading**: Reviews only load when page opens
4. **Efficient Filtering**: Client-side filtering on loaded data
5. **Image Caching**: User photos cached by browser

### Memory Management
- Stream subscription cancelled in `dispose()`
- No memory leaks from lingering subscriptions
- Proper state cleanup on navigation

## Security Notes

1. **Clinic Access**: Verified via userId → clinicId lookup
2. **No Cross-Clinic Access**: Can only view own clinic ratings
3. **Read-Only**: Clinic cannot modify or delete ratings
4. **Authentication Required**: AuthGuard enforces login
5. **Role-Based**: Only admins can access this page

---

**Status:** ✅ Complete and integrated  
**Date:** October 15, 2025  
**Feature:** Clinic ratings and reviews management page  
**Navigation:** Admin sidebar → "Ratings & Reviews"  
**Real-time:** Yes (Firestore streams)
