// lib/services/adp/adp_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../models/adp/adp_data.dart';
import '../../models/adp/player_performance.dart';
import '../../models/adp/adp_comparison.dart';

class ADPService {
  static const String _basePath = 'data_processing/assets/data/adp';
  
  // Cache for loaded data
  static final Map<String, List<ADPComparison>> _cache = {};
  static final Map<String, List<ADPData>> _adpCache = {};
  static final Map<String, List<PlayerPerformance>> _performanceCache = {};

  /// Load ADP comparison data (joined data with calculations)
  static Future<List<ADPComparison>> loadADPComparisons({
    required String scoringFormat,
    int? year,
    String? position,
  }) async {
    final cacheKey = 'comparison_$scoringFormat';
    
    // Check cache first
    if (!_cache.containsKey(cacheKey)) {
      final csvPath = '$_basePath/adp_analysis_$scoringFormat.csv';
      
      debugPrint('Loading ADP comparisons from: $csvPath');
      
      try {
        final csvString = await rootBundle.loadString(csvPath);
        debugPrint('Successfully loaded CSV string, length: ${csvString.length}');
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
          eol: '\n',
          fieldDelimiter: ',',
        );
        
        debugPrint('Parsed CSV rows: ${rows.length}');
        
        if (rows.isEmpty) {
          debugPrint('No rows found in CSV');
          return [];
        }
        
        // Get headers from first row
        final headers = rows[0].map((e) => e.toString()).toList();
        debugPrint('CSV headers: $headers');
        
        // Convert remaining rows to ADPComparison objects
        final comparisons = <ADPComparison>[];
        int skippedRows = 0;
        
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          final Map<String, dynamic> rowMap = {};
          
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowMap[headers[j]] = row[j];
          }
          
          final comparison = ADPComparison.fromCsvRow(rowMap);
          
          // Only include records that have valid ADP data
          if (comparison.avgRankNum > 0 && comparison.player.isNotEmpty) {
            comparisons.add(comparison);
          } else {
            skippedRows++;
          }
        }
        
        debugPrint('Successfully parsed ${comparisons.length} ADP comparisons, skipped $skippedRows invalid rows');
        _cache[cacheKey] = comparisons;
      } catch (e, stackTrace) {
        debugPrint('Error loading ADP comparisons from $csvPath: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow; // Re-throw to see the actual error in the UI
      }
    }
    
    // Filter cached data based on parameters
    List<ADPComparison> result = List.from(_cache[cacheKey]!);
    debugPrint('Before filtering: ${result.length} records');
    
    if (year != null) {
      result = result.where((c) => c.season == year).toList();
      debugPrint('After year filter ($year): ${result.length} records');
    }
    
    if (position != null && position != 'All') {
      result = result.where((c) => c.position == position).toList();
      debugPrint('After position filter ($position): ${result.length} records');
    }
    
    debugPrint('Returning ${result.length} filtered records');
    return result;
  }

  /// Load historical ADP data
  static Future<List<ADPData>> loadHistoricalADP({
    required String scoringFormat,
    int? year,
    String? position,
  }) async {
    final cacheKey = 'adp_$scoringFormat';
    
    if (!_adpCache.containsKey(cacheKey)) {
      final csvPath = '$_basePath/historical_adp_$scoringFormat.csv';
      
      try {
        final csvString = await rootBundle.loadString(csvPath);
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
          eol: '\n',
          fieldDelimiter: ',',
        );
        
        if (rows.isEmpty) return [];
        
        final headers = rows[0].map((e) => e.toString()).toList();
        final adpData = <ADPData>[];
        
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          final Map<String, dynamic> rowMap = {};
          
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowMap[headers[j]] = row[j];
          }
          
          adpData.add(ADPData.fromCsvRow(rowMap, scoringFormat));
        }
        
        _adpCache[cacheKey] = adpData;
      } catch (e, stackTrace) {
        debugPrint('Error loading historical ADP from $csvPath: $e');
        debugPrint('Stack trace: $stackTrace');
        return [];
      }
    }
    
    // Filter cached data
    List<ADPData> result = List.from(_adpCache[cacheKey]!);
    
    if (year != null) {
      result = result.where((a) => a.season == year).toList();
    }
    
    if (position != null && position != 'All') {
      result = result.where((a) => a.position == position).toList();
    }
    
    return result;
  }

  /// Load player performance data
  static Future<List<PlayerPerformance>> loadPlayerPerformance({
    int? year,
    String? position,
  }) async {
    const cacheKey = 'performance';
    
    if (!_performanceCache.containsKey(cacheKey)) {
      const csvPath = '$_basePath/player_performance.csv';
      
      try {
        final csvString = await rootBundle.loadString(csvPath);
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
          eol: '\n',
          fieldDelimiter: ',',
        );
        
        if (rows.isEmpty) return [];
        
        final headers = rows[0].map((e) => e.toString()).toList();
        final performanceData = <PlayerPerformance>[];
        
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          final Map<String, dynamic> rowMap = {};
          
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowMap[headers[j]] = row[j];
          }
          
          performanceData.add(PlayerPerformance.fromCsvRow(rowMap));
        }
        
        _performanceCache[cacheKey] = performanceData;
      } catch (e, stackTrace) {
        debugPrint('Error loading player performance from $csvPath: $e');
        debugPrint('Stack trace: $stackTrace');
        return [];
      }
    }
    
    // Filter cached data
    List<PlayerPerformance> result = List.from(_performanceCache[cacheKey]!);
    
    if (year != null) {
      result = result.where((p) => p.season == year).toList();
    }
    
    if (position != null && position != 'All') {
      result = result.where((p) => p.position == position).toList();
    }
    
    return result;
  }

  /// Get available years from the data
  static Future<List<int>> getAvailableYears(String scoringFormat) async {
    final comparisons = await loadADPComparisons(scoringFormat: scoringFormat);
    final years = comparisons.map((c) => c.season).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Sort descending
    return years;
  }

  /// Get available positions from the data
  static Future<List<String>> getAvailablePositions(String scoringFormat) async {
    final comparisons = await loadADPComparisons(scoringFormat: scoringFormat);
    final positions = comparisons.map((c) => c.position).toSet().toList();
    positions.sort();
    return ['All', ...positions];
  }

  /// Clear cache (useful when data is updated)
  static void clearCache() {
    _cache.clear();
    _adpCache.clear();
    _performanceCache.clear();
  }

  /// Debug method to test asset loading
  static Future<bool> testAssetLoading() async {
    try {
      debugPrint('Testing asset loading...');
      
      // Test loading a simple file to verify asset path works
      final testPath = '$_basePath/metadata.csv';
      debugPrint('Attempting to load: $testPath');
      
      final csvString = await rootBundle.loadString(testPath);
      debugPrint('Successfully loaded metadata.csv, length: ${csvString.length}');
      debugPrint('Content preview: ${csvString.substring(0, csvString.length > 200 ? 200 : csvString.length)}...');
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error testing asset loading: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}