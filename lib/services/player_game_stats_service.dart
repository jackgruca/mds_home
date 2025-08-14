import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/player_game_log.dart';
import '../models/player_weekly_epa.dart';
import '../models/player_weekly_ngs.dart';

// Composite model combining all data sources
class PlayerGameStats {
  final PlayerGameLog gameLog;
  final PlayerWeeklyEpa? epaData;
  final PlayerWeeklyNgs? ngsData;
  
  PlayerGameStats({
    required this.gameLog,
    this.epaData,
    this.ngsData,
  });
  
  // Basic info from game log
  String get playerId => gameLog.playerId;
  String get playerName => gameLog.playerDisplayName.isNotEmpty 
      ? gameLog.playerDisplayName 
      : gameLog.playerName;
  String get position => gameLog.position;
  String get positionGroup => gameLog.positionGroup;
  String get team => gameLog.team;
  String get opponent => gameLog.opponentTeam;
  int get season => gameLog.season;
  int get week => gameLog.week;
  
  // Passing stats
  int get completions => gameLog.completions;
  int get attempts => gameLog.attempts;
  int get passingYards => gameLog.passingYards;
  int get passingTds => gameLog.passingTds;
  int get interceptions => gameLog.interceptions;
  int? get sacks => epaData?.sacks;
  
  // Rushing stats
  int get carries => gameLog.carries;
  int get rushingYards => gameLog.rushingYards;
  int get rushingTds => gameLog.rushingTds;
  
  // Receiving stats
  int get targets => gameLog.targets;
  int get receptions => gameLog.receptions;
  int get receivingYards => gameLog.receivingYards;
  int get receivingTds => gameLog.receivingTds;
  
  // Fantasy
  double get fantasyPointsPpr => gameLog.fantasyPointsPpr;
  double get fantasyPoints => fantasyPointsPpr - (receptions * 1.0); // Standard scoring
  
  // EPA metrics
  double? get passingEpa => epaData?.passingEpaPerPlay;
  double? get rushingEpa => epaData?.rushingEpaPerPlay;
  double? get receivingEpa => epaData?.receivingEpaPerPlay;
  double? get totalEpa => epaData?.epaPerPlay;
  
  // NGS Passing metrics
  double? get avgTimeToThrow => ngsData?.avgTimeToThrow;
  double? get avgCompletedAirYards => ngsData?.avgCompletedAirYards;
  double? get cpoe => ngsData?.completionPercentageAboveExpectation;
  double? get aggressiveness => ngsData?.aggressiveness;
  
  // NGS Rushing metrics
  double? get rushEfficiency => ngsData?.efficiency;
  double? get rushYardsOverExpected => ngsData?.rushYardsOverExpected;
  double? get avgTimeToLos => ngsData?.avgTimeToLos;
  
  // NGS Receiving metrics
  double? get avgSeparation => ngsData?.avgSeparation;
  double? get avgCushion => ngsData?.avgCushion;
  double? get avgYacAboveExpectation => ngsData?.avgYacAboveExpectation;
  double? get catchPercentage => ngsData?.catchPercentage;
  
  // Calculated metrics
  double get completionPercentage => attempts > 0 ? (completions / attempts) * 100 : 0.0;
  double get yardsPerAttempt => attempts > 0 ? passingYards / attempts : 0.0;
  double get yardsPerCarry => carries > 0 ? rushingYards / carries : 0.0;
  double get yardsPerReception => receptions > 0 ? receivingYards / receptions : 0.0;
  double get catchRate => targets > 0 ? (receptions / targets) * 100 : 0.0;
  int get totalYards => passingYards + rushingYards + receivingYards;
  int get totalTds => passingTds + rushingTds + receivingTds;
  int get touches => carries + receptions;
  double get yardsPerTouch => touches > 0 ? (rushingYards + receivingYards) / touches : 0.0;
  
