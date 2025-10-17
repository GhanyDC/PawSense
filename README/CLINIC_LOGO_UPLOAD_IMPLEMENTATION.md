# Clinic Logo Upload Implementation

## Overview
This document describes the implementation of the clinic logo upload feature, allowing veterinary clinics to upload and display their custom logos using Cloudinary cloud storage.

## Features Implemented

### 1. **Database Model Update**
- Added `logoUrl` field to the `Clinic` model
- Field stores the Cloudinary URL for the uploaded logo
- Optional field (nullable) - defaults to null if no logo uploaded

### 2. **Cloudinary Integration**
- Uses existing `CloudinaryService` for image uploads
- Uploads to dedicated `clinic_logos` folder in Cloudinary
- Automatic image optimization and compression
- Secure HTTPS URLs for all uploaded logos

### 3. **Upload Logo Modal**
- User-friendly modal dialog for logo upload
- Image preview before upload
- Support for image selection from device
- Image size optimization (max 1024x1024, 85% quality)
- Real-time upload progress indicator
- Error handling with clear messages

### 4. **Profile Display**
- Logo displayed prominently in vet profile basic info section
- Circular edit button overlay for easy logo changes
- Fallback to default business icon if no logo uploaded
- Square logo display (120x120px) with rounded corners
- Graceful error handling for broken image URLs

## File Structure

```
lib/
├── core/
│   ├── models/
│   │   └── clinic/
│   │       └── clinic_model.dart          # Updated with logoUrl field
│   ├── services/
│   │   ├── cloudinary/
│   │   │   └── cloudinary_service.dart    # Existing service used for uploads
│   │   └── clinic/
│   │       └── clinic_service.dart        # Added updateClinicLogo() method
│   └── widgets/
│       └── admin/
│           └── vet_profile/
│               ├── vet_basic_info.dart    # Updated to display logo
│               └── upload_logo_modal.dart # New modal for logo upload
└── pages/
    └── web/
        └── admin/
            └── vet_profile_screen.dart    # Updated to pass logoUrl
```

## Database Schema Changes

### Firestore Collections Updated

#### `clinics` collection:
```json
{
  "id": "string",
  "userId": "string",
  "clinicName": "string",
  "address": "string",
  "phone": "string",
  "email": "string",
  "website": "string?",
  "logoUrl": "string?",  // NEW FIELD
  "status": "string",
  "scheduleStatus": "string",
  "isVisible": "boolean",
  "scheduleCompletedAt": "timestamp?",
  "createdAt": "timestamp"
}
```

#### `clinicDetails` collection (also updated):
```json
{
  "clinicId": "string",
  "clinicName": "string",
  "address": "string",
  "phone": "string",
  "email": "string",
  "logoUrl": "string?",  // NEW FIELD
  "updatedAt": "timestamp"
}
```

## API Methods

### ClinicService.updateClinicLogo()
```dart
static Future<bool> updateClinicLogo(String logoUrl) async
```
**Purpose**: Updates the clinic logo URL in both `clinics` and `clinicDetails` collections

**Parameters**:
- `logoUrl` (String): The Cloudinary URL of the uploaded logo

**Returns**: 
- `bool`: true if update successful, false otherwise

**Usage**:
```dart
final success = await ClinicService.updateClinicLogo(cloudinaryUrl);
```

### CloudinaryService.uploadImageFromBytes()
```dart
Future<String> uploadImageFromBytes(
  Uint8List bytes,
  String fileName, {
  required String folder,
}) async
```
**Purpose**: Uploads image bytes to Cloudinary and returns secure URL

**Parameters**:
- `bytes` (Uint8List): Raw image bytes
- `fileName` (String): Original filename
- `folder` (String): Cloudinary folder path (e.g., 'clinic_logos')

**Returns**: 
- `String`: Cloudinary secure URL (HTTPS)

## Component Details

### UploadLogoModal Widget

**Location**: `lib/core/widgets/admin/vet_profile/upload_logo_modal.dart`

**Props**:
- `currentLogoUrl` (String?): Current logo URL to display
- `onLogoUploaded` (VoidCallback): Callback fired after successful upload

**Features**:
- Image picker integration (ImagePicker package)
- Image preview with memory display
- Automatic image compression (1024x1024, 85% quality)
- Upload progress indicator
- Error message display
- Cancel and Upload actions

**Usage**:
```dart
showDialog(
  context: context,
  builder: (context) => UploadLogoModal(
    currentLogoUrl: 'https://res.cloudinary.com/...',
    onLogoUploaded: () {
      // Handle post-upload actions
      print('Logo uploaded successfully');
    },
  ),
);
```

### VetProfileBasicInfo Widget Updates

**Location**: `lib/core/widgets/admin/vet_profile/vet_basic_info.dart`

**New Props**:
- `logoUrl` (String?): URL of the clinic logo
- `onLogoUpdated` (VoidCallback?): Callback when logo is updated

**UI Changes**:
- Replaced circular avatar with square logo display (120x120px)
- Added camera icon button overlay for logo upload
- Logo shows with rounded corners (kBorderRadius)
- Fallback to business icon if no logo or error loading
- White border around camera button for better visibility

## User Flow

1. **Viewing Profile**
   - User navigates to vet profile page
   - Logo is displayed if available, otherwise shows default business icon
   - Camera icon visible in bottom-right of logo area

