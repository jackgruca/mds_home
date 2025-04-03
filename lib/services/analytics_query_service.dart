// lib/services/analytics_query_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/draft_analytics.dart';

class AnalyticsQueryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String draftAnalyticsCollection = 'draftAnalytics';

  /// Get most popular picks for a specific team in a specific draft slot
  static Future<List<Map<String, dynamic>>> getMostPopularPicksByTeam({
    required String team,
    int? pickNumber,
    int? round,
    int? limit = 5,
    int? year,
  }) async {
    try {
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection)
          .where('userTeam', isEqualTo: team);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      // Execute the query
      final snapshot = await query.get();

      // Process all draft records
      Map<String, int> playerCounts = {};
      Map<String, Map<String, dynamic>> playerDetails = {};

      for (var doc in snapshot.docs) {
        final record = DraftAnalyticsRecord.fromFirestore(doc);
        
        // Filter picks based on criteria
        for (var pick in record.picks) {
          bool matchesCriteria = true;
          
          if (pickNumber != null && pick.pickNumber != pickNumber) {
            matchesCriteria = false;
          }
          
          if (round != null && pick.round != round.toString()) {
            matchesCriteria = false;
          }
          
          if (matchesCriteria) {
            String key = '${pick.playerName}|${pick.position}';
            playerCounts[key] = (playerCounts[key] ?? 0) + 1;
            
            // Store the most recent details for this player
            playerDetails[key] = {
              'name': pick.playerName,
              'position': pick.position,
              'rank': pick.playerRank,
              'school': pick.school,
              'pickNumber': pick.pickNumber,
              'round': pick.round,
            };
          }
        }
      }

      // Convert to sorted list
      final sortedPlayers = playerCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Return the top results with details
      return sortedPlayers.take(limit ?? 5).map((entry) {
        final details = playerDetails[entry.key] ?? {};
        return {
          ...details,
          'count': entry.value,
          'percentage': snapshot.docs.isEmpty 
              ? 0 
              : '${(entry.value / snapshot.docs.length * 100).toStringAsFixed(1)}%',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting popular picks: $e');
      return [];
    }
  }

  /// Get position frequency breakdown for a team
  static Future<Map<String, dynamic>> getPositionBreakdownByTeam({
    required String team,
    List<int>? rounds,
    int? year,
  }) async {
    try {
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection)
          .where('userTeam', isEqualTo: team);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      // Execute the query
      final snapshot = await query.get();

      // Process position counts
      Map<String, int> positionCounts = {};
      int totalPicks = 0;

      for (var doc in snapshot.docs) {
        final record = DraftAnalyticsRecord.fromFirestore(doc);
        
        for (var pick in record.picks) {
          if (rounds == null || rounds.contains(int.parse(pick.round))) {
            positionCounts[pick.position] = (positionCounts[pick.position] ?? 0) + 1;
            totalPicks++;
          }
        }
      }

      // Calculate percentages
      Map<String, dynamic> result = {
        'total': totalPicks,
        'positions': {},
      };

      for (var position in positionCounts.keys) {
        final count = positionCounts[position] ?? 0;
        result['positions'][position] = {
          'count': count,
          'percentage': totalPicks > 0 
              ? '${(count / totalPicks * 100).toStringAsFixed(1)}%' 
              : '0%',
        };
      }

      return result;
    } catch (e) {
      debugPrint('Error getting position breakdown: $e');
      return {'total': 0, 'positions': {}};
    }
  }

  /// Get average player rank deviation by round or position
  static Future<Map<String, dynamic>> getPlayerRankDeviations({
    int? year,
    String? position,
    int? limit = 10,
  }) async {
    try {
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      // Execute the query
      final snapshot = await query.get();

      // Calculate rank deviations
      Map<String, List<int>> playerDeviations = {};

      for (var doc in snapshot.docs) {
        final record = DraftAnalyticsRecord.fromFirestore(doc);
        
        for (var pick in record.picks) {
          if (position == null || pick.position == position) {
            // Calculate the deviation (positive means picked later than rank)
            int deviation = pick.pickNumber - pick.playerRank;
            
            // Use player name and position as key
            String key = '${pick.playerName}|${pick.position}';
            
            if (!playerDeviations.containsKey(key)) {
              playerDeviations[key] = [];
            }
            
            playerDeviations[key]!.add(deviation);
          }
        }
      }

      // Calculate average deviations
      Map<String, Map<String, dynamic>> averageDeviations = {};
      
      for (var entry in playerDeviations.entries) {
        // Skip players with less than 3 data points
        if (entry.value.length < 3) continue;
        
        int sum = entry.value.reduce((a, b) => a + b);
        double average = sum / entry.value.length;
        
        List<String> parts = entry.key.split('|');
        String playerName = parts[0];
        String playerPosition = parts[1];
        
        averageDeviations[entry.key] = {
          'name': playerName,
          'position': playerPosition,
          'avgDeviation': average.toStringAsFixed(1),
          'sampleSize': entry.value.length,
        };
      }

      // Sort by absolute deviation value (largest first)
      final sortedDeviations = averageDeviations.entries.toList()
        ..sort((a, b) {
          double aVal = double.parse(a.value['avgDeviation'].toString());
          double bVal = double.parse(b.value['avgDeviation'].toString());
          return bVal.abs().compareTo(aVal.abs());
        });

      // Return the most significant deviations
      return {
        'players': sortedDeviations.take(limit ?? 10).map((e) => e.value).toList(),
        'sampleSize': snapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting rank deviations: $e');
      return {'players': [], 'sampleSize': 0};
    }
  }
}