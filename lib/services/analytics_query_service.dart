// lib/services/analytics_query_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mds_home/services/firebase_service.dart';
import '../models/draft_analytics.dart';
import '../services/firebase_service.dart';
import 'analytics_api_service.dart';
import 'analytics_cache_manager.dart';
import 'precomputed_analytics_service.dart';

class AnalyticsQueryService {
  static FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }
  
  static const String draftAnalyticsCollection = 'draftAnalytics';
  static const String precomputedAnalyticsCollection = 'precomputedAnalytics';

  /// Initialize and ensure Firebase connection
  static Future<void> ensureInitialized() async {
    if (!FirebaseService.isInitialized) {
      await FirebaseService.initialize();
    }
  }

  /// Get position frequency breakdown for a team - OPTIMIZED
  static Future<Map<String, dynamic>> getPositionBreakdownByTeam({
    required String team,
    List<int>? rounds,
    int? year,
  }) async {
    // First try to get data from precomputed stats
    return PrecomputedAnalyticsService.getPositionBreakdownByTeam(
      team: team,
      rounds: rounds,
      year: year,
    );
  }

  /// Get average player rank deviation by round or position - OPTIMIZED
  static Future<Map<String, dynamic>> getPlayerRankDeviations({
    int? year,
    String? position,
    int? limit = 10,
  }) async {
    final cacheKey = 'player_deviations_${position ?? 'all'}_${year ?? 'all'}_$limit';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchPlayerRankDeviations(year, position, limit),
    );
  }

  static Future<Map<String, dynamic>> _fetchPlayerRankDeviations(
    int? year,
    String? position,
    int? limit,
  ) async {
    try {
      // Try API first
      final filters = {
        if (year != null) 'year': year,
        if (position != null) 'position': position,
        if (limit != null) 'limit': limit,
      };
      
      final apiData = await AnalyticsApiService.getAnalyticsData(
        dataType: 'playerDeviations',
        filters: filters,
      );
      
      if (!apiData.containsKey('error') && apiData.containsKey('data')) {
        debugPrint('Using API data for player deviations');
        return apiData['data'];
      }
      
      // Fall back to Firestore
      await ensureInitialized();
      
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc('playerDeviations')
          .get();
          
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // Apply filters manually
        var players = List<dynamic>.from(data['players'] ?? []);
        
        if (position != null) {
          // Filter by position if specified
          if (data.containsKey('byPosition') && data['byPosition'].containsKey(position)) {
            players = List<dynamic>.from(data['byPosition'][position]);
          } else {
            players = players.where((p) => p['position'] == position).toList();
          }
        }
        
        // Apply limit
        if (limit != null && players.length > limit) {
          players = players.sublist(0, limit);
        }
        
        debugPrint('Using precomputed player deviations');
        return {
          'players': players,
          'sampleSize': data['sampleSize'],
        };
      }
      
      // Fall back to direct calculation
      return {'players': [], 'sampleSize': 0};
    } catch (e) {
      debugPrint('Error getting player rank deviations: $e');
      return {'players': [], 'sampleSize': 0};
    }
  }

