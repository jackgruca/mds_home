// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/custom_draft_data.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
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
      await FirestoreService.initialize();
      
      _user = FirebaseAuthService.currentUser;
      _error = null;
      
      // Notify listeners when Firebase Auth changes
      // (Already handled in FirebaseAuthService)
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing auth provider: $e');
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
      // Validate email format
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Validate password strength
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters long';
        _isLoading = false;
        notifyListeners();
        return false;
      }

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
      debugPrint('Error registering user: $e');
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
      debugPrint('Error signing in: $e');
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
      debugPrint('Error signing out: $e');
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
      debugPrint('Error requesting password reset: $e');
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
      _user = await FirebaseAuthService.updateFavoriteTeams(favoriteTeams);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating favorite teams: $e');
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
      _user = await FirebaseAuthService.updateUserPreferences(
        preferences: preferences,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating draft preferences: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    return updateDraftPreferences(preferences);
  }

  // Get user's saved custom draft data sets
  Future<List<CustomDraftData>> getUserCustomDraftData() async {
    if (!isLoggedIn || user == null) return [];
    
    try {
      return await FirestoreService.getUserCustomDraftData(user!.id);
    } catch (e) {
      debugPrint('Error getting custom draft data: $e');
      _error = 'Failed to get custom draft data: $e';
      return [];
    }
  }

  // Save a custom draft data set
  Future<bool> saveCustomDraftData(CustomDraftData draftData) async {
    if (!isLoggedIn || user == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await FirestoreService.saveCustomDraftData(user!.id, draftData);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving custom draft data: $e');
      _error = 'Failed to save custom draft data: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a custom draft data set
  Future<bool> deleteCustomDraftData(String name) async {
    if (!isLoggedIn || user == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await FirestoreService.deleteCustomDraftData(user!.id, name);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting custom draft data: $e');
      _error = 'Failed to delete custom draft data: $e';
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
}