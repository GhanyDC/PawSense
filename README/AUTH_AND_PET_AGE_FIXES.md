# Authentication and Pet Age Display Fixes

## Overview
This document describes fixes for two issues discovered during testing:
1. **Auth Blocking Issue**: Users couldn't sign in after changing device time
2. **Pet Age Inconsistency**: List view showed "1 year" while edit form showed "11 months"

## Issue 1: Auth Blocking After Time Change ❌ → ✅

### Problem
When device time was changed, the auth system completely blocked users from signing in, showing a critical error message. This made the app unusable even though the user credentials were correct.

### Root Cause
The `validateTimeBeforeAuth()` method in `auth_time_enhancement.dart` was calling `shouldBlockAuth()` which returned `true` for moderate to critical time skew. This caused `wrapSignInAttempt()` to throw a `FirebaseAuthException`, preventing the sign-in attempt entirely.

**Old behavior:**
```dart
final shouldBlock = await TimeValidationService.shouldBlockAuth();
if (shouldBlock) {
  return 'Your device time is critically incorrect...'; // This message caused exception
}
```

### Solution
Modified `validateTimeBeforeAuth()` to return a warning message instead of a blocking error, and updated `wrapSignInAttempt()` to log the warning but proceed with authentication.

**New behavior in `validateTimeBeforeAuth()`:**
```dart
final result = await TimeValidationService.validateDeviceTime();
if (!result.isValid) {
  return 'Warning: ${result.description}. Some features may not work correctly.';
}
```

**New behavior in `wrapSignInAttempt()`:**
```dart
final timeWarning = await validateTimeBeforeAuth();
if (timeWarning != null) {
  debugPrint('⚠️ Time warning during $operation: $timeWarning');
  // Don't throw - just log the warning and proceed
}
```

### Result
- ✅ Users can now sign in even with incorrect device time
- ✅ Warning is logged in debug console for developers
- ✅ User experience improved: no hard blocking, just graceful warnings
- ✅ Follows principle of "graceful degradation" instead of complete failure

### Testing
To verify the fix:
1. Change device time forward/backward by >1 month
2. Close and reopen the app
3. Attempt to sign in with email/password or Google
4. **Expected**: Sign-in succeeds, warning logged in console
5. **Previous**: Sign-in blocked with critical error

---

## Issue 2: Pet Age Display Inconsistency ❌ → ✅

### Problem
Pet age displayed inconsistently across the app:
- **List view**: Shows "1 year" (using `ageString` getter which rounds 11 months to 1 year)
- **Edit form**: Shows "11 months" (using `initialAge` field from database)

This caused confusion as users saw different values for the same pet.

### Root Cause
The pet model has two age representations:
- **`age` getter**: Dynamically calculated current age (initialAge + months since creation)
- **`initialAge` field**: Stored age in months when pet was created/updated

The edit form was displaying `initialAge` while the list view displayed the calculated `age`:

**Old edit form initialization:**
```dart
_ageController.text = pet.initialAge.toString(); // Shows stored value
```

### Solution
Modified the edit form to use the calculated `age` instead of `initialAge`, and updated the save logic to properly back-calculate `initialAge` based on the entered age and creation date.

**New edit form initialization:**
```dart
_ageController.text = pet.age.toString(); // Shows calculated age (synced with display)
```

**New save logic:**
```dart
if (_isEditing) {
  // Calculate initialAge by subtracting months since creation
  final enteredAge = int.parse(_ageController.text);
  final monthsSinceCreation = (now.year - widget.pet!.createdAt.year) * 12 + 
                             (now.month - widget.pet!.createdAt.month);
  calculatedInitialAge = enteredAge - monthsSinceCreation;
  
  // Ensure initialAge is never negative
  if (calculatedInitialAge < 0) {
    calculatedInitialAge = enteredAge;
    petCreatedAt = now; // Reset creation date if age is too low
  } else {
    petCreatedAt = widget.pet!.createdAt;
  }
} else {
  // When adding new pet, initialAge = entered age
  calculatedInitialAge = int.parse(_ageController.text);
  petCreatedAt = now;
}
```

### Result
- ✅ Edit form now shows the same age as list view
- ✅ Age format is consistent: "11 months" everywhere, or "1 year" everywhere
- ✅ `initialAge` is automatically recalculated when user edits age
- ✅ Pet creation date is preserved unless age math doesn't work out
- ✅ Safety check prevents negative `initialAge` values

### How It Works

