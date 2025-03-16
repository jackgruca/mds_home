// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

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
      _user = await AuthService.signIn(
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

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}