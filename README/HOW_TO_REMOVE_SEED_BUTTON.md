# How to Remove the Seed Button After Use

## ✅ You've Successfully Seeded Your Database!

Once you've clicked the **"Seed Database"** button and successfully created the Terms and Conditions document, you should **remove this button** from your code to prevent accidental re-seeding.

---

## 🗑️ Removal Steps

### **Step 1: Open the Legal Documents Tab File**

Navigate to:
```
lib/core/widgets/super_admin/system_settings/legal_documents_tab.dart
```

### **Step 2: Remove the Import**

**Delete this line** (around line 5):
```dart
import '../../../services/system/seed_legal_documents_service.dart';
```

### **Step 3: Remove the Seed Button**

**Find and delete** this entire button code (around lines 210-225):
```dart
SizedBox(width: kSpacingMedium),
OutlinedButton.icon(
  onPressed: _handleSeedDatabase,
  icon: const Icon(Icons.cloud_upload_outlined),
  label: const Text('Seed Database'),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.warning,
    side: BorderSide(color: AppColors.warning),
    padding: EdgeInsets.symmetric(
      horizontal: kSpacingLarge,
      vertical: kSpacingMedium,
    ),
  ),
),
```

**Keep** the Create Document button that comes after it.

### **Step 4: Remove the Handler Method**

**Find and delete** the entire `_handleSeedDatabase` method (around lines 65-135):
```dart
Future<void> _handleSeedDatabase() async {
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    // ... entire method content ...
  }
}
```

### **Step 5: Save and Hot Reload**

- Save the file
- Hot reload your app (`r` in terminal or click hot reload button)
- The "Seed Database" button should now be gone ✅

---

## 📝 Quick Reference: Code to Remove

### **Remove Import:**
```dart
import '../../../services/system/seed_legal_documents_service.dart';
```

### **Remove Button (in build method):**
```dart
SizedBox(width: kSpacingMedium),
OutlinedButton.icon(
  onPressed: _handleSeedDatabase,
  icon: const Icon(Icons.cloud_upload_outlined),
  label: const Text('Seed Database'),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.warning,
    side: BorderSide(color: AppColors.warning),
    padding: EdgeInsets.symmetric(
      horizontal: kSpacingLarge,
      vertical: kSpacingMedium,
    ),
  ),
),
```

### **Remove Handler Method:**
```dart
Future<void> _handleSeedDatabase() async {
  // ... entire method ...
}
```

---

## 🎯 What to Keep

**Keep these buttons:**
- ✅ Search field
- ✅ "Create Document" button (green/primary color)

**Your final header should look like:**
```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legal Documents', ...),
          Text('Manage terms and conditions...', ...),
        ],
      ),
    ),
    SizedBox(width: kSpacingMedium),
    SizedBox(
      width: 300,
      child: TextField(...), // Search field
    ),
    SizedBox(width: kSpacingMedium),
    ElevatedButton.icon(
      onPressed: _handleCreateDocument,
      icon: const Icon(Icons.add),
      label: const Text('Create Document'),
      // ... styling
    ),
  ],
),
```

---

## ⚠️ Optional: Keep the Service File

You can optionally keep the seed service file in case you need to seed other document types in the future:
```
lib/core/services/system/seed_legal_documents_service.dart
```

Or delete it if you won't need it again.

---

## ✨ After Removal

Your Legal Documents tab will have a cleaner interface with:
- 📊 Header and description
- 🔍 Search bar
- ➕ Create Document button (only)
- 📄 List of legal documents

No more seed button cluttering the UI! 🎉

---

## 🆘 Troubleshooting

**"I removed the button but getting errors"**
- Make sure you removed the import line too
- Make sure you removed the entire `_handleSeedDatabase()` method
- Save all files and restart your app

**"I want to seed another document type"**
- You can use the "Create Document" button instead
- Manually enter the content through the UI
- Or temporarily add the button back for one-time use
