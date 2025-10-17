import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/system/legal_document_model.dart';

/// Service for managing legal documents in Firestore
class LegalDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  static const String _collection = 'legal_documents';
  static const String _versionHistorySubcollection = 'version_history';

  /// Get all legal documents
  Future<List<LegalDocumentModel>> getAllDocuments() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('lastUpdated', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => LegalDocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting legal documents: $e');
      rethrow;
    }
  }

  /// Get a specific document by ID
  Future<LegalDocumentModel?> getDocument(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) return null;
      
      return LegalDocumentModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting document: $e');
      rethrow;
    }
  }

  /// Get active document by type (used for displaying to users)
  Future<LegalDocumentModel?> getActiveDocumentByType(DocumentType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      return LegalDocumentModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting active document: $e');
      rethrow;
    }
  }

  /// Create a new legal document
  Future<String> createDocument(LegalDocumentModel document, String changeNotes) async {
    try {
      // Create document
      final docRef = await _firestore.collection(_collection).add(document.toFirestore());
      
      // Create initial version history
      await _createVersionHistory(docRef.id, document, changeNotes);
      
      return docRef.id;
    } catch (e) {
      print('Error creating document: $e');
      rethrow;
    }
  }

  /// Update an existing legal document
  Future<void> updateDocument(
    String id,
    LegalDocumentModel updatedDocument,
    String changeNotes,
  ) async {
    try {
      // Get old document for version history
      final oldDoc = await getDocument(id);
      
      if (oldDoc == null) {
        throw Exception('Document not found');
      }

      // Update document
      await _firestore.collection(_collection).doc(id).update(updatedDocument.toFirestore());
      
      // Create version history entry
      await _createVersionHistory(id, updatedDocument, changeNotes);
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }

  /// Delete a legal document
  Future<void> deleteDocument(String id) async {
    try {
      // Delete version history subcollection first
      final versionDocs = await _firestore
          .collection(_collection)
          .doc(id)
          .collection(_versionHistorySubcollection)
          .get();
      
      for (var doc in versionDocs.docs) {
        await doc.reference.delete();
      }
      
      // Delete main document
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  /// Get version history for a document
  Future<List<DocumentVersionHistory>> getVersionHistory(String documentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(documentId)
          .collection(_versionHistorySubcollection)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => DocumentVersionHistory.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting version history: $e');
      rethrow;
    }
  }

  /// Create version history entry
  Future<void> _createVersionHistory(
    String documentId,
    LegalDocumentModel document,
    String changeNotes,
  ) async {
    try {
      final versionHistory = DocumentVersionHistory(
        version: document.version,
        timestamp: document.lastUpdated,
        updatedBy: document.updatedBy,
        changeNotes: changeNotes,
        content: document.content,
      );
      
      await _firestore
          .collection(_collection)
          .doc(documentId)
          .collection(_versionHistorySubcollection)
          .add(versionHistory.toMap());
    } catch (e) {
      print('Error creating version history: $e');
      rethrow;
    }
  }

  /// Toggle document active status
  Future<void> toggleDocumentStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      print('Error toggling document status: $e');
      rethrow;
    }
  }

  /// Deactivate all documents of a specific type (before activating a new one)
  Future<void> deactivateAllOfType(DocumentType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .where('isActive', isEqualTo: true)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();
    } catch (e) {
      print('Error deactivating documents: $e');
      rethrow;
    }
  }

  /// Search documents by title or content
  Future<List<LegalDocumentModel>> searchDocuments(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      
      final lowerQuery = query.toLowerCase();
      
      return snapshot.docs
          .map((doc) => LegalDocumentModel.fromFirestore(doc))
          .where((doc) =>
              doc.title.toLowerCase().contains(lowerQuery) ||
              doc.content.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      print('Error searching documents: $e');
      rethrow;
    }
  }
}
