// lib/services/batch_operation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BatchOperationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update multiple documents in the same collection with the same data
  static Future<void> updateMultipleDocuments({
    required String collectionPath,
    required List<String> documentIds,
    required Map<String, dynamic> updateData,
  }) async {
    if (documentIds.isEmpty) return;
    
    try {
      final WriteBatch batch = _firestore.batch();
      
      for (final docId in documentIds) {
        final docRef = _firestore.collection(collectionPath).doc(docId);
        batch.update(docRef, updateData);
      }
      
      await batch.commit();
      debugPrint('Batch update completed for ${documentIds.length} documents');
    } catch (e) {
      debugPrint('Error in batch update: $e');
      rethrow;
    }
  }
  
  /// Set multiple documents in the same collection with different data
  static Future<void> setMultipleDocuments({
    required String collectionPath,
    required Map<String, Map<String, dynamic>> documentData,
    bool merge = true,
  }) async {
    if (documentData.isEmpty) return;
    
    try {
      final WriteBatch batch = _firestore.batch();
      
      documentData.forEach((docId, data) {
        final docRef = _firestore.collection(collectionPath).doc(docId);
        batch.set(docRef, data, SetOptions(merge: merge));
      });
      
      await batch.commit();
      debugPrint('Batch set completed for ${documentData.length} documents');
    } catch (e) {
      debugPrint('Error in batch set: $e');
      rethrow;
    }
  }
  
  /// Delete multiple documents from the same collection
  static Future<void> deleteMultipleDocuments({
    required String collectionPath,
    required List<String> documentIds,
  }) async {
    if (documentIds.isEmpty) return;
    
    try {
      final WriteBatch batch = _firestore.batch();
      
      for (final docId in documentIds) {
        final docRef = _firestore.collection(collectionPath).doc(docId);
        batch.delete(docRef);
      }
      
      await batch.commit();
      debugPrint('Batch delete completed for ${documentIds.length} documents');
    } catch (e) {
      debugPrint('Error in batch delete: $e');
      rethrow;
    }
  }
}