# Appointment Booking - Testing Guide

**Quick Reference for Testing Duplicate Prevention System**

---

## 🧪 Manual Testing Checklist

### Test 1: Rapid Click Protection ⚡
**Goal:** Verify button prevents multiple submissions

**Steps:**
1. Open Book Appointment page
2. Fill all required fields:
   - Select a pet
   - Select a clinic
   - Choose a date
   - Pick a time slot
3. Click "Book Appointment" button **5 times rapidly**

**Expected Results:**
- ✅ Button shows loading indicator after 1st click
- ✅ Button is disabled during submission
- ✅ Only **1 booking** appears in database
- ✅ Success message appears once
- ✅ Console shows: `🚫 Booking already in progress, ignoring duplicate request`

**How to Verify:**
```
1. Check Firestore Console → appointments collection
2. Should see only 1 new document
3. Check appointment history in app
4. Should see only 1 appointment
```

---

### Test 2: Duplicate Booking Prevention 🚫
**Goal:** Prevent booking same appointment twice

**Steps:**
1. Book an appointment:
   - Pet: Max (Dog)
   - Clinic: PawCare Veterinary
   - Date: Tomorrow
   - Time: 10:00 AM
2. Wait for success message
3. Go back to booking page
4. Try to book **exact same appointment** again

**Expected Results:**
- ✅ 1st booking succeeds
- ✅ 2nd booking blocked
- ✅ Error message: "You already have an appointment for this pet at this clinic on this date and time."
- ✅ Red snackbar appears
- ✅ No duplicate in database

**How to Verify:**
```
1. Check Firestore appointments collection
2. Filter by:
   - clinicId = "PawCare Veterinary ID"
   - appointmentDate = tomorrow
   - appointmentTime = "10:00"
3. Should see only 1 document
```

---

### Test 3: Rate Limiting 🔒
**Goal:** Prevent spam bookings

**Steps:**
1. Book appointment #1 (any valid details)
2. Immediately book appointment #2 (different time)
3. Immediately book appointment #3 (different time)
4. Immediately try appointment #4 (different time)

**Expected Results:**
- ✅ Bookings 1-3 succeed
- ✅ Booking 4 **fails** with error:
  - "Too many booking attempts. Please wait a few minutes before trying again."
- ✅ Red snackbar shows rate limit message
- ✅ Console shows: `🚫 Rate limit exceeded for user [userId]`

**Wait 5 minutes, then:**
5. Try booking again

**Expected Results:**
- ✅ Booking succeeds after waiting period

**How to Verify:**
```
1. Check Firestore - should see exactly 3 appointments
2. Wait 5+ minutes
3. Book again - should succeed
4. Total: 4 appointments in database
```

---

### Test 4: Race Condition (Concurrent Bookings) 🏁
**Goal:** Prevent overbooking when 2 users book simultaneously

**Requirements:** 2 devices or 2 browser windows

**Setup:**
- Device 1: Login as User A
- Device 2: Login as User B

**Steps:**
1. **Both devices:** Navigate to booking page
2. **Both devices:** Select SAME clinic
3. **Both devices:** Select SAME date
4. **Both devices:** Select SAME time slot (e.g., 2:00 PM - 3:00 PM)
5. **Both devices:** Fill other details
6. **Simultaneously:** Both users click "Book Appointment" at the same time

**Expected Results:**
- ✅ **One booking succeeds** (User A or User B)
- ✅ **One booking fails** with error:
  - "This time slot was just booked by another user. Please select a different time."
- ✅ Failed user's time slot dropdown **automatically refreshes**
- ✅ That time slot **disappears** from dropdown
- ✅ Only **1 appointment** in database for that slot

**How to Verify:**
```
1. Check Firestore appointments collection
2. Filter by:
   - clinicId = selected clinic
   - appointmentDate = selected date
   - appointmentTime = "14:00"
3. Should see ONLY 1 document
4. Check userId - should be either User A or User B
```

---

### Test 5: Full Slot Filtering 📅
**Goal:** Hide fully booked time slots from dropdown

**Steps:**
1. Book an appointment for tomorrow at 2:00 PM - 3:00 PM
2. Wait for success
3. **Start new booking session:**
   - Select same clinic
   - Select same date (tomorrow)
4. Open time slot dropdown

**Expected Results:**
- ✅ 2:00 PM - 3:00 PM **does NOT appear** in dropdown
- ✅ Other available hours are shown (e.g., 9:00 AM, 10:00 AM, etc.)
- ✅ Dropdown only shows hours with available capacity
- ✅ Console shows: `✅ Loaded X hourly time slots for [Day]`

**Alternative Test - View Filtering in Real-time:**
1. Open booking page on Device 1
2. Select tomorrow's date - note available times
3. On Device 2, book an appointment at 3:00 PM
4. On Device 1, change date and come back to tomorrow
5. Verify 3:00 PM - 4:00 PM no longer appears

**How to Verify:**
```
1. Console log shows capacity checking:
   "Checking slot availability..."
2. Full slots are filtered out
3. Only slots with hasAvailableSlot = true appear
```

---

### Test 6: Error Message Verification 📝
**Goal:** Ensure all error types show correct messages

**Test 6.1: Missing Pet**
- Don't select a pet
- Try to book
- Expected: "Please select a pet first"

**Test 6.2: Missing Clinic**
- Don't select a clinic
- Try to book
- Expected: "Please select a clinic first"

**Test 6.3: Missing Time Slot**
- Don't select a time
- Try to book
- Expected: "Please select an available time slot"