  // Convert to Map for table display
  Map<String, dynamic> toMap() {
    return {
      // Basic info
      'player_id': playerId,
      'player_name': playerName,
      'position': position,
      'position_group': positionGroup,
      'team': team,
      'opponent': opponent,
      'season': season,
      'week': week,
      
      // Passing
      'completions': completions,
      'attempts': attempts,
      'passing_yards': passingYards,
      'passing_tds': passingTds,
      'interceptions': interceptions,
      'sacks': sacks ?? 0,
      'completion_percentage': completionPercentage,
      'yards_per_attempt': yardsPerAttempt,
      
      // Rushing
      'carries': carries,
      'rushing_yards': rushingYards,
      'rushing_tds': rushingTds,
      'yards_per_carry': yardsPerCarry,
      
      // Receiving
      'targets': targets,
      'receptions': receptions,
      'receiving_yards': receivingYards,
      'receiving_tds': receivingTds,
      'yards_per_reception': yardsPerReception,
      'catch_rate': catchRate,
      
      // Fantasy
      'fantasy_points': fantasyPoints,
      'fantasy_points_ppr': fantasyPointsPpr,
      
      // Totals
      'total_yards': totalYards,
      'total_tds': totalTds,
      'touches': touches,
      'yards_per_touch': yardsPerTouch,
      
      // EPA
      'passing_epa': passingEpa ?? 0.0,
      'rushing_epa': rushingEpa ?? 0.0,
      'receiving_epa': receivingEpa ?? 0.0,
      'total_epa': totalEpa ?? 0.0,
      
      // NGS Passing
      'avg_time_to_throw': avgTimeToThrow ?? 0.0,
      'avg_completed_air_yards': avgCompletedAirYards ?? 0.0,
      'cpoe': cpoe ?? 0.0,
      'aggressiveness': aggressiveness ?? 0.0,
      
      // NGS Rushing
      'rush_efficiency': rushEfficiency ?? 0.0,
      'rush_yards_over_expected': rushYardsOverExpected ?? 0.0,
      'avg_time_to_los': avgTimeToLos ?? 0.0,
      
      // NGS Receiving
      'avg_separation': avgSeparation ?? 0.0,
      'avg_cushion': avgCushion ?? 0.0,
      'avg_yac_above_expectation': avgYacAboveExpectation ?? 0.0,
      'catch_percentage': catchPercentage ?? 0.0,
    };
  }
}

class PlayerGameStatsService {
  static final PlayerGameStatsService _instance = PlayerGameStatsService._internal();
  factory PlayerGameStatsService() => _instance;
  PlayerGameStatsService._internal();
  
  // Cache for loaded data
  List<PlayerGameLog>? _gameLogsCache;
  List<PlayerWeeklyEpa>? _epaDataCache;
  List<PlayerWeeklyNgs>? _ngsDataCache;
  List<PlayerWeeklyNgs>? _ngsPassingCache;
  
  // Load all data sources
  Future<void> loadData() async {
    await Future.wait([
      _loadGameLogs(),
      _loadEpaData(),
      _loadNgsData(),
      _loadNgsPassingData(),
    ]);
  }
  
  Future<void> _loadGameLogs() async {
    if (_gameLogsCache != null) return;
    
    try {
      print('Attempting to load game logs CSV...');
      final String csvString = await rootBundle.loadString('data_processing/assets/data/player_game_logs.csv');
      print('CSV string loaded, length: ${csvString.length}');
      
      // Split into lines and manually parse due to inconsistent quoting
      final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print('Split into ${lines.length} lines');
      
      if (lines.isEmpty) {
        print('No lines found in CSV!');
        _gameLogsCache = [];
        return;
      }
      
      // All lines have quotes - use simple quote removal and split
      List<List<dynamic>> csvData = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Remove quotes and split by comma
          final cleanedLine = line.replaceAll('"', '');
          final fields = cleanedLine.split(',').map((f) => f.trim()).toList();
          
          // Validate we have the expected number of fields (24 for player_game_logs)
          if (fields.length < 24) {
            print('Line $i has only ${fields.length} fields, skipping: ${fields.take(5).join(", ")}...');
            continue;
          }
          
          csvData.add(fields);
        } catch (e) {
          print('Error parsing line $i: $line - $e');
          continue; // Skip malformed lines
        }
      }
      
      print('CSV parsed, rows: ${csvData.length}');
      
      if (csvData.isEmpty) {
        print('CSV data is empty!');
        _gameLogsCache = [];
        return;
      }
      
      // Print first row to check structure
      if (csvData.isNotEmpty) {
        print('CSV header: ${csvData.first}');
      }
      
      // Skip header row and convert to PlayerGameLog objects
      _gameLogsCache = csvData.skip(1).map((row) {
        try {
          return PlayerGameLog.fromCsvRow(row);
        } catch (e) {
          print('Error parsing row: $row, error: $e');
          rethrow;
        }
      }).toList();
      
