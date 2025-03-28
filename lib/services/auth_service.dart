// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // Keys for storing data in shared preferences
  static const String _userKey = 'current_user';
  static const String _usersKey = 'registered_users';
  
  // Stream controller for authentication state changes
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
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        debugPrint('User loaded: ${_currentUser?.name}');
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
      // Check if email already exists
      if (await _emailExists(email)) {
        throw Exception('Email already in use');
      }
      
      // Create a new user
      final user = User(
        id: _generateUserId(),
        name: name,
        email: email,
        isSubscribed: isSubscribed,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save the user to storage
      await _saveUser(user, password);
      
      // Set as current user
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
      // Get all users
      final users = await _getAllUsers();
      
      // Find the user with matching email
      for (var user in users.entries) {
        final userData = User.fromJson(jsonDecode(user.key));
        
        if (userData.email.toLowerCase() == email.toLowerCase() && 
            user.value == password) {
          // Update last login
          final updatedUser = userData.copyWith(
            lastLoginAt: DateTime.now(),
          );
          
          // Save the updated user
          await _updateUser(updatedUser, password);
          
          // Set as current user
          await _saveCurrentUser(updatedUser);
          
          return updatedUser;
        }
      }
      
      throw Exception('Invalid email or password');
    } catch (e) {
      debugPrint('Error signing in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }
  
  // Sign out the current user
  static Future<void> signOut() async {
    try {
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
      // Get the user's password
      final password = await _getUserPassword(_currentUser!.id);
      
      // Update the user
      final updatedUser = _currentUser!.copyWith(
        isSubscribed: isSubscribed,
      );
      
      // Save the updated user
      await _updateUser(updatedUser, password);
      
      // Update current user
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }
  
  // Helper methods
  
  // Check if an email already exists
  static Future<bool> _emailExists(String email) async {
    final users = await _getAllUsers();
    
    for (var user in users.entries) {
      final userData = User.fromJson(jsonDecode(user.key));
      if (userData.email.toLowerCase() == email.toLowerCase()) {
        return true;
      }
    }
    
    return false;
  }
  
  // Save a user to storage
  static Future<void> _saveUser(User user, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final users = await _getAllUsers();
      
      // Add the new user
      users[jsonEncode(user.toJson())] = password;
      
      // Save back to preferences
      await prefs.setString(_usersKey, jsonEncode(users));
    } catch (e) {
      debugPrint('Error saving user: $e');
      throw Exception('Failed to save user: $e');
    }
  }
  
  // Update an existing user
  static Future<void> _updateUser(User user, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final users = await _getAllUsers();
      
      // Remove old user data
      users.removeWhere((key, _) {
        final userData = User.fromJson(jsonDecode(key));
        return userData.id == user.id;
      });
      
      // Add updated user
      users[jsonEncode(user.toJson())] = password;
      
      // Save back to preferences
      await prefs.setString(_usersKey, jsonEncode(users));
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }
  
  // Get a user's password
  static Future<String> _getUserPassword(String userId) async {
    try {
      final users = await _getAllUsers();
      
      for (var user in users.entries) {
        final userData = User.fromJson(jsonDecode(user.key));
        if (userData.id == userId) {
          return user.value;
        }
      }
      
      throw Exception('User not found');
    } catch (e) {
      debugPrint('Error getting user password: $e');
      throw Exception('Failed to get user password: $e');
    }
  }
  
  // Get all users from storage
  static Future<Map<String, String>> _getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson != null) {
        final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as String));
      }
      
      return {};
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return {};
    }
  }


static Future<User> updateUser(User user) async {
  // Implementation depends on how your auth service is set up
  // Here's a simple placeholder that just returns the user
  return user;
}

  // Generate and store a password reset token
  static Future<String> generatePasswordResetToken(String email) async {
    try {
      // Get all users
      final users = await _getAllUsers();
      User? user;
      String? password;
      
      // Find the user with matching email
      for (var entry in users.entries) {
        final userData = User.fromJson(jsonDecode(entry.key));
        
        if (userData.email.toLowerCase() == email.toLowerCase()) {
          user = userData;
          password = entry.value;
          break;
        }
      }
      
      if (user == null) {
        throw Exception('Email not found');
      }
      
      // Generate a random token
      final token = _generateResetToken();
      final expiry = DateTime.now().add(const Duration(hours: 24)); // Token valid for 24 hours
      
      // Update the user with the token
      final updatedUser = user.copyWith(
        resetToken: token,
        resetTokenExpiry: expiry,
      );
      
      // Save the updated user
      await _updateUser(updatedUser, password!);
      
      return token;
    } catch (e) {
      debugPrint('Error generating reset token: $e');
      throw Exception('Failed to generate reset token: $e');
    }
  }

  // Verify a password reset token
  static Future<bool> verifyResetToken(String email, String token) async {
    try {
      // Get all users
      final users = await _getAllUsers();
      
      // Find the user with matching email
      for (var entry in users.entries) {
        final userData = User.fromJson(jsonDecode(entry.key));
        
        if (userData.email.toLowerCase() == email.toLowerCase()) {
          // Check if token is valid and not expired
          if (userData.resetToken == token && 
              userData.resetTokenExpiry != null && 
              userData.resetTokenExpiry!.isAfter(DateTime.now())) {
            return true;
          }
          break;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error verifying reset token: $e');
      return false;
    }
  }

  // Reset password using a token
  static Future<bool> resetPassword(String email, String token, String newPassword) async {
    try {
      // Verify the token first
      final isValid = await verifyResetToken(email, token);
      
      if (!isValid) {
        throw Exception('Invalid or expired token');
      }
      
      // Get all users
      final users = await _getAllUsers();
      User? user;
      
      // Find the user with matching email
      for (var entry in users.entries) {
        final userData = User.fromJson(jsonDecode(entry.key));
        
        if (userData.email.toLowerCase() == email.toLowerCase()) {
          user = userData;
          break;
        }
      }
      
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Clear the reset token
      final updatedUser = user.copyWith(
        resetToken: null,
        resetTokenExpiry: null,
      );
      
      // Save the updated user with new password
      await _updateUser(updatedUser, newPassword);
      
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  // Helper method to generate a reset token
  static String _generateResetToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        32, 
        (_) => chars.codeUnitAt(random.nextInt(chars.length))
      )
    );
  }

  // Add these methods to the User preferences section
  static Future<User> updateFavoriteTeams(List<String> favoriteTeams) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // Get the user's password
      final password = await _getUserPassword(_currentUser!.id);
      
      // Update the user
      final updatedUser = _currentUser!.copyWith(
        favoriteTeams: favoriteTeams,
      );
      
      // Save the updated user
      await _updateUser(updatedUser, password);
      
      // Update current user
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
      // Get the user's password
      final password = await _getUserPassword(_currentUser!.id);
      
      // Update the user
      final updatedUser = _currentUser!.copyWith(
        draftPreferences: preferences,
      );
      
      // Save the updated user
      await _updateUser(updatedUser, password);
      
      // Update current user
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating draft preferences: $e');
      throw Exception('Failed to update draft preferences: $e');
    }
  }
  
  // Generate a unique user ID
  static String _generateUserId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        20, 
        (_) => chars.codeUnitAt(random.nextInt(chars.length))
      )
    );
  }
}