**Test 6.4: Rate Limit Exceeded**
- (See Test 3)
- Expected: "Too many booking attempts. Please wait a few minutes before trying again."

**Test 6.5: Duplicate Booking**
- (See Test 2)
- Expected: "You already have an appointment for this pet at this clinic on this date and time."

**Test 6.6: Slot Became Full**
- (See Test 4)
- Expected: "This time slot was just booked by another user. Please select a different time."

---

### Test 7: Booking From Different Entry Points 🚪
**Goal:** Verify protection works from all booking flows

**Test 7.1: Main Booking Page**
- Go to Home → Services → Book Appointment
- Complete booking
- ✅ Should work with all protection

**Test 7.2: From Assessment**
- Complete AI assessment
- Click "Book Appointment" button
- Should navigate to booking page
- Complete booking
- ✅ Should work with all protection

**Test 7.3: From History Detail**
- Go to History tab
- Click on an assessment
- Click "Book Appointment"
- Should navigate to booking page
- Complete booking
- ✅ Should work with all protection

**Test 7.4: From Clinic Details**
- Go to Clinics
- Click on a clinic
- Click "Book Appointment"
- Should navigate to booking page with pre-filled clinic
- Complete booking
- ✅ Should work with all protection

**Expected:** All paths use same booking service → same protection

---

## 🔍 Debugging Tools

### Console Logs to Monitor

**Success Flow:**
```
📋 MOBILE DEBUG: Appointment booked successfully with ID: abc123
🏥 MOBILE DEBUG: Saved with clinicId: xyz
👤 MOBILE DEBUG: Saved with userId: user123
🐾 MOBILE DEBUG: Saved with petId: pet456
📅 MOBILE DEBUG: Saved for date: 2025-10-17 at 10:00
```

**Duplicate Prevention:**
```
🚫 Duplicate booking detected for user [userId] at [time]
```

**Rate Limiting:**
```
🚫 Rate limit exceeded for user [userId] (3 bookings in last 5 minutes)
```

**Slot Full:**
```
🚫 Time slot was just booked by another user
```

**UI Guard:**
```
🚫 Booking already in progress, ignoring duplicate request
```

---

## 📊 Verification Queries

### Check Duplicates
```javascript
// In Firebase Console
db.collection('appointments')
  .where('userId', '==', 'USER_ID')
  .where('petId', '==', 'PET_ID')
  .where('clinicId', '==', 'CLINIC_ID')
  .where('appointmentDate', '==', DATE)
  .where('appointmentTime', '==', 'TIME')
  .get()
  .then(snap => console.log('Count:', snap.size)); // Should be 1
```

### Check Rate Limiting (Dart Debug)
```dart
// In Flutter DevTools Console
print(AppointmentBookingService._userBookingAttempts);
// Shows attempts per user with timestamps
```

### Check Slot Capacity
```javascript
// In Firebase Console
db.collection('appointments')
  .where('clinicId', '==', 'CLINIC_ID')
  .where('appointmentDate', '==', DATE)
  .where('appointmentTime', '==', 'TIME')
  .where('status', 'in', ['pending', 'confirmed'])
  .get()
  .then(snap => console.log('Active bookings:', snap.size)); // Should be ≤ 1
```

---

## 🎯 Success Criteria

**Test is PASSING if:**
- ✅ No duplicate bookings can be created
- ✅ Rate limiting prevents spam
- ✅ Only 1 user wins in race condition
- ✅ Full slots don't appear in dropdown
- ✅ Clear error messages for each scenario
- ✅ Button shows loading state
- ✅ All entry points protected

**Test is FAILING if:**
- ❌ Multiple bookings created from rapid clicks
- ❌ Same booking can be made twice
- ❌ More than 3 bookings in 5 minutes
- ❌ 2 users book same slot successfully
- ❌ Full slots still shown in dropdown
- ❌ Generic "Failed to book" errors
- ❌ Button remains clickable during submission

---

## 🐛 Common Issues & Solutions

### Issue: "Too many attempts" but I only booked once
**Cause:** Rate limit tracking persists in memory  
**Solution:** Hot reload the app to clear memory

### Issue: Time slot disappeared after I selected it
**Cause:** Another user just booked it  
**Solution:** This is correct behavior - select different time

### Issue: Can't book at all - all slots gone
**Cause:** All slots are fully booked  
**Solution:** Select different date or clinic

### Issue: Duplicate prevention not working
**Cause:** Booking status is 'cancelled'  
**Solution:** Duplicate check only considers 'pending' and 'confirmed' statuses

---

## 📝 Test Results Template

```
Date: _____________
Tester: _____________

Test 1: Rapid Click Protection       [ ] Pass  [ ] Fail
Test 2: Duplicate Prevention          [ ] Pass  [ ] Fail
Test 3: Rate Limiting                 [ ] Pass  [ ] Fail
Test 4: Race Condition                [ ] Pass  [ ] Fail
Test 5: Full Slot Filtering           [ ] Pass  [ ] Fail
Test 6: Error Messages                [ ] Pass  [ ] Fail
Test 7: All Entry Points              [ ] Pass  [ ] Fail

Notes:
_________________________________________________
_________________________________________________
_________________________________________________

Overall Status: [ ] All Pass  [ ] Some Failed
```

---

## 🚀 Ready for Production?

Before deploying, ensure:
- [ ] All 7 tests pass
- [ ] No console errors
- [ ] Database shows correct counts
- [ ] Error messages are user-friendly
- [ ] Performance is acceptable
- [ ] Works on all entry points

**If all checked:** System is production-ready! ✅
