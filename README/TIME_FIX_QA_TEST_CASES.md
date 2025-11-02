# QA Test Cases for Time-Dependent Bug Fixes

## 🎯 Test Objective

Validate that the PawSense mobile app functions correctly when device time is changed, ensuring:
1. Pet age calculations remain accurate
2. Authentication works or fails gracefully with clear guidance
3. All time-based features handle time skew appropriately

## 📋 Test Environment Setup

### Prerequisites
- Android emulator or iOS simulator with ability to change system time
- Or physical device with manual time control enabled
- Test account credentials
- At least 2 test pets in the account

### Important Notes
- ⚠️ Always restore correct time after testing
- ⚠️ Some tests may require app restart
- ⚠️ Document actual behavior vs expected behavior
- ⚠️ Take screenshots of errors/warnings

---

## 🧪 Test Suite 1: Pet Age with Device Time Changes

### Test Case 1.1: Normal Operation (Baseline)
**Priority:** High  
**Estimated Time:** 5 minutes

**Preconditions:**
- Device time is correct
- User is signed in
- At least one pet exists (age: 12 months)

**Steps:**
1. Open app and navigate to "My Pets"
2. Note the pet's current age
3. Wait 1 minute (or keep using app normally)
4. Refresh the pets list
5. Verify age displays correctly

**Expected Results:**
- ✅ Pet age displays as expected (12 months)
- ✅ No warnings or errors
- ✅ Age string formatted correctly (e.g., "1 year" not "12 months")

**Pass Criteria:** Age displays correctly with no errors

---

### Test Case 1.2: Device Time +1 Month Forward
**Priority:** High  
**Estimated Time:** 10 minutes

**Preconditions:**
- Device time is correct
- User is signed in
- Test pet age: 12 months

**Steps:**
1. Note current pet age (12 months)
2. Close PawSense app completely
3. Change device time to +1 month in future
4. Reopen PawSense app
5. Navigate to "My Pets"
6. Check if warning appears about time skew
7. Verify pet age displayed
8. Try to use "Add 3 months" feature
9. Verify age after increment
10. Reset device time to correct time
11. Verify age displays correctly

**Expected Results:**
- ⚠️ Warning may appear about device time being off
- ✅ Pet age should still show 12 months (not 13 months)
- ✅ "Add 3 months" feature works correctly
- ✅ After increment, age shows 15 months
- ✅ After resetting time, age remains 15 months (server timestamp used)

**Pass Criteria:** 
- Pet age doesn't incorrectly jump to 13 months
- Manual increment works using server time
- Clear warning shown (if applicable)

---

### Test Case 1.3: Device Time -1 Month Backward
**Priority:** High  
**Estimated Time:** 10 minutes

**Preconditions:**
- Device time is correct
- User is signed in
- Test pet age: 12 months

**Steps:**
1. Note current pet age (12 months)
2. Close PawSense app
3. Change device time to -1 month in past
4. Reopen PawSense app
5. Check for time skew warning
6. Navigate to "My Pets"
7. Verify pet age displayed
8. Try to add new pet with age 6 months
9. Check if new pet age displays correctly
10. Reset device time to correct time
11. Verify both pets' ages

**Expected Results:**
- ⚠️ Warning appears about device time being off
- ✅ Existing pet age shows 12 months (not 11 or negative)
- ✅ New pet can be created
- ✅ New pet age shows correctly as 6 months
- ✅ After time reset, ages remain correct

**Pass Criteria:**
- Pet age never goes below initial age
- No negative ages or crashes
- Warning clearly indicates time issue

---

### Test Case 1.4: Device Time +1 Year Forward
**Priority:** High  
**Estimated Time:** 10 minutes

**Preconditions:**
- Device time is correct
- User is signed in
- Test pet age: 12 months

**Steps:**
1. Note current pet age
2. Close PawSense app
3. Change device time to +1 year in future
4. Reopen PawSense app
5. Check for critical time warning
6. Navigate to "My Pets"
7. Verify pet age displayed
8. Try to edit pet details
9. Try to delete a pet
10. Reset device time
11. Verify app functionality returns to normal

**Expected Results:**
- ⚠️ Critical warning about device time
- ✅ Pet age displays correctly (not 24 months)
- ✅ Pet editing works
- ✅ Pet deletion works
- ✅ After time reset, all features work normally

**Pass Criteria:**
- App remains functional despite extreme time change
- Clear guidance provided to user
- Server timestamps prevent incorrect age calculations

