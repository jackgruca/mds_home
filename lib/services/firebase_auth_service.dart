// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart' as app_models;

class FirebaseAuthService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current user
  static app_models.User? _currentUser;
  
  // Get current user
  static app_models.User? get currentUser => _currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;
  
  // Initialize Firebase Auth service
  static Future<void> initialize() async {
    try {
      // Listen for auth state changes
      _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
        if (firebaseUser == null) {
          _currentUser = null;
          return;
        }
        
        try {
          // Get user data from Firestore
          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            _currentUser = app_models.User(
              id: firebaseUser.uid,
              name: userData['name'] ?? firebaseUser.displayName ?? '',
              email: userData['email'] ?? firebaseUser.email ?? '',
              isSubscribed: userData['isSubscribed'] ?? false,
              createdAt: userData['createdAt'] != null 
                  ? (userData['createdAt'] as Timestamp).toDate() 
                  : DateTime.now(),
              lastLoginAt: userData['lastLoginAt'] != null 
                  ? (userData['lastLoginAt'] as Timestamp).toDate() 
                  : DateTime.now(),
              favoriteTeams: userData['favoriteTeams'] != null 
                  ? List<String>.from(userData['favoriteTeams']) 
                  : null,
              draftPreferences: userData['draftPreferences'],
            );
          } else {
            // Create basic user if not in Firestore
            _currentUser = app_models.User(
              id: firebaseUser.uid,
              name: firebaseUser.displayName ?? '',
              email: firebaseUser.email ?? '',
              isSubscribed: false,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            );
            
            // Save to Firestore
            await _firestore.collection('users').doc(firebaseUser.uid).set({
              'name': _currentUser!.name,
              'email': _currentUser!.email,
              'isSubscribed': _currentUser!.isSubscribed,
              'createdAt': Timestamp.fromDate(_currentUser!.createdAt),
              'lastLoginAt': Timestamp.fromDate(_currentUser!.lastLoginAt),
            });
          }
        } catch (e) {
          debugPrint('Error loading user data: $e');
        }
      });
      
      debugPrint('Firebase Auth Service initialized');
    } catch (e) {
      debugPrint('Error initializing Firebase Auth: $e');
    }
  }
  
  // Register new user
  static Future<app_models.User> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Failed to create user');
      }
      
      // Update display name
      await credential.user!.updateDisplayName(name);
      
      // Create user model
      final user = app_models.User(
        id: credential.user!.uid,
        name: name,
        email: email,
        isSubscribed: isSubscribed,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'isSubscribed': user.isSubscribed,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt),
      });
      
      // Send email verification
      await credential.user!.sendEmailVerification();
      
      _currentUser = user;
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw _handleAuthError(e);
    }
  }
  
  // Sign in
  static Future<app_models.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Failed to sign in');
      }
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
      
      // Create or update user model
      app_models.User user;
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        user = app_models.User(
          id: credential.user!.uid,
          name: userData['name'] ?? credential.user!.displayName ?? '',
          email: userData['email'] ?? credential.user!.email ?? '',
          isSubscribed: userData['isSubscribed'] ?? false,
          createdAt: userData['createdAt'] != null 
              ? (userData['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          lastLoginAt: DateTime.now(),
          favoriteTeams: userData['favoriteTeams'] != null 
              ? List<String>.from(userData['favoriteTeams']) 
              : null,
          draftPreferences: userData['draftPreferences'],
        );
      } else {
        user = app_models.User(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? '',
          email: credential.user!.email ?? '',
          isSubscribed: false,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
      
      // Update last login
      await _firestore.collection('users').doc(user.id).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
      
      _currentUser = user;
      return user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      throw _handleAuthError(e);
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
  
  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      throw _handleAuthError(e);
    }
  }
  
  // Update user profile
  static Future<app_models.User> updateUserProfile({
    required String name,
    required bool isSubscribed,
  }) async {
    if (_auth.currentUser == null || _currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update Firebase Auth display name
      await _auth.currentUser!.updateDisplayName(name);
      
      // Update user model
      final updatedUser = _currentUser!.copyWith(
        name: name,
        isSubscribed: isSubscribed,
      );
      
      // Update Firestore
      await _firestore.collection('users').doc(updatedUser.id).update({
        'name': name,
        'isSubscribed': isSubscribed,
      });
      
      _currentUser = updatedUser;
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
  
  // Update user preferences
  static Future<app_models.User> updateUserPreferences({
    required Map<String, dynamic> preferences,
  }) async {
    if (_auth.currentUser == null || _currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Merge with existing preferences
      Map<String, dynamic> updatedPreferences = 
        _currentUser!.draftPreferences != null 
        ? {..._currentUser!.draftPreferences!, ...preferences}
        : preferences;
      
      // Update user model
      final updatedUser = _currentUser!.copyWith(
        draftPreferences: updatedPreferences,
      );
      
      // Update Firestore
      await _firestore.collection('users').doc(updatedUser.id).update({
        'draftPreferences': updatedPreferences,
      });
      
      _currentUser = updatedUser;
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      throw Exception('Failed to update preferences: $e');
    }
  }
  
  // Update favorite teams
  static Future<app_models.User> updateFavoriteTeams(List<String> favoriteTeams) async {
    if (_auth.currentUser == null || _currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update user model
      final updatedUser = _currentUser!.copyWith(
        favoriteTeams: favoriteTeams,
      );
      
      // Update Firestore
      await _firestore.collection('users').doc(updatedUser.id).update({
        'favoriteTeams': favoriteTeams,
      });
      
      _currentUser = updatedUser;
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating favorite teams: $e');
      throw Exception('Failed to update favorite teams: $e');
    }
  }
  
  // Helper method to handle Firebase Auth errors
  static Exception _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return Exception('This email is already in use. Please try a different one or sign in.');
        case 'weak-password':
          return Exception('Password is too weak. Please use a stronger password.');
        case 'invalid-email':
          return Exception('The email address is not valid.');
        case 'user-not-found':
        case 'wrong-password':
          return Exception('Invalid email or password.');
        case 'user-disabled':
          return Exception('Your account has been disabled.');
        case 'too-many-requests':
          return Exception('Too many failed login attempts. Please try again later.');
        default:
          return Exception('Authentication error: ${error.message}');
      }
    }
    
    return Exception('Authentication error: $error');
  }
}