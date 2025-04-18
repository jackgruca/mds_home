// lib/services/analytics_query_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    try {
      // First try to get data from precomputed stats
      Map<String, dynamic> precomputedData = await PrecomputedAnalyticsService.getPositionBreakdownByTeam(
        team: team,
        rounds: rounds,
        year: year,
      );
      
      // Check if we received valid data with positions
      if (precomputedData.containsKey('positions') && 
          precomputedData['positions'] is Map && 
          (precomputedData['positions'] as Map).isNotEmpty) {
        debugPrint('Using precomputed position data');
        return precomputedData;
      }
      
      // If no precomputed data, fall back to direct calculation
      debugPrint('Precomputed data empty, falling back to direct calculation');
      return await _calculatePositionBreakdown(team, rounds, year);
    } catch (e) {
      debugPrint('Error in getPositionBreakdownByTeam: $e');
      // On error, try direct calculation
      return await _calculatePositionBreakdown(team, rounds, year);
    }
  }

  /// Direct calculation of position breakdown from raw analytics data
  static Future<Map<String, dynamic>> _calculatePositionBreakdown(
    String team,
    List<int>? rounds,
    int? year,
  ) async {
    try {
      await ensureInitialized();
      
      // Build the query based on filters
      Query query = _firestore.collection(draftAnalyticsCollection);
      
      if (team != 'All Teams') {
        query = query.where('userTeam', isEqualTo: team);
      }
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      // For better performance, limit to a reasonable number
      query = query.limit(100);
      
      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} draft analytics documents for position breakdown');
      
      if (snapshot.docs.isEmpty) {
        return {'total': 0, 'positions': {}};
      }
      
      // Process all picks and count positions
      Map<String, int> positionCounts = {};
      int totalPicks = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
          
          for (var pickData in picks) {
            final pick = DraftPickRecord.fromFirestore(pickData);
            
            // Filter by round if specified
            if (rounds != null && !rounds.contains(int.tryParse(pick.round))) {
              continue;
            }
            
            // Count position
            final position = pick.position;
            positionCounts[position] = (positionCounts[position] ?? 0) + 1;
            totalPicks++;
          }
        } catch (e) {
          debugPrint('Error processing position document: $e');
        }
      }
      
      // Format as expected by the UI
      Map<String, dynamic> result = {
        'total': totalPicks,
        'positions': {}
      };
      
      for (var entry in positionCounts.entries) {
        result['positions'][entry.key] = {
          'count': entry.value,
          'percentage': '${((entry.value / totalPicks) * 100).toStringAsFixed(1)}%'
        };
      }
      
      return result;
    } catch (e) {
      debugPrint('Error calculating position breakdown: $e');
      return {'total': 0, 'positions': {}};
    }
  }

  /// Get average player rank deviation by round or position - OPTIMIZED
  static Future<Map<String, dynamic>> getPlayerRankDeviations({
    int? year,
    String? position,
    int? limit = 10,
  }) async {
    try {
      final cacheKey = 'player_deviations_${position ?? 'all'}_${year ?? 'all'}_$limit';
      
      // First check the cache
      if (AnalyticsCacheManager.isCacheFresh(cacheKey)) {
        return await AnalyticsCacheManager.getCachedData(
          cacheKey, 
          () => _fetchPlayerRankDeviations(year, position, limit),
        );
      }
      
      // Try precomputed data
      try {
        final apiData = await AnalyticsApiService.getAnalyticsData(
          dataType: 'playerDeviations',
          filters: {
            if (year != null) 'year': year,
            if (position != null) 'position': position,
            if (limit != null) 'limit': limit,
          },
        );
        
        if (!apiData.containsKey('error') && apiData.containsKey('data')) {
          // Check if data actually has players
          if (apiData['data'].containsKey('players') &&
              apiData['data']['players'] is List &&
              (apiData['data']['players'] as List).isNotEmpty) {
            debugPrint('Using API data for player deviations');
            return apiData['data'];
          }
        }
      } catch (e) {
        debugPrint('API error for player deviations: $e');
      }
      
      // Fall back to direct calculation
      return await _calculatePlayerDeviations(year, position, limit);
    } catch (e) {
      debugPrint('Error in getPlayerRankDeviations: $e');
      // Fall back to direct calculation on error
      return await _calculatePlayerDeviations(year, position, limit);
    }
  }
  
  /// Direct calculation of player deviations from raw analytics data
  static Future<Map<String, dynamic>> _calculatePlayerDeviations(
    int? year,
    String? position,
    int? limit,
  ) async {
    try {
      await ensureInitialized();
      
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection);
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      // Limit to a reasonable amount for performance
      query = query.limit(50);
      
      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} draft analytics documents for player deviations');
      
      if (snapshot.docs.isEmpty) {
        return {'players': [], 'sampleSize': 0};
      }
      
      // Calculate deviations
      Map<String, Map<String, dynamic>> playerData = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
          
          for (var pickData in picks) {
            final pick = DraftPickRecord.fromFirestore(pickData);
            
            // Filter by position if specified
            if (position != null && pick.position != position) {
              continue;
            }
            
            // Calculate deviation
            final deviation = pick.pickNumber - pick.playerRank;
            
            // Create player key (name + position to avoid duplicates)
            final key = '${pick.playerName}|${pick.position}';
            
            if (!playerData.containsKey(key)) {
              playerData[key] = {
                'name': pick.playerName,
                'position': pick.position,
                'deviations': <double>[],
                'school': pick.school,
              };
            }
            
            // Add this deviation
            playerData[key]!['deviations'] = 
                [...(playerData[key]!['deviations'] as List<double>), deviation.toDouble()];
          }
        } catch (e) {
          debugPrint('Error processing deviation document: $e');
        }
      }
      
      // Calculate averages
      List<Map<String, dynamic>> deviations = [];
      
      for (var entry in playerData.entries) {
        List<double> values = List<double>.from(entry.value['deviations']);
        
        // Only include players with multiple data points
        if (values.length >= 2) {
          double sum = values.reduce((a, b) => a + b);
          double avg = sum / values.length;
          
          deviations.add({
            'name': entry.value['name'],
            'position': entry.value['position'],
            'avgDeviation': avg.toStringAsFixed(1),
            'sampleSize': values.length,
            'school': entry.value['school'],
          });
        }
      }
      
      // Sort by absolute deviation
      deviations.sort((a, b) => 
        double.parse(b['avgDeviation']).abs().compareTo(
            double.parse(a['avgDeviation']).abs()));
      
      // Apply limit if specified
      if (limit != null && limit > 0 && deviations.length > limit) {
        deviations = deviations.sublist(0, limit);
      }
      
      return {
        'players': deviations,
        'sampleSize': snapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error calculating player deviations: $e');
      return {'players': [], 'sampleSize': 0};
    }
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
      return await _calculatePlayerDeviations(year, position, limit);
    } catch (e) {
      debugPrint('Error getting player rank deviations: $e');
      return {'players': [], 'sampleSize': 0};
    }
  }

  /// Get consensus team needs based on position frequency - OPTIMIZED
  static Future<Map<String, List<String>>> getConsensusTeamNeeds({
    int? year,
  }) async {
    try {
      // First try to get data from precomputed stats
      Map<String, List<String>> precomputedData = await PrecomputedAnalyticsService.getConsensusTeamNeeds(
        year: year,
      );
      
      // Check if we received valid data
      if (precomputedData.isNotEmpty) {
        debugPrint('Using precomputed team needs');
        return precomputedData;
      }
      
      // If empty, fall back to direct calculation
      debugPrint('Precomputed team needs empty, falling back to direct calculation');
      return await _calculateTeamNeeds(year);
    } catch (e) {
      debugPrint('Error in getConsensusTeamNeeds: $e');
      // On error, fall back to direct calculation
      return await _calculateTeamNeeds(year);
    }
  }

  /// Direct calculation of team needs from raw analytics data
  static Future<Map<String, List<String>>> _calculateTeamNeeds(int? year) async {
    try {
      await ensureInitialized();
      
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection);
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      // Limit to reasonable amount for performance
      query = query.limit(100);
      
      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} draft analytics documents for team needs');
      
      if (snapshot.docs.isEmpty) {
        // Provide some reasonable default needs as fallback
        return _getDefaultTeamNeeds();
      }
      
      // Process positions by team
      Map<String, Map<String, int>> teamPositionCounts = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
          
          // Process each pick, focusing on early rounds (1-3)
          for (var pickData in picks) {
            final pick = DraftPickRecord.fromFirestore(pickData);
            final round = int.tryParse(pick.round) ?? 0;
            
            // Focus on early rounds
            if (round > 3) continue;
            
            final position = pick.position;
            final team = pick.actualTeam;
            
            // Initialize team data if needed
            teamPositionCounts[team] ??= {};
            
            // Weight by round: Round 1 = 3x, Round 2 = 2x, Round 3 = 1x
            int weight = 4 - round;
            teamPositionCounts[team]![position] = 
                (teamPositionCounts[team]![position] ?? 0) + weight;
          }
        } catch (e) {
          debugPrint('Error processing team needs document: $e');
        }
      }
      
      // Convert to needs by reversing logic - positions drafted least are needs
      Map<String, List<String>> teamNeeds = {};
      
      // Calculate needs for each team
      for (var teamName in teamPositionCounts.keys) {
        // Get all standard positions
        List<String> standardPositions = [
          'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'EDGE', 'DL', 'LB', 'CB', 'S'
        ];
        
        // Count occurrences for each position
        Map<String, int> positionCounts = teamPositionCounts[teamName] ?? {};
        
        // Convert to scores where lower means more needed
        Map<String, int> positionScores = {};
        
        for (var position in standardPositions) {
          positionScores[position] = positionCounts[position] ?? 0;
        }
        
        // Sort positions by counts (ascending = most needed first)
        List<MapEntry<String, int>> sortedPositions = positionScores.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        
        // Take top 5 lowest counts as needs
        teamNeeds[teamName] = sortedPositions
            .take(5)
            .map((e) => e.key)
            .toList();
      }
      
      // If some teams are missing, add defaults
      if (teamNeeds.length < 32) {
        Map<String, List<String>> defaults = _getDefaultTeamNeeds();
        for (var team in defaults.keys) {
          if (!teamNeeds.containsKey(team)) {
            teamNeeds[team] = defaults[team]!;
          }
        }
      }
      
      return teamNeeds;
    } catch (e) {
      debugPrint('Error calculating team needs: $e');
      return _getDefaultTeamNeeds();
    }
  }

  /// Generate reasonable default team needs when no data is available
  static Map<String, List<String>> _getDefaultTeamNeeds() {
    // Basic mapping of teams to reasonable needs
    return {
      'Arizona Cardinals': ['OT', 'EDGE', 'CB', 'WR', 'DL'],
      'Atlanta Falcons': ['EDGE', 'DL', 'CB', 'IOL', 'RB'],
      'Baltimore Ravens': ['CB', 'EDGE', 'WR', 'DL', 'IOL'],
      'Buffalo Bills': ['WR', 'LB', 'CB', 'IOL', 'RB'],
      'Carolina Panthers': ['WR', 'OT', 'CB', 'IOL', 'EDGE'],
      'Chicago Bears': ['IOL', 'EDGE', 'DL', 'CB', 'WR'],
      'Cincinnati Bengals': ['OT', 'DL', 'CB', 'IOL', 'TE'],
      'Cleveland Browns': ['DL', 'EDGE', 'WR', 'S', 'LB'],
      'Dallas Cowboys': ['DL', 'IOL', 'LB', 'RB', 'CB'],
      'Denver Broncos': ['QB', 'OT', 'EDGE', 'CB', 'WR'],
      'Detroit Lions': ['CB', 'EDGE', 'DL', 'S', 'IOL'],
      'Green Bay Packers': ['OT', 'DL', 'TE', 'S', 'IOL'],
      'Houston Texans': ['RB', 'DL', 'IOL', 'TE', 'S'],
      'Indianapolis Colts': ['EDGE', 'CB', 'WR', 'IOL', 'DL'],
      'Jacksonville Jaguars': ['EDGE', 'CB', 'DL', 'IOL', 'S'],
      'Kansas City Chiefs': ['EDGE', 'CB', 'OT', 'WR', 'DL'],
      'Las Vegas Raiders': ['QB', 'OT', 'CB', 'DL', 'EDGE'],
      'Los Angeles Chargers': ['OT', 'IOL', 'WR', 'DL', 'S'],
      'Los Angeles Rams': ['OT', 'IOL', 'EDGE', 'LB', 'CB'],
      'Miami Dolphins': ['OT', 'IOL', 'EDGE', 'RB', 'LB'],
      'Minnesota Vikings': ['DL', 'CB', 'WR', 'IOL', 'S'],
      'New England Patriots': ['QB', 'OT', 'WR', 'CB', 'IOL'],
      'New Orleans Saints': ['QB', 'DL', 'IOL', 'LB', 'TE'],
      'New York Giants': ['QB', 'WR', 'IOL', 'EDGE', 'LB'],
      'New York Jets': ['OT', 'EDGE', 'CB', 'S', 'IOL'],
      'Philadelphia Eagles': ['LB', 'RB', 'CB', 'S', 'EDGE'],
      'Pittsburgh Steelers': ['OT', 'CB', 'WR', 'DL', 'IOL'],
      'San Francisco 49ers': ['CB', 'S', 'IOL', 'EDGE', 'WR'],
      'Seattle Seahawks': ['DL', 'IOL', 'EDGE', 'LB', 'CB'],
      'Tampa Bay Buccaneers': ['EDGE', 'IOL', 'CB', 'DL', 'QB'],
      'Tennessee Titans': ['OT', 'EDGE', 'CB', 'WR', 'IOL'],
      'Washington Commanders': ['LB', 'S', 'OT', 'CB', 'TE']
    };
  }

  /// Get consolidated position trends by pick - OPTIMIZED
  static Future<List<Map<String, dynamic>>> getConsolidatedPositionsByPick({
    String? team,
    int? round,
    int? year,
  }) async {
    try {
      // First try to get data from precomputed stats
      List<Map<String, dynamic>> precomputedData = await PrecomputedAnalyticsService.getConsolidatedPositionsByPick(
        team: team,
        round: round,
        year: year,
      );
      
      // Check if we received valid data
      if (precomputedData.isNotEmpty) {
        debugPrint('Using precomputed positions by pick');
        return precomputedData;
      }
      
      // If empty, fall back to direct calculation
      debugPrint('Precomputed positions by pick empty, falling back to direct calculation');
      
      // If team is specified, handle differently
      if (team != null && team != 'All Teams') {
        return await getTopPositionsByTeam(
          team: team,
          round: round,
          year: year,
        );
      }
      
      return await _calculatePositionsByPick(team, round, year);
    } catch (e) {
      debugPrint('Error in getConsolidatedPositionsByPick: $e');
      // On error, fall back to direct calculation
      return await _calculatePositionsByPick(team, round, year);
    }
  }

  /// Direct calculation of positions by pick from raw analytics data
  static Future<List<Map<String, dynamic>>> _calculatePositionsByPick(
    String? team,
    int? round,
    int? year,
  ) async {
    try {
      await ensureInitialized();
      
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection);
      
      if (team != null && team != 'All Teams') {
        query = query.where('userTeam', isEqualTo: team);
      }
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      // Limit to reasonable amount for performance
      query = query.limit(100);
      
      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} draft analytics documents for positions by pick');
      
      if (snapshot.docs.isEmpty) {
        return [];
      }
      
      // Process positions by pick
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
            
            // Skip invalid data
            if (pickNumber <= 0 || position.isEmpty) continue;
            
            // Initialize data for this pick
            pickPositionCounts[pickNumber] ??= {};
            pickPositionCounts[pickNumber]![position] = 
                (pickPositionCounts[pickNumber]![position] ?? 0) + 1;
            
            // Track total for percentage calculation
            pickTotals[pickNumber] = (pickTotals[pickNumber] ?? 0) + 1;
            
            // Store round for reference
            pickRounds[pickNumber] = pick.round;
          }
        } catch (e) {
          debugPrint('Error processing positions by pick document: $e');
        }
      }
      
      // Convert to required format
      List<Map<String, dynamic>> result = [];
      
      for (var pickEntry in pickPositionCounts.entries) {
        final pickNumber = pickEntry.key;
        final positionCounts = pickEntry.value;
        final totalForPick = pickTotals[pickNumber] ?? 0;
        
        if (totalForPick == 0) continue;
        
        // Process positions into list format with percentages
        List<Map<String, dynamic>> positions = [];
        
        for (var posEntry in positionCounts.entries) {
          positions.add({
            'position': posEntry.key,
            'count': posEntry.value,
            'percentage': '${((posEntry.value / totalForPick) * 100).toStringAsFixed(1)}%',
          });
        }
        
        // Sort by count
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
      debugPrint('Error calculating positions by pick: $e');
      return [];
    }
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
          var data = apiData['data']['data'];
          if (data is List && data.isNotEmpty) {
            return List<Map<String, dynamic>>.from(data);
          }
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
          if (data.containsKey('data') && data['data'] is List && (data['data'] as List).isNotEmpty) {
            debugPrint('Using precomputed players by pick');
            return List<Map<String, dynamic>>.from(data['data']);
          }
        }
        
        // For team-specific data
        if (data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
          var teamData = data['byTeam'][team];
          if (teamData is List && teamData.isNotEmpty) {
            debugPrint('Using precomputed players by pick for team: $team');
            return List<Map<String, dynamic>>.from(teamData);
          }
        }
      }
      
      // Fall back to direct calculation
      return await _calculatePlayersByPick(team, round, year);
    } catch (e) {
      debugPrint('Error getting consolidated players by pick: $e');
      return await _calculatePlayersByPick(team, round, year);
    }
  }

  /// Direct calculation of players by pick from raw analytics data
  static Future<List<Map<String, dynamic>>> _calculatePlayersByPick(
    String? team,
    int? round,
    int? year,
  ) async {
    try {
      await ensureInitialized();
      
      // Build the query
      Query query = _firestore.collection(draftAnalyticsCollection);
      
      if (team != null && team != 'All Teams') {
        query = query.where('userTeam', isEqualTo: team);
      }
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      // Limit to reasonable amount for performance
      query = query.limit(100);
      
      // Execute the query
      final snapshot = await query.get();
      debugPrint('Found ${snapshot.docs.length} draft analytics documents for players by pick');
      
      if (snapshot.docs.isEmpty) {
        return [];
      }
      
      // Process players by pick
      Map<int, Map<String, Map<String, dynamic>>> pickPlayerData = {};
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
            
            // Skip invalid data
            if (pickNumber <= 0 || playerName.isEmpty) continue;
            
            // Create a unique key for player + position to avoid duplicates
            final playerKey = '$playerName|$position';
            
            // Initialize data for this pick
            pickPlayerData[pickNumber] ??= {};
            pickPlayerData[pickNumber]![playerKey] ??= {
              'player': playerName,
              'position': position,
              'count': 0,
            };
            
            // Increment count
            pickPlayerData[pickNumber]![playerKey]!['count'] = 
                (pickPlayerData[pickNumber]![playerKey]!['count'] as int) + 1;
            
            // Track total for percentage calculation
            pickTotals[pickNumber] = (pickTotals[pickNumber] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Error processing players by pick document: $e');
        }
      }
      
      // Convert to required format
      List<Map<String, dynamic>> result = [];
      
      for (var pickEntry in pickPlayerData.entries) {
        final pickNumber = pickEntry.key;
        final playerData = pickEntry.value;
        final totalForPick = pickTotals[pickNumber] ?? 0;
        
        if (totalForPick == 0) continue;
        
        // Convert player data to list
        List<Map<String, dynamic>> players = playerData.values
            .map((data) => {
              'player': data['player'],
              'position': data['position'],
              'count': data['count'],
              'percentage': '${((data['count'] as int) / totalForPick * 100).toStringAsFixed(1)}%',
            })
            .toList();
        
        // Sort by count (highest first)
        players.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
        
        result.add({
          'pick': pickNumber,
          'players': players,
          'totalDrafts': totalForPick,
        });
      }
      
      // Sort by pick number
      result.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
      
      return result;
    } catch (e) {
      debugPrint('Error calculating players by pick: $e');
      return [];
    }
  }

