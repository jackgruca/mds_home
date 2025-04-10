// Update lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class AuthService {
  // Keys for storing data in shared preferences
  static const String _userKey = 'current_user';
  
  // Current user
  static User? _currentUser;
  
  // Get the current user
  static User? get currentUser => _currentUser;
  
  // Check if the user is logged in
  static bool get isLoggedIn => _currentUser != null;
  
  // Initialize the auth service
  static Future<void> initialize() async {
    await _loadCurrentUser();
  }
  
  // Load the current user from shared preferences
  static Future<void> _loadCurrentUser() async {
    try {
      // First check if Firebase has a current user
      final firebaseCurrentUser = FirebaseService.currentUser;
      if (firebaseCurrentUser != null) {
        final userData = await FirebaseService.getUserFromFirestore(firebaseCurrentUser.uid);
        if (userData != null) {
          _currentUser = userData;
          await _saveCurrentUser(_currentUser!);
          debugPrint('User loaded from Firebase: ${_currentUser?.name}');
          return;
        }
      }
      
      // Fall back to stored preferences for offline use
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        debugPrint('User loaded from preferences: ${_currentUser?.name}');
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      _currentUser = null;
    }
  }
  
  // Save the current user to shared preferences
  static Future<void> _saveCurrentUser(User user) async {
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
  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    try {
      // Create the user with Firebase
      final user = await FirebaseService.registerUser(
        name: name,
        email: email,
        password: password,
        isSubscribed: isSubscribed,
      );
      
      // Save to local storage
      await _saveCurrentUser(user);
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw Exception('Failed to register: $e');
    }
  }
  
  // Sign in an existing user
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase
      final user = await FirebaseService.signInUser(
        email: email,
        password: password,
      );
      
      // Save to local storage for offline access
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
      await FirebaseService.signOutUser();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
  
  // Update the user's subscription status
  static Future<User> updateSubscription(bool isSubscribed) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        isSubscribed: isSubscribed,
      );
      
      // Update in Firebase
      await FirebaseService.updateUserInFirestore(updatedUser);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }
  
  // Generate and store a password reset token
  static Future<String> generatePasswordResetToken(String email) async {
    try {
      await FirebaseService.sendPasswordResetEmail(email);
      return "reset_token_sent";
    } catch (e) {
      debugPrint('Error generating reset token: $e');
      throw Exception('Failed to generate reset token: $e');
    }
  }

  // Verify a password reset token
  static Future<bool> verifyResetToken(String email, String token) async {
    try {
      // Firebase handles verification differently
      // This is a stub that returns true if token is not empty
      return token.isNotEmpty;
    } catch (e) {
      debugPrint('Error verifying reset token: $e');
      return false;
    }
  }

  // Reset password using a token
  static Future<bool> resetPassword(String email, String token, String newPassword) async {
    try {
      // This is a stub that returns true if token is not empty
      // In a real implementation, you would use the Firebase auth API
      return token.isNotEmpty;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  // Add these methods to the User preferences section
  static Future<User> updateFavoriteTeams(List<String> favoriteTeams) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        favoriteTeams: favoriteTeams,
      );
      
      // Update in Firebase
      await FirebaseService.updateFavoriteTeams(updatedUser.id, favoriteTeams);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating favorite teams: $e');
      throw Exception('Failed to update favorite teams: $e');
    }
  }

  static Future<User> updateDraftPreferences(Map<String, dynamic> preferences) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        draftPreferences: preferences,
      );
      
      // Update in Firebase
      await FirebaseService.updateDraftPreferences(updatedUser.id, preferences);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating draft preferences: $e');
      throw Exception('Failed to update draft preferences: $e');
    }
  }
  
  static Future<User> updateUser(User user) async {
    try {
      // Update in Firebase
      await FirebaseService.updateUserInFirestore(user);
      
      // Save to SharedPreferences
      await _saveCurrentUser(user);
      
      return user;
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Helper method for saving custom draft data
  static Future<bool> saveCustomDraftData(List<dynamic> customDraftData) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Update the user model
      final updatedUser = _currentUser!.copyWith(
        customDraftData: customDraftData,
      );
      
      // Update in Firebase
      await FirebaseService.saveCustomDraftData(updatedUser.id, customDraftData);
      
      // Save to SharedPreferences
      await _saveCurrentUser(updatedUser);
      
      return true;
    } catch (e) {
      debugPrint('Error saving custom draft data: $e');
      return false;
    }
  }

  // Check if email is verified
  static bool isEmailVerified() {
    return FirebaseService.isEmailVerified();
  }
  
  // Send email verification
  static Future<void> sendEmailVerification() async {
    await FirebaseService.sendEmailVerification();
  }
  
  // Delete account
  static Future<bool> deleteAccount() async {
    try {
      final success = await FirebaseService.deleteAccount();
      
      if (success) {
        // Clear local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_userKey);
        _currentUser = null;
      }
      
      return success;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
}