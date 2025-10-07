import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/support/faq_item_model.dart';

/// Demo data seeder for FAQ items
class FAQDemoSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'faqs';

  /// Seed demo FAQ data
  static Future<void> seedDemoFAQs() async {
    try {
      // Check if FAQs already exist
      final existingFAQs = await _firestore.collection(_collection).limit(1).get();
      if (existingFAQs.docs.isNotEmpty) {
        print('FAQs already exist, skipping seeding');
        return;
      }

      // Super Admin FAQs (General App FAQs)
      final superAdminFAQs = [
        {
          'question': 'How do I use the AI assessment feature?',
          'answer': 'To use the AI assessment feature, tap the camera button on the home screen, take a clear photo of your pet\'s skin condition, and follow the guided assessment process. The AI will analyze the image and provide insights about potential skin conditions.',
          'category': 'AI Assessment',
          'isSuperAdminFAQ': true,
        },
        {
          'question': 'How accurate is the AI skin disease detection?',
          'answer': 'Our AI system is trained on thousands of veterinary images and provides preliminary assessments. While highly accurate, the AI results should always be confirmed by a qualified veterinarian for proper diagnosis and treatment.',
          'category': 'AI Assessment',
          'isSuperAdminFAQ': true,
        },
        {
          'question': 'How do I book an appointment through the app?',
          'answer': 'To book an appointment, go to the home screen, tap "Book Appointment", select your preferred clinic, choose an available time slot, and provide the necessary pet information. You can also book directly after completing an AI assessment.',
          'category': 'Appointments',
          'isSuperAdminFAQ': true,
        },
        {
          'question': 'Can I cancel or reschedule my appointment?',
          'answer': 'Yes, you can manage your appointments through the "Appointment History" section. Please note that cancellations should be made at least 24 hours in advance when possible.',
          'category': 'Appointments',
          'isSuperAdminFAQ': true,
        },
        {
          'question': 'How do I add multiple pets to my account?',
          'answer': 'You can add multiple pets by going to the "Pets" section and tapping the "+" button. Fill in each pet\'s information including name, breed, age, and any medical notes.',
          'category': 'Pet Management',
          'isSuperAdminFAQ': true,
        },
        {
          'question': 'Is my pet\'s medical data secure?',
          'answer': 'Yes, we take data security seriously. All pet medical information is encrypted and stored securely in compliance with data protection regulations. Only you and authorized veterinarians can access your pet\'s information.',
          'category': 'Privacy & Security',
          'isSuperAdminFAQ': true,
        },
      ];

      // Sample Clinic FAQs (for demo clinic)
      final clinicFAQs = [
        {
          'question': 'What are your operating hours?',
          'answer': 'We are open Monday to Friday from 8:00 AM to 6:00 PM, and Saturday from 9:00 AM to 4:00 PM. We are closed on Sundays and major holidays.',
          'category': 'Hours & Location',
          'isSuperAdminFAQ': false,
          'clinicId': 'demo_clinic_1',
        },
        {
          'question': 'Do you accept walk-in appointments?',
          'answer': 'We primarily work by appointment to ensure quality care and minimal wait times. However, we do accept urgent walk-ins based on availability. For non-emergency cases, we recommend booking through the PawSense app.',
          'category': 'Appointments',
          'isSuperAdminFAQ': false,
          'clinicId': 'demo_clinic_1',
        },
        {
          'question': 'What should I bring for my pet\'s first visit?',
          'answer': 'Please bring any previous medical records, vaccination certificates, current medications, and a list of questions. If your pet has behavioral concerns or dietary needs, please inform us when booking.',
          'category': 'First Visit',
          'isSuperAdminFAQ': false,
          'clinicId': 'demo_clinic_1',
        },
        {
          'question': 'What payment methods do you accept?',
          'answer': 'We accept cash, credit cards (Visa, MasterCard), debit cards, and some pet insurance plans. Payment is due at the time of service unless prior arrangements have been made.',
          'category': 'Payment',
          'isSuperAdminFAQ': false,
          'clinicId': 'demo_clinic_1',
        },
        {
          'question': 'Do you provide emergency services?',
          'answer': 'For after-hours emergencies, please contact our emergency hotline. During regular hours, we handle urgent cases based on availability. For life-threatening emergencies, we may refer you to the nearest 24-hour emergency clinic.',
          'category': 'Emergency Care',
          'isSuperAdminFAQ': false,
          'clinicId': 'demo_clinic_1',
        },
        {
          'question': 'How often should my pet have a check-up?',
          'answer': 'We recommend annual wellness exams for healthy adult pets, and bi-annual visits for senior pets (7+ years). Puppies and kittens may need more frequent visits during their first year.',
          'category': 'Preventive Care',
          'isSuperAdminFAQ': false,
          'clinicId': 'demo_clinic_1',
        },
      ];

      // Seed Super Admin FAQs
      for (final faqData in superAdminFAQs) {
        final docRef = _firestore.collection(_collection).doc();
        final faq = FAQItemModel(
          id: docRef.id,
          question: faqData['question'] as String,
          answer: faqData['answer'] as String,
          category: faqData['category'] as String,
          views: 0,
          helpfulVotes: 0,
          clinicId: null,
          isSuperAdminFAQ: true,
          createdAt: DateTime.now(),
          createdBy: 'system',
          isPublished: true,
        );
        await docRef.set(faq.toMap());
      }

      // Seed Clinic FAQs
      for (final faqData in clinicFAQs) {
        final docRef = _firestore.collection(_collection).doc();
        final faq = FAQItemModel(
          id: docRef.id,
          question: faqData['question'] as String,
          answer: faqData['answer'] as String,
          category: faqData['category'] as String,
          views: 0,
          helpfulVotes: 0,
          clinicId: faqData['clinicId'] as String,
          isSuperAdminFAQ: false,
          createdAt: DateTime.now(),
          createdBy: 'system',
          isPublished: true,
        );
        await docRef.set(faq.toMap());
      }

      print('✅ Demo FAQ data seeded successfully');
      print('   - ${superAdminFAQs.length} Super Admin FAQs');
      print('   - ${clinicFAQs.length} Clinic FAQs');
    } catch (e) {
      print('Error seeding demo FAQ data: $e');
    }
  }

  /// Clear all FAQ data (for testing)
  static Future<void> clearAllFAQs() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ All FAQs cleared');
    } catch (e) {
      print('Error clearing FAQs: $e');
    }
  }
}