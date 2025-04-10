// lib/services/firestore_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/custom_draft_data.dart';
import 'firebase_auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  static final CollectionReference _usersCollection = _firestore.collection('users');
  static final CollectionReference _draftDataCollection = _firestore.collection('draftData');
  
  // Initialize Firestore service
  static Future<void> initialize() async {
    try {
      debugPrint('Firestore Service initialized');
    } catch (e) {
      debugPrint('Error initializing Firestore: $e');
    }
  }
  
  // Get user's custom draft data
  static Future<List<CustomDraftData>> getUserCustomDraftData(String userId) async {
    try {
      final snapshot = await _draftDataCollection
          .doc(userId)
          .collection('userDrafts')
          .orderBy('lastModified', descending: true)
          .get();
      
      final List<CustomDraftData> result = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        result.add(CustomDraftData(
          name: data['name'] ?? 'Unnamed Dataset',
          year: data['year'] ?? DateTime.now().year,
          lastModified: data['lastModified'] != null 
              ? (data['lastModified'] as Timestamp).toDate() 
              : DateTime.now(),
          teamNeeds: data['teamNeeds'] != null 
              ? _decodeNestedList(data['teamNeeds']) 
              : null,
          playerRankings: data['playerRankings'] != null 
              ? _decodeNestedList(data['playerRankings']) 
              : null,
        ));
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting custom draft data: $e');
      return [];
    }
  }
  
  // Save custom draft data
  static Future<String> saveCustomDraftData(String userId, CustomDraftData draftData) async {
    try {
      // Create reference to user's draft data
      final userDraftRef = _draftDataCollection.doc(userId).collection('userDrafts');
      
      // Check if draft with same name exists
      final existingQuery = await userDraftRef
          .where('name', isEqualTo: draftData.name)
          .limit(1)
          .get();
      
      // If exists, update it
      if (existingQuery.docs.isNotEmpty) {
        final docId = existingQuery.docs.first.id;
        await userDraftRef.doc(docId).update({
          'name': draftData.name,
          'year': draftData.year,
          'lastModified': Timestamp.fromDate(draftData.lastModified),
          'teamNeeds': draftData.teamNeeds != null 
              ? _encodeNestedList(draftData.teamNeeds!) 
              : null,
          'playerRankings': draftData.playerRankings != null 
              ? _encodeNestedList(draftData.playerRankings!) 
              : null,
        });
        return docId;
      } 
      // Otherwise create new one
      else {
        final docRef = await userDraftRef.add({
          'name': draftData.name,
          'year': draftData.year,
          'lastModified': Timestamp.fromDate(draftData.lastModified),
          'teamNeeds': draftData.teamNeeds != null 
              ? _encodeNestedList(draftData.teamNeeds!) 
              : null,
          'playerRankings': draftData.playerRankings != null 
              ? _encodeNestedList(draftData.playerRankings!) 
              : null,
        });
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error saving custom draft data: $e');
      throw Exception('Failed to save custom draft data: $e');
    }
  }
  
  // Delete custom draft data
  static Future<void> deleteCustomDraftData(String userId, String dataName) async {
    try {
      // Find the document with the given name
      final query = await _draftDataCollection
          .doc(userId)
          .collection('userDrafts')
          .where('name', isEqualTo: dataName)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting custom draft data: $e');
      throw Exception('Failed to delete custom draft data: $e');
    }
  }
  
  // Helper methods for nested lists
  static List<dynamic> _encodeNestedList(List<List<dynamic>> nestedList) {
    return nestedList;
  }
  
  static List<List<dynamic>> _decodeNestedList(List<dynamic> jsonList) {
    return jsonList.map<List<dynamic>>((item) => 
      List<dynamic>.from(item as List)
    ).toList();
  }
}