2. **Uploading Logo**
   - User clicks camera icon button
   - Upload Logo Modal opens
   - User sees current logo (if any)
   - User clicks "Choose Image" button
   - Image picker opens
   - User selects image from device
   - Image preview appears in modal
   - User clicks "Upload Logo" button
   - Upload progress shown
   - On success: Modal closes, snackbar confirms, profile auto-updates via stream
   - On error: Error message shown in modal

3. **Changing Logo**
   - Same flow as uploading
   - Current logo shown in modal
   - New image replaces old one in Cloudinary and database

## Real-time Updates

The implementation uses Firestore streams to automatically update the UI when the logo changes:

```dart
_profileSubscription = VetProfileService.streamVetProfile().listen(
  (profileData) {
    if (profileData != null) {
      setState(() {
        _vetProfile = {
          // ... other fields
          'logoUrl': clinic?['logoUrl'] ?? clinicDetails?['logoUrl'],
        };
      });
    }
  },
);
```

## Image Specifications

### Upload Requirements:
- **Formats**: Any format supported by ImagePicker (JPEG, PNG, etc.)
- **Max Dimensions**: 1024 x 1024 pixels (auto-resized)
- **Quality**: 85% compression
- **Source**: Device gallery only

### Display Specifications:
- **Dimensions**: 120 x 120 pixels
- **Border Radius**: kBorderRadius (from constants)
- **Fit**: BoxFit.cover (maintains aspect ratio, crops if needed)

### Cloudinary Storage:
- **Folder**: `clinic_logos/`
- **Naming**: `{sanitized_filename}_{timestamp}`
- **URL**: HTTPS secure URL
- **Transformations**: None (handled by upload size limits)

## Error Handling

### Image Selection Errors:
```dart
try {
  final XFile? image = await _picker.pickImage(...);
} catch (e) {
  setState(() {
    _errorMessage = 'Error picking image: $e';
  });
}
```

### Upload Errors:
```dart
try {
  final logoUrl = await _cloudinaryService.uploadImageFromBytes(...);
} catch (e) {
  setState(() {
    _errorMessage = 'Error uploading logo: $e';
    _isUploading = false;
  });
}
```

### Database Update Errors:
```dart
final success = await ClinicService.updateClinicLogo(logoUrl);
if (!success) {
  setState(() {
    _errorMessage = 'Failed to update clinic logo';
  });
}
```

### Display Errors:
```dart
Image.network(
  logoUrl!,
  errorBuilder: (context, error, stackTrace) {
    return _buildDefaultAvatar(); // Fallback to default
  },
)
```

## Security Considerations

1. **Authentication**: All uploads require authenticated user session
2. **Authorization**: Only the clinic owner can upload/change their logo
3. **File Validation**: Image picker restricts to image files only
4. **Size Limits**: Images automatically compressed to 1024x1024
5. **Cloudinary Security**: Uses upload preset with security restrictions
6. **HTTPS Only**: All URLs use secure HTTPS protocol

## Testing Checklist

- [ ] Upload new logo from gallery
- [ ] Replace existing logo
- [ ] Cancel upload operation
- [ ] Test with various image formats (JPEG, PNG)
- [ ] Test with very large images (auto-compression)
- [ ] Test with very small images
- [ ] Test error handling (network errors, invalid images)
- [ ] Verify logo displays correctly in profile
- [ ] Verify logo persists after refresh
- [ ] Test camera button hover/click states
- [ ] Verify fallback to default icon works
- [ ] Test real-time update when logo changes

## Future Enhancements

1. **Image Cropping**: Allow users to crop/adjust logo before upload
2. **Multiple Sizes**: Generate and store multiple sizes (thumbnail, medium, large)
3. **Logo Guidelines**: Show size/format recommendations in modal
4. **Camera Capture**: Add option to take photo with camera (mobile)
5. **Logo History**: Keep history of previous logos
6. **Bulk Operations**: Allow superadmin to manage all clinic logos
7. **Logo Approval**: Require superadmin approval for logo changes
8. **Logo Analytics**: Track logo views and engagement

## Dependencies

- `image_picker: ^1.0.0` - Image selection from device
- `http: ^1.0.0` - HTTP requests for Cloudinary
- `cloud_firestore: ^4.0.0` - Firestore database
- `flutter_dotenv: ^5.0.0` - Environment variables for Cloudinary credentials

## Environment Variables Required

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_upload_preset
```

## Migration Notes

### Existing Clinics:
- `logoUrl` field will be null for existing clinics
- UI gracefully handles null values with default icon
- No data migration required

### Adding Sample Logo:
```dart
await _firestore.collection('clinics').doc(userId).update({
  'logoUrl': 'https://res.cloudinary.com/your-cloud/image/upload/clinic_logos/sample_logo.png',
});
```

## Troubleshooting

### Logo Not Displaying:
1. Check if `logoUrl` field exists in database
2. Verify URL is valid and accessible
3. Check network connectivity
4. Verify Image.network error builder is triggered

### Upload Failing:
1. Verify Cloudinary credentials in .env
2. Check network connectivity
3. Verify image file is valid
4. Check Cloudinary quota/limits
5. Review console logs for error details

### Real-time Update Not Working:
1. Verify Firestore stream is active
2. Check if `logoUrl` is being extracted from stream data
3. Verify setState() is called after stream update
4. Check console for stream errors

## Support

For issues or questions:
1. Check console logs for detailed error messages
2. Verify Cloudinary dashboard for upload status
3. Check Firestore console for data updates
4. Review this documentation for troubleshooting steps

---

**Last Updated**: October 16, 2025
**Version**: 1.0.0
**Author**: PawSense Development Team
