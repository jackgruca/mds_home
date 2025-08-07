// lib/services/csv_player_stats_service.dart

import 'package:flutter/services.dart';

class PlayerStatEntry {
  final String season;
  final String seasonType;
  final String? week;
  final String playerId;
  final String playerName;
  final String? playerDisplayName;
  final String position;
  final String? positionGroup;
  final String team;
  
  // Passing stats
  final int attempts;
  final int completions;
  final double passingYards;
  final int passingTds;
  final int interceptions;
  final int sacks;
  final double sackYards;
  final int sackFumbles;
  final int sackFumblesLost;
  final double passingAirYards;
  final double passingYardsAfterCatch;
  final int passingFirstDowns;
  final double passingEpa;
  final int passing2ptConversions;
  
  // Rushing stats
  final int carries;
  final double rushingYards;
  final int rushingTds;
  final int rushingFumbles;
  final int rushingFumblesLost;
  final int rushingFirstDowns;
  final double rushingEpa;
  final int rushing2ptConversions;
  
  // Receiving stats
  final int targets;
  final int receptions;
  final double receivingYards;
  final int receivingTds;
  final int receivingFumbles;
  final int receivingFumblesLost;
  final double receivingAirYards;
  final double receivingYardsAfterCatch;
  final int receivingFirstDowns;
  final double receivingEpa;
  final int receiving2ptConversions;
  
  // Fantasy stats
  final double fantasyPoints;
  final double fantasyPointsPpr;
  
  // Calculated stats
  final double completionPercentage;
  final double yardsPerAttempt;
  final double touchdownPercentage;
  final double interceptionPercentage;
  final double yardsPerCarry;
  final double catchPercentage;
  final double yardsPerReception;
  final double yardsPerTarget;
  final double totalYards;
  final int totalTds;

  PlayerStatEntry({
    required this.season,
    required this.seasonType,
    this.week,
    required this.playerId,
    required this.playerName,
    this.playerDisplayName,
    required this.position,
    this.positionGroup,
    required this.team,
    required this.attempts,
    required this.completions,
    required this.passingYards,
    required this.passingTds,
    required this.interceptions,
    required this.sacks,
    required this.sackYards,
    required this.sackFumbles,
    required this.sackFumblesLost,
    required this.passingAirYards,
    required this.passingYardsAfterCatch,
    required this.passingFirstDowns,
    required this.passingEpa,
    required this.passing2ptConversions,
    required this.carries,
    required this.rushingYards,
    required this.rushingTds,
    required this.rushingFumbles,
    required this.rushingFumblesLost,
    required this.rushingFirstDowns,
    required this.rushingEpa,
    required this.rushing2ptConversions,
    required this.targets,
    required this.receptions,
    required this.receivingYards,
    required this.receivingTds,
    required this.receivingFumbles,
    required this.receivingFumblesLost,
    required this.receivingAirYards,
    required this.receivingYardsAfterCatch,
    required this.receivingFirstDowns,
    required this.receivingEpa,
    required this.receiving2ptConversions,
    required this.fantasyPoints,
    required this.fantasyPointsPpr,
    required this.completionPercentage,
    required this.yardsPerAttempt,
    required this.touchdownPercentage,
    required this.interceptionPercentage,
    required this.yardsPerCarry,
    required this.catchPercentage,
    required this.yardsPerReception,
    required this.yardsPerTarget,
    required this.totalYards,
    required this.totalTds,
  });

