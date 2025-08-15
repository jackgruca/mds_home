// lib/services/csv_depth_charts_service.dart

import 'package:flutter/services.dart';

class DepthChartEntry {
  final String season;
  final String team;
  final String fullName;
  final String position;
  final String positionGroup;
  final String? jerseyNumber;
  final String depthChartPosition;
  final int depthChartOrder;
  final int yearsExp;
  final int ageAtSeason;
  final String? height;
  final String? weight;
  final String status;
  final String? rookieYear;
  final String? college;

  DepthChartEntry({
    required this.season,
    required this.team,
    required this.fullName,
    required this.position,
    required this.positionGroup,
    this.jerseyNumber,
    required this.depthChartPosition,
    required this.depthChartOrder,
    required this.yearsExp,
    required this.ageAtSeason,
    this.height,
    this.weight,
    required this.status,
    this.rookieYear,
    this.college,
  });

  factory DepthChartEntry.fromCsvRow(Map<String, String> row) {
    return DepthChartEntry(
      season: row['season'] ?? '',
      team: row['team'] ?? '',
      fullName: row['full_name'] ?? '',
      position: row['position'] ?? '',
      positionGroup: row['position_group'] ?? '',
      jerseyNumber: row['jersey_number'],
      depthChartPosition: row['depth_chart_position'] ?? '',
      depthChartOrder: int.tryParse(row['depth_chart_order'] ?? '1') ?? 1,
      yearsExp: int.tryParse(row['years_exp'] ?? '0') ?? 0,
      ageAtSeason: int.tryParse(row['age_at_season'] ?? '25') ?? 25,
      height: row['height'],
      weight: row['weight'],
      status: row['status'] ?? 'Active',
      rookieYear: row['rookie_year'],
      college: row['college'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'team': team,
      'full_name': fullName,
      'position': position,
      'position_group': positionGroup,
      'jersey_number': jerseyNumber,
      'depth_chart_position': depthChartPosition,
      'depth_chart_order': depthChartOrder,
      'years_exp': yearsExp,
      'age_at_season': ageAtSeason,
      'height': height,
      'weight': weight,
      'status': status,
      'rookie_year': rookieYear,
      'college': college,
    };
  }
}

class CsvDepthChartsService {
  static List<DepthChartEntry>? _cachedDepthCharts;
  static const String _csvAssetPath = 'data/processed/player_stats/nfl_depth_charts.csv';

  /// Load depth chart data from CSV
  static Future<void> _loadDepthChartsFromCSV() async {
    if (_cachedDepthCharts != null) {
      print('DEBUG: Using cached depth charts data (${_cachedDepthCharts!.length} entries)');
      return;
    }

    print('DEBUG: Loading depth charts from $_csvAssetPath');
    try {
      final csvData = await rootBundle.loadString(_csvAssetPath);
      print('DEBUG: CSV data loaded, size: ${csvData.length} characters');
      
      _cachedDepthCharts = await _parseDepthChartsData(csvData);
      print('DEBUG: Parsed ${_cachedDepthCharts!.length} depth chart entries');
      
      if (_cachedDepthCharts!.isNotEmpty) {
        final firstEntry = _cachedDepthCharts!.first;
        print('DEBUG: First entry: ${firstEntry.fullName} - ${firstEntry.team} - ${firstEntry.position}');
      }
    } catch (e) {
      print('ERROR: Error loading depth charts CSV: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      _cachedDepthCharts = [];
    }
  }

  /// Parse CSV data into DepthChartEntry objects
  static Future<List<DepthChartEntry>> _parseDepthChartsData(String csvData) async {
    List<DepthChartEntry> entries = [];
    List<String> lines = csvData.split('\n');

    if (lines.isEmpty) return entries;

    // Parse header row
    List<String> headers = _parseCSVLine(lines[0]);
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }

    // Parse data rows
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        List<String> values = _parseCSVLine(line);
        if (values.length >= headers.length - 3) { // Allow some missing columns
          Map<String, String> row = {};
          for (String header in headers) {
            int? index = columnIndices[header];
            if (index != null && index < values.length) {
              row[header] = values[index];
            }
          }
          entries.add(DepthChartEntry.fromCsvRow(row));
        }
      } catch (e) {
        continue; // Skip invalid rows
      }
    }

