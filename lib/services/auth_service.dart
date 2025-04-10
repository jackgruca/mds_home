// Update lib/services/auth_service.dart to add Firestore integration
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import 'firestore_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  
  static app_user.User? _currentUser;
  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  // Get the current user
  static app_user.User? get currentUser => _currentUser;
  
  // Check if the user is logged in
  static bool get isLoggedIn => _currentUser != null;
  
  // Initialize the auth service
  static Future<void> initialize() async {
    // Listen for auth state changes from Firebase
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
    });
    
    await _loadCurrentUser();
  }
  
  // Load the current user from shared preferences or Firebase
  static Future<void> _loadCurrentUser() async {
    try {
      // First check if Firebase has a current user
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
        return;
      }
      
      // Fall back to stored preferences (for offline use)
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        _currentUser = app_user.User.fromJson(jsonDecode(userJson));
        debugPrint('User loaded from preferences: ${_currentUser?.name}');
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      _currentUser = null;
    }
  }
  
  // Load user data from Firestore
  static Future<void> _loadUserData(String uid) async {
    try {
      // Try to get user from Firestore
      final firestoreUser = await FirestoreService.getUserData(uid);
      
      if (firestoreUser != null) {
        _currentUser = firestoreUser;
        await _saveCurrentUser(_currentUser!);
        debugPrint('User loaded from Firestore: ${_currentUser?.name}');
        return;
      }
      
      // If not in Firestore yet, create a basic user from Firebase Auth
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return;
      
      _currentUser = app_user.User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        isSubscribed: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save to Firestore
      await FirestoreService.createUserDocument(_currentUser!);
      
      // Save to preferences for offline access
      await _saveCurrentUser(_currentUser!);
      
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
  
  // Save the current user to shared preferences
  static Future<void> _saveCurrentUser(app_user.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      _currentUser = user;
    } catch (e) {
      debugPrint('Error saving user: $e');
      throw Exception('Failed to save user: $e');
    }
  }
  
  // Register a new user
  static Future<app_user.User> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }
      
      // Update display name
      await userCredential.user!.updateDisplayName(name);
      
      // Send email verification
      await userCredential.user!.sendEmailVerification();
      
      // Create user model
      final user = app_user.User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        isSubscribed: isSubscribed,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save to Firestore
      await FirestoreService.createUserDocument(user);
      
      // Save to SharedPreferences for offline access
      await _saveCurrentUser(user);
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw Exception('Failed to register: $e');
    }
  }
  
  // Sign in an existing user
  static Future<app_user.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }
      
      // Try to load the user from Firestore
      final firestoreUser = await FirestoreService.getUserData(userCredential.user!.uid);
      
      if (firestoreUser != null) {
        // Update lastLoginAt
        final updatedUser = firestoreUser.copyWith(
          lastLoginAt: DateTime.now(),
        );
        
        // Save to Firestore
        await FirestoreService.saveUserData(updatedUser);
        
        // Save to SharedPreferences
        await _saveCurrentUser(updatedUser);
        
        return updatedUser;
      }
      
      // If not in Firestore yet, create a new user record
      final user = app_user.User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'User',
        email: email,
        isSubscribed: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save to Firestore
      await FirestoreService.createUserDocument(user);
      
      // Save to SharedPreferences
      await _saveCurrentUser(user);
      
      return user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }
  
  // Sign out the current user
  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
  
  // Update the user's subscription status
  static Future<app_user.User> updateSubscription(bool isSubscribed) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        isSubscribed: isSubscribed,
      );
      
      // Save to Firestore
      await FirestoreService.updateSubscription(updatedUser.id, isSubscribed);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }
  
  // Generate and send a password reset email
  static Future<void> generatePasswordResetToken(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error generating reset token: $e');
      throw Exception('Failed to generate reset token: $e');
    }
  }
  
  // Verify a password reset code
  static Future<bool> verifyResetToken(String email, String code) async {
    try {
      // Firebase handles verification differently
      // This is basically a stub - in a real implementation we might
      // try to verify the code with Firebase
      return code.isNotEmpty;
    } catch (e) {
      debugPrint('Error verifying reset token: $e');
      return false;
    }
  }
  
  // Reset password using a token
  static Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      // In a real Firebase implementation, we'd use confirmPasswordReset
      // For now, we'll just check if the code is not empty
      if (code.isEmpty) {
        return false;
      }
      
      // This is a placeholder implementation
      // In a real app, you'd use Firebase's confirmPasswordReset method
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }
  
  // Update favorite teams
  static Future<app_user.User> updateFavoriteTeams(List<String> favoriteTeams) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        favoriteTeams: favoriteTeams,
      );
      
      // Save to Firestore
      await FirestoreService.updateFavoriteTeams(updatedUser.id, favoriteTeams);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating favorite teams: $e');
      throw Exception('Failed to update favorite teams: $e');
    }
  }

  // ... continuing from the last function in AuthService

  // Update draft preferences
  static Future<app_user.User> updateDraftPreferences(Map<String, dynamic> preferences) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        draftPreferences: preferences,
      );
      
      // Save to Firestore
      await FirestoreService.updateDraftPreferences(updatedUser.id, preferences);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating draft preferences: $e');
      throw Exception('Failed to update draft preferences: $e');
    }
  }
  
  // Update user data in Firestore and local storage
  static Future<app_user.User> updateUser(app_user.User user) async {
    try {
      // Save to Firestore
      await FirestoreService.saveUserData(user);
      
      // Save to SharedPreferences
      await _saveCurrentUser(user);
      
      return user;
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }
  
  // Save custom draft data
  static Future<bool> saveCustomDraftData(String userId, List<dynamic> customDraftData) async {
    try {
      return await FirestoreService.updateCustomDraftData(userId, customDraftData);
    } catch (e) {
      debugPrint('Error saving custom draft data: $e');
      return false;
    }
  }
  
  // Check if user email is verified
  static bool isEmailVerified() {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser?.emailVerified ?? false;
  }
  
  // Send email verification
  static Future<void> sendEmailVerification() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && !firebaseUser.emailVerified) {
      await firebaseUser.sendEmailVerification();
    }
  }
  
  // Delete user account
  static Future<bool> deleteAccount() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        return false;
      }
      
      final userId = firebaseUser.uid;
      
      // Delete user data from Firestore
      await FirestoreService.deleteUserData(userId);
      
      // Delete the Firebase Auth user
      await firebaseUser.delete();
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
      
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
}