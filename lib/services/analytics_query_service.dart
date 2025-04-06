// lib/services/analytics_query_service.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draft_analytics.dart';
import '../services/firebase_service.dart';
import 'analytics_data_manager.dart';

class AnalyticsQueryService {
  static FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }
  
  static const String draftAnalyticsCollection = 'draftAnalytics';

  /// Initialize and ensure Firebase connection
  static Future<void> ensureInitialized() async {
    if (!FirebaseService.isInitialized) {
      await FirebaseService.initialize();
    }
  }

  /// Get most popular picks for a specific team in a specific draft slot
  static Future<List<Map<String, dynamic>>> getMostPopularPicksByTeam({
    required String team,
    int? pickNumber,
    int? round,
    int? limit = 5,
    int? year,
  }) async {
    try {
      await ensureInitialized();
      debugPrint('Fetching popular picks for team: $team, round: $round');

      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection)
          .where('userTeam', isEqualTo: team);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} documents for team: $team');

      // Process all draft records
      Map<String, int> playerCounts = {};
      Map<String, Map<String, dynamic>> playerDetails = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
          
          // Filter picks based on criteria
          for (var pickData in picks) {
            final pick = DraftPickRecord.fromFirestore(pickData);
            
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
        } catch (e) {
          debugPrint('Error processing document: $e');
        }
      }

      // Convert to sorted list
      final sortedPlayers = playerCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Return the top results with details
      return sortedPlayers.take(limit ?? 5).map((entry) {
        final details = playerDetails[entry.key] ?? {};
        return {
          'name': details['name'] ?? 'Unknown Player',
          'position': details['position'] ?? 'Unknown',
          'rank': details['rank'] ?? 0,
          'school': details['school'] ?? '',
          'pickNumber': details['pickNumber'] ?? 0,
          'round': details['round'] ?? '1',
          'count': entry.value,
          'percentage': snapshot.docs.isEmpty 
              ? '0%' 
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
      await ensureInitialized();
      debugPrint('Fetching position breakdown for team: $team');

      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection)
          .where('userTeam', isEqualTo: team);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} documents for position breakdown');

      // Process position counts
      Map<String, int> positionCounts = {};
      int totalPicks = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
          
          for (var pickData in picks) {
            final pick = DraftPickRecord.fromFirestore(pickData);
            
            if (rounds == null || rounds.contains(int.tryParse(pick.round) ?? 0)) {
              positionCounts[pick.position] = (positionCounts[pick.position] ?? 0) + 1;
              totalPicks++;
            }
          }
        } catch (e) {
          debugPrint('Error processing document for position breakdown: $e');
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
      await ensureInitialized();
      debugPrint('Fetching player rank deviations');

      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} documents for rank deviations');

      // Calculate rank deviations
      Map<String, List<int>> playerDeviations = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
          
          for (var pickData in picks) {
            final pick = DraftPickRecord.fromFirestore(pickData);
            
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
        } catch (e) {
          debugPrint('Error processing document for rank deviations: $e');
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
        String playerPosition = parts.length > 1 ? parts[1] : 'Unknown';
        
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

static Future<List<Map<String, dynamic>>> getConsolidatedPositionsByPick({
  String? team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching minimal position trends for ${team ?? 'All Teams'}, round: ${round ?? 'All'}');
    
    // Get from local storage first if possible
    final String storageKey = 'position_trends_${team ?? "all"}_${round ?? "all"}_$year';
    
    // Try to get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(storageKey);
    
    if (storedData != null) {
      try {
        return List<Map<String, dynamic>>.from(
          jsonDecode(storedData).map((x) => Map<String, dynamic>.from(x))
        );
      } catch (e) {
        debugPrint('Error parsing stored position trends: $e');
      }
    }
    
    // If not found in storage, load minimal data
    final data = await AnalyticsDataManager().loadMinimalDataFor(
      'position_trends',
      team: team,
      round: round?.toString(),
    );
    
    final List<Map<String, dynamic>> result = [];
    
    // Process the data
    if (data.containsKey('positions')) {
      final positions = data['positions'] as List?;
      if (positions != null) {
        for (final position in positions) {
          result.add(Map<String, dynamic>.from(position));
        }
      }
    }
    
    // Store for future use
    prefs.setString(storageKey, jsonEncode(result));
    
    return result;
  } catch (e) {
    debugPrint('Error getting consolidated position trends: $e');
    return [];
  }
}

static Future<Map<String, List<String>>> getConsensusTeamNeeds({
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching minimal consensus team needs');
    
    // Try local storage first
    final String storageKey = 'consensus_needs_$year';
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(storageKey);
    
    if (storedData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(storedData);
        final Map<String, List<String>> result = {};
        
        decoded.forEach((key, value) {
          if (value is List) {
            result[key] = List<String>.from(value);
          }
        });
        
        return result;
      } catch (e) {
        debugPrint('Error parsing stored team needs: $e');
      }
    }
    
    // Load minimal data
    final data = await AnalyticsDataManager().loadMinimalDataFor('team_needs');
    final Map<String, List<String>> result = {};
    
    // Process the data
    data.forEach((team, needs) {
      if (needs is List) {
        result[team] = List<String>.from(needs);
      }
    });
    
    // Store for future use
    prefs.setString(storageKey, jsonEncode(result));
    
    return result;
  } catch (e) {
    debugPrint('Error getting consensus needs: $e');
    return {};
  }
}

static Future<List<Map<String, dynamic>>> getConsolidatedPlayersByPick({
  String? team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching consolidated player trends for ${team ?? 'All Teams'}, round ${round ?? 'All'}');
    
    // Initialize data manager if needed
    AnalyticsDataManager().initialize();
    
    // For demonstration - you'd need to add a specific player trends method to the data manager
    // For now we'll return some sample data
    return [];
  } catch (e) {
    debugPrint('Error getting consolidated player trends: $e');
    return [];
  }
}

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