// Add this method to the AnalyticsQueryService class

/// Get top positions by pick number for a specific team
static Future<List<Map<String, dynamic>>> getTopPositionsByTeam({
  required String team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching position trends by pick for $team, round $round');

    // Build the query
    Query query = _firestore.collection(draftAnalyticsCollection);
    
    if (team != 'All Teams') {
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
          
          // Filter by team
          if (team != 'All Teams' && pick.actualTeam != team) {
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
  required String team,
  int? round,
  int? year,
}) async {
  try {
    await ensureInitialized();
    debugPrint('Fetching player trends for $team, round $round');

    // Build the query
    Query query = _firestore.collection(draftAnalyticsCollection);
    
    if (team != 'All Teams') {
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
          
          // Filter by team
          if (team != 'All Teams' && pick.actualTeam != team) {
            continue;
          }
          
          // Each pick has the team's actual selection details
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
// lib/services/analytics_query_service.dart

// Add this method to force a refresh of the analytics cache
static Future<bool> forceRefreshAnalyticsCache() async {
  try {
    // Clear local cache
    AnalyticsCacheManager.clearCache();
    
    // Force reload of metadata and position distribution
    await PrecomputedAnalyticsService.getLatestStatsTimestamp();
    await PrecomputedAnalyticsService.getPositionBreakdownByTeam(team: 'All Teams');
    
    return true;
  } catch (e) {
    debugPrint('Error refreshing analytics cache: $e');
    return false;
  }
}

// Modify the getConsolidatedPositionsByPick method to handle empty results
static Future<List<Map<String, dynamic>>> getConsolidatedPositionsByPickOnDemand({
  String? team,
  int? round,
  int? year,
}) async {
  try {
    // First try to get data from precomputed stats
    final result = await PrecomputedAnalyticsService.getConsolidatedPositionsByPick(
      team: team,
      round: round,
      year: year,
    );
    
    // Check if the result is empty
    if (result.isEmpty) {
      debugPrint('No precomputed position data found, calculating on-demand...');
      
      // Fall back to calculating on demand for this specific query
      return await _calculateOnDemandPositionsByPick(team, round, year);
    }
    
    return result;
  } catch (e) {
    debugPrint('Error getting consolidated positions by pick: $e');
    
    // Fall back to calculating on demand for this specific query
    debugPrint('Falling back to on-demand calculation...');
    return await _calculateOnDemandPositionsByPick(team, round, year);
  }
}

// Add a new method to calculate positions by pick on demand with limit
static Future<List<Map<String, dynamic>>> _calculateOnDemandPositionsByPick(
  String? team,
  int? round,
  int? year,
) async {
  try {
    await ensureInitialized();
    debugPrint('Calculating positions by pick on demand for ${team ?? 'All Teams'}, round $round');

    // Build the query with limits to avoid loading too much data
    Query query = _firestore.collection(draftAnalyticsCollection).limit(100);
    
    if (team != null && team != 'All Teams') {
      query = query.where('userTeam', isEqualTo: team);
    }

    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }

    // Execute the query
    final snapshot = await query.get();
    debugPrint('Found ${snapshot.docs.length} documents for on-demand position trends');

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
        debugPrint('Error processing document for on-demand position trends: $e');
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
    debugPrint('Error calculating on-demand position trends: $e');
    return [];
  }
}
}