  factory PlayerStatEntry.fromCsvRow(Map<String, String> row) {
    return PlayerStatEntry(
      season: row['season'] ?? '',
      seasonType: row['season_type'] ?? 'REG',
      week: row['week'],
      playerId: row['player_id'] ?? '',
      playerName: row['player_name'] ?? '',
      playerDisplayName: row['player_display_name'],
      position: row['position'] ?? '',
      positionGroup: row['position_group'],
      team: row['team'] ?? '',
      attempts: int.tryParse(row['attempts'] ?? '0') ?? 0,
      completions: int.tryParse(row['completions'] ?? '0') ?? 0,
      passingYards: double.tryParse(row['passing_yards'] ?? '0') ?? 0.0,
      passingTds: int.tryParse(row['passing_tds'] ?? '0') ?? 0,
      interceptions: int.tryParse(row['interceptions'] ?? '0') ?? 0,
      sacks: int.tryParse(row['sacks'] ?? '0') ?? 0,
      sackYards: double.tryParse(row['sack_yards'] ?? '0') ?? 0.0,
      sackFumbles: int.tryParse(row['sack_fumbles'] ?? '0') ?? 0,
      sackFumblesLost: int.tryParse(row['sack_fumbles_lost'] ?? '0') ?? 0,
      passingAirYards: double.tryParse(row['passing_air_yards'] ?? '0') ?? 0.0,
      passingYardsAfterCatch: double.tryParse(row['passing_yards_after_catch'] ?? '0') ?? 0.0,
      passingFirstDowns: int.tryParse(row['passing_first_downs'] ?? '0') ?? 0,
      passingEpa: double.tryParse(row['passing_epa'] ?? '0') ?? 0.0,
      passing2ptConversions: int.tryParse(row['passing_2pt_conversions'] ?? '0') ?? 0,
      carries: int.tryParse(row['carries'] ?? '0') ?? 0,
      rushingYards: double.tryParse(row['rushing_yards'] ?? '0') ?? 0.0,
      rushingTds: int.tryParse(row['rushing_tds'] ?? '0') ?? 0,
      rushingFumbles: int.tryParse(row['rushing_fumbles'] ?? '0') ?? 0,
      rushingFumblesLost: int.tryParse(row['rushing_fumbles_lost'] ?? '0') ?? 0,
      rushingFirstDowns: int.tryParse(row['rushing_first_downs'] ?? '0') ?? 0,
      rushingEpa: double.tryParse(row['rushing_epa'] ?? '0') ?? 0.0,
      rushing2ptConversions: int.tryParse(row['rushing_2pt_conversions'] ?? '0') ?? 0,
      targets: int.tryParse(row['targets'] ?? '0') ?? 0,
      receptions: int.tryParse(row['receptions'] ?? '0') ?? 0,
      receivingYards: double.tryParse(row['receiving_yards'] ?? '0') ?? 0.0,
      receivingTds: int.tryParse(row['receiving_tds'] ?? '0') ?? 0,
      receivingFumbles: int.tryParse(row['receiving_fumbles'] ?? '0') ?? 0,
      receivingFumblesLost: int.tryParse(row['receiving_fumbles_lost'] ?? '0') ?? 0,
      receivingAirYards: double.tryParse(row['receiving_air_yards'] ?? '0') ?? 0.0,
      receivingYardsAfterCatch: double.tryParse(row['receiving_yards_after_catch'] ?? '0') ?? 0.0,
      receivingFirstDowns: int.tryParse(row['receiving_first_downs'] ?? '0') ?? 0,
      receivingEpa: double.tryParse(row['receiving_epa'] ?? '0') ?? 0.0,
      receiving2ptConversions: int.tryParse(row['receiving_2pt_conversions'] ?? '0') ?? 0,
      fantasyPoints: double.tryParse(row['fantasy_points'] ?? '0') ?? 0.0,
      fantasyPointsPpr: double.tryParse(row['fantasy_points_ppr'] ?? '0') ?? 0.0,
      completionPercentage: double.tryParse(row['completion_percentage'] ?? '0') ?? 0.0,
      yardsPerAttempt: double.tryParse(row['yards_per_attempt'] ?? '0') ?? 0.0,
      touchdownPercentage: double.tryParse(row['touchdown_percentage'] ?? '0') ?? 0.0,
      interceptionPercentage: double.tryParse(row['interception_percentage'] ?? '0') ?? 0.0,
      yardsPerCarry: double.tryParse(row['yards_per_carry'] ?? '0') ?? 0.0,
      catchPercentage: double.tryParse(row['catch_percentage'] ?? '0') ?? 0.0,
      yardsPerReception: double.tryParse(row['yards_per_reception'] ?? '0') ?? 0.0,
      yardsPerTarget: double.tryParse(row['yards_per_target'] ?? '0') ?? 0.0,
      totalYards: double.tryParse(row['total_yards'] ?? '0') ?? 0.0,
      totalTds: int.tryParse(row['total_tds'] ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'season_type': seasonType,
      'week': week,
      'player_id': playerId,
      'player_name': playerName,
      'player_display_name': playerDisplayName,
      'position': position,
      'position_group': positionGroup,
      'team': team,
      'attempts': attempts,
      'completions': completions,
      'passing_yards': passingYards,
      'passing_tds': passingTds,
      'interceptions': interceptions,
      'sacks': sacks,
      'sack_yards': sackYards,
      'sack_fumbles': sackFumbles,
      'sack_fumbles_lost': sackFumblesLost,
      'passing_air_yards': passingAirYards,
      'passing_yards_after_catch': passingYardsAfterCatch,
      'passing_first_downs': passingFirstDowns,
      'passing_epa': passingEpa,
      'passing_2pt_conversions': passing2ptConversions,
      'carries': carries,
      'rushing_yards': rushingYards,
      'rushing_tds': rushingTds,
      'rushing_fumbles': rushingFumbles,
      'rushing_fumbles_lost': rushingFumblesLost,
      'rushing_first_downs': rushingFirstDowns,
      'rushing_epa': rushingEpa,
      'rushing_2pt_conversions': rushing2ptConversions,
      'targets': targets,
      'receptions': receptions,
      'receiving_yards': receivingYards,
      'receiving_tds': receivingTds,
      'receiving_fumbles': receivingFumbles,
      'receiving_fumbles_lost': receivingFumblesLost,
      'receiving_air_yards': receivingAirYards,
      'receiving_yards_after_catch': receivingYardsAfterCatch,
      'receiving_first_downs': receivingFirstDowns,
      'receiving_epa': receivingEpa,
      'receiving_2pt_conversions': receiving2ptConversions,
      'fantasy_points': fantasyPoints,
      'fantasy_points_ppr': fantasyPointsPpr,
      'completion_percentage': completionPercentage,
      'yards_per_attempt': yardsPerAttempt,
      'touchdown_percentage': touchdownPercentage,
      'interception_percentage': interceptionPercentage,
      'yards_per_carry': yardsPerCarry,
      'catch_percentage': catchPercentage,
      'yards_per_reception': yardsPerReception,
      'yards_per_target': yardsPerTarget,
      'total_yards': totalYards,
      'total_tds': totalTds,
    };
  }
}

class CsvPlayerStatsService {
  static List<PlayerStatEntry>? _cachedPlayerStats;
  static const String _csvAssetPath = 'assets/nfl_player_stats.csv';

