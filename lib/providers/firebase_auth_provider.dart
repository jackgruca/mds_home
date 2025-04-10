// lib/providers/firebase_auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../models/custom_draft_data.dart';

class FirebaseAuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuthService.initialize();
      _user = FirebaseAuthService.currentUser;
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
      _user = await FirebaseAuthService.register(
        name: name,
        email: email,
        password: password,
        isSubscribed: isSubscribed,
      );
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

  // Sign in an existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await FirebaseAuthService.signIn(
        email: email,
        password: password,
      );
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
  
  // Sign out the current user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuthService.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final updatedUser = _user!.copyWith(isSubscribed: isSubscribed);
      _user = await FirebaseAuthService.updateUser(updatedUser);
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
      await FirebaseAuthService.sendPasswordResetEmail(email);
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
      final updatedUser = _user!.copyWith(favoriteTeams: favoriteTeams);
      _user = await FirebaseAuthService.updateUser(updatedUser);
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
      final updatedUser = _user!.copyWith(draftPreferences: preferences);
      _user = await FirebaseAuthService.updateUser(updatedUser);
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

  // Update user in database
  Future<bool> _updateUserInDb() async {
    if (_user == null) {
      _error = "Cannot update: No user is logged in";
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await FirebaseAuthService.updateUser(_user!);
      
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

  // Get user's saved custom draft data sets
  List<CustomDraftData> getUserCustomDraftData() {
    if (!isLoggedIn || user == null) return [];
    
    final List<dynamic> storedData = user?.customDraftData ?? [];
    return storedData.map((data) => 
      CustomDraftData.fromJson(data)
    ).toList();
  }

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
      
      // Update user's custom data
      user?.customDraftData = jsonData;
      
      // Save to database
      return await _updateUserInDb();
    } catch (e) {
      debugPrint('Error saving custom draft data: $e');
      _error = 'Failed to save custom draft data: $e';
      return false;
    }
  }

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
      
      // Update user's custom data
      user?.customDraftData = jsonData;
      
      // Save to database
      return await _updateUserInDb();
    } catch (e) {
      debugPrint('Error deleting custom draft data: $e');
      _error = 'Failed to delete custom draft data: $e';
      return false;
    }
  }
}