---

### Test Case 1.5: Pet Age Increment During Time Skew
**Priority:** High  
**Estimated Time:** 15 minutes

**Preconditions:**
- Device time is correct
- User is signed in
- Test pet age: 24 months

**Steps:**
1. Verify initial pet age (24 months = 2 years)
2. Change device time to +2 months forward
3. Reopen app
4. Go to pet edit page
5. Use "Quick Age Update" to add 6 months
6. Verify new age displays correctly
7. Check pet card on main list
8. Sign out
9. Reset device time to correct time
10. Sign back in
11. Verify pet age is correct (30 months = 2 years 6 months)
12. Wait 1 real month (or simulate in Firebase)
13. Verify age automatically becomes 31 months

**Expected Results:**
- ✅ Age increment uses server timestamp
- ✅ New age calculated correctly (30 months)
- ✅ Age persists correctly after time reset
- ✅ Automatic aging resumes from correct baseline
- ✅ No duplicate age increments

**Pass Criteria:**
- Manual increment works correctly with time skew
- Server timestamp ensures accuracy
- Automatic aging continues properly

---

## 🔐 Test Suite 2: Authentication with Time Changes

### Test Case 2.1: Email Sign-In with Time +1 Month
**Priority:** Critical  
**Estimated Time:** 10 minutes

**Preconditions:**
- User is signed out
- Device time is correct
- Valid test account credentials

**Steps:**
1. Ensure user is signed out
2. Change device time to +1 month forward
3. Open PawSense app
4. Attempt to sign in with email and password
5. Observe any warnings or errors
6. If blocked, note error message
7. If successful, verify app functionality
8. Reset device time to correct time
9. Try signing in again

**Expected Results:**
**Scenario A (Sign-in works):**
- ⚠️ Warning shown about time skew
- ✅ Sign-in succeeds
- ✅ All features work normally

**Scenario B (Sign-in blocked):**
- ❌ Clear error message explaining time issue
- 📝 Instructions provided to fix time
- ✅ After fixing time, sign-in works

**Pass Criteria:**
- No generic or cryptic error messages
- User understands why sign-in failed
- Clear actionable steps provided

---

### Test Case 2.2: Google Sign-In with Time -1 Month
**Priority:** Critical  
**Estimated Time:** 10 minutes

**Preconditions:**
- User is signed out
- Device time is correct
- Google account configured on device

**Steps:**
1. Ensure user is signed out
2. Change device time to -1 month in past
3. Open PawSense app
4. Tap "Sign in with Google"
5. Complete Google authentication flow
6. Observe results
7. If blocked, read error message
8. Reset device time
9. Retry Google Sign-In

**Expected Results:**
**Likely Outcome:**
- ⚠️ OAuth flow may fail due to SSL/certificate issues
- ❌ Clear error message mentions time problem
- 📝 Guidance to sync device time
- ✅ After fixing time, Google Sign-In works

**Pass Criteria:**
- Error message specifically mentions device time
- User isn't confused by technical jargon
- Sign-in works after time correction

---

### Test Case 2.3: Token Refresh During Active Session
**Priority:** High  
**Estimated Time:** 60 minutes

**Preconditions:**
- User is signed in
- Device time is correct
- App is running

**Steps:**
1. Sign in to app
2. Verify authentication monitoring initialized
3. Use app normally for 50 minutes
4. Monitor console logs for token refresh
5. At 50-minute mark, observe auto-refresh
6. Verify user remains signed in
7. Try to perform protected operation (e.g., create pet)
8. Verify operation succeeds

**Expected Results:**
- ✅ Token automatically refreshed at 50 minutes
- ✅ User remains signed in seamlessly
- ✅ Console log shows "Auth token refreshed successfully"
- ✅ All operations continue working

**Pass Criteria:**
- Automatic token refresh happens
- User experience uninterrupted
- No re-authentication required

---

### Test Case 2.4: Sign-In Retry After Time Correction
**Priority:** High  
**Estimated Time:** 10 minutes

**Preconditions:**
- User is signed out
- Device time is correct

**Steps:**
1. Change device time to +6 months forward
2. Try to sign in (should fail with clear error)
3. Read error message
4. **Without closing app**, go to device settings
5. Set device time to "Automatic" (correct time)
6. Return to PawSense app
7. Tap "Retry" or re-enter credentials
8. Attempt sign-in again
9. Verify successful authentication

