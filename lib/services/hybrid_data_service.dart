import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'robust_csv_parser.dart';

/// Hybrid data service that uses CSV with Firebase fallback
/// This allows incremental migration one dataset at a time
class HybridDataService {
  static final HybridDataService _instance = HybridDataService._internal();
  factory HybridDataService() => _instance;
  HybridDataService._internal();

  // Track which datasets are available in CSV
  static const Map<String, String> csvDatasets = {
    'playerStats': 'assets/data/player_stats_2024.csv',
    // Add more datasets here as we migrate them
  };

  // Cache for loaded CSV data
  final Map<String, List<Map<String, dynamic>>> _csvCache = {};
  
  /// Test if CSV loading works
  Future<bool> testCsvLoading() async {
    try {
      print('🧪 Testing robust CSV parsing...');
      return await RobustCsvParser.testParsing();
    } catch (e) {
      print('❌ Robust CSV loading failed: $e');
      return false;
    }
  }

  /// Get player stats - tries CSV first, falls back to Firebase
  Future<List<Map<String, dynamic>>> getPlayerStats({
    String? position,
    List<int>? seasons, // NEW: Multi-season support
    int? limit,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      // Try CSV first
      print('📊 Attempting to load from CSV...');
      final csvData = await _loadPlayerStatsFromCsv();
      
      if (csvData.isNotEmpty) {
        print('✅ Using CSV data (${csvData.length} records)');
        
        // Apply filters
        var filtered = csvData;
        
        if (position != null) {
          filtered = filtered.where((p) => p['position'] == position).toList();
        }
        
        // Apply season filter
        if (seasons != null && seasons.isNotEmpty) {
          filtered = filtered.where((p) => seasons.contains(p['season'])).toList();
        }
        
        // Apply sorting
        if (orderBy != null) {
          filtered.sort((a, b) {
            final aVal = a[orderBy] ?? 0;
            final bVal = b[orderBy] ?? 0;
            if (aVal is num && bVal is num) {
              return descending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
            }
            return 0;
          });
        }
        
        // Apply limit
        if (limit != null && filtered.length > limit) {
          filtered = filtered.take(limit).toList();
        }
        
        return filtered;
      }
    } catch (e) {
      print('⚠️ CSV failed, falling back to Firebase: $e');
    }
    
    // Fallback to Firebase
    return _loadPlayerStatsFromFirebase(
      position: position,
      seasons: seasons,
      limit: limit,
      orderBy: orderBy,
      descending: descending,
    );
  }

  /// Load player stats from CSV
  Future<List<Map<String, dynamic>>> _loadPlayerStatsFromCsv() async {
    // Check cache first
    if (_csvCache.containsKey('playerStats')) {
      return _csvCache['playerStats']!;
    }
    
    // Use robust parser
    final data = await RobustCsvParser.parsePlayerStats();
    
    // Cache the data
    _csvCache['playerStats'] = data;
    
    return data;
  }

  /// Load player stats from Firebase (fallback)
  Future<List<Map<String, dynamic>>> _loadPlayerStatsFromFirebase({
    String? position,
    List<int>? seasons,
    int? limit,
    String? orderBy,
    bool descending = true,
  }) async {
    print('🔥 Loading from Firebase...');
    
    Query query = FirebaseFirestore.instance.collection('playerSeasonStats');
    
    if (position != null) {
      query = query.where('position', isEqualTo: position);
    }
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Clear CSV cache
  void clearCache() {
    _csvCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedDatasets': _csvCache.keys.toList(),
      'playerStatsRecords': _csvCache['playerStats']?.length ?? 0,
    };
  }

  /// Get all available seasons from the dataset
  Future<List<int>> getAvailableSeasons() async {
    try {
      final csvData = await _loadPlayerStatsFromCsv();
      if (csvData.isNotEmpty) {
        final seasons = csvData
            .map((player) => player['season'] as int?)
            .where((season) => season != null)
            .cast<int>()
            .toSet()
            .toList();
        seasons.sort((a, b) => b.compareTo(a)); // Most recent first
        return seasons;
      }
    } catch (e) {
      print('⚠️ Error getting seasons: $e');
    }
    
    // Default seasons if CSV fails
    return [2024, 2023, 2022, 2021, 2020];
  }

  /// Preload data in background for faster app performance
  static Future<void> preloadCriticalData() async {
    try {
      print('🚀 Preloading critical data...');
      final service = HybridDataService();
      
      // Preload player stats
      await service.getPlayerStats();
      
      print('✅ Critical data preloaded');
    } catch (e) {
      print('⚠️ Preload failed: $e');
      // Don't throw - this is background optimization
    }
  }
}