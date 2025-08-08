// lib/services/csv_edge_rankings_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'rankings/csv_rankings_service.dart';

class CsvEdgeRankingsService {
  static List<Map<String, dynamic>> _cachedData = [];
  static bool _isLoaded = false;
  static final CSVRankingsService _csvService = CSVRankingsService();

  /// Load all EDGE rankings data from CSV using the working service pattern
  static Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      print('🔍 EDGE: Loading CSV from assets/rankings/edge_rankings.csv...');
      _cachedData = await _csvService.fetchRankings('edge');
      _isLoaded = true;
      print('✅ EDGE rankings data loaded: ${_cachedData.length} player-seasons');
    } catch (e) {
      print('❌ Error loading EDGE rankings data: $e');
      throw Exception('Failed to load EDGE rankings data: $e');
    }
  }

  /// Get EDGE rankings with filtering options
  static Future<List<Map<String, dynamic>>> getEdgeRankings({
    String? season,
    String? team,
    int? tier,
    int limit = 100,
    String orderBy = 'ranking',
    bool orderDescending = false,
  }) async {
    await loadData();
    
    print('🔍 EDGE: getEdgeRankings called with season=$season, team=$team, tier=$tier');
    print('🔍 EDGE: Starting with ${_cachedData.length} total records');
    List<Map<String, dynamic>> filteredData = List.from(_cachedData);

    // Apply filters
    if (season != null && season.isNotEmpty) {
      final beforeCount = filteredData.length;
      filteredData = filteredData.where((player) => 
        player['season']?.toString() == season).toList();
      print('🔍 EDGE: Season filter "$season": $beforeCount -> ${filteredData.length}');
      
      if (filteredData.isEmpty && beforeCount > 0) {
        print('🔍 EDGE: Available seasons: ${_cachedData.map((r) => r['season']).toSet().toList()}');
      }
    }

    if (team != null && team.isNotEmpty) {
      final beforeCount = filteredData.length;
      filteredData = filteredData.where((player) => 
        player['team']?.toString().toUpperCase() == team.toUpperCase()).toList();
      print('🔍 EDGE: Team filter "$team": $beforeCount -> ${filteredData.length}');
    }

    if (tier != null) {
      filteredData = filteredData.where((player) => 
        _parseDouble(player['tier']) == tier).toList();
      print('🔍 EDGE: Tier filter $tier: ${filteredData.length} records after filter');
    }

    // Sort data
    filteredData.sort((a, b) {
      dynamic aValue = a[orderBy];
      dynamic bValue = b[orderBy];
      
      // Handle numeric sorting
      if (_isNumeric(aValue) && _isNumeric(bValue)) {
        double aNum = _parseDouble(aValue);
        double bNum = _parseDouble(bValue);
        int result = aNum.compareTo(bNum);
        return orderDescending ? -result : result;
      }
      
      // Handle string sorting
      String aStr = aValue?.toString() ?? '';
      String bStr = bValue?.toString() ?? '';
      int result = aStr.compareTo(bStr);
      return orderDescending ? -result : result;
    });

    // Apply limit
    final result = filteredData.take(limit).toList();
    print('🔍 EDGE: Final result: ${result.length} records (limit: $limit)');
    return result;
  }

  /// Get available seasons
  static Future<List<String>> getSeasons() async {
    await loadData();
    return _cachedData
        .map((player) => player['season']?.toString() ?? '')
        .where((season) => season.isNotEmpty)
        .toSet()
        .toList()
        ..sort((a, b) => b.compareTo(a)); // Latest first
  }

  /// Get available teams
  static Future<List<String>> getTeams() async {
    await loadData();
    return _cachedData
        .map((player) => player['team']?.toString() ?? '')
        .where((team) => team.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  /// Get available tiers
  static Future<List<int>> getTiers() async {
    await loadData();
    return _cachedData
        .map((player) => _parseDouble(player['tier']).toInt())
        .toSet()
        .toList()
        ..sort();
  }

  /// Helper: Parse double from dynamic value
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper: Check if value is numeric
  static bool _isNumeric(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    if (value is String) return double.tryParse(value) != null;
    return false;
  }

  /// Clear cached data
  static void clearCache() {
    _cachedData.clear();
    _isLoaded = false;
  }
}