static Future<int?> getDraftCount() async {
  try {
    await ensureInitialized();

    AggregateQuery countQuery = _firestore
        .collection(draftAnalyticsCollection)
        .count();

    AggregateQuerySnapshot snapshot = await countQuery.get();

    return snapshot.count;
  } catch (e) {
    debugPrint('Error getting draft count: $e');
    return -1; // or 0, depending on your preference
  }
}
  /// Get consensus team needs based on position frequency - OPTIMIZED
  static Future<Map<String, List<String>>> getConsensusTeamNeeds({
    int? year,
  }) async {
    // First try to get data from precomputed stats
    return PrecomputedAnalyticsService.getConsensusTeamNeeds(
      year: year,
    );
  }

  /// Get consolidated position trends by pick - OPTIMIZED
  static Future<List<Map<String, dynamic>>> getConsolidatedPositionsByPick({
    String? team,
    int? round,
    int? year,
  }) async {
    // First try to get data from precomputed stats
    return PrecomputedAnalyticsService.getConsolidatedPositionsByPick(
      team: team,
      round: round,
      year: year,
    );
  }

  /// Get consolidated player selections by pick - OPTIMIZED
  static Future<List<Map<String, dynamic>>> getConsolidatedPlayersByPick({
  String? team,
  int? round,
  int? year,
}) async {
  // Use the new function in precomputed analytics service
  return PrecomputedAnalyticsService.getConsolidatedPlayersByPick(
    team: team,
    round: round,
    year: year,
  );
}
  
  static Future<List<Map<String, dynamic>>> _fetchConsolidatedPlayersByPick(
    String? team,
    int? round,
    int? year,
  ) async {
    try {
      // Try API first
      final filters = {
        if (team != null) 'team': team,
        if (round != null) 'round': round,
        if (year != null) 'year': year,
      };
      
      String dataType = 'playersByPick';
      if (round != null) {
        dataType = 'playersByPickRound$round';
      }
      
      final apiData = await AnalyticsApiService.getAnalyticsData(
        dataType: dataType,
        filters: filters,
      );
      
      if (!apiData.containsKey('error') && apiData.containsKey('data')) {
        debugPrint('Using API data for players by pick');
        
        if (apiData['data'].containsKey('data')) {
          return List<Map<String, dynamic>>.from(apiData['data']['data'] ?? []);
        }
      }
      
      // Fall back to Firestore
      await ensureInitialized();
      
      String docId = 'playersByPick';
      if (round != null) {
        docId = 'playersByPickRound$round';
      }
      
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc(docId)
          .get();
          
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // For all teams data
        if (team == null || team == 'All Teams') {
          debugPrint('Using precomputed players by pick for round: ${round ?? 'all'}');
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        
        // For team-specific data
        if (data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
          debugPrint('Using precomputed players by pick for team: $team, round: ${round ?? 'all'}');
          return List<Map<String, dynamic>>.from(data['byTeam'][team] ?? []);
        }
      }
      
      // Fall back to direct calculation
      return [];
    } catch (e) {
      debugPrint('Error getting consolidated players by pick: $e');
      return [];
    }
  }

  /// Get top positions by pick number
static Future<List<Map<String, dynamic>>> getTopPositionsByTeam({
  String? team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching position trends by pick for ${team ?? 'All Teams'}, round $round');

    // Build the query
    Query query = _firestore.collection(draftAnalyticsCollection);
    
    if (team != null) {
      query = query.where('userTeam', isEqualTo: team);
    }

    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }

    // Execute the query
    final snapshot = await query.get();
    debugPrint('Found ${snapshot.docs.length} documents for position trends');

    // Organize data by pick number
    Map<int, Map<String, int>> pickPositionCounts = {};
    Map<int, int> pickTotals = {};
    Map<int, String> pickRounds = {};

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
        
        for (var pickData in picks) {
          final pick = DraftPickRecord.fromFirestore(pickData);
          
          // Filter by round if specified
          if (round != null && int.tryParse(pick.round) != round) {
            continue;
          }
          
          final pickNumber = pick.pickNumber;
          final position = pick.position;
          
          // Initialize data structures if needed
          if (!pickPositionCounts.containsKey(pickNumber)) {
            pickPositionCounts[pickNumber] = {};
          }
          if (!pickTotals.containsKey(pickNumber)) {
            pickTotals[pickNumber] = 0;
          }
          
          // Count position for this pick
          pickPositionCounts[pickNumber]![position] = 
              (pickPositionCounts[pickNumber]![position] ?? 0) + 1;
          
          // Increment total count for this pick
          pickTotals[pickNumber] = (pickTotals[pickNumber] ?? 0) + 1;
          
          // Store round for this pick
          pickRounds[pickNumber] = pick.round;
        }
      } catch (e) {
        debugPrint('Error processing document for position trends: $e');
      }
    }

    // Convert to desired output format
    List<Map<String, dynamic>> result = [];
    
    for (var pickEntry in pickPositionCounts.entries) {
      final pickNumber = pickEntry.key;
      final positionCounts = pickEntry.value;
      final totalForPick = pickTotals[pickNumber] ?? 0;
      
      if (totalForPick == 0) continue;
      
      // Convert position counts to sorted list with percentages
      List<Map<String, dynamic>> positions = positionCounts.entries
          .map((e) => {
                'position': e.key,
                'count': e.value,
                'percentage': '${((e.value / totalForPick) * 100).toStringAsFixed(1)}%',
              })
          .toList();
      
      // Sort positions by count (highest first)
      positions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      result.add({
        'pick': pickNumber,
        'round': pickRounds[pickNumber] ?? '?',
        'positions': positions,
        'totalDrafts': totalForPick,
      });
    }
    
    // Sort by pick number
    result.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
    
    return result;
  } catch (e) {
    debugPrint('Error getting position trends: $e');
    return [];
  }
}

