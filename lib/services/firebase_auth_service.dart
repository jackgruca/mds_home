// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart' as app_user;

class FirebaseAuthService {
  static firebase_auth.FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static bool _initialized = false;

  // Initialize Firebase Auth
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      _auth = firebase_auth.FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      debugPrint('Firebase Auth initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Auth: $e');
      throw Exception('Firebase Auth initialization failed: $e');
    }
  }

  // Check if user is logged in
  static bool get isLoggedIn {
    return _auth?.currentUser != null;
  }

  // Get current user
  static app_user.User? get currentUser {
    final firebaseUser = _auth?.currentUser;
    if (firebaseUser == null) return null;
    
    // This is a placeholder - in a real implementation,
    // you would fetch the user document from Firestore
    return app_user.User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  // Sign up new user
  static Future<app_user.User> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user!.updateDisplayName(name);
      
      // Create user document in Firestore
      final user = app_user.User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        isSubscribed: isSubscribed,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      await _firestore!.collection('users').doc(user.id).set(user.toJson());
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw Exception('Failed to register: $e');
    }
  }

  // Sign in existing user
  static Future<app_user.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get user document from Firestore
      final doc = await _firestore!.collection('users').doc(userCredential.user!.uid).get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        
        // Update last login time
        await _firestore!.collection('users').doc(userCredential.user!.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
        
        return app_user.User.fromJson(userData);
      } else {
        // Create user document if it doesn't exist (migration case)
        final user = app_user.User(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? '',
          email: userCredential.user!.email ?? '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _firestore!.collection('users').doc(user.id).set(user.toJson());
        
        return user;
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth!.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update user data
  static Future<app_user.User> updateUser(app_user.User user) async {
    try {
      await _firestore!.collection('users').doc(user.id).update(user.toJson());
      return user;
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Get user by ID
  static Future<app_user.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return app_user.User.fromJson(doc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }
}