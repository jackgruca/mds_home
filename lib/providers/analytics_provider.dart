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
  // Clear all cached data
void clearCache() {
  _teamNeeds.clear();
  _positionDistribution.clear();
  AnalyticsCacheManager.clearCache();
  notifyListeners();
}

// Refresh all data
Future<void> refreshData() async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  
  try {
    // Clear all cached data
    _teamNeeds.clear();
    _positionDistribution.clear();
    await AnalyticsCacheManager.refreshAllAnalytics();
    
    // Fetch latest metadata timestamp
    _lastUpdated = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
    
    // Pre-load critical data
    await getTeamNeeds(year: DateTime.now().year);
    await getPositionDistribution(team: 'All Teams');
    
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    debugPrint('Error refreshing analytics data: $e');
    _error = 'Failed to refresh data: $e';
    _isLoading = false;
    notifyListeners();
  }
}

// Add this property after _lastUpdated
String? _error;

// Getter for error
String? get error => _error;
}