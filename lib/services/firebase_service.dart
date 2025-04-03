// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/draft_analytics.dart';
import '../models/draft_pick.dart';
import '../models/trade_package.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String draftAnalyticsCollection = 'draftAnalytics';
  
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
    }
  }

  /// Save draft results to Firestore
  static Future<bool> saveDraftAnalytics({
    required String userTeam,
    required List<DraftPick> completedPicks,
    required List<TradePackage> executedTrades,
    required int year,
  }) async {
    try {
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
      final DraftAnalyticsRecord record = DraftAnalyticsRecord(
        id: '', // Firestore will generate an ID
        userTeam: userTeam,
        timestamp: DateTime.now(),
        year: year,
        picks: pickRecords,
        trades: tradeRecords,
      );

      // Save to Firestore
      await _firestore.collection(draftAnalyticsCollection).add(record.toFirestore());
      
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
}