/// Get top players by pick number
static Future<List<Map<String, dynamic>>> getTopPlayersByTeam({
  String? team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching player trends for ${team ?? 'All Teams'}, round $round');

    // Build the query
    Query query = _firestore.collection(draftAnalyticsCollection);
    
    if (team != null) {
      query = query.where('userTeam', isEqualTo: team);
    }

    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }

    // Execute the query
    final snapshot = await query.get();
    debugPrint('Found ${snapshot.docs.length} documents for player trends');

    // Organize data by pick number and player
    Map<int, Map<String, Map<String, dynamic>>> pickPlayerCounts = {};
    Map<int, int> pickTotals = {};

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
        
        for (var pickData in picks) {
          final pick = DraftPickRecord.fromFirestore(pickData);
          
          // Filter by round if specified
          if (round != null && int.tryParse(pick.round) != round) {
            continue;
          }
          
          final pickNumber = pick.pickNumber;
          final playerName = pick.playerName;
          final position = pick.position;
          
          // Initialize data structures if needed
          if (!pickPlayerCounts.containsKey(pickNumber)) {
            pickPlayerCounts[pickNumber] = {};
          }
          if (!pickTotals.containsKey(pickNumber)) {
            pickTotals[pickNumber] = 0;
          }
          
          // Create or update player entry
          String playerKey = '$playerName|$position';
          if (!pickPlayerCounts[pickNumber]!.containsKey(playerKey)) {
            pickPlayerCounts[pickNumber]![playerKey] = {
              'player': playerName,
              'position': position,
              'count': 0,
            };
          }
          
          // Increment count for this player
          pickPlayerCounts[pickNumber]![playerKey]!['count'] = 
              (pickPlayerCounts[pickNumber]![playerKey]!['count'] as int) + 1;
          
          // Increment total count for this pick
          pickTotals[pickNumber] = (pickTotals[pickNumber] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('Error processing document for player trends: $e');
      }
    }

    // Convert to desired output format
    List<Map<String, dynamic>> result = [];
    
    for (var pickEntry in pickPlayerCounts.entries) {
      final pickNumber = pickEntry.key;
      final playerCounts = pickEntry.value;
      final totalForPick = pickTotals[pickNumber] ?? 0;
      
      if (totalForPick == 0) continue;
      
      // Convert player counts to list with percentages
      List<Map<String, dynamic>> players = playerCounts.values
          .map((data) => {
                'player': data['player'],
                'position': data['position'],
                'count': data['count'],
                'percentage': '${((data['count'] as int) / totalForPick * 100).toStringAsFixed(1)}%',
              })
          .toList();
      
      // Sort players by count (highest first)
      players.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      // Take only the top player
      if (players.isNotEmpty) {
        result.add({
          'pick': pickNumber,
          'player': players.first['player'],
          'position': players.first['position'],
          'count': players.first['count'],
          'percentage': players.first['percentage'],
          'totalDrafts': totalForPick,
        });
      }
    }
    
    // Sort by pick number
    result.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
    
    return result;
  } catch (e) {
    debugPrint('Error getting player trends: $e');
    return [];
  }
}

// Add this method to lib/services/analytics_query_service.dart

/// Get actual draft history for a specific team
static Future<List<Map<String, dynamic>>> getTeamDraftHistory({
  required String team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching team draft history for $team, round $round');

    // Build the query
    Query query = _firestore.collection(draftAnalyticsCollection)
        .where('userTeam', isEqualTo: team);

    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }

    // Execute the query
    final snapshot = await query.get();
    debugPrint('Found ${snapshot.docs.length} documents for team draft history');

    // Extract this team's picks from all the documents
    List<Map<String, dynamic>> teamPicks = [];

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
        
        for (var pickData in picks) {
          final pick = DraftPickRecord.fromFirestore(pickData);
          
          // Only include picks where this team is the actual team (not original team)
          if (pick.actualTeam == team) {
            // Filter by round if specified
            if (round != null && int.tryParse(pick.round) != round) {
              continue;
            }
            
            teamPicks.add({
              'pickNumber': pick.pickNumber,
              'round': pick.round,
              'playerName': pick.playerName,
              'position': pick.position,
              'playerRank': pick.playerRank,
              'school': pick.school,
            });
          }
        }
      } catch (e) {
        debugPrint('Error processing document for team draft history: $e');
      }
    }
    
    // Sort by pick number
    teamPicks.sort((a, b) => (a['pickNumber'] as int).compareTo(b['pickNumber'] as int));
    
    return teamPicks;
  } catch (e) {
    debugPrint('Error getting team draft history: $e');
    return [];
  }
}

}