**Example scenario:**
- Pet created on January 1, 2024 with initialAge = 10 months
- Current date: February 1, 2024 (1 month later)
- Calculated age: 10 + 1 = 11 months

**Display in list view:**
```
ageString = "11 months" (using age getter)
```

**Display in edit form:**
```
Age field = "11" (using age getter, synced!)
```

**When user saves after editing:**
```
Entered age: 13 months
Months since creation: 1 month (Feb - Jan)
New initialAge: 13 - 1 = 12 months
✅ Next time: age = 12 + 1 = 13 months (consistent!)
```

### Testing
To verify the fix:
1. Open pet list and note the age display (e.g., "11 months" or "1 year")
2. Tap on the pet to edit
3. **Expected**: Age field shows the same value as list view
4. **Previous**: Age field showed different value (initialAge)
5. Change the age and save
6. **Expected**: Age updates correctly and stays consistent across views

---

## Files Modified

### lib/core/services/auth/auth_time_enhancement.dart
- Modified `validateTimeBeforeAuth()` to return warning instead of blocking error
- Modified `wrapSignInAttempt()` to log warning but proceed with auth

### lib/pages/mobile/pets/add_edit_pet_page.dart
- Modified `_initializeFormData()` to use `pet.age` instead of `pet.initialAge`
- Modified `_savePet()` to calculate `initialAge` based on entered age and creation date

### lib/main.dart
- Added auth monitoring restoration on app startup for existing sessions
- Prevents token expiration when user closes/reopens app without signing out

---

## Ready to Test ✅

Both issues are now fixed! The app is ready for testing:

### Test Scenario 1: Auth with Time Change
```
1. Sign out if signed in
2. Change device time forward by 2 months
3. Close and reopen app
4. Attempt to sign in
   ✅ Should succeed with warning logged
```

### Test Scenario 2: Pet Age Consistency
```
1. Create a pet with age 11 months
2. View pet in list (should show "11 months")
3. Edit the pet
   ✅ Should show "11" in age field
4. Change age to 13 months and save
5. View pet in list again
   ✅ Should show "1 year 1 month" consistently
```

### Test Scenario 3: Close and Reopen App (Session Persistence)
```
1. Sign in to the app
2. Close the app completely (don't sign out)
3. Wait a few minutes
4. Reopen the app
   ✅ Should remain signed in (session persisted)
   ✅ Auth monitoring automatically restored
   ✅ Token refresh continues working
5. Use app features normally
   ✅ Everything works without re-signing in
```

### Expected Behavior
- No more auth blocking due to time changes ✅
- Pet age displays consistently across all screens ✅
- Edit form and list view always show the same age ✅
- Age calculations work correctly even after editing ✅
- Auth monitoring restored automatically on app restart ✅
- Token refresh works even after closing/reopening app ✅

---

## Implementation Notes

### Auth Fix Philosophy
The fix follows the "fail gracefully" principle:
- Don't block critical functionality (auth) due to time issues
- Log warnings for developers
- Allow users to proceed even if time is wrong
- Firebase will still handle actual token validation

### Pet Age Fix Philosophy
The fix ensures "single source of truth":
- `age` getter is the authoritative calculated age
- `initialAge` is a stored value used for calculation
- Edit form syncs with display by showing calculated age
- Save logic back-calculates initialAge to maintain consistency

### Edge Cases Handled
1. Negative `initialAge` → Reset creation date
2. Device time moved backward → Safety check prevents negative ages
3. Very old pets → No changes, calculations still work
4. New pets → initialAge = entered age (straightforward)
5. **App closed without sign-out → Auth monitoring automatically restored on startup**
6. **Existing session on app launch → Token refresh continues seamlessly**

---

## Additional Enhancement: Session Persistence

### Problem Discovered
When you close the app without signing out and reopen it later:
- Firebase Auth keeps you signed in (session persisted) ✅
- But `initializeAuthMonitoring()` was only called during sign-in ❌
- Token refresh timer not running → tokens could expire after 60 minutes ❌

### Solution Implemented
Modified `main.dart` to check for existing authenticated user on app startup:

```dart
// Initialize auth monitoring if user is already signed in
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser != null) {
  AuthTimeEnhancement.initializeAuthMonitoring(FirebaseAuth.instance);
  print('🔐 Auth monitoring restored for existing session');
}
```

### Benefits
- ✅ Token refresh monitoring continues even after app restart
- ✅ No need to sign in again after closing app
- ✅ Seamless user experience with persistent sessions
- ✅ Prevents token expiration issues during long app sessions
