# Legal Documents Database Seeding Guide

## Quick Start - Seed Your Database

### Option 1: Automatic Seeding (Recommended)

Add this to your `main.dart` file **ONE TIME ONLY**:

```dart
import 'package:pawsense/scripts/seed_legal_documents.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🌱 SEED DATABASE - Run once, then comment out or remove
  // await seedLegalDocuments();
  
  runApp(const MyApp());
}
```

**Steps:**
1. Uncomment the `await seedLegalDocuments();` line
2. Run your app once
3. Check Firebase Console → Firestore → `legal_documents` collection
4. **Comment out or remove** the line after successful seeding
5. Done! ✅

### Option 2: Manual Firestore Entry

1. Go to Firebase Console → Firestore Database
2. Create collection: `legal_documents`
3. Click "Add document"
4. Use auto-generated ID or custom ID
5. Add these fields:

```json
{
  "title": "Terms and Conditions",
  "content": "[Paste full terms content from below]",
  "version": "1.0",
  "lastUpdated": "October 17, 2025 at 12:00:00 PM UTC+8",
  "updatedBy": "admin@pawsense.com",
  "isActive": true,
  "type": "termsAndConditions"
}
```

6. Create subcollection `version_history` inside the document
7. Add document with these fields:

```json
{
  "version": "1.0",
  "timestamp": "October 17, 2025 at 12:00:00 PM UTC+8",
  "updatedBy": "System",
  "changeNotes": "Initial version - Terms and Conditions for PawSense application",
  "content": "[Same terms content as above]"
}
```

### Full Terms and Conditions Content

Copy this content for the `content` field:

```
Welcome to PawSense, an AI-enabled mobile application that uses YOLO-based image processing to assist in the early detection of common pet skin diseases and provide real-time care guidance. By downloading, accessing, or using the PawSense application, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully before using the App.

1. Acceptance of Terms

By accessing or using PawSense, you agree to be legally bound by these Terms. If you do not agree, you must discontinue use of the App immediately.

2. Purpose of the App

PawSense is designed to:
• Provide AI-assisted screening of visible skin conditions in cats and dogs.
• Offer non-prescriptive care guidance and informational resources.
• Facilitate user access to nearby veterinary clinics and related services.

Important: PawSense is not a substitute for professional veterinary diagnosis, advice, or treatment. All health concerns should be confirmed with a licensed veterinarian.

3. User Responsibilities

You agree to:
• Provide accurate and truthful information when registering and using the App.
• Use the App only for lawful purposes and in compliance with applicable laws.
• Avoid misuse of the App, including attempting to reverse engineer, hack, or disrupt services.

4. AI Detection Limitations

• The App detects only visible skin conditions and cannot diagnose internal health issues.
• Accuracy depends on image quality, lighting, and the diversity of the AI training dataset.
• Only one condition per image will be identified; multiple conditions may require separate scans.

5. Data Collection and Privacy

PawSense collects certain personal data (e.g., name, email, pet details) and scan history to provide services.
Images submitted are used for analysis and may be stored for model improvement, with anonymization where applicable.
All data handling follows our Privacy Policy. By using the App, you consent to such data processing.

6. Intellectual Property

All content, features, and functionalities of PawSense—including text, graphics, AI models, and software—are owned by the PawSense developers and are protected by copyright, trademark, and other intellectual property laws.

7. Third-Party Services

The App may include integrations with third-party services (e.g., maps for locating clinics, cloud AI services). Your use of such services is subject to their respective terms and conditions.

8. Disclaimers

PawSense is provided "as is" without warranties of any kind, express or implied.
The developers are not liable for any damages, losses, or injuries resulting from reliance on the Apps results or guidance.
Veterinary care decisions should always be made with professional input.

9. Limitation of Liability

To the maximum extent permitted by law, PawSense and its developers will not be liable for:
• Errors or inaccuracies in AI analysis.
• Any loss or damage resulting from reliance on the Apps outputs.
• Service interruptions, bugs, or technical failures.

10. Modifications to Terms

We may update these Terms at any time. Continued use of the App after updates means you accept the revised Terms.

11. Governing Law

These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines.
```

## Verification

After seeding, verify in Firebase Console:

### Check Collection
```
legal_documents/
  [document_id]/
    ✓ title: "Terms and Conditions"
    ✓ content: [Full text]
    ✓ version: "1.0"
    ✓ lastUpdated: [Timestamp]
    ✓ updatedBy: "System" or "admin@pawsense.com"
    ✓ isActive: true
    ✓ type: "termsAndConditions"
    
    version_history/
      [version_id]/
        ✓ version: "1.0"
        ✓ timestamp: [Timestamp]
        ✓ updatedBy: "System"
        ✓ changeNotes: "Initial version..."
        ✓ content: [Full text]
```

### Check in Super Admin Panel

1. Login as Super Admin
2. Go to **System Settings**
3. Click **Legal Documents** tab
4. You should see:
   - ✅ "Terms and Conditions" document
   - ✅ Status badge: ACTIVE (green)
   - ✅ Version: 1.0
   - ✅ Updated by and timestamp

## Firestore Security Rules

Add these rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is super admin
    function isSuperAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // Legal documents collection
    match /legal_documents/{document} {
      // Anyone can read active documents
      allow read: if resource.data.isActive == true;
      
      // Super admins can read all documents
      allow read: if isSuperAdmin();
      
      // Only super admins can write
      allow create, update, delete: if isSuperAdmin();
      
      // Version history subcollection
      match /version_history/{version} {
        allow read, write: if isSuperAdmin();
      }
    }
  }
}
```

## Troubleshooting

### "Documents not showing in Super Admin"
- ✓ Check Firestore has `legal_documents` collection
- ✓ Check document has `isActive: true`
- ✓ Check your user has `role: 'super_admin'` in `users` collection
- ✓ Check Firestore security rules allow reading

### "Failed to seed database"
- ✓ Check Firebase is initialized before calling `seedLegalDocuments()`
- ✓ Check network connection
- ✓ Check Firestore security rules allow writing (disable temporarily for seeding)
- ✓ Check Firebase Console for error messages

### "Seeding runs multiple times"
- ✓ **Comment out** `await seedLegalDocuments();` after first run
- ✓ The script checks if Terms and Conditions exists before creating

### "Version history not showing"
- ✓ Check `version_history` subcollection exists inside the document
- ✓ Check subcollection has at least one document
- ✓ Check Firestore security rules allow reading subcollection

## Next Steps

After seeding:

1. ✅ Test creating new document via Super Admin panel
2. ✅ Test editing document (creates version history)
3. ✅ Test activating/deactivating documents
4. ✅ Test viewing version history
5. ✅ Update mobile app to fetch from Firestore (see main README)
6. ✅ Add Privacy Policy and other documents as needed

## Summary

| Method | Best For | Effort | Control |
|--------|----------|--------|---------|
| **Option 1** (Script) | Quick setup, automated | ⚡ Low | 🔄 Automated |
| **Option 2** (Manual) | Fine-grained control | ⏱️ Medium | ✋ Manual |

**Recommendation:** Use **Option 1** for initial seeding, then manage all documents through the Super Admin panel UI.
