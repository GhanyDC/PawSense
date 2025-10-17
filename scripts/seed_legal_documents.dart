import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to seed initial Terms and Conditions to Firestore
/// 
/// HOW TO USE:
/// 1. Run this function once from your app initialization or a separate seed script
/// 2. You can call it from main.dart or create a separate seeder utility
/// 3. This will create the initial Terms and Conditions document
/// 
/// Example usage in main.dart:
/// ```dart
/// import 'package:pawsense/scripts/seed_legal_documents.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   
///   // Uncomment this line to seed the database (run once only)
///   // await seedLegalDocuments();
///   
///   runApp(MyApp());
/// }
/// ```

Future<void> seedLegalDocuments() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collection = 'legal_documents';
  
  try {
    print('Starting legal documents seeding...');
    
    // Check if Terms and Conditions already exists
    final existingDocs = await firestore
        .collection(collection)
        .where('type', isEqualTo: 'termsAndConditions')
        .get();
    
    if (existingDocs.docs.isNotEmpty) {
      print('Terms and Conditions already exists. Skipping seeding.');
      return;
    }
    
    // Create Terms and Conditions document
    final termsContent = '''Welcome to PawSense, an AI-enabled mobile application that uses YOLO-based image processing to assist in the early detection of common pet skin diseases and provide real-time care guidance. By downloading, accessing, or using the PawSense application, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully before using the App.

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

These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines.''';
    
    final termsData = {
      'title': 'Terms and Conditions',
      'content': termsContent,
      'version': '1.0',
      'lastUpdated': Timestamp.now(),
      'updatedBy': 'System',
      'isActive': true,
      'type': 'termsAndConditions',
    };
    
    // Create the document
    final docRef = await firestore.collection(collection).add(termsData);
    print('✅ Terms and Conditions created with ID: ${docRef.id}');
    
    // Create initial version history
    final versionHistoryData = {
      'version': '1.0',
      'timestamp': Timestamp.now(),
      'updatedBy': 'System',
      'changeNotes': 'Initial version - Terms and Conditions for PawSense application',
      'content': termsContent,
    };
    
    await firestore
        .collection(collection)
        .doc(docRef.id)
        .collection('version_history')
        .add(versionHistoryData);
    print('✅ Version history created');
    
    print('✅ Legal documents seeding completed successfully!');
    
  } catch (e) {
    print('❌ Error seeding legal documents: $e');
    rethrow;
  }
}

/// Manual seeding function - can be called directly with specific content
Future<void> seedCustomLegalDocument({
  required String title,
  required String content,
  required String type, // 'termsAndConditions', 'privacyPolicy', 'userAgreement', 'other'
  String version = '1.0',
  String updatedBy = 'System',
  String changeNotes = 'Initial version',
  bool isActive = true,
}) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collection = 'legal_documents';
  
  try {
    print('Creating custom legal document: $title');
    
    final documentData = {
      'title': title,
      'content': content,
      'version': version,
      'lastUpdated': Timestamp.now(),
      'updatedBy': updatedBy,
      'isActive': isActive,
      'type': type,
    };
    
    // Create the document
    final docRef = await firestore.collection(collection).add(documentData);
    print('✅ Document created with ID: ${docRef.id}');
    
    // Create initial version history
    final versionHistoryData = {
      'version': version,
      'timestamp': Timestamp.now(),
      'updatedBy': updatedBy,
      'changeNotes': changeNotes,
      'content': content,
    };
    
    await firestore
        .collection(collection)
        .doc(docRef.id)
        .collection('version_history')
        .add(versionHistoryData);
    print('✅ Version history created');
    
  } catch (e) {
    print('❌ Error creating document: $e');
    rethrow;
  }
}
