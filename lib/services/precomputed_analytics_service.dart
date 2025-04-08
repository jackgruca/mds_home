// lib/services/precomputed_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/firebase_service.dart';

class PrecomputedAnalyticsService {
  static FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }
  
  // Collection paths
  static const String precomputedAnalyticsCollection = 'precomputedAnalytics';
  static const String teamStatsCollection = 'teamStats';
  static const String positionTrendsCollection = 'positionTrends';
  static const String playerStatsCollection = 'playerStats';
  
  /// Initialize and ensure Firebase connection
  static Future<void> ensureInitialized() async {
    if (!FirebaseService.isInitialized) {
      await FirebaseService.initialize();
    }
  }
  
  /// Get the latest stats timestamp
  static Future<DateTime?> getLatestStatsTimestamp() async {
    try {
      await ensureInitialized();
      
      final doc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc('metadata')
          .get();
      
      if (doc.exists && doc.data() != null) {
        final Timestamp timestamp = doc.data()!['lastUpdated'];
        return timestamp.toDate();
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting latest stats timestamp: $e');
      return null;
    }
  }
  
  /// Get position distribution by team
  static Future<Map<String, dynamic>> getPositionBreakdownByTeam({
    String? team,
    List<int>? rounds,
    int? year,
  }) async {
    final cacheKey = 'position_breakdown_${team ?? 'all'}_${rounds?.join('_') ?? 'all'}_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchPositionBreakdown(team, rounds, year),
    );
  }
  
  static Future<Map<String, dynamic>> _fetchPositionBreakdown(
    String? team,
    List<int>? rounds,
    int? year,
  ) async {
    try {
      await ensureInitialized();
      
      // Check if precomputed data exists
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc('positionDistribution')
          .get();
          
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // If requesting all teams and all rounds (most common case),
        // we can use the precomputed overall distribution
        if (team == null && rounds == null) {
          debugPrint('Using precomputed position distribution');
          return data['overall'] ?? {'total': 0, 'positions': {}};
        }
        
        // For team-specific data, check if it exists in precomputed
        if (team != null && data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
          debugPrint('Using precomputed position distribution for team: $team');
          return data['byTeam'][team] ?? {'total': 0, 'positions': {}};
        }
      }
      
      // If we don't have precomputed data, fall back to direct calculation
      debugPrint('Falling back to direct calculation for position distribution');
      // This will call your original analytics query method
      // Note: You would implement this to call your existing calculation method
      
      // For this example, we'll return empty data
      return {'total': 0, 'positions': {}};
    } catch (e) {
      debugPrint('Error getting position breakdown: $e');
      return {'total': 0, 'positions': {}};
    }
  }
  
  /// Get consensus team needs
  static Future<Map<String, List<String>>> getConsensusTeamNeeds({int? year}) async {
    final cacheKey = 'team_needs_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchConsensusTeamNeeds(year),
    );
  }
  
  static Future<Map<String, List<String>>> _fetchConsensusTeamNeeds(int? year) async {
    try {
      await ensureInitialized();
      
      // Check for precomputed data
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc('teamNeeds')
          .get();
          
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // If year filter matches the precomputed year, use it
        if (year == null || year.toString() == data['year'].toString()) {
          debugPrint('Using precomputed team needs');
          return Map<String, List<String>>.from(
            data['needs'].map((key, value) => 
              MapEntry(key, List<String>.from(value))
            )
          );
        }
      }
      
      // Fall back to direct calculation
      debugPrint('Falling back to direct calculation for team needs');
      // Call original method here
      
      return {};
    } catch (e) {
      debugPrint('Error getting consensus team needs: $e');
      return {};
    }
  }
  
  /// Get consolidated position trends by pick
  static Future<List<Map<String, dynamic>>> getConsolidatedPositionsByPick({
    String? team,
    int? round,
    int? year,
  }) async {
    final cacheKey = 'positions_by_pick_${team ?? 'all'}_${round ?? 'all'}_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchConsolidatedPositionsByPick(team, round, year),
    );
  }
  
  static Future<List<Map<String, dynamic>>> _fetchConsolidatedPositionsByPick(
    String? team,
    int? round,
    int? year,
  ) async {
    try {
      await ensureInitialized();
      
      // Check for precomputed data
      String docId = 'positionsByPick';
      if (round != null) {
        docId = 'positionsByPickRound$round';
      }
      
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc(docId)
          .get();
          
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // For all teams data
        if (team == null || team == 'All Teams') {
          debugPrint('Using precomputed positions by pick for round: ${round ?? 'all'}');
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        
        // For team-specific data
        if (data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
          debugPrint('Using precomputed positions by pick for team: $team, round: ${round ?? 'all'}');
          return List<Map<String, dynamic>>.from(data['byTeam'][team] ?? []);
        }
      }
      
      // Fall back to direct calculation
      debugPrint('Falling back to direct calculation for positions by pick');
      // Call original method here
      
      return [];
    } catch (e) {
      debugPrint('Error getting consolidated positions by pick: $e');
      return [];
    }
  }
  
  /// Get consolidated player selections by pick
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
      await ensureInitialized();
      
      // Similar to positions by pick, check for precomputed data
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
        
        if (team == null || team == 'All Teams') {
          debugPrint('Using precomputed players by pick for round: ${round ?? 'all'}');
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        
        if (data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
          debugPrint('Using precomputed players by pick for team: $team, round: ${round ?? 'all'}');
          return List<Map<String, dynamic>>.from(data['byTeam'][team] ?? []);
        }
      }
      
      // Fall back to direct calculation
      debugPrint('Falling back to direct calculation for players by pick');
      // Call original method here
      
      return [];
    } catch (e) {
      debugPrint('Error getting consolidated players by pick: $e');
      return [];
    }
  }
  
  /// Get player rank deviations (risers and fallers)
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
      await ensureInitialized();
      
      // Check for precomputed data
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc('playerDeviations')
          .get();
          
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // For all positions
        if (position == null || position == 'All Positions') {
          debugPrint('Using precomputed player deviations for all positions');
          return {
            'players': List<Map<String, dynamic>>.from(data['players'] ?? []).take(limit ?? 10).toList(),
            'sampleSize': data['sampleSize'] ?? 0,
          };
        }
        
        // For position-specific data
        if (data.containsKey('byPosition') && data['byPosition'].containsKey(position)) {
          debugPrint('Using precomputed player deviations for position: $position');
          return {
            'players': List<Map<String, dynamic>>.from(data['byPosition'][position] ?? []).take(limit ?? 10).toList(),
            'sampleSize': data['positionSampleSizes']?[position] ?? 0,
          };
        }
      }
      
      // Fall back to direct calculation
      debugPrint('Falling back to direct calculation for player rank deviations');
      // Call original method here
      
      return {'players': [], 'sampleSize': 0};
    } catch (e) {
      debugPrint('Error getting player rank deviations: $e');
      return {'players': [], 'sampleSize': 0};
    }
  }
}