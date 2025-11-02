# Testing Time-Dependent Features - Step-by-Step Guide

## The Issue
When you change device time drastically (e.g., +1 month), network/DNS resolution fails. This causes authentication and data fetching to fail because:
1. ❌ Can't get fresh auth tokens
2. ❌ Can't fetch data from Firestore
3. ❌ No cached data available yet (on first launch)

## ✅ Correct Testing Procedure

### Step 1: Sign In With CORRECT Time First
```
1. Set device time to AUTOMATIC
2. Launch PawSense app
3. Sign in with your account
4. Let the app fully load:
   ✓ Home page loads
   ✓ Profile visible
   ✓ Pets list shows
   ✓ Wait ~5 seconds for data to cache
```

**Why?** This ensures Firestore offline cache is populated with your data.

### Step 2: Now Change Device Time
```
1. Go to Settings → Date & Time
2. Disable "Automatic date & time"
3. Change date forward (e.g., +1 day, +1 week, +1 month)
4. Return to PawSense (DON'T close it)
```

### Step 3: Use the App
```
1. Navigate around the app
2. View your pets
3. Check pet age changes
4. Test your feature

Expected:
✅ You stay signed in
✅ Data shows from cache
✅ Pet age increments correctly
✅ App continues working
```

## ❌ What NOT To Do

### DON'T: Close App After Time Change
```
❌ Change device time
❌ Close app completely
❌ Reopen app
Result: Firestore cache may be cleared, no data available
```

### DON'T: Sign Out After Time Change
```
❌ Change device time
❌ Sign out
❌ Try to sign in again
Result: Network errors, can't authenticate
```

### DON'T: Change Time BEFORE First Sign-In
```
❌ Change device time first
❌ Then try to sign in
Result: SSL/certificate errors, authentication fails
```

## Troubleshooting

### Problem: "User not found" After Changing Time
**Solution:**
1. Change device time BACK to automatic
2. Wait 5 seconds for network to recover
3. Navigate to different page and back
4. Data should load from server now
5. Change time again (while app is running)

### Problem: Can't Sign In With Changed Time
**Solution:**
1. Set device time back to automatic
2. Sign in successfully
3. Let app load all data
4. THEN change time (don't close app)

### Problem: Empty Pet List After Time Change
**Solution:**
1. Check console logs for "Using stale cached"
2. If not, you need to reload with correct time first
3. Change time back → reload data → change time again

### Problem: App Closes During Testing
**Solution:**
1. Set time back to automatic
2. Reopen app and sign in
3. Let data cache for ~10 seconds
4. Change time (keep app open)

## Best Practice Testing Workflow

```
┌─────────────────────────────────────────┐
│ 1. Device Time: AUTOMATIC               │
│    ✅ Sign in                            │
│    ✅ Load all data                      │
│    ✅ Wait 10 seconds                    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. Change Time: +1 day                  │
│    ✅ App still running                  │
│    ✅ Data visible from cache            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. Test Your Feature                    │
│    ✅ Pet age increments                 │
│    ✅ Other time-based features work     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. Continue Testing                     │
│    ✅ Change time more (+1 week, +1 mo)  │
│    ✅ Test different scenarios           │
│    ✅ Keep app running                   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 5. When Done                            │
│    ✅ Set time back to automatic         │
│    ✅ Close and reopen app               │
│    ✅ Everything works normally again    │
└─────────────────────────────────────────┘
```

## Console Log Checks

### Good Signs ✅
```
✅ AuthGuard: User data loaded from cache for role: user
✅ Keeping 3 existing pets (offline mode)
📡 TokenManager: Network error - using cached token
✅ Firestore offline persistence enabled
```

### Warning Signs ⚠️
```
⚠️ AuthGuard: No valid token found - may be offline
⚠️ TokenManager: Failed to get token
📡 Network error detected - keeping existing pets
```

### Bad Signs ❌ (Need to reload with correct time)
```
❌ AuthGuard: User document not found in Firestore
❌ PetInfoCard user not found
❌ No cached user data available
❌ Failed to load pets
```

## Quick Recovery If Something Goes Wrong

```bash
1. Set device time to AUTOMATIC
2. Wait 5 seconds
3. Pull to refresh or navigate away and back
4. Data should load
5. Once data is visible, change time again
```

## Why This Matters

**Firestore Offline Persistence**:
- Requires data to be fetched at least once
- Caches data locally on device
- Only works if you've loaded the data before going "offline"

**Time Change = Network Failure**:
- Extreme time changes break DNS resolution
- App can't connect to Firebase servers
- Must rely on cached data

**Solution**:
- Load data FIRST (with correct time)
- THEN change time (data stays in cache)
- App works with cached data

## Summary

✅ **DO THIS:**
1. Sign in with correct time
2. Load all data and wait
3. Change time while app is running
4. Test your feature
5. Keep app running

❌ **DON'T DO THIS:**
1. ❌ Change time before signing in
2. ❌ Close app after changing time
3. ❌ Sign out after changing time
4. ❌ Try to reload fresh data with wrong time

---

**Last Updated**: November 3, 2025
**Status**: Optimized for time-dependent feature testing
