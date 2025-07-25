import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// Service for loading and querying local CSV data
/// This replaces Firebase calls with local data access
class LocalDataService {
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  // Cache for loaded data
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  final Map<String, Map<String, int>> _indexCache = {};
  
  /// Load player stats from CSV
  Future<List<Map<String, dynamic>>> loadPlayerStats() async {
    const cacheKey = 'player_stats_2024';
    
    // Return cached data if available
    if (_dataCache.containsKey(cacheKey)) {
      return _dataCache[cacheKey]!;
    }
    
    try {
      // Load CSV from assets
      final csvString = await rootBundle.loadString('assets/data/player_stats_2024.csv');
      
      // Parse CSV
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) {
        throw Exception('CSV file is empty');
      }
      
      // Extract headers
      final headers = csvTable[0].map((e) => e.toString()).toList();
      
      // Convert to list of maps
      final List<Map<String, dynamic>> data = [];
      for (int i = 1; i < csvTable.length; i++) {
        final Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length && j < csvTable[i].length; j++) {
          // Convert numeric strings to proper types
          final value = csvTable[i][j];
          if (value is String) {
            // Try to parse as number
            final numValue = num.tryParse(value);
            row[headers[j]] = numValue ?? value;
          } else {
            row[headers[j]] = value;
          }
        }
        data.add(row);
      }
      
      // Cache the data
      _dataCache[cacheKey] = data;
      
      // Build indexes for common queries
      _buildIndexes(cacheKey, data);
      
      print('✅ Loaded ${data.length} player stats records');
      return data;
    } catch (e) {
      print('❌ Error loading player stats: $e');
      throw Exception('Failed to load player stats: $e');
    }
  }
  
  /// Build indexes for faster queries
  void _buildIndexes(String cacheKey, List<Map<String, dynamic>> data) {
    final index = <String, int>{};
    
    // Index by player_id
    for (int i = 0; i < data.length; i++) {
      final playerId = data[i]['player_id']?.toString();
      if (playerId != null) {
        index['player_$playerId'] = i;
      }
    }
    
    _indexCache[cacheKey] = index;
  }
  
  /// Query player stats with filters (mirrors Firebase query API)
  Future<List<Map<String, dynamic>>> queryPlayerStats({
    String? position,
    String? team,
    int? season,
    String? playerId,
    String? orderBy,
    bool descending = true,
    int? limit,
  }) async {
    // Ensure data is loaded
    final allData = await loadPlayerStats();
    
    // Apply filters
    var filtered = allData.where((player) {
      if (position != null && player['position'] != position) return false;
      if (team != null && player['recent_team'] != team) return false;
      if (season != null && player['season'] != season) return false;
      if (playerId != null && player['player_id'] != playerId) return false;
      return true;
    }).toList();
    
    // Apply ordering
    if (orderBy != null) {
      filtered.sort((a, b) {
        final aValue = a[orderBy] ?? 0;
        final bValue = b[orderBy] ?? 0;
        
        // Handle numeric comparison
        if (aValue is num && bValue is num) {
          return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
        }
        
        // Handle string comparison
        final aStr = aValue.toString();
        final bStr = bValue.toString();
        return descending ? bStr.compareTo(aStr) : aStr.compareTo(bStr);
      });
    }
    
    // Apply limit
    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }
    
    return filtered;
  }
  
  /// Get top performers by stat
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String stat,
    String? position,
    int season = 2024,
    int limit = 10,
  }) async {
    return queryPlayerStats(
      position: position,
      season: season,
      orderBy: stat,
      descending: true,
      limit: limit,
    );
  }
  
  /// Search players by name
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final allData = await loadPlayerStats();
    final searchQuery = query.toLowerCase();
    
    return allData.where((player) {
      final displayName = player['player_display_name_lower']?.toString() ?? '';
      final playerName = player['player_name']?.toString().toLowerCase() ?? '';
      return displayName.contains(searchQuery) || playerName.contains(searchQuery);
    }).toList();
  }
  
  /// Get player by ID (optimized with index)
  Future<Map<String, dynamic>?> getPlayerById(String playerId) async {
    final allData = await loadPlayerStats();
    final index = _indexCache['player_stats_2024'];
    
    // Use index if available
    if (index != null) {
      final idx = index['player_$playerId'];
      if (idx != null && idx < allData.length) {
        return allData[idx];
      }
    }
    
    // Fallback to linear search
    return allData.firstWhere(
      (player) => player['player_id'] == playerId,
      orElse: () => {},
    );
  }
  
  /// Get metadata about the data
  Future<Map<String, dynamic>> getMetadata() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/metadata.json');
      return json.decode(jsonString);
    } catch (e) {
      return {
        'error': 'Failed to load metadata',
        'message': e.toString(),
      };
    }
  }
  
  /// Clear all caches
  void clearCache() {
    _dataCache.clear();
    _indexCache.clear();
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedDatasets': _dataCache.keys.toList(),
      'totalRecords': _dataCache.values.fold(0, (sum, list) => sum + list.length),
      'indexes': _indexCache.keys.toList(),
    };
  }
}