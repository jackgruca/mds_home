// lib/providers/analytics_provider.dart
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/precomputed_analytics_service.dart';
import '../services/analytics_query_service.dart'; // Add direct import

class AnalyticsProvider extends ChangeNotifier {
  // Cache for commonly accessed data
  Map<String, dynamic> _teamNeeds = {};
  final Map<String, dynamic> _positionDistribution = {};
  bool _isLoading = false;
  DateTime? _lastUpdated;
  String? _errorMessage;
  
  // Getter for loading state
  bool get isLoading => _isLoading;
  
  // Getter for last updated timestamp
  DateTime? get lastUpdated => _lastUpdated;
  
  // Getter for error message
  String? get errorMessage => _errorMessage;
  
  // Constructor
  AnalyticsProvider() {
    _initialize();
  }
  
  // Initialize with metadata
  Future<void> _initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _lastUpdated = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
    } catch (e) {
      debugPrint('Error initializing analytics provider: $e');
      _errorMessage = 'Could not load analytics metadata. Using direct data access.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get the last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    try {
      final timestamp = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
      _lastUpdated = timestamp;
      return timestamp;
    } catch (e) {
      debugPrint('Error getting last updated timestamp: $e');
      return null;
    }
  }
  
  // Get team needs, using cache if available
  Future<Map<String, List<String>>> getTeamNeeds({int? year}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if we have cached data
      if (_teamNeeds.isNotEmpty && _teamNeeds.containsKey('year') && _teamNeeds['year'] == year) {
        _isLoading = false;
        notifyListeners();
        return Map<String, List<String>>.from(_teamNeeds['data']);
      }
      
      // Use the enhanced analytics query service that handles fallbacks
      final needs = await AnalyticsQueryService.getConsensusTeamNeeds(year: year);
      
      // Cache the result
      _teamNeeds = {
        'data': needs,
        'year': year,
      };
      
      _isLoading = false;
      notifyListeners();
      return needs;
    } catch (e) {
      debugPrint('Error getting team needs: $e');
      _errorMessage = 'Error loading team needs data: $e';
      _isLoading = false;
      notifyListeners();
      return {}; // Return empty map on error
    }
  }
  
  // Get position distribution, using cache if available
  Future<Map<String, dynamic>> getPositionDistribution({
    String? team,
    List<int>? rounds,
    int? year,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final cacheKey = 'distribution_${team ?? 'all'}_${rounds?.join('_') ?? 'all'}_${year ?? 'all'}';
      
      // Check if we have cached data
      if (_positionDistribution.containsKey(cacheKey)) {
        _isLoading = false;
        notifyListeners();
        return Map<String, dynamic>.from(_positionDistribution[cacheKey]);
      }
      
      // Use the enhanced analytics query service
      final distribution = await AnalyticsQueryService.getPositionBreakdownByTeam(
        team: team ?? 'All Teams',
        rounds: rounds,
        year: year,
      );
      
      // Cache the result
      _positionDistribution[cacheKey] = distribution;
      
      _isLoading = false;
      notifyListeners();
      return distribution;
    } catch (e) {
      debugPrint('Error getting position distribution: $e');
      _errorMessage = 'Error loading position data: $e';
      _isLoading = false;
      notifyListeners();
      return {'total': 0, 'positions': {}}; // Return empty data on error
    }
  }

  // Get position trends by pick
  Future<List<Map<String, dynamic>>> getPositionsByPick({
    String? team,
    int? round,
    int? year,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Use the analytics query service that handles fallbacks
      final data = await AnalyticsQueryService.getConsolidatedPositionsByPick(
        team: team,
        round: round,
        year: year,
      );
      
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint('Error getting positions by pick: $e');
      _errorMessage = 'Error loading position trends: $e';
      _isLoading = false;
      notifyListeners();
      return []; // Return empty list on error
    }
  }

  // Get player trends by pick
  Future<List<Map<String, dynamic>>> getPlayersByPick({
    String? team,
    int? round,
    int? year,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Use the analytics query service
      final data = await AnalyticsQueryService.getConsolidatedPlayersByPick(
        team: team,
        round: round,
        year: year,
      );
      
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint('Error getting players by pick: $e');
      _errorMessage = 'Error loading player trends: $e';
      _isLoading = false;
      notifyListeners();
      return []; // Return empty list on error
    }
  }

  // Get player rank deviations
  Future<Map<String, dynamic>> getPlayerRankDeviations({
    int? year,
    String? position,
    int? limit = 10,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Use the analytics query service
      final data = await AnalyticsQueryService.getPlayerRankDeviations(
        year: year,
        position: position,
        limit: limit,
      );
      
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint('Error getting player rank deviations: $e');
      _errorMessage = 'Error loading player analytics: $e';
      _isLoading = false;
      notifyListeners();
      return {'players': [], 'sampleSize': 0}; // Return empty data on error
    }
  }
  
  // Clear all cached data
  void clearCache() {
    _teamNeeds.clear();
    _positionDistribution.clear();
    _errorMessage = null;
    AnalyticsCacheManager.clearCache();
    _initialize(); // Refresh the timestamp
    notifyListeners();
  }
}