  /// Load player stats from CSV
  static Future<void> _loadPlayerStatsFromCSV() async {
    if (_cachedPlayerStats != null) {
      print('DEBUG: Using cached player stats data (${_cachedPlayerStats!.length} entries)');
      return;
    }

    print('DEBUG: Loading player stats from $_csvAssetPath');
    try {
      final csvData = await rootBundle.loadString(_csvAssetPath);
      print('DEBUG: CSV data loaded, size: ${csvData.length} characters');
      
      _cachedPlayerStats = await _parsePlayerStatsData(csvData);
      print('DEBUG: Parsed ${_cachedPlayerStats!.length} player stat entries');
      
      if (_cachedPlayerStats!.isNotEmpty) {
        final firstEntry = _cachedPlayerStats!.first;
        print('DEBUG: First entry: ${firstEntry.playerName} - ${firstEntry.team} - ${firstEntry.position}');
      }
    } catch (e) {
      print('ERROR: Error loading player stats CSV: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      _cachedPlayerStats = [];
    }
  }

  /// Parse CSV data into PlayerStatEntry objects
  static Future<List<PlayerStatEntry>> _parsePlayerStatsData(String csvData) async {
    List<PlayerStatEntry> entries = [];
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
        if (values.length >= headers.length - 5) { // Allow some missing columns
          Map<String, String> row = {};
          for (String header in headers) {
            int? index = columnIndices[header];
            if (index != null && index < values.length) {
              row[header] = values[index];
            }
          }
          entries.add(PlayerStatEntry.fromCsvRow(row));
        }
      } catch (e) {
        continue; // Skip invalid rows
      }
    }