    return entries;
  }

  /// Get depth charts with filters
  static Future<List<Map<String, dynamic>>> getDepthCharts({
    String? season,
    String? team,
    String? week, // Not used in CSV version but kept for compatibility
    String? position,
    String? positionGroup,
    int limit = 100,
    String orderBy = 'depth_chart_order',
    bool orderDescending = false,
  }) async {
    print('DEBUG: getDepthCharts called with season=$season, team=$team, position=$position, positionGroup=$positionGroup');
    
    await _loadDepthChartsFromCSV();

    List<DepthChartEntry> filtered = _cachedDepthCharts ?? [];
    print('DEBUG: Starting with ${filtered.length} total entries');

    // Apply filters
    if (season != null && season != 'All') {
      final originalCount = filtered.length;
      filtered = filtered.where((entry) => entry.season == season).toList();
      print('DEBUG: After season filter ($season): ${filtered.length} entries (was $originalCount)');
    }

    if (team != null && team != 'All') {
      final originalCount = filtered.length;
      filtered = filtered.where((entry) => entry.team == team).toList();
      print('DEBUG: After team filter ($team): ${filtered.length} entries (was $originalCount)');
    }

    if (position != null && position != 'All') {
      final originalCount = filtered.length;
      filtered = filtered.where((entry) => entry.position == position).toList();
      print('DEBUG: After position filter ($position): ${filtered.length} entries (was $originalCount)');
    }

    if (positionGroup != null && positionGroup != 'All') {
      final originalCount = filtered.length;
      filtered = filtered.where((entry) => entry.positionGroup == positionGroup).toList();
      print('DEBUG: After positionGroup filter ($positionGroup): ${filtered.length} entries (was $originalCount)');
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (orderBy) {
        case 'full_name':
          result = a.fullName.compareTo(b.fullName);
          break;
        case 'position':
          result = a.position.compareTo(b.position);
          break;
        case 'depth_chart_order':
          result = a.depthChartOrder.compareTo(b.depthChartOrder);
          break;
        case 'years_exp':
          result = a.yearsExp.compareTo(b.yearsExp);
          break;
        case 'age_at_season':
          result = a.ageAtSeason.compareTo(b.ageAtSeason);
          break;
        default:
          result = a.depthChartOrder.compareTo(b.depthChartOrder);
      }
      return orderDescending ? -result : result;
    });

    // Apply limit
    if (filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered.map((entry) => entry.toJson()).toList();
  }

  /// Get unique teams
  static Future<List<String>> getTeams() async {
    await _loadDepthChartsFromCSV();
    Set<String> teams = (_cachedDepthCharts ?? []).map((e) => e.team).toSet();
    return teams.toList()..sort();
  }

  /// Get unique seasons
  static Future<List<String>> getSeasons() async {
    await _loadDepthChartsFromCSV();
    Set<String> seasons = (_cachedDepthCharts ?? []).map((e) => e.season).toSet();
    return seasons.toList()..sort();
  }

  /// Get unique positions
  static Future<List<String>> getPositions() async {
    await _loadDepthChartsFromCSV();
    Set<String> positions = (_cachedDepthCharts ?? []).map((e) => e.position).toSet();
    return positions.toList()..sort();
  }

  /// Get unique position groups
  static Future<List<String>> getPositionGroups() async {
    await _loadDepthChartsFromCSV();
    Set<String> groups = (_cachedDepthCharts ?? []).map((e) => e.positionGroup).toSet();
    return groups.toList()..sort();
  }

  /// Clear cached data
  static void clearCache() {
    _cachedDepthCharts = null;
  }

  /// Helper method to parse CSV lines (handles quoted values)
  static List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }

    result.add(current.toString().trim());
    return result;
  }
}