// lib/services/analytics_query_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/draft_analytics.dart';
import '../services/firebase_service.dart';
import 'analytics_api_service.dart';
import 'analytics_cache_manager.dart';
import 'precomputed_analytics_service.dart';

class AnalyticsQueryService {
  List<String> teamNeeds = [];
  List<Map<String, dynamic>> teamOriginalPicks = [];
  List<Map<String, dynamic>> topPositionsByPick = [];
  List<Map<String, dynamic>> topPlayersByPick = [];
  List<Map<String, dynamic>> tradePatterns = [];

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
    final cacheKey = 'players_by_pick_${team ?? 'all'}_${round ?? 'all'}_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchConsolidatedPlayersByPick(team, round, year),
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

/// Get top positions by pick for a specific team
static Future<List<Map<String, dynamic>>> getTopPositionsByTeamAndPick({
  required String team,
  int? round,
}) async {
  try {
    await ensureInitialized();
    
    // First try to get precomputed data
    final data = await getConsolidatedPositionsByPick(team: team, round: round);
    
    // Add the 'pick' property for each entry if not present
    for (final entry in data) {
      if (!entry.containsKey('pick') && entry.containsKey('pickNumber')) {
        entry['pick'] = entry['pickNumber'];
      }
    }
    
    return data;
  } catch (e) {
    debugPrint('Error getting top positions by team and pick: $e');
    return [];
  }
}
/// Get most common players by pick for a specific team
static Future<List<Map<String, dynamic>>> getTopPlayersByTeamAndPick({
  required String team,
  int? round,
}) async {
  try {
    await ensureInitialized();
    
    // First try to get precomputed data
    final data = await getConsolidatedPlayersByPick(team: team, round: round);
    
    // Add the 'pick' property for each entry if not present
    for (final entry in data) {
      if (!entry.containsKey('pick') && entry.containsKey('pickNumber')) {
        entry['pick'] = entry['pickNumber'];
      }
    }
    
    return data;
  } catch (e) {
    debugPrint('Error getting top players by team and pick: $e');
    return [];
  }
}

/// Get consensus team needs for a specific team
static Future<List<String>> getTeamConsensusNeeds({required String team}) async {
  try {
    await ensureInitialized();
    
    final db = _firestore;
    final teamNeedsDoc = await db.collection('precomputedAnalytics')
        .doc('teamNeeds')
        .get();
    
    if (teamNeedsDoc.exists) {
      final data = teamNeedsDoc.data() as Map<String, dynamic>;
      if (data.containsKey('needs') && data['needs'].containsKey(team)) {
        return List<String>.from(data['needs'][team]);
      }
    }
    
    return [];
  } catch (e) {
    debugPrint('Error getting team consensus needs: $e');
    return [];
  }
}

/// Get team draft history (original picks)
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
          
