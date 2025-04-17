// lib/providers/analytics_provider.dart (Updated)
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/precomputed_analytics_service.dart';
import '../services/direct_analytics_service.dart'; // Import the direct service

class AnalyticsProvider extends ChangeNotifier {
  // Cache for commonly accessed data
  Map<String, dynamic> _teamNeeds = {};
  final Map<String, dynamic> _positionDistribution = {};
  bool _isLoading = false;
  DateTime? _lastUpdated;
  bool _precomputedAvailable = false;
  
  // Getter for loading state
  bool get isLoading => _isLoading;
  
  // Getter for last updated timestamp
  DateTime? get lastUpdated => _lastUpdated;
  
  // Getter for precomputed availability
  bool get precomputedAvailable => _precomputedAvailable;
  
  // Constructor
  AnalyticsProvider() {
    _initialize();
  }
  
  // Initialize with metadata
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if precomputed analytics are available
      try {
        _lastUpdated = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
        if (_lastUpdated != null) {
          _precomputedAvailable = true;
        }
      } catch (e) {
        debugPrint('Precomputed analytics not available: $e');
        _precomputedAvailable = false;
        
        // Use current time as fallback timestamp
        _lastUpdated = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error initializing analytics provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get team needs, using cache if available
  Future<Map<String, List<String>>> getTeamNeeds({int? year}) async {
    try {
      debugPrint('Fetching team needs for year: $year');
      
      if (_teamNeeds.isNotEmpty && _teamNeeds.containsKey('year') && _teamNeeds['year'] == year) {
        debugPrint('Using cached team needs data');
        return Map<String, List<String>>.from(_teamNeeds['data']);
      }
      
      if (_precomputedAvailable) {
        debugPrint('Fetching team needs from PrecomputedAnalyticsService');
        final needs = await PrecomputedAnalyticsService.getConsensusTeamNeeds(year: year);
        
        // Debug output to check what's being returned
        debugPrint('Received team needs data: ${needs.length} teams');
        
        // Cache the result
        _teamNeeds = {
          'data': needs,
          'year': year,
        };
        
        return needs;
      } else {
        debugPrint('Fetching team needs from DirectAnalyticsService');
        final needs = await DirectAnalyticsService.getTeamNeeds(year: year);
        
        // Debug output to check what's being returned
        debugPrint('Received team needs data from direct service: ${needs.length} teams');
        
        // Cache the result
        _teamNeeds = {
          'data': needs,
          'year': year,
        };
        
        return needs;
      }
    } catch (e) {
      debugPrint('Error fetching team needs: $e');
      // Return empty data on error instead of throwing
      return {};
    }
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
    
    if (_precomputedAvailable) {
      final distribution = await PrecomputedAnalyticsService.getPositionBreakdownByTeam(
        team: team,
        rounds: rounds,
        year: year,
      );
      
      // Cache the result
      _positionDistribution[cacheKey] = distribution;
      
      return distribution;
    } else {
      final distribution = await DirectAnalyticsService.getPositionDistribution(
        team: team,
        rounds: rounds,
        year: year,
      );
      
      // Cache the result
      _positionDistribution[cacheKey] = distribution;
      
      return distribution;
    }
  }
  
  // Get position trends for a specific round
  Future<List<Map<String, dynamic>>> getPositionTrendsByRound({
    required int round,
    String? team,
  }) async {
    final cacheKey = 'position_trends_round${round}_${team ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () async {
        if (_precomputedAvailable) {
          final result = await PrecomputedAnalyticsService.getConsolidatedPositionsByPick(
            round: round,
            team: team,
          );
          return result;
        } else {
          final result = await DirectAnalyticsService.getPositionTrendsByRound(
            round: round,
            team: team,
          );
          
          if (result.containsKey('error')) {
            return <Map<String, dynamic>>[];
          }
          
          return List<Map<String, dynamic>>.from(result['data'] ?? []);
        }
      },
    );
  }
  
  // Clear all cached data
  void clearCache() {
    _teamNeeds.clear();
    _positionDistribution.clear();
    AnalyticsCacheManager.clearCache();
    notifyListeners();
  }
}