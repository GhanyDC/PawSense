# Dynamic Dashboard Username Display

## Date: October 14, 2025

## Problem

The dashboard header displayed a hardcoded welcome message:
```dart
'Welcome back, Dr. Johnson' // make this dynamic later and fetch from user profile
```

This needed to be replaced with the actual logged-in user's name from their profile.

## Solution

### 1. Added User Name Fetching in Dashboard Screen

**File:** `lib/pages/web/admin/dashboard_screen.dart`

#### Changes Made:

1. **Added `_userName` field** to store the user's display name:
```dart
String? _userName; // User's display name
```

2. **Created `_getCurrentUserName()` method** to fetch the user's name:
```dart
/// Get current user's display name
Future<String?> _getCurrentUserName() async {
  try {
    final user = await AuthGuard.getCurrentUser();
    if (user == null) return null;

    // Build display name from firstName and lastName
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName} ${user.lastName}';
    } else if (user.firstName != null) {
      return user.firstName;
    } else if (user.lastName != null) {
      return user.lastName;
    } else {
      return user.username;
    }
  } catch (e) {
    AppLogger.error('Error getting current user name', error: e, tag: 'DashboardScreen');
    return null;
  }
}
```

3. **Updated `_loadDashboardData()`** to fetch the user's name:
```dart
// Get the current user's clinic ID and name
final clinicId = await DashboardService.getCurrentUserClinicId();
final userName = await _getCurrentUserName();

_clinicId = clinicId;
_userName = userName;
```

4. **Passed `userName` to DashboardHeader**:
```dart
DashboardHeader(
  selectedPeriod: selectedPeriod,
  userName: _userName,  // ✅ Now dynamic
  onPeriodChanged: (period) {
    _safeSetState(() {
      selectedPeriod = period;
    });
    _loadStats();
  },
),
```

5. **Added AuthGuard import**:
```dart
import '../../../core/guards/auth_guard.dart';
```

### 2. Updated Dashboard Header Widget

**File:** `lib/core/widgets/admin/dashboard/dashboard_header.dart`

#### Changes Made:

1. **Added `userName` parameter** to the widget:
```dart
class DashboardHeader extends StatelessWidget {
  final String selectedPeriod;
  final String? userName;  // ✅ New optional parameter
  final Function(String) onPeriodChanged;

  const DashboardHeader({
    super.key,
    required this.selectedPeriod,
    this.userName,  // ✅ Optional - defaults to null
    required this.onPeriodChanged,
  });
```

2. **Updated `_buildHeaderInfo()` to use dynamic name**:
```dart
Widget _buildHeaderInfo() {
  // Build welcome message with dynamic name
  String welcomeMessage = 'Welcome back';
  if (userName != null && userName!.isNotEmpty) {
    welcomeMessage = 'Welcome back, $userName';
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Dashboard',
        style: kTextStyleTitle.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 4),
      Text(
        welcomeMessage,  // ✅ Now dynamic
        style: TextStyle(
          fontSize: kFontSizeRegular,
          color: AppColors.textSecondary,
        ),
      ),
      // ... rest of the widget
    ],
  );
}
```

## User Name Priority Logic

The system uses the following priority to build the display name:

1. **First Name + Last Name** - "John Doe"
2. **First Name only** - "John"
3. **Last Name only** - "Doe"
4. **Username** - "john.doe" (fallback)
5. **null** - If no user data is available, shows "Welcome back" without a name

## How It Works

### Loading Flow:

1. Dashboard screen initializes
2. Header appears immediately with "Welcome back" (no name yet)
3. `_loadDashboardData()` is called
4. User's name is fetched from AuthGuard
5. `_userName` state is updated
6. Header re-renders with personalized welcome message: "Welcome back, John Doe"

### Graceful Degradation:

- ✅ If user name is loading: Shows "Welcome back"
- ✅ If user has first and last name: Shows "Welcome back, John Doe"
- ✅ If user has only first name: Shows "Welcome back, John"
- ✅ If user has only username: Shows "Welcome back, john.doe"
- ✅ If name fetch fails: Shows "Welcome back"

## Benefits

1. ✅ **Personalized Experience** - Users see their actual name
2. ✅ **Professional** - No more hardcoded placeholder names
3. ✅ **Flexible** - Handles various name configurations
4. ✅ **Graceful** - Doesn't break if name is unavailable
5. ✅ **Fast** - Header shows immediately, name updates when loaded
6. ✅ **Type Safe** - Uses nullable String with proper checks

## User Experience

### Before:
```
Dashboard
Welcome back, Dr. Johnson  ← Hardcoded, wrong for all users
Monitor your clinic's performance and recent activity
```

### After (with name):
```
Dashboard
Welcome back, John Doe  ← Real user's name
Monitor your clinic's performance and recent activity
```

### After (loading):
```
Dashboard
Welcome back  ← Generic message while loading
Monitor your clinic's performance and recent activity
```

## Testing Scenarios

- ✅ User with firstName and lastName
- ✅ User with firstName only
- ✅ User with lastName only
- ✅ User with username only
- ✅ User data fetch error
- ✅ Null user data
- ✅ Empty string values

## Files Modified

1. **lib/pages/web/admin/dashboard_screen.dart**
   - Added `_userName` field
   - Created `_getCurrentUserName()` method
   - Updated `_loadDashboardData()` to fetch user name
   - Passed `userName` to DashboardHeader
   - Added AuthGuard import

2. **lib/core/widgets/admin/dashboard/dashboard_header.dart**
   - Added optional `userName` parameter
   - Updated `_buildHeaderInfo()` to use dynamic name
   - Removed hardcoded "Dr. Johnson" placeholder

## Dependencies

- `AuthGuard.getCurrentUser()` - Fetches current user's data
- `UserModel` - Contains firstName, lastName, username fields
- User must be authenticated with valid Firestore user document

## Related Models

**UserModel** (`lib/core/models/user/user_model.dart`):
```dart
class UserModel {
  final String uid;
  final String username;
  final String? firstName;
  final String? lastName;
  // ... other fields
}
```

## Performance Impact

- ✅ Minimal - Single additional async call during dashboard load
- ✅ Cached - User name is stored in state, not fetched repeatedly
- ✅ Non-blocking - Header appears immediately while name loads
- ✅ Efficient - Reuses existing AuthGuard service

## Future Enhancements

Potential improvements for the future:
1. Add profile picture next to name
2. Add user role badge (Admin, Doctor, etc.)
3. Cache user name in PageStorage for faster subsequent loads
4. Add user preference for display name format
5. Support for title prefixes (Dr., Mr., Ms., etc.)