          // Only include picks where this team is the original team (not traded for)
          if (pick.originalTeam == team) {
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
              'actualTeam': pick.actualTeam, // Add this to see if it was traded
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

/// Get most common trade destinations for a team's picks
static Future<List<Map<String, dynamic>>> getTeamTradePatterns({
  required String team,
  int? round,
}) async {
  try {
    await ensureInitialized();
    
    final db = _firestore;
    final snapshot = await db.collection(draftAnalyticsCollection)
        .limit(500) // Limit to avoid processing too many
        .get();
    
    // Map to track trade patterns by pick
    Map<int, List<Map<String, dynamic>>> tradesByPick = {};
    
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
        
        for (var pickData in picks) {
          // Check if this was originally team's pick
          if (pickData['originalTeam'] == team && pickData['actualTeam'] != team) {
            final pickNumber = pickData['pickNumber'] as int;
            final currentRound = int.tryParse(pickData['round']?.toString() ?? '') ?? 0;
            
            // Filter by round if specified
            if (round != null && currentRound != round) {
              continue;
            }
            
            final tradedTo = pickData['actualTeam'];
            final position = pickData['position'];
            final playerName = pickData['playerName'];
            
            tradesByPick.putIfAbsent(pickNumber, () => []);
            
            // Find if we already have this trade destination
            bool found = false;
            for (var trade in tradesByPick[pickNumber]!) {
              if (trade['tradedTo'] == tradedTo) {
                trade['count'] = (trade['count'] as int) + 1;
                found = true;
                
                // Update players
                if (!trade['players'].contains(playerName)) {
                  trade['players'].add(playerName);
                }
                
                // Update positions
                if (!trade['positions'].contains(position)) {
                  trade['positions'].add(position);
                }
                
                break;
              }
            }
            
            if (!found) {
              tradesByPick[pickNumber]!.add({
                'tradedTo': tradedTo,
                'count': 1,
                'positions': [position],
                'players': [playerName],
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error processing document for trade patterns: $e');
      }
    }
    
    // Format results
    List<Map<String, dynamic>> result = [];
    
    tradesByPick.forEach((pickNumber, trades) {
      // Sort by count
      trades.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      // Only take top 3 for each pick
      final topTrades = trades.take(3).toList();
      
      result.add({
        'pick': pickNumber,
        'trades': topTrades,
      });
    });
    
    // Sort by pick number
    result.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
    
    return result;
  } catch (e) {
    debugPrint('Error getting team trade patterns: $e');
    return [];
  }
}

/// Get best value players by round
static Future<List<Map<String, dynamic>>> getValuePlayersByRound({int? round}) async {
  try {
    await ensureInitialized();
    
    // For this we need player deviations
    final db = _firestore;
    final deviationsDoc = await db.collection('precomputedAnalytics')
        .doc('playerDeviations')
        .get();
    
    if (!deviationsDoc.exists) {
      return [];
    }
    
    final data = deviationsDoc.data() as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
    
    // Filter players with positive deviation (positive value, picked later than rank)
    final valuePlayersByRound = <int, List<Map<String, dynamic>>>{};
    
    for (final player in players) {
      // Parse deviation
      final dev = double.tryParse(player['avgDeviation']?.toString() ?? '0') ?? 0;
      
      // Skip if not a value pick (negative deviation means picked earlier than rank)
      if (dev <= 0) continue;
      
      // Try to determine round
      int playerRound = 0;
      try {
        // We'll approximate round from the average draft position and deviation
        final aproxRank = player['rank'] ?? ((player['avgDeviation'] as double).abs().toInt());
        
        if (aproxRank <= 32) playerRound = 1;
        else if (aproxRank <= 64) playerRound = 2;
        else if (aproxRank <= 105) playerRound = 3;
        else if (aproxRank <= 143) playerRound = 4;
        else if (aproxRank <= 179) playerRound = 5;
        else if (aproxRank <= 217) playerRound = 6;
        else playerRound = 7;
      } catch (e) {
        playerRound = 0;
      }
      
      // Skip if round doesn't match filter
      if (round != null && playerRound != round) continue;
      
      // Add to round list
      valuePlayersByRound.putIfAbsent(playerRound, () => []);
      valuePlayersByRound[playerRound]!.add({
        ...player,
        'round': playerRound,
      });
    }
    
    // Sort each round by deviation (highest value first)
    valuePlayersByRound.forEach((round, players) {
      players.sort((a, b) {
        final aDevStr = a['avgDeviation']?.toString() ?? '0';
        final bDevStr = b['avgDeviation']?.toString() ?? '0';
        
        final aDev = double.tryParse(aDevStr) ?? 0;
        final bDev = double.tryParse(bDevStr) ?? 0;
        
        return bDev.compareTo(aDev);
      });
    });
    
    // Format response
    List<Map<String, dynamic>> result = [];
    
    // If round is specified, return just that round
    if (round != null && valuePlayersByRound.containsKey(round)) {
      result = List<Map<String, dynamic>>.from(valuePlayersByRound[round]!.take(10));
    } else {
      // Otherwise, get top 5 from each round
      for (int r = 1; r <= 7; r++) {
        if (valuePlayersByRound.containsKey(r)) {
          final topFive = valuePlayersByRound[r]!.take(5).toList();
          result.addAll(topFive);
        }
      }
    }
    
    return result;
  } catch (e) {
    debugPrint('Error getting value players by round: $e');
    return [];
  }
}

/// Get biggest reach picks by round
static Future<List<Map<String, dynamic>>> getReachPicksByRound({int? round}) async {
  try {
    await ensureInitialized();
    
    // For this we need player deviations
    final db = _firestore;
    final deviationsDoc = await db.collection('precomputedAnalytics')
        .doc('playerDeviations')
        .get();
    
    if (!deviationsDoc.exists) {
      return [];
    }
    
    final data = deviationsDoc.data() as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
    
    // Filter players with negative deviation (picked earlier than rank)
    final reachPlayersByRound = <int, List<Map<String, dynamic>>>{};
    
    for (final player in players) {
      // Parse deviation
      final dev = double.tryParse(player['avgDeviation']?.toString() ?? '0') ?? 0;
      
      // Skip if not a reach pick (positive deviation means picked later than rank)
      if (dev >= 0) continue;
      
      // Try to determine round (similar logic as valuePlayersByRound)
      int playerRound = 0;
      try {
        // We'll approximate round from the average draft position and deviation
        final aproxRank = player['rank'] ?? ((player['avgDeviation'] as double).abs().toInt());
        
        if (aproxRank <= 32) playerRound = 1;
        else if (aproxRank <= 64) playerRound = 2;
        else if (aproxRank <= 105) playerRound = 3;
        else if (aproxRank <= 143) playerRound = 4;
        else if (aproxRank <= 179) playerRound = 5;
        else if (aproxRank <= 217) playerRound = 6;
        else playerRound = 7;
      } catch (e) {
        playerRound = 0;
      }
      
      // Skip if round doesn't match filter
      if (round != null && playerRound != round) continue;
      
      // Add to round list
      reachPlayersByRound.putIfAbsent(playerRound, () => []);
      reachPlayersByRound[playerRound]!.add({
        ...player,
        'round': playerRound,
      });
    }
    
    // Sort each round by deviation (biggest reach first)
    reachPlayersByRound.forEach((round, players) {
      players.sort((a, b) {
        final aDevStr = a['avgDeviation']?.toString() ?? '0';
        final bDevStr = b['avgDeviation']?.toString() ?? '0';
        
        final aDev = double.tryParse(aDevStr) ?? 0;
        final bDev = double.tryParse(bDevStr) ?? 0;
        
        return aDev.compareTo(bDev); // Negative values, smallest first
      });
    });
    
    // Format response
    List<Map<String, dynamic>> result = [];
    
    // If round is specified, return just that round
    if (round != null && reachPlayersByRound.containsKey(round)) {
      result = List<Map<String, dynamic>>.from(reachPlayersByRound[round]!.take(10));
    } else {
      // Otherwise, get top 5 from each round
      for (int r = 1; r <= 7; r++) {
        if (reachPlayersByRound.containsKey(r)) {
          final topFive = reachPlayersByRound[r]!.take(5).toList();
          result.addAll(topFive);
        }
      }
    }
    
    return result;
  } catch (e) {
    debugPrint('Error getting reach picks by round: $e');
    return [];
  }
}

/// Get most common trading teams by round
static Future<List<Map<String, dynamic>>> getMostActiveTradeTeamsByRound({int? round}) async {
  try {
    await ensureInitialized();
    
    final db = _firestore;
    final snapshot = await db.collection(draftAnalyticsCollection)
        .limit(500) // Limit to avoid processing too many
        .get();
    
    // Maps to track trade frequency
    Map<String, Map<int, int>> teamTradeUpsByRound = {};
    Map<String, Map<int, int>> teamTradeDownsByRound = {};
    
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final trades = List<Map<String, dynamic>>.from(data['trades'] ?? []);
        
        for (var trade in trades) {
          final offering = trade['teamOffering'] as String?;
          final receiving = trade['teamReceiving'] as String?;
          
          if (offering == null || receiving == null) continue;
          
          // Try to determine round of target pick
          final targetPick = trade['targetPick'] as int?;
          int tradeRound = 0;
          
          if (targetPick != null) {
            if (targetPick <= 32) tradeRound = 1;
            else if (targetPick <= 64) tradeRound = 2;
            else if (targetPick <= 105) tradeRound = 3;
            else if (targetPick <= 143) tradeRound = 4;
            else if (targetPick <= 179) tradeRound = 5;
            else if (targetPick <= 217) tradeRound = 6;
            else tradeRound = 7;
          }
          
          // Skip if round doesn't match filter
          if (round != null && tradeRound != round) continue;
          
          // Track team trading up (receiving team)
          teamTradeUpsByRound.putIfAbsent(receiving, () => {});
          teamTradeUpsByRound[receiving]!.putIfAbsent(tradeRound, () => 0);
          teamTradeUpsByRound[receiving]![tradeRound] = (teamTradeUpsByRound[receiving]![tradeRound] ?? 0) + 1;
          
          // Track team trading down (offering team)
          teamTradeDownsByRound.putIfAbsent(offering, () => {});
          teamTradeDownsByRound[offering]!.putIfAbsent(tradeRound, () => 0);
          teamTradeDownsByRound[offering]![tradeRound] = (teamTradeDownsByRound[offering]![tradeRound] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('Error processing document for trade teams: $e');
      }
    }
    
    // Format results
    Map<int, List<Map<String, dynamic>>> tradeUpsByRound = {};
    Map<int, List<Map<String, dynamic>>> tradeDownsByRound = {};
    
    // Process trade ups
    teamTradeUpsByRound.forEach((team, rounds) {
      rounds.forEach((r, count) {
        tradeUpsByRound.putIfAbsent(r, () => []);
        tradeUpsByRound[r]!.add({
          'team': team,
          'count': count,
          'direction': 'up',
        });
      });
    });
    
    // Process trade downs
    teamTradeDownsByRound.forEach((team, rounds) {
      rounds.forEach((r, count) {
        tradeDownsByRound.putIfAbsent(r, () => []);
        tradeDownsByRound[r]!.add({
          'team': team,
          'count': count,
          'direction': 'down',
        });
      });
    });
    
    // Sort each round by count
    tradeUpsByRound.forEach((r, teams) {
      teams.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    });
    
    tradeDownsByRound.forEach((r, teams) {
      teams.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    });
    
    // Combine results
    List<Map<String, dynamic>> result = [];
    
    if (round != null) {
      // Return specific round
      result.add({
        'round': round,
        'tradeUps': tradeUpsByRound[round]?.take(5).toList() ?? [],
        'tradeDowns': tradeDownsByRound[round]?.take(5).toList() ?? [],
      });
    } else {
      // Return all rounds
      for (int r = 1; r <= 7; r++) {
        result.add({
          'round': r,
          'tradeUps': tradeUpsByRound[r]?.take(5).toList() ?? [],
          'tradeDowns': tradeDownsByRound[r]?.take(5).toList() ?? [],
        });
      }
    }
    
    return result;
  } catch (e) {
    debugPrint('Error getting most active trade teams by round: $e');
    return [];
  }
}
}