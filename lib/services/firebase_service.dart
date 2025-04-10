// Update to lib/services/firebase_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:js' as js;
import '../models/draft_analytics.dart';
import '../models/draft_pick.dart';
import '../models/trade_package.dart';
import '../models/user.dart' as app_user;

class FirebaseService {
  static FirebaseFirestore? _firestoreInstance;
  static const String draftAnalyticsCollection = 'draftAnalytics';
  static const String usersCollection = 'users';
  static bool _initialized = false;
  
  static FirebaseFirestore get _firestore {
    if (_firestoreInstance == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _firestoreInstance!;
  }

  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Get the current authenticated user
  static firebase_auth.User? get currentUser => _auth.currentUser;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (kIsWeb) {
        // On web, check if Firebase is already initialized via index.html
        if (js.context.hasProperty('firebase')) {
          // Firebase is loaded via script tag, use the existing instance
          debugPrint('Firebase already loaded via script tag, using existing instance');
          _firestoreInstance = FirebaseFirestore.instance;
          _initialized = true;
          return;
        }
      }
      
      // Standard initialization for non-web or web without script tag
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCLO_VAZ9l6PK541-tFkYRquISv5x1I-Dw",
          authDomain: "nfl-draft-simulator-9265f.firebaseapp.com",
          projectId: "nfl-draft-simulator-9265f",
          storageBucket: "nfl-draft-simulator-9265f.firebasestorage.app",
          messagingSenderId: "900728713837",
          appId: "1:900728713837:web:3e0c47b05b144c758f8564",
          measurementId: "G-8QGNSTTZGH",
        ),
      );
      
      _firestoreInstance = FirebaseFirestore.instance;
      _initialized = true;
      debugPrint('Firebase initialized successfully via Firebase.initializeApp()');

      // Set up auth state listener for debugging
      _auth.authStateChanges().listen((firebase_auth.User? user) {
        if (user == null) {
          debugPrint('User is currently signed out');
        } else {
          debugPrint('User is signed in: ${user.email}');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      // Still attempt to get Firestore instance in case Firebase was initialized elsewhere
      try {
        _firestoreInstance = FirebaseFirestore.instance;
        _initialized = true;
        debugPrint('Retrieved Firestore instance after error');
      } catch (innerError) {
        debugPrint('Could not get Firestore instance: $innerError');
      }
    }
  }

  /// Save draft results to Firestore
  static Future<bool> saveDraftAnalytics({
    required String userTeam,
    required List<DraftPick> completedPicks,
    required List<TradePackage> executedTrades,
    required int year,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      debugPrint('Starting to save draft analytics...');
      
      // Get current user ID if authenticated
      String? userId = _auth.currentUser?.uid;
      
      // Convert picks to records
      final List<DraftPickRecord> pickRecords = completedPicks
          .where((pick) => pick.selectedPlayer != null)
          .map((pick) => DraftPickRecord(
                pickNumber: pick.pickNumber,
                originalTeam: pick.originalPickNumber != null ? 
                    _findOriginalTeam(completedPicks, pick.originalPickNumber!) : pick.teamName,
                actualTeam: pick.teamName,
                playerId: pick.selectedPlayer!.id,
                playerName: pick.selectedPlayer!.name,
                position: pick.selectedPlayer!.position,
                playerRank: pick.selectedPlayer!.rank,
                school: pick.selectedPlayer!.school,
                round: pick.round,
              ))
          .toList();

      // Convert trades to records
      final List<TradeRecord> tradeRecords = executedTrades
          .map((trade) => TradeRecord(
                teamOffering: trade.teamOffering,
                teamReceiving: trade.teamReceiving,
                picksOffered:
                    trade.picksOffered.map((pick) => pick.pickNumber).toList(),
                targetPick: trade.targetPick.pickNumber,
                additionalTargetPicks: trade.additionalTargetPicks
                    .map((pick) => pick.pickNumber)
                    .toList(),
                valueOffered: trade.totalValueOffered,
                targetValue: trade.targetPickValue,
              ))
          .toList();

      // Create analytics record
      final Map<String, dynamic> recordData = {
        'userTeam': userTeam,
        'timestamp': FieldValue.serverTimestamp(),
        'year': year,
        'picks': pickRecords.map((record) => record.toFirestore()).toList(),
        'trades': tradeRecords.map((record) => record.toFirestore()).toList(),
      };

      // Add user ID if available
      if (userId != null) {
        recordData['userId'] = userId;
      }

      // Save to Firestore
      debugPrint('Saving to Firestore collection: $draftAnalyticsCollection');
      await _firestore.collection(draftAnalyticsCollection).add(recordData);
      
      debugPrint('Draft analytics saved successfully');
      return true;
    } catch (e) {
      debugPrint('Error saving draft analytics: $e');
      return false;
    }
  }

  /// Find original team for a pick by looking up the original pick number
  static String _findOriginalTeam(List<DraftPick> allPicks, int originalPickNumber) {
    for (var pick in allPicks) {
      if (pick.pickNumber == originalPickNumber) {
        return pick.teamName;
      }
    }
    return ''; // Default if not found
  }

  /// Setup the required analytics collections for optimized querying
  static Future<bool> setupAnalyticsCollections() async {
    try {
      // Ensure Firebase is initialized
      if (!isInitialized) {
        await initialize();
      }
      
      final FirebaseFirestore db = FirebaseFirestore.instance;
      
      debugPrint('Starting analytics collections setup...');
      
      // Create metadata document in precomputedAnalytics collection
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'documentsProcessed': 0,
        'setupDate': FieldValue.serverTimestamp()
      });
      
      // Create positionDistribution document
      await db.collection('precomputedAnalytics').doc('positionDistribution').set({
        'overall': {
          'total': 0,
          'positions': {}
        },
        'byTeam': {},
        'lastUpdated': FieldValue.serverTimestamp()
      });
      
      // Create teamNeeds document
      await db.collection('precomputedAnalytics').doc('teamNeeds').set({
        'needs': {},
        'year': DateTime.now().year,
        'lastUpdated': FieldValue.serverTimestamp()
      });
      
      // Create positionsByPick document
      await db.collection('precomputedAnalytics').doc('positionsByPick').set({
        'data': [],
        'lastUpdated': FieldValue.serverTimestamp()
      });
      
      // Create playerDeviations document
      await db.collection('precomputedAnalytics').doc('playerDeviations').set({
        'players': [],
        'byPosition': {},
        'sampleSize': 0,
        'positionSampleSizes': {},
        'lastUpdated': FieldValue.serverTimestamp()
      });
      
      // Setup round-specific position documents for rounds 1-7
      for (int round = 1; round <= 7; round++) {
        await db.collection('precomputedAnalytics').doc('positionsByPickRound$round').set({
          'data': [],
          'lastUpdated': FieldValue.serverTimestamp()
        });
      }
      
      // Create a test document in cachedQueries collection
      await db.collection('cachedQueries').doc('setup_verification').set({
        'created': FieldValue.serverTimestamp(),
        'expires': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
        'testData': 'Collection setup complete'
      });
      
      debugPrint('Successfully created analytics collections!');
      return true;
    } catch (e) {
      debugPrint('Error setting up analytics collections: $e');
      return false;
    }
  }

  /// Trigger analytics aggregation (for testing/admin purposes)
  static Future<bool> triggerAnalyticsAggregation() async {
    try {
      // Ensure Firebase is initialized
      if (!isInitialized) {
        await initialize();
      }
      
      debugPrint('Manually triggering analytics aggregation...');
      
      // For a simple test implementation, we'll directly write to the
      // precomputedAnalytics/metadata document to indicate an aggregation was requested
      final db = FirebaseFirestore.instance;
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'manualTrigger': true,
        'triggerTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // In a real implementation, you would call a Firebase HTTP function
      // const functions = FirebaseFunctions.instance;
      // final callable = functions.httpsCallable('triggerAnalyticsAggregation');
      // final result = await callable.call();
      
      debugPrint('Analytics aggregation triggered. Check Firebase logs.');
      return true;
    } catch (e) {
      debugPrint('Error triggering analytics aggregation: $e');
      return false;
    }
  }

  /// Check if analytics collections exist
  static Future<bool> checkAnalyticsCollections() async {
    try {
      if (!isInitialized) {
        await initialize();
      }
      
      final db = FirebaseFirestore.instance;
      final metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
      
      return metadataDoc.exists;
    } catch (e) {
      debugPrint('Error checking analytics collections: $e');
      return false;
    }
  }
  
  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized;

  //
  // AUTH METHODS
  //

  /// Register a new user
  static Future<app_user.User> registerUser({
    required String name,
    required String email,
    required String password,
    required bool isSubscribed,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
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
      await saveUserToFirestore(user);
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw Exception('Failed to register: $e');
    }
  }

  /// Sign in a user
  static Future<app_user.User> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }
      
      // Get user data from Firestore
      app_user.User? user = await getUserFromFirestore(userCredential.user!.uid);
      
      // If user doesn't exist in Firestore, create a new record
      if (user == null) {
        user = app_user.User(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: email,
          isSubscribed: false,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        // Save to Firestore
        await saveUserToFirestore(user);
      } else {
        // Update lastLoginAt
        user = user.copyWith(lastLoginAt: DateTime.now());
        await updateUserInFirestore(user);
      }
      
      return user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign out the current user
  static Future<void> signOutUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Check if user email is verified
  static bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      throw Exception('Failed to send email verification: $e');
    }
  }

  /// Delete the current user's account
  static Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Delete user data from Firestore
      await _firestore.collection(usersCollection).doc(user.uid).delete();
      
      // Delete the Firebase Auth user
      await user.delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  //
  // USER DATA METHODS
  //

  /// Get user data from Firestore
  static Future<app_user.User?> getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      final data = doc.data()!;
      
      return app_user.User(
        id: userId,
        name: data['name'] ?? 'User',
        email: data['email'] ?? '',
        isSubscribed: data['isSubscribed'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        resetToken: data['resetToken'],
        resetTokenExpiry: (data['resetTokenExpiry'] as Timestamp?)?.toDate(),
        favoriteTeams: data['favoriteTeams'] != null ? 
            List<String>.from(data['favoriteTeams']) : null,
        draftPreferences: data['draftPreferences'],
      );
    } catch (e) {
      debugPrint('Error getting user from Firestore: $e');
      return null;
    }
  }

  /// Save user to Firestore
  static Future<bool> saveUserToFirestore(app_user.User user) async {
    try {
      final userData = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'isSubscribed': user.isSubscribed,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if they exist
      if (user.favoriteTeams != null) {
        userData['favoriteTeams'] = user.favoriteTeams!;
      }
      
      if (user.draftPreferences != null) {
        userData['draftPreferences'] = user.draftPreferences!;
      }
      
      await _firestore.collection(usersCollection).doc(user.id).set(userData);
      return true;
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
      return false;
    }
  }

  /// Update user in Firestore
  static Future<bool> updateUserInFirestore(app_user.User user) async {
    try {
      final userData = {
        'name': user.name,
        'email': user.email,
        'isSubscribed': user.isSubscribed,
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if they exist
      if (user.favoriteTeams != null) {
        userData['favoriteTeams'] = user.favoriteTeams!;
      }
      
      if (user.draftPreferences != null) {
        userData['draftPreferences'] = user.draftPreferences!;
      }
      
      await _firestore.collection(usersCollection).doc(user.id).update(userData);
      return true;
    } catch (e) {
      debugPrint('Error updating user in Firestore: $e');
      return false;
    }
  }

  /// Update user's favorite teams
  static Future<bool> updateFavoriteTeams(String userId, List<String> favoriteTeams) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'favoriteTeams': favoriteTeams,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating favorite teams: $e');
      return false;
    }
  }

  /// Update user's draft preferences
  static Future<bool> updateDraftPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'draftPreferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating draft preferences: $e');
      return false;
    }
  }

  /// Save custom draft data
  static Future<bool> saveCustomDraftData(String userId, List<dynamic> customDraftData) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'customDraftData': customDraftData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving custom draft data: $e');
      return false;
    }
  }
}