**Expected Results:**
- ❌ First attempt fails with time-related error
- 📝 Error message explains device time issue
- ⏰ Error suggests enabling automatic time
- ✅ After time correction, sign-in succeeds immediately
- ✅ No app restart required

**Pass Criteria:**
- Retry works without app restart
- User understands and can fix the issue
- Sign-in success after correction

---

### Test Case 2.5: Authentication with Critical Time Skew
**Priority:** High  
**Estimated Time:** 10 minutes

**Preconditions:**
- User is signed out
- Device time is correct

**Steps:**
1. Change device time to +2 years forward
2. Open PawSense app
3. Attempt email sign-in
4. Check if critical warning appears
5. Try to bypass warning (if possible)
6. Note error message details
7. Reset device time to correct time
8. Retry sign-in
9. Verify successful authentication

**Expected Results:**
- ⚠️ Critical time skew warning appears
- ❌ Sign-in blocked with clear explanation
- 🚫 Cannot proceed without fixing time
- 📝 Step-by-step fix instructions provided
- ✅ After time fix, sign-in works perfectly

**Pass Criteria:**
- Critical cases properly blocked
- User not confused or frustrated
- Clear recovery path provided

---

## 🔄 Test Suite 3: Network Reconnection Scenarios

### Test Case 3.1: Network Disconnect with Time Change
**Priority:** Medium  
**Estimated Time:** 15 minutes

**Preconditions:**
- User is signed in
- Device has network connection

**Steps:**
1. Disconnect device from network (airplane mode)
2. Change device time to +1 month forward
3. Try to use app offline (view pets, etc.)
4. Reconnect to network
5. Observe app behavior
6. Check if time resync happens
7. Try to create new pet
8. Verify operation uses correct timestamp

**Expected Results:**
- ✅ App works offline with local data
- ⏰ Time resync happens on reconnect
- ✅ Console log shows "Server time synced"
- ✅ New operations use server timestamps
- ✅ No data corruption

**Pass Criteria:**
- Graceful handling of offline → online transition
- Automatic time resync on reconnect
- Correct timestamps used after reconnect

---

### Test Case 3.2: Poor Network with Time Skew
**Priority:** Low  
**Estimated Time:** 10 minutes

**Preconditions:**
- User is signed in
- Simulate poor network (if possible)

**Steps:**
1. Enable network throttling or use slow network
2. Change device time to +1 month
3. Try to perform operations (create pet, edit pet, etc.)
4. Monitor for timeout or errors
5. Verify user feedback
6. Restore good network
7. Verify operations complete or can be retried

**Expected Results:**
- ✅ Loading indicators shown during slow operations
- ⏰ Time sync may take longer but still completes
- ⚠️ Appropriate error messages if timeout
- ♻️ Retry options provided
- ✅ Eventually succeeds or fails gracefully

**Pass Criteria:**
- No app crashes or freezes
- User informed of network issues
- Operations eventually complete

---

## 🌍 Test Suite 4: Edge Cases and Special Scenarios

### Test Case 4.1: Daylight Saving Time Change
**Priority:** Low  
**Estimated Time:** 10 minutes

**Preconditions:**
- Device supports DST
- User is signed in

**Steps:**
1. Note current pet ages
2. Manually change time zone to trigger DST (±1 hour)
3. Observe app behavior
4. Check if any warnings appear
5. Verify pet ages unchanged
6. Try authentication operations
7. Reset to original time zone

**Expected Results:**
- ✅ No warnings for 1-hour change (within tolerance)
- ✅ Pet ages remain correct
- ✅ Authentication works normally
- ✅ No user intervention needed

**Pass Criteria:**
- DST changes handled automatically
- No false positive warnings
- Seamless user experience

---

### Test Case 4.2: Multiple Time Changes in Sequence
**Priority:** Medium  
**Estimated Time:** 15 minutes

**Preconditions:**
- User is signed in
- Test pet age: 12 months

**Steps:**
1. Verify initial pet age
2. Change time to +1 month
3. Check pet age
4. Change time to +3 months (total +4 months)
5. Check pet age
6. Change time back to -2 months (total +2 months)
7. Check pet age
8. Reset to correct time
9. Verify final pet age

**Expected Results:**
- ✅ Pet age uses server time consistently
- ✅ Age doesn't fluctuate with time changes
- ✅ Final age based on server timestamp
- ✅ No accumulated errors from multiple changes

**Pass Criteria:**
- Age calculation remains stable
- Server time prevents compounding errors
- Correct final state after reset

