// lib/services/precomputed_analytics_service.dart (MODIFIED)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/firebase_service.dart';
import '../services/analytics_api_service.dart'; // Add this

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
      // Try to get metadata from API first
      final apiMetadata = await AnalyticsApiService.getAnalyticsMetadata();
      
      if (!apiMetadata.containsKey('error') && 
           apiMetadata.containsKey('metadata') && 
           apiMetadata['metadata']?.containsKey('lastUpdated')) {
        // Convert timestamp to DateTime
        final timestamp = apiMetadata['metadata']['lastUpdated'];
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        }
      }
      
      // Fall back to Firestore if API fails
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
  
  /// Get position distribution by team - MODIFIED to use API
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
      // Try API first
      final filters = {
        if (team != null) 'team': team,
        if (rounds != null) 'rounds': rounds,
        if (year != null) 'year': year,
      };
      
      final apiData = await AnalyticsApiService.getAnalyticsData(
        dataType: 'positionDistribution',
        filters: filters,
      );
      
      if (!apiData.containsKey('error') && apiData.containsKey('data')) {
        debugPrint('Using API data for position distribution');
        
        final data = apiData['data'];
        
        // If requesting all teams or specific team, handle accordingly
        if (team == null) {
          return data['overall'] ?? {'total': 0, 'positions': {}};
        } else if (data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
          return data['byTeam'][team] ?? {'total': 0, 'positions': {}};
        }
      }
      
      // Fall back to Firestore if API fails
      await ensureInitialized();
      
      final precomputedDoc = await _firestore
          .collection(precomputedAnalyticsCollection)
          .doc('positionDistribution')
          .get();
          
      // lib/services/precomputed_analytics_service.dart (MODIFIED - continued)
      
      if (precomputedDoc.exists && precomputedDoc.data() != null) {
        final data = precomputedDoc.data()!;
        
        // If requesting all teams and all rounds,
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
      // This would call your original analytics query method
      
      // For this example, return empty data
      return {'total': 0, 'positions': {}};
    } catch (e) {
      debugPrint('Error getting position breakdown: $e');
      return {'total': 0, 'positions': {}};
    }
  }
  
  /// Get consensus team needs - MODIFIED to use API
  static Future<Map<String, List<String>>> getConsensusTeamNeeds({int? year}) async {
    final cacheKey = 'team_needs_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchConsensusTeamNeeds(year),
    );
  }
  
  static Future<Map<String, List<String>>> _fetchConsensusTeamNeeds(int? year) async {
    try {
      // Try API first
      final filters = {
        if (year != null) 'year': year,
      };
      
      final apiData = await AnalyticsApiService.getAnalyticsData(
        dataType: 'teamNeeds',
        filters: filters,
      );
      
      if (!apiData.containsKey('error') && apiData.containsKey('data')) {
        debugPrint('Using API data for team needs');
        
        final data = apiData['data'];
        
        if (data.containsKey('needs')) {
          return Map<String, List<String>>.from(
            data['needs'].map((key, value) => 
              MapEntry(key, List<String>.from(value))
            )
          );
        }
      }
      
      // Fall back to Firestore if API fails
      await ensureInitialized();
      
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
  
  /// Get consolidated position trends by pick - MODIFIED to use API
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
      // Try API first
      final filters = {
        if (team != null) 'team': team,
        if (round != null) 'round': round,
        if (year != null) 'year': year,
      };
      
      String dataType = 'positionsByPick';
      if (round != null) {
        dataType = 'positionsByPickRound$round';
      }
      
      final apiData = await AnalyticsApiService.getAnalyticsData(
        dataType: dataType,
        filters: filters,
      );
      
      if (!apiData.containsKey('error') && apiData.containsKey('data')) {
        debugPrint('Using API data for positions by pick');
        
        if (apiData['data'].containsKey('data')) {
          return List<Map<String, dynamic>>.from(apiData['data']['data'] ?? []);
        }
      }
      
      // Fall back to Firestore if API fails
      await ensureInitialized();
      
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
}
