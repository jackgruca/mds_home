// lib/services/draft_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/draft_pick.dart';
import '../models/draft_session.dart';
import '../models/trade_package.dart';

class DraftAnalyticsService {
  final FirebaseFirestore _firestore;
  final uuid = const Uuid();

  DraftAnalyticsService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Save a complete draft session
  Future<bool> saveDraftSession({
    required String userId, 
    required String userTeam,
    required int draftYear,
    required List<DraftPick> completedPicks,
    required List<TradePackage> executedTrades,
  }) async {
    try {
      // Create a unique ID for this draft session
      String sessionId = uuid.v4();
      
      // Get current timestamp
      DateTime timestamp = DateTime.now();
      
      // Convert picks to storable format
      List<Map<String, dynamic>> picks = completedPicks
          .where((pick) => pick.selectedPlayer != null)
          .map((pick) => DraftSession.pickToMap(pick))
          .toList();
      
      // Convert trades to storable format
      List<Map<String, dynamic>> trades = executedTrades
          .map((trade) => DraftSession.tradeToMap(trade))
          .toList();
      
      // Create draft session object
      DraftSession session = DraftSession(
        id: sessionId,
        userId: userId,
        userTeam: userTeam,
        timestamp: timestamp,
        draftYear: draftYear,
        picks: picks,
        trades: trades,
      );
      
      // Save to Firestore
      await _firestore.collection('draftSessions').doc(sessionId).set(session.toJson());
      
      debugPrint('Draft session saved successfully: $sessionId');
      return true;
    } catch (e) {
      debugPrint('Error saving draft session: $e');
      return false;
    }
  }

  // Get all draft sessions for analytics processing
  Future<List<DraftSession>> getAllDraftSessions() async {
    try {
      final snapshot = await _firestore.collection('draftSessions').get();
      return snapshot.docs.map((doc) => DraftSession.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching draft sessions: $e');
      return [];
    }
  }

  // Get draft sessions for a specific team
  Future<List<DraftSession>> getTeamDraftSessions(String teamName) async {
    try {
      final snapshot = await _firestore
          .collection('draftSessions')
          .where('userTeam', isEqualTo: teamName)
          .get();
      
      return snapshot.docs.map((doc) => DraftSession.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching team draft sessions: $e');
      return [];
    }
  }

  // Get common picks for a specific team in a position
  Future<Map<String, int>> getCommonTeamPicks(String teamName, int pickNumber) async {
    try {
      final sessions = await getTeamDraftSessions(teamName);
      
      // Count player selections at this pick
      Map<String, int> playerCounts = {};
      
      for (var session in sessions) {
        for (var pick in session.picks) {
          if (pick['pickNumber'] == pickNumber && pick['teamName'] == teamName) {
            String playerName = pick['playerName'] ?? 'Unknown';
            playerCounts[playerName] = (playerCounts[playerName] ?? 0) + 1;
          }
        }
      }
      
      return playerCounts;
    } catch (e) {
      debugPrint('Error analyzing common team picks: $e');
      return {};
    }
  }

  // Get position frequency for a team in early rounds
  Future<Map<String, int>> getTeamPositionFrequency(String teamName, {int maxRound = 3}) async {
    try {
      final sessions = await getTeamDraftSessions(teamName);
      
      // Count positions drafted in early rounds
      Map<String, int> positionCounts = {};
      
      for (var session in sessions) {
        for (var pick in session.picks) {
          if (pick['teamName'] == teamName && int.parse(pick['round']) <= maxRound) {
            String position = pick['playerPosition'] ?? 'Unknown';
            positionCounts[position] = (positionCounts[position] ?? 0) + 1;
          }
        }
      }
      
      return positionCounts;
    } catch (e) {
      debugPrint('Error analyzing team position frequency: $e');
      return {};
    }
  }

  // Calculate average draft position vs consensus rank
  Future<Map<String, double>> getPlayerDraftPositionVariance() async {
    try {
      final sessions = await getAllDraftSessions();
      
      // Track selections for each player
      Map<String, List<int>> playerPositions = {};
      Map<String, int> playerRanks = {};
      
      for (var session in sessions) {
        for (var pick in session.picks) {
          String playerName = pick['playerName'] ?? 'Unknown';
          int pickNumber = pick['pickNumber'];
          int playerRank = pick['playerRank'] ?? 999;
          
          if (!playerPositions.containsKey(playerName)) {
            playerPositions[playerName] = [];
            playerRanks[playerName] = playerRank;
          }
          
          playerPositions[playerName]!.add(pickNumber);
        }
      }
      
      // Calculate average position vs rank
      Map<String, double> positionVariance = {};
      
      playerPositions.forEach((player, positions) {
        if (positions.isNotEmpty) {
          double avgPosition = positions.reduce((a, b) => a + b) / positions.length;
          int consensusRank = playerRanks[player] ?? 999;
          
          // Positive means player goes later than consensus, negative means earlier
          positionVariance[player] = avgPosition - consensusRank;
        }
      });
      
      return positionVariance;
    } catch (e) {
      debugPrint('Error calculating position variance: $e');
      return {};
    }
  }
}