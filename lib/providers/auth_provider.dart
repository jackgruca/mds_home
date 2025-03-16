// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize and listen for auth changes
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Set up listener for auth state changes
      _authService.authStateChanges.listen((firebase_auth.User? firebaseUser) async {
        if (firebaseUser != null) {
          // User is signed in, fetch their data
          _user = await _authService.getUserData(firebaseUser.uid);
        } else {
          // User is signed out
          _user = null;
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
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
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        isSubscribed: isSubscribed,
      );
      
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      
      _error = 'Failed to create account';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _getFirebaseErrorMessage(e);
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
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      
      _error = 'Failed to sign in';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _getFirebaseErrorMessage(e);
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
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getFirebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update subscription status
  Future<bool> updateProfile({
    String? name,
    bool? isSubscribed,
    Map<String, dynamic>? preferences,
  }) async {
    if (_user == null) {
      _error = 'No user logged in';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.updateUserProfile(
        uid: _user!.uid,
        name: name,
        isSubscribed: isSubscribed,
        preferences: preferences,
      );
      
      // Update local user object
      if (name != null || isSubscribed != null || preferences != null) {
        _user = _user!.copyWith(
          name: name ?? _user!.name,
          isSubscribed: isSubscribed ?? _user!.isSubscribed,
          preferences: preferences ?? _user!.preferences,
        );
      }
      
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
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_user == null) {
      _error = 'No user logged in';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getFirebaseErrorMessage(e);
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
  
  // Helper method to convert Firebase errors to user-friendly messages
  String _getFirebaseErrorMessage(dynamic error) {
    String message = 'An error occurred. Please try again.';
    
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password.';
          break;
        case 'email-already-in-use':
          message = 'This email is already in use.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'requires-recent-login':
          message = 'Please sign in again to perform this action.';
          break;
        default:
          message = error.message ?? message;
      }
    } else {
      message = error.toString();
    }
    
    return message;
  }
}