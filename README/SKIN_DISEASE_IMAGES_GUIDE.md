# Skin Disease Images Guide

## Overview
The Skin Disease Library now supports both **local asset images** and **network images** (URLs). The system automatically detects which type of image to use based on the `imageUrl` field in Firestore.

## Image Storage Location
All local skin disease images should be stored in:
```
assets/img/skin_diseases/
```

Example:
```
assets/img/skin_diseases/
  ├── allopecia.jpg
  ├── ringworm.jpg
  ├── flea_allergy.jpg
  └── hot_spots.jpg
```

## How It Works

### 1. **Asset Images (Recommended)**
When storing images locally in your Flutter app:

**Firestore `imageUrl` field**: Store just the **filename**
```
imageUrl: "allopecia.jpg"
```

The app will automatically construct the full path:
```dart
assets/img/skin_diseases/allopecia.jpg
```

### 2. **Network Images**
If you need to use images from the internet:

**Firestore `imageUrl` field**: Store the **full URL**
```
imageUrl: "https://example.com/images/disease.jpg"
```

## Firestore Document Example

### Using Local Asset Image
```json
{
  "id": "alopecia",
  "name": "Alopecia (Hair Loss)",
  "imageUrl": "allopecia.jpg",  // ← Just the filename
  "species": ["cats"],
  "severity": "Moderate",
  "detectionMethod": "ai",
  "categories": ["Allergic", "Parasitic"],
  "description": "Patchy or generalized hair loss...",
  "symptoms": ["Hair loss", "Itching"],
  "causes": ["Allergies", "Parasites"],
  "treatments": ["Medicated shampoos", "Topical treatments"],
  "duration": "2-8 weeks",
  "isContagious": false,
  "viewCount": 0,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### Using Network Image
```json
{
  "id": "ringworm",
  "name": "Ringworm",
  "imageUrl": "https://cloudinary.com/images/ringworm.jpg",  // ← Full URL
  "species": ["cats", "dogs"],
  "severity": "Moderate",
  // ... rest of fields
}
```

## Image Detection Logic

The app uses this logic to determine image type:

```dart
// Check if URL starts with http:// or https://
if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
  // Load as network image
  Image.network(imageUrl)
} else {
  // Load as asset image
  Image.asset('assets/img/skin_diseases/$imageUrl')
}
```

## Image Requirements

### Recommended Specifications
- **Format**: JPG, PNG, or WebP
- **Resolution**: 800x800px or higher (square aspect ratio preferred)
- **File Size**: Under 500KB for optimal performance
- **Quality**: High quality, clear medical images

### Naming Convention
Use lowercase with underscores:
- ✅ `allopecia.jpg`
- ✅ `flea_allergy.jpg`
- ✅ `hot_spots.png`
- ❌ `Allopecia.jpg` (avoid capital letters)
- ❌ `flea allergy.jpg` (avoid spaces)

## Adding New Images

### Step 1: Add Image to Assets Folder
Place your image file in:
```
assets/img/skin_diseases/your_disease.jpg
```

### Step 2: Update Firestore Document
Set the `imageUrl` field to just the filename:
```json
{
  "imageUrl": "your_disease.jpg"
}
```

### Step 3: Test
The image should automatically display in:
- ✅ Disease cards (80x80px thumbnail)
- ✅ Detail page header (200px height)
- ✅ Search results
- ✅ Filter results

## Fallback Behavior

If an image fails to load (missing file or broken URL), the app displays a **placeholder icon**:
- 📋 Medical information icon
- Gray background
- No app crashes or errors

## Benefits of Asset Images vs Network Images

| Feature | Asset Images | Network Images |
|---------|-------------|----------------|
| **Load Speed** | ⚡ Instant | 🐌 Depends on network |
| **Offline Access** | ✅ Always available | ❌ Requires internet |
| **App Size** | 📦 Increases bundle | 📦 No impact |
| **Cost** | 💰 Free | 💰 Bandwidth costs |
| **CDN Required** | ❌ No | ✅ Yes (Cloudinary, Firebase Storage) |
| **Maintenance** | 🔧 Update requires app release | 🔧 Update Firestore only |

## Migration from Network to Asset Images

If you're currently using network images and want to switch to assets:

1. **Download all images** from your CDN/storage
2. **Rename files** to match naming convention
3. **Place in** `assets/img/skin_diseases/`
4. **Update Firestore** documents:
   ```
   Before: "imageUrl": "https://cloudinary.com/.../allopecia.jpg"
   After:  "imageUrl": "allopecia.jpg"
   ```
5. **No code changes needed** - automatic detection!

## Troubleshooting

### Image Not Displaying

**Check 1**: Verify file exists
```
assets/img/skin_diseases/allopecia.jpg  ← File must exist
```

**Check 2**: Verify pubspec.yaml includes assets
```yaml
flutter:
  assets:
    - assets/img/  # ← This includes all subfolders
```

**Check 3**: Run `flutter clean` and rebuild
```bash
flutter clean
flutter pub get
flutter run
```

**Check 4**: Check Firestore `imageUrl` field
```
✅ "allopecia.jpg"           (correct)
✅ "hot_spots.png"          (correct)
❌ "allopecia"              (missing extension)
❌ "Allopecia.jpg"          (case mismatch)
❌ "/allopecia.jpg"         (leading slash)
```

### Image Quality Issues

**Problem**: Image looks blurry
**Solution**: Use higher resolution images (recommended 800x800px minimum)

**Problem**: Image too large, slow performance
**Solution**: Compress images before adding to assets (use ImageOptim, TinyPNG, etc.)

## Example Usage

### Firestore Console
When adding a new disease document:

```
Collection: skinDiseases
Document ID: (auto-generated)

Fields:
  name: "Flea Allergy Dermatitis"
  imageUrl: "flea_allergy.jpg"  ← Just the filename!
  species: ["cats", "dogs"]
  severity: "Moderate"
  (... other fields)
```

### File Structure
```
PawSense/
├── assets/
│   └── img/
│       └── skin_diseases/
│           ├── allopecia.jpg
│           ├── flea_allergy.jpg
│           ├── ringworm.jpg
│           └── hot_spots.jpg
├── lib/
│   └── (app code)
└── pubspec.yaml
```

## Performance Tips

1. **Optimize images** before adding to assets
2. **Use JPG** for photos (smaller file size)
3. **Use PNG** for images with transparency
4. **Keep file sizes** under 500KB
5. **Use consistent dimensions** (e.g., 800x800px)

## Summary

✅ **Asset images**: Store in `assets/img/skin_diseases/`, use filename only in Firestore
✅ **Network images**: Store full URL in Firestore
✅ **Automatic detection**: App handles both types seamlessly
✅ **Fallback**: Placeholder icon if image fails
✅ **No code changes**: Just update Firestore `imageUrl` field

---

**Last Updated**: October 7, 2025
**Version**: 1.0.0