      print('Loaded ${_gameLogsCache!.length} game logs');
      if (_gameLogsCache!.isNotEmpty) {
        print('Sample player: ${_gameLogsCache!.first.playerName}');
      }
    } catch (e) {
      print('Error loading game logs: $e');
      print('Stack trace: ${StackTrace.current}');
      _gameLogsCache = [];
    }
  }
  
  Future<void> _loadEpaData() async {
    if (_epaDataCache != null) return;
    
    try {
      final String csvString = await rootBundle.loadString('data_processing/assets/data/player_weekly_epa.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) return;
      
      _epaDataCache = csvData.skip(1).map((row) {
        return PlayerWeeklyEpa.fromCsvRow(row);
      }).toList();
    } catch (e) {
      print('Error loading EPA data: $e');
      _epaDataCache = [];
    }
  }
  
  Future<void> _loadNgsData() async {
    if (_ngsDataCache != null) return;
    
    try {
      final String csvString = await rootBundle.loadString('data_processing/assets/data/player_weekly_ngs.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) return;
      
      _ngsDataCache = csvData.skip(1).map((row) {
        return PlayerWeeklyNgs.fromCsvRow(row);
      }).toList();
    } catch (e) {
      print('Error loading NGS data: $e');
      _ngsDataCache = [];
    }
  }
  
  Future<void> _loadNgsPassingData() async {
    if (_ngsPassingCache != null) return;
    
    try {
      final String csvString = await rootBundle.loadString('data_processing/assets/data/player_weekly_passing_ngs.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) return;
      
      _ngsPassingCache = csvData.skip(1).map((row) {
        return PlayerWeeklyNgs.fromPassingCsvRow(row);
      }).toList();
    } catch (e) {
      print('Error loading NGS passing data: $e');
      _ngsPassingCache = [];
    }
  }
  
  // Get combined player game stats with filters
  Future<List<PlayerGameStats>> getPlayerGameStats({
    String? season,
    String? week,
    String? position,
    String? team,
    String? playerName,
  }) async {
    // Ensure data is loaded
    await loadData();
    
    // Start with game logs as the base
    List<PlayerGameLog> filteredLogs = _gameLogsCache ?? [];
    
    // Apply filters
    if (season != null && season != 'All') {
      filteredLogs = filteredLogs.where((log) => log.season.toString() == season).toList();
    }
    
    if (week != null && week != 'All') {
      filteredLogs = filteredLogs.where((log) => log.week.toString() == week).toList();
    }
    
    if (position != null && position != 'All') {
      if (position == 'WR' || position == 'TE') {
        // Handle WR/TE combo
        filteredLogs = filteredLogs.where((log) => 
          log.positionGroup == 'WR' || log.positionGroup == 'TE'
        ).toList();
      } else {
        filteredLogs = filteredLogs.where((log) => log.positionGroup == position).toList();
      }
    }
    
    if (team != null && team != 'All') {
      filteredLogs = filteredLogs.where((log) => log.team == team).toList();
    }
    
    if (playerName != null && playerName.isNotEmpty) {
      final searchTerm = playerName.toLowerCase();
      filteredLogs = filteredLogs.where((log) => 
        log.playerName.toLowerCase().contains(searchTerm) ||
        log.playerDisplayName.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    // Combine with EPA and NGS data
    List<PlayerGameStats> combinedStats = [];
    
    for (var gameLog in filteredLogs) {
      // Find matching EPA data
      PlayerWeeklyEpa? epaData;
      if (_epaDataCache != null) {
        try {
          epaData = _epaDataCache!.firstWhere(
            (epa) => epa.playerId == gameLog.playerId && 
                     epa.season == gameLog.season && 
                     epa.week == gameLog.week,
          );
        } catch (e) {
          // Try matching by name if ID doesn't match
          try {
            epaData = _epaDataCache!.firstWhere(
              (epa) => epa.playerName == gameLog.playerName && 
                       epa.season == gameLog.season && 
                       epa.week == gameLog.week,
            );
          } catch (e) {
            epaData = null;
          }
        }
      }
      
      // Find matching NGS data (check both regular and passing)
      PlayerWeeklyNgs? ngsData;
      if (_ngsDataCache != null) {
        try {
          ngsData = _ngsDataCache!.firstWhere(
            (ngs) => ngs.playerId == gameLog.playerId && 
                     ngs.season == gameLog.season && 
                     ngs.week == gameLog.week,
          );
        } catch (e) {
          ngsData = null;
        }
      }
      
      // Check passing NGS if not found and player is QB
      if (ngsData == null && gameLog.positionGroup == 'QB' && _ngsPassingCache != null) {
        try {
          ngsData = _ngsPassingCache!.firstWhere(
            (ngs) => ngs.playerId == gameLog.playerId && 
                     ngs.season == gameLog.season && 
                     ngs.week == gameLog.week,
          );
        } catch (e) {
          ngsData = null;
        }
      }
      
      combinedStats.add(PlayerGameStats(
        gameLog: gameLog,
        epaData: epaData,
        ngsData: ngsData,
      ));
    }
    
    return combinedStats;
  }
  
  // Get available seasons
  Future<List<String>> getAvailableSeasons() async {
    await loadData();
    final seasons = (_gameLogsCache ?? [])
        .map((log) => log.season.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
    return seasons; // Don't add 'All' here - let the screen handle it
  }
  
  // Get available weeks
  Future<List<String>> getAvailableWeeks() async {
    await loadData();
    final weeks = (_gameLogsCache ?? [])
        .map((log) => log.week.toString())
        .toSet()
        .toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return weeks; // Don't add 'All' here - let the screen handle it
  }
  
  // Clear cache
  void clearCache() {
    _gameLogsCache = null;
    _epaDataCache = null;
    _ngsDataCache = null;
    _ngsPassingCache = null;
  }
}