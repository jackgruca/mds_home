import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// Unified service for all player game-level statistics
/// Consolidates position-specific stats into a single queryable interface
class UnifiedGameStatsService {
  static final UnifiedGameStatsService _instance = UnifiedGameStatsService._internal();
  factory UnifiedGameStatsService() => _instance;
  UnifiedGameStatsService._internal();

  // Core data structures
  final List<PlayerGameStats> _allGameStats = [];
  final Map<String, List<PlayerGameStats>> _statsByPlayer = {};
  final Map<String, List<PlayerGameStats>> _statsByGame = {};
  final Map<String, PlayerGameStats> _statsByPlayerGame = {};
  
  bool _isLoaded = false;

  /// Initialize service and load all game data
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    // Load each position file
    await _loadPositionStats('quarterback_game_stats.csv', 'QB');
    await _loadPositionStats('runningback_game_stats.csv', 'RB');
    await _loadPositionStats('widereceiver_game_stats.csv', 'WR');
    await _loadPositionStats('tightend_game_stats.csv', 'TE');
    
    _isLoaded = true;
    print('Loaded ${_allGameStats.length} total game stats records');
  }

  /// Load position-specific CSV file
  Future<void> _loadPositionStats(String filename, String position) async {
    try {
      final csvString = await rootBundle.loadString('assets/data/$filename');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) return;
      
      final headers = csvTable[0].map((e) => e.toString()).toList();
      
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        final stats = PlayerGameStats.fromCsvRow(headers, row, position);
        
        if (stats.playerId.isNotEmpty && stats.gameId.isNotEmpty) {
          _allGameStats.add(stats);
          
          // Index by player
          _statsByPlayer.putIfAbsent(stats.playerId, () => []).add(stats);
          
          // Index by game
          _statsByGame.putIfAbsent(stats.gameId, () => []).add(stats);
          
          // Index by player-game combo
          _statsByPlayerGame['${stats.playerId}_${stats.gameId}'] = stats;
        }
      }
    } catch (e) {
      print('Error loading $filename: $e');
    }
  }

  /// Get all games for a specific player
  Future<List<PlayerGameStats>> getPlayerGameLog(
    String playerId, {
    int? season,
    int? startWeek,
    int? endWeek,
    bool includePlayoffs = true,
    bool sortDescending = true,
  }) async {
    await initialize();
    
    var games = _statsByPlayer[playerId] ?? [];
    
    // Apply filters
    games = games.where((game) {
      if (season != null && game.season != season) return false;
      if (startWeek != null && game.week < startWeek) return false;
      if (endWeek != null && game.week > endWeek) return false;
      if (!includePlayoffs && game.week > 18) return false; // Assuming week > 18 is playoffs
      return true;
    }).toList();
    
    // Sort by week (most recent first by default)
    games.sort((a, b) => sortDescending 
      ? b.week.compareTo(a.week) 
      : a.week.compareTo(b.week));
    
    return games;
  }

  /// Get season aggregation for a player
  Future<SeasonStats> getPlayerSeasonStats(
    String playerId,
    int season, {
    bool includePlayoffs = true,
  }) async {
    final games = await getPlayerGameLog(
      playerId,
      season: season,
      includePlayoffs: includePlayoffs,
    );
    
    return SeasonStats.fromGames(playerId, season, games);
  }

  /// Get all players who played in a specific game
  Future<List<PlayerGameStats>> getGameRoster(String gameId) async {
    await initialize();
    return _statsByGame[gameId] ?? [];
  }

  /// Get career stats for a player
  Future<CareerStats> getPlayerCareerStats(String playerId) async {
    await initialize();
    final allGames = _statsByPlayer[playerId] ?? [];
    return CareerStats.fromGames(playerId, allGames);
  }

  /// Search for games by criteria
  Future<List<PlayerGameStats>> searchGames({
    String? team,
    String? opponent,
    int? minPassingYards,
    int? minRushingYards,
    int? minReceivingYards,
  }) async {
    await initialize();
    
    return _allGameStats.where((game) {
      if (team != null && game.team != team) return false;
      if (opponent != null && game.opponent != opponent) return false;
      if (minPassingYards != null && game.passingYards < minPassingYards) return false;
      if (minRushingYards != null && game.rushingYards < minRushingYards) return false;
      if (minReceivingYards != null && game.receivingYards < minReceivingYards) return false;
      return true;
    }).toList();
  }
}

/// Individual game statistics for a player
class PlayerGameStats {
  final String playerId;
  final String playerName;
  final String position;
  final String gameId;
  final int season;
  final int week;
  final String team;
  final String opponent;
  final bool isHome;
  
  // Passing stats
  final int passingAttempts;
  final int completions;
  final int passingYards;
  final int passingTds;
  final int interceptions;
  
  // Rushing stats
  final int rushingAttempts;
  final int rushingYards;
  final int rushingTds;
  
  // Receiving stats
  final int targets;
  final int receptions;
  final int receivingYards;
  final int receivingTds;
  
  // Fantasy
  final double fantasyPointsPpr;
  final double fantasyPointsStandard;

  PlayerGameStats({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.gameId,
    required this.season,
    required this.week,
    required this.team,
    required this.opponent,
    required this.isHome,
    this.passingAttempts = 0,
    this.completions = 0,
    this.passingYards = 0,
    this.passingTds = 0,
    this.interceptions = 0,
    this.rushingAttempts = 0,
    this.rushingYards = 0,
    this.rushingTds = 0,
    this.targets = 0,
    this.receptions = 0,
    this.receivingYards = 0,
    this.receivingTds = 0,
    this.fantasyPointsPpr = 0.0,
    this.fantasyPointsStandard = 0.0,
  });

