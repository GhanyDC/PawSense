# Pet Breeds Navigation Troubleshooting Guide

## Issue: Clicking Pet Breeds redirects to sign-in page

### Root Cause Analysis

The navigation is protected by AuthGuard which checks:
1. Is the user authenticated?
2. Does the user have the correct role?

For Pet Breeds (`/super-admin/pet-breeds`), the user MUST have role `super_admin`.

---

## Quick Fix: Verify Your User Role in Firebase

### Step 1: Check Your User Document in Firebase Console

1. Open Firebase Console: https://console.firebase.google.com/
2. Select your PawSense project
3. Go to **Firestore Database**
4. Navigate to the **`users`** collection
5. Find YOUR user document (by email or UID)
6. Check the **`role`** field

**Expected value**: `super_admin`  
**If it shows**: `admin` or `user` → This is the problem!

---

## Solution 1: Update Your Role in Firebase Console (Recommended)

### Manual Update:
1. In Firebase Console → Firestore → `users` collection
2. Click on your user document
3. Find the `role` field
4. Click edit (pencil icon)
5. Change value to: `super_admin` (exactly as written, all lowercase)
6. Save changes
7. **Log out and log back in** to PawSense
8. Try accessing Pet Breeds again

---

## Solution 2: Use Firestore Rules to Allow Testing (Temporary)

If you need immediate access for testing, temporarily update Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Temporary rule for testing - REMOVE AFTER TESTING
    match /petBreeds/{breedId} {
      allow read, write: if request.auth != null;
    }
    
    // Keep existing rules...
  }
}
```

⚠️ **Warning**: This allows ANY authenticated user to access Pet Breeds. Remove after testing!

---

## Solution 3: Create a Test Super Admin Account

### Using Firebase Console:

1. **Create Auth User**:
   - Firebase Console → Authentication → Users
   - Click "Add user"
   - Email: `superadmin@test.com`
   - Password: (set a strong password)
   - Click "Add user"

2. **Create Firestore Document**:
   - Firebase Console → Firestore Database
   - Navigate to `users` collection
   - Click "Add document"
   - Document ID: (use the UID from Authentication)
   - Add fields:
     ```
     email: "superadmin@test.com"
     role: "super_admin"
     firstName: "Super"
     lastName: "Admin"
     createdAt: (current timestamp)
     ```
   - Save

3. **Login with New Account**:
   - Log out of PawSense
   - Login with `superadmin@test.com`
   - Try accessing Pet Breeds

---

## Debugging Steps

### Check Console Output:

When you try to access Pet Breeds, open browser DevTools (F12) and check the Console for logs:

**Expected logs**:
```
AuthGuard.validateRouteAccess() called for: /super-admin/pet-breeds
AuthGuard: User found with role: super_admin
AuthGuard: Access granted for route: /super-admin/pet-breeds
```

**If you see this instead**:
```
AuthGuard: User found with role: admin  // ← Wrong role!
AuthGuard: Access denied, redirecting to: /web_login
```
**→ Your user doesn't have super_admin role!**

---

### Quick Role Check Script:

You can also check your current role by running this in browser console (F12):

```javascript
// Check current user role
firebase.auth().currentUser.getIdToken()
  .then(token => fetch('https://firestore.googleapis.com/v1/projects/YOUR_PROJECT/databases/(default)/documents/users/' + firebase.auth().currentUser.uid, {
    headers: {'Authorization': 'Bearer ' + token}
  }))
  .then(r => r.json())
  .then(data => console.log('Your role:', data.fields.role.stringValue));
```

---

## Permanent Solution: Proper Super Admin Setup

### Create a Secure Super Admin Creation Process:

**Option A: Cloud Function** (Recommended for production):

```javascript
// functions/index.js
exports.createSuperAdmin = functions.https.onCall(async (data, context) => {
  // Only allow existing super admins to create new super admins
  const callerRole = context.auth?.token?.role;
  if (callerRole !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only super admins can create super admins');
  }
  
  const { email, password, firstName, lastName } = data;
  
  // Create auth user
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: `${firstName} ${lastName}`,
  });
  
  // Set custom claim
  await admin.auth().setCustomUserClaims(userRecord.uid, { role: 'super_admin' });
  
  // Create Firestore document
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    email,
    role: 'super_admin',
    firstName,
    lastName,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  return { success: true, uid: userRecord.uid };
});
```

**Option B: Admin SDK Script** (One-time setup):

```javascript
// setup-super-admin.js
const admin = require('firebase-admin');
admin.initializeApp();

async function createSuperAdmin() {
  const email = 'youremail@example.com';
  const password = 'your-secure-password';
  
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: 'Super Admin',
  });
  
  await admin.auth().setCustomUserClaims(userRecord.uid, { role: 'super_admin' });
  
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    email,
    role: 'super_admin',
    firstName: 'Super',
    lastName: 'Admin',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log('Super admin created:', userRecord.uid);
}

createSuperAdmin().catch(console.error);
```

---

## Verification Checklist

After updating your role, verify:

- [ ] Firebase Console shows `role: "super_admin"` for your user
- [ ] You've logged out and logged back in
- [ ] Browser console shows "Access granted" log
- [ ] "Pet Breeds" menu item is visible in sidebar
- [ ] Clicking "Pet Breeds" navigates to `/super-admin/pet-breeds`
- [ ] Pet Breeds screen loads without redirecting
- [ ] You can see the "Add New Breed" button

---

## Still Not Working?

### Check these common issues:

1. **Cache Issue**: 
   - Clear browser cache
   - Hard refresh (Ctrl+Shift+R)
   - Try incognito/private mode

2. **Session Issue**:
   - Log out completely
   - Close all browser tabs
   - Log back in

3. **Token Issue**:
   - Check if token has expired
   - Force token refresh by logging out/in

4. **Firestore Rules**:
   - Ensure rules allow super_admin to read petBreeds collection
   - Check Firebase Console → Firestore → Rules

5. **Route Registration**:
   - Verify `breed_management_screen.dart` is imported in `app_router.dart`
   - Verify route path is `/super-admin/pet-breeds` (not `/super_admin/pet-breeds`)
   - Verify `role_manager.dart` includes Pet Breeds in super_admin routes

---

## Contact Support

If none of these solutions work:

1. Share console logs from browser DevTools (F12 → Console)
2. Share your user document structure from Firestore
3. Share any error messages from the console
4. Confirm: "I am logged in as: [email]"
5. Confirm: "My role in Firestore is: [role]"

---

## Expected Behavior After Fix

✅ Login as super admin  
✅ See "Pet Breeds" in sidebar (with 🐾 icon)  
✅ Click "Pet Breeds"  
✅ Navigate to `/super-admin/pet-breeds`  
✅ See "Pet Breeds Management" page  
✅ See statistics cards  
✅ See "Add New Breed" button  
✅ No redirect to login page  

---

**TL;DR**: Your user account needs `role: "super_admin"` in the Firestore `users` collection. Update it in Firebase Console, log out, log back in, and it should work!
