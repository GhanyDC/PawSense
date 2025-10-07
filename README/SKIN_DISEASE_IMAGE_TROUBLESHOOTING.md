# Skin Disease Image Troubleshooting Guide

## Problem: Images Not Displaying

If you've updated Firestore but images aren't showing, follow these steps:

## Step 1: Check Your Firestore Document

Open Firebase Console → Firestore → `skinDiseases` collection

**Verify the `imageUrl` field**:

✅ **CORRECT FORMAT** (for local assets):
```
imageUrl: "allopecia.jpg"
```

❌ **WRONG FORMATS**:
```
imageUrl: "allopecia"                      // Missing file extension
imageUrl: "Allopecia.jpg"                  // Capital letter (case-sensitive)
imageUrl: "/allopecia.jpg"                 // Leading slash
imageUrl: "assets/img/skin_diseases/allopecia.jpg"  // Full path (use filename only)
imageUrl: " allopecia.jpg"                 // Extra space at start
imageUrl: "allopecia.jpg "                 // Extra space at end
```

## Step 2: Check Your File System

**Verify the file exists at the exact location**:
```
c:\Users\delac\PawSense\assets\img\skin_diseases\allopecia.jpg
```

**File name must match EXACTLY**:
- Same spelling
- Same capitalization (case-sensitive!)
- Same file extension (.jpg, .png, etc.)

Example:
- Firestore: `"allopecia.jpg"`
- File: `allopecia.jpg` ✅
- File: `Allopecia.jpg` ❌ (capital A doesn't match!)

## Step 3: Run Flutter Clean and Rebuild

When you add new assets, Flutter needs to rebuild:

```powershell
# Clean the build
flutter clean

# Get dependencies
flutter pub get

# Run the app (hot restart won't work for new assets!)
flutter run
```

**IMPORTANT**: Hot reload (⚡) will NOT pick up new assets. You must:
- Stop the app
- Run `flutter clean`
- Run `flutter run` again

## Step 4: Check Debug Console

I've added debug logging to help you identify the issue. When you run the app, check the console for:

```
🖼️ Image Debug for "Alopecia (Hair Loss)":
   Raw imageUrl: "allopecia.jpg"
   Is network image: false
   Loading from ASSETS: assets/img/skin_diseases/allopecia.jpg
```

**If you see an error**:
```
❌ Asset image FAILED: Unable to load asset: assets/img/skin_diseases/allopecia.jpg
```

This means one of these issues:
1. File doesn't exist at that path
2. File name doesn't match exactly
3. You didn't run `flutter clean` after adding the asset
4. pubspec.yaml isn't configured correctly

## Step 5: Verify pubspec.yaml

Check that your `pubspec.yaml` includes:

```yaml
flutter:
  assets:
    - assets/img/  # This includes all subfolders
```

✅ Your pubspec.yaml is already configured correctly!

## Step 6: Common Mistakes Checklist

Go through this checklist:

### File Name Issues
- [ ] File exists in `assets/img/skin_diseases/` folder
- [ ] File name matches EXACTLY (including capitalization)
- [ ] File has extension (.jpg, .png, etc.)
- [ ] No extra spaces in filename

### Firestore Issues
- [ ] `imageUrl` field contains only the filename
- [ ] No leading/trailing spaces in `imageUrl` value
- [ ] No full path, just filename
- [ ] File extension included

### Build Issues
- [ ] Ran `flutter clean` after adding images
- [ ] Ran `flutter pub get`
- [ ] Did full restart (not just hot reload)
- [ ] Stopped and restarted app completely

## Step 7: Test with Debug Commands

Run these PowerShell commands to verify:

```powershell
# Check if file exists
Test-Path "c:\Users\delac\PawSense\assets\img\skin_diseases\allopecia.jpg"
# Should return: True

# List all images in folder
Get-ChildItem "c:\Users\delac\PawSense\assets\img\skin_diseases"
# Should show: allopecia.jpg

# Check file size (should be > 0)
(Get-Item "c:\Users\delac\PawSense\assets\img\skin_diseases\allopecia.jpg").Length
# Should show file size in bytes
```

## Step 8: Check Firestore Data Type

In Firebase Console, verify the field type:

**Correct**: `imageUrl` should be a **string** field
```json
{
  "imageUrl": "allopecia.jpg"  // string type
}
```

**Wrong**: If it's an object, array, or other type
```json
{
  "imageUrl": {
    "path": "allopecia.jpg"  // WRONG - should be flat string
  }
}
```

## Quick Fix Steps

If nothing works, try this quick fix:

1. **Delete the Firestore document** completely
2. **Create a new document** with this exact structure:

```json
{
  "id": "alopecia",
  "name": "Alopecia (Hair Loss)",
  "imageUrl": "allopecia.jpg",
  "species": ["cats"],
  "severity": "Moderate",
  "detectionMethod": "ai",
  "categories": ["Allergic"],
  "description": "Patchy or generalized hair loss that often reveals flaky or irritated skin underneath.",
  "symptoms": ["Hair loss", "Bald patches"],
  "causes": ["Allergies", "Parasites"],
  "treatments": ["Medicated shampoos", "Topical treatments"],
  "duration": "2-8 weeks",
  "isContagious": false,
  "viewCount": 0,
  "createdAt": [Timestamp - use server timestamp],
  "updatedAt": [Timestamp - use server timestamp]
}
```

3. **Verify file name** matches exactly: `allopecia.jpg`

4. **Stop the app** completely

5. **Run in terminal**:
```powershell
cd c:\Users\delac\PawSense
flutter clean
flutter pub get
flutter run
```

## Example Debug Output

When working correctly, you should see:

```
🔵 Loading data...
🔵 Data loaded: 1 diseases, 1 categories
🔵 Before filters - All diseases: 1
🔵 Applying filters...
✅ "Alopecia (Hair Loss)" PASSED all filters!
🟢 Filtered diseases: 1
🖼️ Image Debug for "Alopecia (Hair Loss)":
   Raw imageUrl: "allopecia.jpg"
   Is network image: false
   Loading from ASSETS: assets/img/skin_diseases/allopecia.jpg
```

No error messages after this = **Image loaded successfully!** ✅

## Still Not Working?

If you still see the placeholder icon (📋), check:

1. **Console output** - Look for the `❌ Asset image FAILED` message
2. **The error message** will tell you the exact problem
3. **Share the console output** and I can help debug further

## Testing Different Image Formats

You can use:
- ✅ `.jpg` files
- ✅ `.jpeg` files  
- ✅ `.png` files
- ✅ `.webp` files

Make sure the Firestore `imageUrl` matches the actual file extension:
- File: `allopecia.jpg` → Firestore: `"allopecia.jpg"` ✅
- File: `allopecia.png` → Firestore: `"allopecia.png"` ✅
- File: `allopecia.jpg` → Firestore: `"allopecia.png"` ❌

---

**Next Steps**: 
1. Run the app and check the console for debug messages
2. Look for the `🖼️ Image Debug` output
3. If you see an error, follow the steps above to fix it
