// lib/services/analytics_data_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cache_service.dart';

/// Service for efficient access to analytics data using consolidated queries and caching
class AnalyticsDataManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'analytics_daily_snapshots';
  
  // Current data version - increment when data structure changes
  static const String _dataVersion = "1";
  
  // Singleton instance
  static final AnalyticsDataManager _instance = AnalyticsDataManager._internal();
  factory AnalyticsDataManager() => _instance;
  AnalyticsDataManager._internal();
  
  // Cached map of all analytics data
  Map<String, dynamic> _cachedAnalyticsData = {};
  DateTime? _lastDataRefresh;
  bool _isLoading = false;
  
  // Signal if data is ready
  bool get isDataReady => _cachedAnalyticsData.isNotEmpty;
  bool get isLoading => _isLoading;
  
  /// Initialize the data manager. Call this at app startup.
  /// Initialize the data manager - but don't load data yet
void initialize() {
  debugPrint('Analytics Data Manager initialized - data will be loaded on demand');
}

/// Load minimal data for a specific team or query - call this instead of refreshData
Future<Map<String, dynamic>> loadMinimalDataFor(String dataType, {String? team, String? round}) async {
  if (_isLoading) {
    // Return empty while loading
    return {};
  }
  
  _isLoading = true;
  final cacheKey = 'analytics_${dataType}_${team ?? "all"}_${round ?? "all"}';
  
  // Try to get from cache first
  final cachedData = CacheService.getData(cacheKey);
  if (cachedData != null) {
    _isLoading = false;
    return Map<String, dynamic>.from(cachedData);
  }
  
  try {
    Map<String, dynamic> result = {};
    
    // Load only what's needed based on dataType
    switch (dataType) {
      case 'position_trends':
        // Just load position trends for this team/round
        final query = _firestore
            .collection('position_trends')
            .limit(1); // Adjust as needed
            
        if (round != null && round != 'all') {
          query.where('round', isEqualTo: round);
        }
        
        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          result = snapshot.docs.first.data();
        }
        break;
        
      case 'team_needs':
        // Just load team needs
        final snapshot = await _firestore
            .collection('consensus_needs')
            .doc('latest')
            .get();
            
        if (snapshot.exists) {
          result = snapshot.data() ?? {};
        }
        break;
        
      // Add other specific data types as needed
    }
    
    // Cache for future use
    CacheService.setData(cacheKey, result);
    return result;
    
  } catch (e) {
    debugPrint('Error loading minimal data: $e');
    return {};
  } finally {
    _isLoading = false;
  }
}
  
  /// Force a refresh of all analytics data - use sparingly
  Future<void> refreshData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    debugPrint('Refreshing all analytics data...');
    
    // Check cache first
    final cachedData = CacheService.getCacheWithVersion('all_analytics', _dataVersion, 
        validity: const Duration(hours: 12));
    
    if (cachedData != null) {
      _cachedAnalyticsData = Map<String, dynamic>.from(cachedData);
      _lastDataRefresh = DateTime.now();
      _isLoading = false;
      debugPrint('Loaded analytics data from cache: ${_cachedAnalyticsData.length} entries');
      return;
    }
    
    try {
      // Get the most recent 30 days of data
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      // Format dates for Firestore query
      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      
      // Make a single query for all data
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();
      
      // Clear previous data
      _cachedAnalyticsData = {};
      
      // Process all documents
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String;
        
        // Store by date for easy access
        _cachedAnalyticsData[date] = data;
      }
      
      // Process team-specific data
      await _processTeamData();
      
      // Process position trend data 
      await _processPositionTrends();
      
      // Process other aggregate data
      _processAggregateData();
      
      // Cache the processed data
      CacheService.setCacheWithVersion('all_analytics', _dataVersion, _cachedAnalyticsData);
      
      _lastDataRefresh = DateTime.now();
      debugPrint('Refreshed analytics data: ${_cachedAnalyticsData.length} entries');
    } catch (e) {
      debugPrint('Error refreshing analytics data: $e');
    } finally {
      _isLoading = false;
    }
  }
  
  /// Processes team-specific data in a single batch
  Future<void> _processTeamData() async {
    try {
      // Get team pick data
      final teamPicksSnapshot = await _firestore
          .collection('team_picks_analytics')
          .orderBy('count', descending: true)
          .get();
      
      Map<String, List<Map<String, dynamic>>> teamPicksData = {};
      
      for (final doc in teamPicksSnapshot.docs) {
        final data = doc.data();
        final team = data['team'] as String;
        final position = data['position'] as String;
        final picks = (data['picks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        if (!teamPicksData.containsKey(team)) {
          teamPicksData[team] = [];
        }
        
        teamPicksData[team]!.add({
          'position': position,
          'count': data['count'] ?? 0,
          'percentage': data['percentage'] ?? '0%',
          'picks': picks,
        });
      }
      
      // Store in cache
      _cachedAnalyticsData['team_picks'] = teamPicksData;
      
    } catch (e) {
      debugPrint('Error processing team data: $e');
    }
  }
  
  /// Process position trends across rounds
  Future<void> _processPositionTrends() async {
    try {
      final positionTrendsSnapshot = await _firestore
          .collection('position_trends')
          .get();
      
      Map<String, List<Map<String, dynamic>>> roundPositionData = {};
      
      for (final doc in positionTrendsSnapshot.docs) {
        final data = doc.data();
        final round = data['round'] as String? ?? 'all';
        final positions = (data['positions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        roundPositionData[round] = positions;
      }
      
      // Store in cache
      _cachedAnalyticsData['position_trends'] = roundPositionData;
      
    } catch (e) {
      debugPrint('Error processing position trends: $e');
    }
  }
  
  /// Process aggregate data from existing entries
  void _processAggregateData() {
    // Calculate consensus team needs
    Map<String, List<String>> consensusNeeds = {};
    
    // Team position frequency
    Map<String, Map<String, int>> teamPositionCounts = {};
    
    // Extract from existing data if available
    if (_cachedAnalyticsData.containsKey('team_picks')) {
      final teamPicksData = _cachedAnalyticsData['team_picks'] as Map<String, List<Map<String, dynamic>>>;
      
      teamPicksData.forEach((team, positions) {
        // Sort positions by count/frequency
        positions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
        
        // Extract top 5 positions as consensus needs
        consensusNeeds[team] = positions.take(5).map((p) => p['position'] as String).toList();
        
        // Track position counts
        teamPositionCounts[team] = {};
        for (final position in positions) {
          teamPositionCounts[team]![position['position'] as String] = position['count'] as int;
        }
      });
    }
    
    // Store processed aggregate data
    _cachedAnalyticsData['consensus_needs'] = consensusNeeds;
    _cachedAnalyticsData['team_position_counts'] = teamPositionCounts;
  }
  
  /// Get position trends for a specific round (or all rounds)
  List<Map<String, dynamic>> getPositionTrends({String? round, String? team}) {
    if (!isDataReady) return [];
    
    // Auto-refresh if data is stale (older than 1 hour)
    _checkDataFreshness();
    
    final roundKey = round?.toString() ?? 'all';
    final trends = (_cachedAnalyticsData['position_trends'] as Map<String, dynamic>?)?[roundKey];
    
    if (trends == null) return [];
    
    final result = List<Map<String, dynamic>>.from(trends as List);
    
    // Filter by team if specified
    if (team != null && team != 'All Teams') {
      return result.where((item) => 
        (item['team'] as String?) == team
      ).toList();
    }
    
    return result;
  }
  
  /// Get top players by position frequency
  List<Map<String, dynamic>> getPositionFrequency({String? team}) {
    if (!isDataReady) return [];
    
    // Auto-refresh if data is stale (older than 1 hour)
    _checkDataFreshness();
    
    if (team == null || team == 'All Teams') {
      // Return overall position frequency
      final allPositions = <String, int>{};
      
      (_cachedAnalyticsData['team_position_counts'] as Map<String, Map<String, int>>?)?.forEach((_, positions) {
        positions.forEach((position, count) {
          allPositions[position] = (allPositions[position] ?? 0) + count;
        });
      });
      
      // Convert to sorted list
      final result = allPositions.entries.map((e) => {
        'position': e.key,
        'count': e.value,
        'percentage': '${((e.value / allPositions.values.fold(0, (a, b) => a + b)) * 100).toStringAsFixed(1)}%',
      }).toList();
      
      // Sort by count
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return result;
    } else {
      // Return team-specific position frequency
      final teamData = (_cachedAnalyticsData['team_picks'] as Map<String, List<Map<String, dynamic>>>?)?[team];
      
      if (teamData == null) return [];
      
      // Already sorted by count in the processing step
      return List<Map<String, dynamic>>.from(teamData);
    }
  }
  
  /// Get consensus team needs
  Map<String, List<String>> getConsensusTeamNeeds() {
    if (!isDataReady) return {};
    
    // Auto-refresh if data is stale (older than 1 hour)
    _checkDataFreshness();
    
    return Map<String, List<String>>.from(_cachedAnalyticsData['consensus_needs'] as Map<String, dynamic>? ?? {});
  }
  
  /// Check if data is fresh, refresh if needed
  void _checkDataFreshness() {
    if (_lastDataRefresh == null) return;
    
    final now = DateTime.now();
    if (now.difference(_lastDataRefresh!) > const Duration(hours: 1)) {
      // Schedule a refresh in the background
      Future.microtask(() => refreshData());
    }
  }
  
  /// Clear all cached data
  void clearCache() {
    _cachedAnalyticsData = {};
    _lastDataRefresh = null;
    CacheService.clearCacheWithPrefix('all_analytics');
    debugPrint('Cleared analytics data cache');
  }
}