  factory PlayerGameStats.fromCsvRow(
    List<String> headers, 
    List<dynamic> row,
    String position,
  ) {
    final data = Map<String, dynamic>.fromIterables(headers, row);
    
    return PlayerGameStats(
      playerId: data['passer_player_id'] ?? data['rusher_player_id'] ?? 
                data['receiver_player_id'] ?? data['player_id'] ?? '',
      playerName: data['player_name'] ?? '',
      position: position,
      gameId: data['game_id'] ?? '',
      season: _parseInt(data['season']),
      week: _parseInt(data['week']),
      team: data['team'] ?? '',
      opponent: _extractOpponent(data['game_id'] ?? '', data['team'] ?? ''),
      isHome: _isHomeGame(data['game_id'] ?? '', data['team'] ?? ''),
      // Position-specific stats
      passingAttempts: _parseInt(data['pass_attempts']),
      completions: _parseInt(data['completions']),
      passingYards: _parseInt(data['passing_yards']),
      passingTds: _parseInt(data['passing_tds']),
      interceptions: _parseInt(data['interceptions']),
      rushingAttempts: _parseInt(data['rushing_attempts'] ?? data['carries']),
      rushingYards: _parseInt(data['rushing_yards']),
      rushingTds: _parseInt(data['rushing_tds']),
      targets: _parseInt(data['targets']),
      receptions: _parseInt(data['receptions']),
      receivingYards: _parseInt(data['receiving_yards']),
      receivingTds: _parseInt(data['receiving_tds']),
      fantasyPointsPpr: _parseDouble(data['fantasy_points_ppr']),
      fantasyPointsStandard: _parseDouble(data['fantasy_points']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _extractOpponent(String gameId, String team) {
    // gameId format: 2023_01_ARI_WAS
    final parts = gameId.split('_');
    if (parts.length >= 4) {
      return parts[2] == team ? parts[3] : parts[2];
    }
    return '';
  }

  static bool _isHomeGame(String gameId, String team) {
    // gameId format: 2023_01_ARI_WAS (home team is second)
    final parts = gameId.split('_');
    if (parts.length >= 4) {
      return parts[3] == team;
    }
    return false;
  }
}

/// Season aggregation of game stats
class SeasonStats {
  final String playerId;
  final int season;
  final int gamesPlayed;
  final Map<String, dynamic> totals;
  final Map<String, double> averages;

  SeasonStats({
    required this.playerId,
    required this.season,
    required this.gamesPlayed,
    required this.totals,
    required this.averages,
  });

  factory SeasonStats.fromGames(String playerId, int season, List<PlayerGameStats> games) {
    final totals = <String, dynamic>{};
    final averages = <String, double>{};
    
    // Calculate totals
    for (final game in games) {
      totals['passingYards'] = (totals['passingYards'] ?? 0) + game.passingYards;
      totals['passingTds'] = (totals['passingTds'] ?? 0) + game.passingTds;
      totals['rushingYards'] = (totals['rushingYards'] ?? 0) + game.rushingYards;
      totals['rushingTds'] = (totals['rushingTds'] ?? 0) + game.rushingTds;
      totals['receivingYards'] = (totals['receivingYards'] ?? 0) + game.receivingYards;
      totals['receivingTds'] = (totals['receivingTds'] ?? 0) + game.receivingTds;
      totals['receptions'] = (totals['receptions'] ?? 0) + game.receptions;
      totals['fantasyPointsPpr'] = (totals['fantasyPointsPpr'] ?? 0.0) + game.fantasyPointsPpr;
    }
    
    // Calculate averages
    if (games.isNotEmpty) {
      totals.forEach((key, value) {
        averages[key] = value / games.length;
      });
    }
    
    return SeasonStats(
      playerId: playerId,
      season: season,
      gamesPlayed: games.length,
      totals: totals,
      averages: averages,
    );
  }
}

/// Career aggregation of game stats
class CareerStats {
  final String playerId;
  final int seasonsPlayed;
  final int totalGames;
  final Map<String, dynamic> careerTotals;
  final Map<int, SeasonStats> seasonBreakdown;

  CareerStats({
    required this.playerId,
    required this.seasonsPlayed,
    required this.totalGames,
    required this.careerTotals,
    required this.seasonBreakdown,
  });

  factory CareerStats.fromGames(String playerId, List<PlayerGameStats> games) {
    final seasonGroups = <int, List<PlayerGameStats>>{};
    final careerTotals = <String, dynamic>{};
    
    // Group by season
    for (final game in games) {
      seasonGroups.putIfAbsent(game.season, () => []).add(game);
    }
    
    // Create season stats
    final seasonBreakdown = <int, SeasonStats>{};
    seasonGroups.forEach((season, seasonGames) {
      seasonBreakdown[season] = SeasonStats.fromGames(playerId, season, seasonGames);
    });
    
    // Calculate career totals
    for (final game in games) {
      careerTotals['passingYards'] = (careerTotals['passingYards'] ?? 0) + game.passingYards;
      careerTotals['passingTds'] = (careerTotals['passingTds'] ?? 0) + game.passingTds;
      careerTotals['rushingYards'] = (careerTotals['rushingYards'] ?? 0) + game.rushingYards;
      careerTotals['rushingTds'] = (careerTotals['rushingTds'] ?? 0) + game.rushingTds;
      careerTotals['receivingYards'] = (careerTotals['receivingYards'] ?? 0) + game.receivingYards;
      careerTotals['receivingTds'] = (careerTotals['receivingTds'] ?? 0) + game.receivingTds;
    }
    
    return CareerStats(
      playerId: playerId,
      seasonsPlayed: seasonGroups.length,
      totalGames: games.length,
      careerTotals: careerTotals,
      seasonBreakdown: seasonBreakdown,
    );
  }
}