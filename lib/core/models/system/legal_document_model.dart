import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for legal documents (Terms & Conditions, Privacy Policy, etc.)
class LegalDocumentModel {
  final String id;
  final String title;
  final String content; // HTML/Rich text content
  final String version;
  final DateTime lastUpdated;
  final String updatedBy;
  final bool isActive;
  final DocumentType type;

  LegalDocumentModel({
    required this.id,
    required this.title,
    required this.content,
    required this.version,
    required this.lastUpdated,
    required this.updatedBy,
    required this.isActive,
    required this.type,
  });

  /// Create from Firestore document
  factory LegalDocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegalDocumentModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      version: data['version'] ?? '1.0',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] ?? '',
      isActive: data['isActive'] ?? true,
      type: DocumentType.values.firstWhere(
        (e) => e.toString() == 'DocumentType.${data['type']}',
        orElse: () => DocumentType.termsAndConditions,
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'version': version,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
      'isActive': isActive,
      'type': type.name,
    };
  }

  /// Create a copy with updated fields
  LegalDocumentModel copyWith({
    String? id,
    String? title,
    String? content,
    String? version,
    DateTime? lastUpdated,
    String? updatedBy,
    bool? isActive,
    DocumentType? type,
  }) {
    return LegalDocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
    );
  }
}

/// Type of legal document
enum DocumentType {
  termsAndConditions,
  privacyPolicy,
  userAgreement,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.termsAndConditions:
        return 'Terms and Conditions';
      case DocumentType.privacyPolicy:
        return 'Privacy Policy';
      case DocumentType.userAgreement:
        return 'User Agreement';
      case DocumentType.other:
        return 'Other';
    }
  }
}

/// Version history entry for tracking changes
class DocumentVersionHistory {
  final String version;
  final DateTime timestamp;
  final String updatedBy;
  final String changeNotes;
  final String content;

  DocumentVersionHistory({
    required this.version,
    required this.timestamp,
    required this.updatedBy,
    required this.changeNotes,
    required this.content,
  });

  factory DocumentVersionHistory.fromMap(Map<String, dynamic> data) {
    return DocumentVersionHistory(
      version: data['version'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] ?? '',
      changeNotes: data['changeNotes'] ?? '',
      content: data['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedBy': updatedBy,
      'changeNotes': changeNotes,
      'content': content,
    };
  }
}
