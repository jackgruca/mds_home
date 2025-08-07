import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/player_info.dart';
import '../models/player_career_stats.dart';
import '../models/player_game_log.dart';
import '../models/player_weekly_epa.dart';
import '../models/player_season_epa_summary.dart';
import '../models/player_weekly_ngs.dart';

class PlayerDataService {
  static final PlayerDataService _instance = PlayerDataService._internal();
  factory PlayerDataService() => _instance;
  PlayerDataService._internal();

  List<PlayerInfo>? _cachedPlayers;
  Map<String, List<PlayerInfo>>? _playersByTeam;
  Map<String, PlayerInfo>? _playersById;
  
  List<PlayerCareerStats>? _cachedCareerStats;
  Map<String, List<PlayerCareerStats>>? _careerStatsByPlayer;
  
  List<PlayerGameLog>? _cachedGameLogs;
  Map<String, List<PlayerGameLog>>? _gameLogsByPlayer;
  
  List<PlayerWeeklyEpa>? _cachedWeeklyEpa;
  Map<String, List<PlayerWeeklyEpa>>? _weeklyEpaByPlayer;
  
  List<PlayerSeasonEpaSummary>? _cachedSeasonEpaSummary;
  Map<String, List<PlayerSeasonEpaSummary>>? _seasonEpaSummaryByPlayer;
  
  List<PlayerWeeklyNgs>? _cachedWeeklyNgs;
  Map<String, List<PlayerWeeklyNgs>>? _weeklyNgsByPlayer;

  Future<void> loadPlayerData() async {
    if (_cachedPlayers != null) {
      print('Player data already cached: ${_cachedPlayers!.length} players');
      return;
    }

    // Try paths in order of preference
    final pathsToTry = [
      'data_processing/assets/data/current_players_combined.csv',
      'current_players_combined.csv',  // Fallback
    ];

    for (String path in pathsToTry) {
      try {
        print('🔍 Trying to load CSV from: $path');
        
        // Load CSV file from assets
        final csvString = await rootBundle.loadString(path);
        print('✅ CSV loaded successfully from $path, length: ${csvString.length} characters');
        
        // Debug: show first 200 characters
        print('🔍 First 200 chars: ${csvString.substring(0, csvString.length > 200 ? 200 : csvString.length)}');
        
        // Debug: count line breaks
        final lines = csvString.split('\n');
        print('🔍 Line breaks found: ${lines.length - 1}');
        print('🔍 First 3 lines:');
        for (int i = 0; i < 3 && i < lines.length; i++) {
          print('   Line $i: ${lines[i].length} chars - ${lines[i].substring(0, lines[i].length > 50 ? 50 : lines[i].length)}...');
        }
        
        // Parse CSV with explicit configuration
        final List<List<dynamic>> csvTable = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
        ).convert(csvString);
        print('✅ CSV parsed successfully, ${csvTable.length} rows found');
        
        if (csvTable.isNotEmpty) {
          print('📋 CSV header (first 5 columns): ${csvTable[0].take(5).toList()}');
        }
        
        // Skip header row and convert to PlayerInfo objects
        _cachedPlayers = [];
        int successCount = 0;
        int errorCount = 0;
        
        for (int i = 1; i < csvTable.length; i++) {
          try {
            final player = PlayerInfo.fromCsvRow(csvTable[i]);
            _cachedPlayers!.add(player);
            successCount++;
            
            // Log first player for verification
            if (i == 1) {
              print('📊 First player parsed: ${player.fullName} (${player.team}, ${player.position})');
            }
          } catch (e) {
            print('❌ Error parsing row $i: $e');
            if (errorCount < 3) { // Only show first 3 errors to avoid spam
              print('   Row data: ${csvTable[i].take(10).toList()}...');
            }
            errorCount++;
          }
        }

        // Create indexes for fast lookups
        _buildIndexes();
        
        print('🎉 Successfully loaded $successCount players ($errorCount errors) from $path');
        
        if (_cachedPlayers!.isNotEmpty) {
          print('👤 Sample players:');
          for (int i = 0; i < 3 && i < _cachedPlayers!.length; i++) {
            final p = _cachedPlayers![i];
            print('   ${i+1}. ${p.fullName} (${p.team}, ${p.position}) - ${p.fantasyPpg} PPG');
          }
        }
        
        // Success! Break out of the loop
        return;
        
      } catch (e) {
        print('❌ Failed to load from $path: $e');
        continue;
      }
    }
    
