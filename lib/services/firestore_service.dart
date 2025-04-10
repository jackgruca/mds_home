// Create a new file: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get a user document reference
  static DocumentReference _getUserRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }
  
  // Get user data from Firestore
  static Future<app_user.User?> getUserData(String userId) async {
    try {
      final doc = await _getUserRef(userId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Create User from Firestore data
      return app_user.User(
        id: userId,
        name: data['name'] ?? 'User',
        email: data['email'] ?? '',
        isSubscribed: data['isSubscribed'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        resetToken: data['resetToken'],
        resetTokenExpiry: (data['resetTokenExpiry'] as Timestamp?)?.toDate(),
        favoriteTeams: data['favoriteTeams'] != null ? 
            List<String>.from(data['favoriteTeams']) : null,
        draftPreferences: data['draftPreferences'],
        customDraftData: data['customDraftData'],
      );
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Create or update user in Firestore
  static Future<bool> saveUserData(app_user.User user) async {
    try {
      final userData = {
        'name': user.name,
        'email': user.email,
        'isSubscribed': user.isSubscribed,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if they exist
      if (user.favoriteTeams != null) {
        userData['favoriteTeams'] = user.favoriteTeams;
      }
      
      if (user.draftPreferences != null) {
        userData['draftPreferences'] = user.draftPreferences;
      }
      
      if (user.customDraftData != null) {
        userData['customDraftData'] = user.customDraftData;
      }
      
      await _getUserRef(user.id).set(userData, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error saving user data: $e');
      return false;
    }
  }
  
  // Update user favorite teams
  static Future<bool> updateFavoriteTeams(String userId, List<String> favoriteTeams) async {
    try {
      await _getUserRef(userId).update({
        'favoriteTeams': favoriteTeams,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating favorite teams: $e');
      return false;
    }
  }
  
  // Update user draft preferences
  static Future<bool> updateDraftPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _getUserRef(userId).update({
        'draftPreferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating draft preferences: $e');
      return false;
    }
  }
  
  // Update user subscription status
  static Future<bool> updateSubscription(String userId, bool isSubscribed) async {
    try {
      await _getUserRef(userId).update({
        'isSubscribed': isSubscribed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating subscription status: $e');
      return false;
    }
  }
  
  // Update user custom draft data
  static Future<bool> updateCustomDraftData(String userId, List<dynamic> customDraftData) async {
    try {
      await _getUserRef(userId).update({
        'customDraftData': customDraftData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating custom draft data: $e');
      return false;
    }
  }
  
  // Create user document when a new user registers
  static Future<bool> createUserDocument(app_user.User user) async {
    try {
      final userData = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'isSubscribed': user.isSubscribed,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt),
        'favoriteTeams': user.favoriteTeams ?? [],
        'draftPreferences': user.draftPreferences ?? {},
        'customDraftData': user.customDraftData ?? [],
      };
      
      await _getUserRef(user.id).set(userData);
      return true;
    } catch (e) {
      debugPrint('Error creating user document: $e');
      return false;
    }
  }
  
  // Delete user data (for account deletion)
  static Future<bool> deleteUserData(String userId) async {
    try {
      await _getUserRef(userId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      return false;
    }
  }
}