    return entries;
  }

  /// Get player stats with filters
  static Future<List<Map<String, dynamic>>> getPlayerStats({
    String? season,
    String? team,
    String? position,
    String? playerName,
    String? week,
    int limit = 100,
    String orderBy = 'fantasy_points',
    bool orderDescending = true,
  }) async {
    print('DEBUG: getPlayerStats called with season=$season, team=$team, position=$position, playerName=$playerName');
    
    await _loadPlayerStatsFromCSV();

    List<PlayerStatEntry> filtered = _cachedPlayerStats ?? [];
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

    if (playerName != null && playerName.isNotEmpty) {
      final originalCount = filtered.length;
      String searchTerm = playerName.toLowerCase();
      filtered = filtered.where((entry) => 
        entry.playerName.toLowerCase().contains(searchTerm) ||
        (entry.playerDisplayName?.toLowerCase().contains(searchTerm) ?? false)
      ).toList();
      print('DEBUG: After player name filter ($playerName): ${filtered.length} entries (was $originalCount)');
    }

    if (week != null && week != 'All') {
      final originalCount = filtered.length;
      filtered = filtered.where((entry) => entry.week == week).toList();
      print('DEBUG: After week filter ($week): ${filtered.length} entries (was $originalCount)');
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (orderBy) {
        case 'player_name':
          result = a.playerName.compareTo(b.playerName);
          break;
        case 'fantasy_points':
          result = a.fantasyPoints.compareTo(b.fantasyPoints);
          break;
        case 'fantasy_points_ppr':
          result = a.fantasyPointsPpr.compareTo(b.fantasyPointsPpr);
          break;
        case 'passing_yards':
          result = a.passingYards.compareTo(b.passingYards);
          break;
        case 'rushing_yards':
          result = a.rushingYards.compareTo(b.rushingYards);
          break;
        case 'receiving_yards':
          result = a.receivingYards.compareTo(b.receivingYards);
          break;
        case 'total_yards':
          result = a.totalYards.compareTo(b.totalYards);
          break;
        case 'total_tds':
          result = a.totalTds.compareTo(b.totalTds);
          break;
        default:
          result = a.fantasyPoints.compareTo(b.fantasyPoints);
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
    await _loadPlayerStatsFromCSV();
    Set<String> teams = (_cachedPlayerStats ?? []).map((e) => e.team).toSet();
    return teams.toList()..sort();
  }

  /// Get unique seasons
  static Future<List<String>> getSeasons() async {
    await _loadPlayerStatsFromCSV();
    Set<String> seasons = (_cachedPlayerStats ?? []).map((e) => e.season).toSet();
    return seasons.toList()..sort();
  }

  /// Get unique positions
  static Future<List<String>> getPositions() async {
    await _loadPlayerStatsFromCSV();
    Set<String> positions = (_cachedPlayerStats ?? []).map((e) => e.position).toSet();
    return positions.toList()..sort();
  }

  /// Get unique weeks
  static Future<List<String>> getWeeks() async {
    await _loadPlayerStatsFromCSV();
    Set<String> weeks = (_cachedPlayerStats ?? [])
        .where((e) => e.week != null)
        .map((e) => e.week!)
        .toSet();
    return weeks.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  }

  /// Clear cached data
  static void clearCache() {
    _cachedPlayerStats = null;
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