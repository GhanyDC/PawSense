# Contagious Tag Debug Guide

## Why Contagious Tags May Not Be Showing

This guide helps you debug why the contagious visual tags aren't appearing on your disease statistics.

---

## 🔍 Possible Reasons & Solutions

### 1. **Disease Names Don't Match Between Collections**

**Problem:** The disease names in `assessment_results` don't exactly match the names in `skinDiseases` collection.

**How to Check:**
1. Open Firebase Console → Firestore Database
2. Compare disease names in both collections:
   - `assessment_results` → `detectionResults` → `detections` → `label`
   - `skinDiseases` → `name` field

**Common Mismatches:**
- Case differences: `"Hotspot"` vs `"hotspot"` vs `"HOTSPOT"`
- Spacing: `"Fungal Infection"` vs `"Fungal  Infection"` (double space)
- Underscores: `"Fungal_Infection"` vs `"Fungal Infection"`
- Special characters: `"Ringworm"` vs `"Ringworm (Dermatophytosis)"`

**Solution:**
- The code now does **case-insensitive matching**
- Check console logs to see what disease names are being queried
- Update disease names in `skinDiseases` to match exactly what AI detection returns

---

### 2. **isContagious Field Not Set in Database**

**Problem:** The `isContagious` field is missing or set to `false` for all diseases.

**How to Check:**
1. Open Firebase Console → Firestore Database
2. Go to `skinDiseases` collection
3. Click on each disease document
4. Check if `isContagious` field exists and is set to `true`

**Solution:**
Set `isContagious: true` for contagious diseases in Firestore:

```javascript
// Example: Diseases that should be marked as contagious
Ringworm - isContagious: true (highly contagious fungal infection)
Mange - isContagious: true (contagious parasitic infection)
Scabies - isContagious: true (highly contagious mite infestation)
Fleas - isContagious: true (can spread between pets)
Ticks - isContagious: false (not transmitted pet-to-pet directly)
Hotspot - isContagious: false (bacterial, not typically contagious)
Pyoderma - isContagious: false (bacterial skin infection, not contagious)
```

---

### 3. **Collection Name Mismatch**

**Problem:** Your Firestore collection is named differently.

**Current Code Expects:** `skinDiseases`

**How to Check:**
1. Look at your Firestore collections
2. Check if it's named `skinDiseases`, `skin_diseases`, `diseases`, etc.

**Solution:**
If your collection has a different name, update line 281 in:
`lib/core/services/user/disease_statistics_service.dart`

```dart
.collection('skinDiseases')  // Change this to your collection name
```

---

### 4. **No Assessment Data in User's Area**

**Problem:** The statistics are loading but there are no assessments in the user's area.

**How to Check:**
- Look at the console logs when viewing Area Statistics
- Look for messages like: "No users found in area"

**Solution:**
- Make sure you have assessment results in your database
- Make sure user addresses are properly formatted
- Try with a test user in a populated area

---

### 5. **Cache is Blocking Updates**

**Problem:** You updated the database but the old data is cached.

**Solution:**
1. **Hot Restart** the app (not hot reload)
2. Or clear app data and restart
3. The cache resets when the app fully restarts

---

### 6. **Firestore Rules Blocking Access**

**Problem:** Your Firestore security rules don't allow reading from `skinDiseases` collection.

**How to Check:**
Look at console logs for permission errors:
```
Error fetching contagious info: [permission-denied]
```

**Solution:**
Update your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all users to read skin diseases
    match /skinDiseases/{document=**} {
      allow read: if true;  // Everyone can read disease information
      allow write: if request.auth != null && 
                   request.auth.token.role == 'super_admin';
    }
  }
}
```

---

## 🛠️ How to Debug

### Step 1: Check Console Logs

Run your app and navigate to the Area Statistics. Look for these logs:

```
🔍 Checking contagious status for: "Hotspot"
📡 Querying Firestore collection: skinDiseases
🔎 Query: where("name", isEqualTo: "Hotspot")
📊 Exact match query returned 1 documents
✅ Found disease in Firestore (exact match)!
   - Document ID: abc123
   - Disease name in DB: Hotspot
   - isContagious: true
```

### Step 2: Check What Diseases Are Being Searched

Look for this log pattern:
```
📊 Analyzing 26 detections for Dog...
📋 Disease counts:
   - Hotspot: 10
   - Ringworm: 9
   - Fleas: 3
```

These are the exact disease names being searched in Firestore.

### Step 3: Check Firestore Query Results

If you see:
```
⚠️ No match found. Sample disease names in database:
   - "ringworm" (ID: xyz, Contagious: true)
   - "Hotspot" (ID: abc, Contagious: true)
```

This shows what's actually in your database vs. what you're searching for.

### Step 4: Verify the Visual Component

Add a test disease with `isContagious: true` manually:

```dart
// Temporary test in area_statistics_card.dart
final stat = DiseaseStatistic(
  diseaseName: 'Test Disease',
  count: 10,
  totalCases: 100,
  percentage: 10.0,
  species: 'Dog',
  isContagious: true,  // Force to true for testing
);
```

---

## ✅ Quick Checklist

- [ ] Disease names in `skinDiseases` collection match names in `assessment_results`
- [ ] `isContagious` field exists and is set to `true` for contagious diseases
- [ ] Collection name is `skinDiseases` (or code is updated to match your collection)
- [ ] Firestore rules allow reading from `skinDiseases` collection
- [ ] Assessment data exists in the user's area
- [ ] App has been hot restarted (not just hot reloaded)
- [ ] No errors in console logs when fetching contagious info
- [ ] Console shows diseases being found with `isContagious: true`

---

## 📱 Testing Steps

1. **Hot restart** the app
2. Navigate to **Home** page
3. Scroll to **Area Statistics** section
4. Look for diseases with **yellow "Contagious" badges**
5. Tap **"View All"** button
6. Check if contagious diseases show the badge in the full list
7. Check console/terminal for debug logs

---

## 🐛 Still Not Working?

If tags still don't show after checking everything above:

1. **Check the actual query in console logs** - The logs will show exactly what's being searched
2. **Manually verify one disease** - Pick one disease (like "Ringworm"), make sure:
   - It exists in `skinDiseases` collection
   - Name matches exactly (check console logs for the search term)
   - `isContagious: true` is set
   - It appears in your area statistics
3. **Test with a forced true value** - Temporarily hardcode `isContagious: true` to verify the UI is working

---

## 📝 Example Firestore Document Structure

Your `skinDiseases` collection should look like this:

```javascript
{
  "name": "Ringworm",
  "description": "A fungal infection...",
  "imageUrl": "ringworm.jpg",
  "species": ["dogs", "cats"],
  "severity": "moderate",
  "detectionMethod": "ai",
  "symptoms": ["circular lesions", "hair loss"],
  "causes": ["fungal infection"],
  "treatments": ["antifungal medication"],
  "duration": "2-4 weeks",
  "isContagious": true,  // ← THIS IS THE KEY FIELD
  "categories": ["fungal", "skin"],
  "viewCount": 0,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

## 🎯 Most Common Issue

**90% of the time, the issue is:**
Disease names in detection results don't match the names in your `skinDiseases` collection.

**Quick Fix:**
Check console logs to see what disease names are being queried, then update your Firestore documents to match those exact names.
