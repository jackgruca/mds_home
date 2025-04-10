// lib/services/firebase_auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_models;

/// Service for Firebase Authentication (to be implemented in Phase 2)
class FirebaseAuthService {
  /// Future implementation note: This class will replace AuthService
  /// in Phase 2 of the authentication implementation plan.
  
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  // Placeholder for current user
  static app_models.User? _currentUser;
  
  // Get current user
  static app_models.User? get currentUser => _currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;
  
  // Initialize Firebase Auth service
  static Future<void> initialize() async {
    // This will be implemented in Phase 2
    // The stub is here to prepare for migration
    debugPrint('Firebase Auth Service initialized (placeholder)');
  }
  
  // Convert Firebase User to App User
  static app_models.User? _firebaseUserToAppUser(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) return null;
    
    // This will be expanded in Phase 2
    return app_models.User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      isSubscribed: false, // Default value
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
  
  // Auth state changes
  static Stream<app_models.User?> get authStateChanges {
    // This will be implemented in Phase 2
    // For now, return an empty stream
    return Stream.value(null);
  }
  
  // Register new user stub
  static Future<app_models.User> register({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    // This will be implemented in Phase 2
    throw UnimplementedError('Firebase Auth not yet implemented');
  }
  
  // Sign in stub
  static Future<app_models.User> signIn({
    required String email,
    required String password,
  }) async {
    // This will be implemented in Phase 2
    throw UnimplementedError('Firebase Auth not yet implemented');
  }
  
  // Sign out stub
  static Future<void> signOut() async {
    // This will be implemented in Phase 2
    throw UnimplementedError('Firebase Auth not yet implemented');
  }
  
  // Password reset stub
  static Future<void> sendPasswordResetEmail(String email) async {
    // This will be implemented in Phase 2
    throw UnimplementedError('Firebase Auth not yet implemented');
  }
}