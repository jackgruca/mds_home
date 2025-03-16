// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart' as app_models;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get the current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  // Authentication stream
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // Register a new user
  Future<app_models.User?> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    try {
      // Create auth account
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Failed to create account');
      
      // Set display name
      await firebaseUser.updateDisplayName(name);
      
      // Create user document in Firestore
      final user = app_models.User(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        isSubscribed: isSubscribed,
        preferences: {
          'hasPersonalRankings': false,
        },
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toFirestore());
      
      // Send email verification
      await firebaseUser.sendEmailVerification();
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    }
  }
  
  // Sign in an existing user
  Future<app_models.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Failed to sign in');
      
      // Update last login time
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return app_models.User.fromFirestore(userDoc.data()!, firebaseUser.uid);
      }
      
      // If user document doesn't exist, create it
      final user = app_models.User(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        isSubscribed: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toFirestore());
      
      return user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
  
  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  // Get user data from Firestore
  Future<app_models.User?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return app_models.User.fromFirestore(userDoc.data()!, uid);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    bool? isSubscribed,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (name != null) {
        updates['name'] = name;
        // Update display name in Firebase Auth as well
        if (currentFirebaseUser != null) {
          await currentFirebaseUser!.updateDisplayName(name);
        }
      }
      
      if (isSubscribed != null) updates['isSubscribed'] = isSubscribed;
      if (preferences != null) updates['preferences'] = preferences;
      
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) throw Exception('No user is signed in');
      
      // Re-authenticate user before changing password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }
}