// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:js' as js;
import '../models/draft_analytics.dart';
import '../models/draft_pick.dart';
import '../models/trade_package.dart';

class FirebaseService {
  static FirebaseFirestore? _firestoreInstance;
  static const String draftAnalyticsCollection = 'draftAnalytics';
  static bool _initialized = false;
  
  static FirebaseFirestore get _firestore {
    if (_firestoreInstance == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _firestoreInstance!;
  }
  
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
  
  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized;
}