---

### Test Case 4.3: App Update During Time Skew
**Priority:** Low  
**Estimated Time:** 10 minutes

**Preconditions:**
- Device time is set +1 month forward
- User is signed in

**Steps:**
1. With time skewed, close app completely
2. Clear app cache (if possible)
3. Reopen app
4. Verify time service re-initializes
5. Check pet ages
6. Verify authentication state
7. Reset device time
8. Force refresh/restart app

**Expected Results:**
- ✅ Time service initializes on app start
- ✅ Sync happens automatically
- ✅ Pet ages display correctly
- ✅ Auth state maintained
- ✅ No data loss

**Pass Criteria:**
- App recovers gracefully from restart
- Time sync happens automatically
- User experience unaffected

---

## 📊 Test Results Template

### Test Execution Summary

| Test Case | Priority | Status | Notes |
|-----------|----------|--------|-------|
| 1.1 Normal Operation | High | ⬜ Pass / ⬜ Fail | |
| 1.2 Time +1 Month | High | ⬜ Pass / ⬜ Fail | |
| 1.3 Time -1 Month | High | ⬜ Pass / ⬜ Fail | |
| 1.4 Time +1 Year | High | ⬜ Pass / ⬜ Fail | |
| 1.5 Age Increment During Skew | High | ⬜ Pass / ⬜ Fail | |
| 2.1 Email Sign-In +1 Month | Critical | ⬜ Pass / ⬜ Fail | |
| 2.2 Google Sign-In -1 Month | Critical | ⬜ Pass / ⬜ Fail | |
| 2.3 Token Refresh | High | ⬜ Pass / ⬜ Fail | |
| 2.4 Sign-In Retry | High | ⬜ Pass / ⬜ Fail | |
| 2.5 Critical Time Skew | High | ⬜ Pass / ⬜ Fail | |
| 3.1 Network Disconnect | Medium | ⬜ Pass / ⬜ Fail | |
| 3.2 Poor Network | Low | ⬜ Pass / ⬜ Fail | |
| 4.1 DST Change | Low | ⬜ Pass / ⬜ Fail | |
| 4.2 Multiple Changes | Medium | ⬜ Pass / ⬜ Fail | |
| 4.3 App Update | Low | ⬜ Pass / ⬜ Fail | |

### Issue Tracking Template

**Issue #:** ___  
**Test Case:** ___  
**Severity:** Critical / High / Medium / Low  
**Description:** ___  
**Steps to Reproduce:** ___  
**Expected Behavior:** ___  
**Actual Behavior:** ___  
**Screenshots:** ___  
**Device/OS:** ___  
**App Version:** ___  

---

## ✅ Success Criteria

### Overall Pass Requirements:

1. ✅ **All Critical priority tests pass** (2.1, 2.2)
2. ✅ **At least 90% of High priority tests pass** (1.1-1.5, 2.3-2.5)
3. ✅ **No major regressions in existing functionality**
4. ✅ **Clear user guidance provided for all time-related errors**
5. ✅ **Pet age calculations remain accurate in all scenarios**

### Quality Gates:

- **Pet Age Accuracy:** 100% (no incorrect ages displayed)
- **Auth Graceful Degradation:** 100% (clear errors, no crashes)
- **User Experience:** Clear guidance in ≥95% of error cases
- **Performance:** No significant degradation (<5% impact)

---

## 📝 Test Execution Notes

**Tester Name:** _________________  
**Test Date:** _________________  
**App Version:** _________________  
**Device/Emulator:** _________________  
**OS Version:** _________________  

**General Observations:**
- Time sync reliability: ___
- Warning message clarity: ___
- User experience rating (1-5): ___
- Any unexpected behaviors: ___

**Recommendations:**
- ___
- ___
- ___

---

## 🔍 Debugging Tips for Testers

### Check Server Time Status:
Enable developer logs and look for:
```
⏰ Server time synchronized
   Device time: ...
   Server time: ...
   Offset: ... seconds
```

### Check Auth Monitoring:
Look for:
```
✅ Auth monitoring initialized
✅ Auth token refreshed successfully
```

### Check Time Validation:
Look for:
```
⚠️ Device time skew detected: X minutes
⚠️ Time skew warning: ...
```

### Force Time Resync:
If needed during testing, you can trigger manual resync by restarting the app.

---

**Document Version:** 1.0  
**Last Updated:** November 2, 2025  
**Status:** Ready for QA Execution