    // If we get here, all paths failed
    print('💥 CRITICAL: All CSV loading attempts failed!');
    print('📁 Available paths in pubspec.yaml should include our CSV files');
    _cachedPlayers = [];
  }

  void _buildIndexes() {
    if (_cachedPlayers == null) return;

    // Group by team
    _playersByTeam = {};
    _playersById = {};
    
    for (final player in _cachedPlayers!) {
      // By team
      _playersByTeam!.putIfAbsent(player.team, () => []).add(player);
      
      // By ID
      _playersById![player.playerId] = player;
    }

    // Sort players within each team by position group and fantasy points
    _playersByTeam!.forEach((team, players) {
      players.sort((a, b) {
        // First sort by position group priority
        final positionOrder = ['QB', 'RB', 'WR', 'TE'];
        final aIndex = positionOrder.indexOf(a.positionGroup);
        final bIndex = positionOrder.indexOf(b.positionGroup);
        
        if (aIndex != bIndex) {
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        }
        
        // Then by fantasy points
        return b.fantasyPointsPpr.compareTo(a.fantasyPointsPpr);
      });
    });
  }

  List<PlayerInfo> getAllPlayers() {
    return _cachedPlayers ?? [];
  }

  List<PlayerInfo> getPlayersByTeam(String team) {
    return _playersByTeam?[team] ?? [];
  }

  PlayerInfo? getPlayerById(String playerId) {
    return _playersById?[playerId];
  }

  List<String> getAllTeams() {
    if (_playersByTeam == null) return [];
    final teams = _playersByTeam!.keys.toList();
    teams.sort();
    return teams;
  }

  List<PlayerInfo> searchPlayers(String query) {
    if (_cachedPlayers == null || query.isEmpty) return [];
    
    return _cachedPlayers!
        .where((player) => player.matchesSearch(query))
        .toList();
  }

  List<PlayerInfo> getPlayersByPosition(String position) {
    if (_cachedPlayers == null) return [];
    
    return _cachedPlayers!
        .where((player) => player.position == position || player.positionGroup == position)
        .toList()
      ..sort((a, b) => b.fantasyPointsPpr.compareTo(a.fantasyPointsPpr));
  }

  // Get top players by fantasy points
  List<PlayerInfo> getTopPlayers({int limit = 50, String? position}) {
    if (_cachedPlayers == null) return [];
    
    var players = _cachedPlayers!;
    
    if (position != null) {
      players = players
          .where((p) => p.position == position || p.positionGroup == position)
          .toList();
    }
    
    players.sort((a, b) => b.fantasyPointsPpr.compareTo(a.fantasyPointsPpr));
    
    return players.take(limit).toList();
  }

  // Career Stats Methods
  Future<void> loadCareerStats() async {
    if (_cachedCareerStats != null) return;

    try {
      print('🏈 Loading career stats data...');
      final csvString = await rootBundle.loadString('data_processing/assets/data/player_career_stats.csv');
      
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(csvString);

      _cachedCareerStats = [];
      _careerStatsByPlayer = {};
      
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final stats = PlayerCareerStats.fromCsvRow(csvTable[i]);
          _cachedCareerStats!.add(stats);
          
          _careerStatsByPlayer!.putIfAbsent(stats.playerId, () => []).add(stats);
        } catch (e) {
          print('Error parsing career stats row $i: $e');
        }
      }

      // Sort career stats by season
      _careerStatsByPlayer!.forEach((playerId, stats) {
        stats.sort((a, b) => b.season.compareTo(a.season));
      });

      print('✅ Loaded ${_cachedCareerStats!.length} career stat records');
      
    } catch (e) {
      print('❌ Error loading career stats: $e');
      _cachedCareerStats = [];
      _careerStatsByPlayer = {};
    }
  }

  List<PlayerCareerStats> getPlayerCareerStats(String playerId) {
    return _careerStatsByPlayer?[playerId] ?? [];
  }

  // Game Logs Methods
  Future<void> loadGameLogs() async {
    if (_cachedGameLogs != null) return;

    try {
      print('🏈 Loading game logs data...');
      final csvString = await rootBundle.loadString('data_processing/assets/data/player_game_logs.csv');
      
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(csvString);

      _cachedGameLogs = [];
      _gameLogsByPlayer = {};
      
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final gameLog = PlayerGameLog.fromCsvRow(csvTable[i]);
          _cachedGameLogs!.add(gameLog);
          
          _gameLogsByPlayer!.putIfAbsent(gameLog.playerId, () => []).add(gameLog);
        } catch (e) {
          print('Error parsing game log row $i: $e');
        }
      }

      // Sort game logs by week
      _gameLogsByPlayer!.forEach((playerId, logs) {
        logs.sort((a, b) => a.week.compareTo(b.week));
      });

      print('✅ Loaded ${_cachedGameLogs!.length} game log records');
      
    } catch (e) {
      print('❌ Error loading game logs: $e');
      _cachedGameLogs = [];
      _gameLogsByPlayer = {};
    }
  }

  List<PlayerGameLog> getPlayerGameLogs(String playerId) {
    return _gameLogsByPlayer?[playerId] ?? [];
  }

  // Weekly EPA Methods
  Future<void> loadWeeklyEpaStats() async {
    if (_cachedWeeklyEpa != null) return;

    try {
      print('📊 Loading weekly EPA data...');
      final csvString = await rootBundle.loadString('data_processing/assets/data/player_weekly_epa.csv');
      
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(csvString);

      _cachedWeeklyEpa = [];
      _weeklyEpaByPlayer = {};
      
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final weeklyEpa = PlayerWeeklyEpa.fromCsvRow(csvTable[i]);
          _cachedWeeklyEpa!.add(weeklyEpa);
          
          _weeklyEpaByPlayer!.putIfAbsent(weeklyEpa.playerId, () => []).add(weeklyEpa);
        } catch (e) {
          print('Error parsing weekly EPA row $i: $e');
        }
      }

      // Sort weekly EPA by season/week
      _weeklyEpaByPlayer!.forEach((playerId, stats) {
        stats.sort((a, b) {
          if (a.season != b.season) return b.season.compareTo(a.season);
          return a.week.compareTo(b.week);
        });
      });

      print('✅ Loaded ${_cachedWeeklyEpa!.length} weekly EPA records');
      
    } catch (e) {
      print('❌ Error loading weekly EPA: $e');
      _cachedWeeklyEpa = [];
      _weeklyEpaByPlayer = {};
    }
  }

  Future<void> loadSeasonEpaSummary() async {
    if (_cachedSeasonEpaSummary != null) return;

    try {
      print('📊 Loading season EPA summary...');
      final csvString = await rootBundle.loadString('data_processing/assets/data/player_season_epa_summary.csv');
      
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(csvString);

      _cachedSeasonEpaSummary = [];
      _seasonEpaSummaryByPlayer = {};
      
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final seasonSummary = PlayerSeasonEpaSummary.fromCsvRow(csvTable[i]);
          _cachedSeasonEpaSummary!.add(seasonSummary);
          
          _seasonEpaSummaryByPlayer!.putIfAbsent(seasonSummary.playerId, () => []).add(seasonSummary);
        } catch (e) {
          print('Error parsing season EPA summary row $i: $e');
        }
      }

      // Sort by season (most recent first)
      _seasonEpaSummaryByPlayer!.forEach((playerId, summaries) {
        summaries.sort((a, b) => b.season.compareTo(a.season));
      });

      print('✅ Loaded ${_cachedSeasonEpaSummary!.length} season EPA summaries');
      
    } catch (e) {
      print('❌ Error loading season EPA summary: $e');
      _cachedSeasonEpaSummary = [];
      _seasonEpaSummaryByPlayer = {};
    }
  }

  List<PlayerWeeklyEpa> getPlayerWeeklyEpa(String playerId) {
    return _weeklyEpaByPlayer?[playerId] ?? [];
  }

  List<PlayerSeasonEpaSummary> getPlayerSeasonEpaSummary(String playerId) {
    return _seasonEpaSummaryByPlayer?[playerId] ?? [];
  }

  // Get weekly EPA for a specific season
  List<PlayerWeeklyEpa> getPlayerWeeklyEpaForSeason(String playerId, int season) {
    final allWeekly = getPlayerWeeklyEpa(playerId);
    return allWeekly.where((epa) => epa.season == season).toList()
      ..sort((a, b) => a.week.compareTo(b.week));
  }

  // Weekly NGS Methods
  Future<void> loadWeeklyNgsStats() async {
    if (_cachedWeeklyNgs != null) return;

    try {
      print('📊 Loading weekly NGS data...');
      
      // Load existing rushing/receiving NGS data
      final csvString = await rootBundle.loadString('data_processing/assets/data/player_weekly_ngs.csv');
      
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(csvString);

      _cachedWeeklyNgs = [];
      _weeklyNgsByPlayer = {};
      
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final weeklyNgs = PlayerWeeklyNgs.fromCsvRow(csvTable[i]);
          _cachedWeeklyNgs!.add(weeklyNgs);
          
          _weeklyNgsByPlayer!.putIfAbsent(weeklyNgs.playerId, () => []).add(weeklyNgs);
        } catch (e) {
          print('Error parsing weekly NGS row $i: $e');
        }
      }

      // Load new passing NGS data
      try {
        print('📊 Loading weekly passing NGS data...');
        final passingCsvString = await rootBundle.loadString('data_processing/assets/data/player_weekly_passing_ngs.csv');
        
        final List<List<dynamic>> passingCsvTable = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
        ).convert(passingCsvString);

        for (int i = 1; i < passingCsvTable.length; i++) {
          try {
            final passingNgs = PlayerWeeklyNgs.fromPassingCsvRow(passingCsvTable[i]);
            _cachedWeeklyNgs!.add(passingNgs);
            
            _weeklyNgsByPlayer!.putIfAbsent(passingNgs.playerId, () => []).add(passingNgs);
          } catch (e) {
            print('Error parsing weekly passing NGS row $i: $e');
          }
        }
        print('✅ Loaded ${passingCsvTable.length - 1} passing NGS records');
      } catch (e) {
        print('⚠️ Could not load passing NGS data: $e');
      }

      // Sort weekly NGS by season/week
      _weeklyNgsByPlayer!.forEach((playerId, stats) {
        stats.sort((a, b) {
          if (a.season != b.season) return b.season.compareTo(a.season);
          return a.week.compareTo(b.week);
        });
      });

      print('✅ Loaded ${_cachedWeeklyNgs!.length} total weekly NGS records');
      
    } catch (e) {
      print('❌ Error loading weekly NGS: $e');
      _cachedWeeklyNgs = [];
      _weeklyNgsByPlayer = {};
    }
  }

  List<PlayerWeeklyNgs> getPlayerWeeklyNgs(String playerId) {
    return _weeklyNgsByPlayer?[playerId] ?? [];
  }

  // Get weekly NGS for a specific season
  List<PlayerWeeklyNgs> getPlayerWeeklyNgsForSeason(String playerId, int season) {
    final allWeekly = getPlayerWeeklyNgs(playerId);
    return allWeekly.where((ngs) => ngs.season == season).toList()
      ..sort((a, b) => a.week.compareTo(b.week));
  }
}