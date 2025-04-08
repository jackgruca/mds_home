// lib/providers/analytics_provider.dart (NEW FILE)
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/precomputed_analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  // Cache for commonly accessed data
  Map<String, dynamic> _teamNeeds = {};
  final Map<String, dynamic> _positionDistribution = {};
  bool _isLoading = false;
  DateTime? _lastUpdated;
  
  // Getter for loading state
  bool get isLoading => _isLoading;
  
  // Getter for last updated timestamp
  DateTime? get lastUpdated => _lastUpdated;
  
  // Constructor
  AnalyticsProvider() {
    _initialize();
  }
  
  // Initialize with metadata
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _lastUpdated = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
    } catch (e) {
      debugPrint('Error initializing analytics provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get team needs, using cache if available
  Future<Map<String, List<String>>> getTeamNeeds({int? year}) async {
    if (_teamNeeds.isNotEmpty && _teamNeeds.containsKey('year') && _teamNeeds['year'] == year) {
      return Map<String, List<String>>.from(_teamNeeds['data']);
    }
    
    final needs = await PrecomputedAnalyticsService.getConsensusTeamNeeds(year: year);
    
    // Cache the result
    _teamNeeds = {
      'data': needs,
      'year': year,
    };
    
    return needs;
  }
  
  // Get position distribution, using cache if available
  Future<Map<String, dynamic>> getPositionDistribution({
    String? team,
    List<int>? rounds,
    int? year,
  }) async {
    final cacheKey = 'distribution_${team ?? 'all'}_${rounds?.join('_') ?? 'all'}_${year ?? 'all'}';
    
    if (_positionDistribution.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_positionDistribution[cacheKey]);
    }
    
    final distribution = await PrecomputedAnalyticsService.getPositionBreakdownByTeam(
      team: team,
      rounds: rounds,
      year: year,
    );
    
    // Cache the result
    _positionDistribution[cacheKey] = distribution;
    
    return distribution;
  }
  
  // Clear all cached data
  void clearCache() {
    _teamNeeds.clear();
    _positionDistribution.clear();
    AnalyticsCacheManager.clearCache();
    notifyListeners();
  }
}