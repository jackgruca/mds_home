// Update lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../models/custom_draft_data.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
 get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.initialize();
      _user = AuthService.currentUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.register(
        name: name,
        email: email,
        password: password,
        isSubscribed: isSubscribed,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatAuthError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in an existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatAuthError(e.toString());
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign out the current user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    // Update user profile
  Future<bool> updateUser(User updatedUser) async {
    if (_user == null) {
      _error = "Cannot update: No user is logged in";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.updateUser(updatedUser);
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      _error = 'Failed to update user data: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update the user's subscription status
  Future<bool> updateSubscription(bool isSubscribed) async {
    if (_user == null) {
      _error = 'No user logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.updateSubscription(isSubscribed);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request a password reset
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.generatePasswordResetToken(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset a password with token
  Future<bool> resetPassword(String email, String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await AuthService.resetPassword(email, token, newPassword);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = _formatAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify a reset token
  Future<bool> verifyResetToken(String email, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isValid = await AuthService.verifyResetToken(email, token);
      _isLoading = false;
      notifyListeners();
      return isValid;
    } catch (e) {
      _error = _formatAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user favorite teams
  Future<bool> updateFavoriteTeams(List<String> favoriteTeams) async {
    if (_user == null) {
      _error = 'No user logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.updateFavoriteTeams(favoriteTeams);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user draft preferences
  Future<bool> updateDraftPreferences(Map<String, dynamic> preferences) async {
    if (_user == null) {
      _error = 'No user logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.updateDraftPreferences(preferences);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _updateUserInDb() async {
    if (_user == null) {
      _error = "Cannot update: No user is logged in";
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.updateUser(_user!);
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      _error = 'Failed to update user data: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to format Firebase Auth errors into user-friendly messages
  String _formatAuthError(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email address';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters';
    } else if (errorMessage.contains('invalid-email')) {
      return 'The email address is not valid';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This user account has been disabled';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please try again later';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'This login method is not enabled';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection';
    }
    
    // Default error message
    return 'An error occurred: $errorMessage';
  }

  // Get user's saved custom draft data sets
  List<CustomDraftData> getUserCustomDraftData() {
    if (!isLoggedIn || user == null) return [];
    
    final List<dynamic> storedData = user?.customDraftData ?? [];
    return storedData.map((data) => 
      CustomDraftData.fromJson(data)
    ).toList();
  }

  // Save a custom draft data set
  // Save a custom draft data set
Future<bool> saveCustomDraftData(CustomDraftData draftData) async {
  if (!isLoggedIn || user == null) return false;
  
  try {
    // Get current custom data
    List<CustomDraftData> currentData = getUserCustomDraftData();
    
    // Check if a set with this name already exists
    int existingIndex = currentData.indexWhere((data) => data.name == draftData.name);
    
    if (existingIndex >= 0) {
      // Update existing data set
      currentData[existingIndex] = draftData;
    } else {
      // Add new data set
      currentData.add(draftData);
    }
    
    // Convert to JSON for storage
    List<Map<String, dynamic>> jsonData = currentData.map((data) => 
      data.toJson()
    ).toList();
    
    // Since user.customDraftData is final, we need to create a new User object
    final updatedUser = user!.copyWith(
      customDraftData: jsonData
    );
    
    // Update user in AuthProvider
    _user = updatedUser;
    
    // Save to database (this method should update both local storage and Firestore)
    return await _updateUserInDb();
  } catch (e) {
    debugPrint('Error saving custom draft data: $e');
    _error = 'Failed to save custom draft data: $e';
    return false;
  }
}

  // Delete a custom draft data set
  // Delete a custom draft data set
Future<bool> deleteCustomDraftData(String name) async {
  if (!isLoggedIn || user == null) return false;
  
  try {
    // Get current custom data
    List<CustomDraftData> currentData = getUserCustomDraftData();
    
    // Remove the data set with the given name
    currentData.removeWhere((data) => data.name == name);
    
    // Convert to JSON for storage
    List<Map<String, dynamic>> jsonData = currentData.map((data) => 
      data.toJson()
    ).toList();
    
    // Create a new User object with updated customDraftData
    final updatedUser = user!.copyWith(
      customDraftData: jsonData
    );
    
    // Update user in AuthProvider
    _user = updatedUser;
    
    // Save to database
    return await _updateUserInDb();
  } catch (e) {
    debugPrint('Error deleting custom draft data: $e');
    _error = 'Failed to delete custom draft data: $e';
    return false;
  }
}
}