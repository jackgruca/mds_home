import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// Service for loading and managing game-level player statistics
class GameLevelDataService {
  static final GameLevelDataService _instance = GameLevelDataService._internal();
  factory GameLevelDataService() => _instance;
  GameLevelDataService._internal();

  // Cache for loaded data
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  
  /// Load game-level player stats from CSV
  Future<List<Map<String, dynamic>>> loadGameLevelStats() async {
    const cacheKey = 'player_game_stats_2024';
    
    if (_dataCache.containsKey(cacheKey)) {
      return _dataCache[cacheKey]!;
    }
    
    try {
      final csvString = await rootBundle.loadString('assets/data/player_game_stats_2024.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) {
        throw Exception('Game level CSV file is empty');
      }
      
      final headers = csvTable[0].map((e) => e.toString()).toList();
      final List<Map<String, dynamic>> data = [];
      
      for (int i = 1; i < csvTable.length; i++) {
        final Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length && j < csvTable[i].length; j++) {
          final value = csvTable[i][j];
          if (value is String && value.trim().isNotEmpty && value.trim() != 'NA') {
            final numValue = num.tryParse(value);
            row[headers[j]] = numValue ?? value.trim();
          } else {
            row[headers[j]] = null;
          }
        }
        
        // Only add rows with valid player_id
        if (row['player_id'] != null && row['player_id'].toString().trim().isNotEmpty) {
          data.add(row);
        }
      }
      
      _dataCache[cacheKey] = data;
      return data;
    } catch (e) {
      throw Exception('Failed to load game level stats: $e');
    }
  }

  /// Get game logs for a specific player
  Future<List<Map<String, dynamic>>> getPlayerGameLogs(String playerId) async {
    final allData = await loadGameLevelStats();
    
    print('Getting game logs for player_id: $playerId');
    print('Total game records: ${allData.length}');
    
    final playerGames = allData
        .where((game) => game['player_id'] == playerId)
        .toList();
        
    print('Found ${playerGames.length} games for player $playerId');
    
    if (playerGames.isEmpty) {
      // Debug: Find similar player IDs
      final similarIds = allData
          .where((game) => game['player_id'].toString().contains(playerId.substring(playerId.length > 5 ? 5 : 0)))
          .map((game) => '${game['player_id']}: ${game['player_name']}')
          .toSet()
          .take(3)
          .toList();
      print('Similar player IDs found: $similarIds');
    }
    
    return playerGames
      ..sort((a, b) {
        final weekA = a['week'] as num? ?? 0;
        final weekB = b['week'] as num? ?? 0;
        return weekA.compareTo(weekB);
      });
  }

  /// Get aggregated season stats for a player from game-level data
  Future<Map<String, dynamic>?> getPlayerSeasonStats(String playerId) async {
    final gameLogs = await getPlayerGameLogs(playerId);
    
    if (gameLogs.isEmpty) return null;
    
    // Aggregate stats across all games
    final aggregated = <String, dynamic>{};
    
    // Initialize counters
    num totalPassAttempts = 0;
    num totalCompletions = 0;
    num totalPassingYards = 0;
    num totalPassingTds = 0;
    num totalInterceptions = 0;
    num totalRushAttempts = 0;
    num totalRushingYards = 0;
    num totalRushingTds = 0;
    num totalTargets = 0;
    num totalReceptions = 0;
    num totalReceivingYards = 0;
    num totalReceivingTds = 0;
    num totalFantasyPoints = 0;
    int gamesPlayed = 0;
    
    // Get player info from first game
    final firstGame = gameLogs.first;
    aggregated['player_id'] = firstGame['player_id'];
    aggregated['player_name'] = firstGame['player_name'];
    aggregated['position'] = firstGame['position'];
    aggregated['team'] = firstGame['team'];
    aggregated['season'] = firstGame['season'];
    
    // Aggregate across games
    for (final game in gameLogs) {
      gamesPlayed++;
      
      // Passing stats
      totalPassAttempts += (game['pass_attempts'] as num?) ?? 0;
      totalCompletions += (game['completions'] as num?) ?? 0;
      totalPassingYards += (game['passing_yards'] as num?) ?? 0;
      totalPassingTds += (game['passing_tds'] as num?) ?? 0;
      totalInterceptions += (game['interceptions'] as num?) ?? 0;
      
      // Rushing stats
      totalRushAttempts += (game['rush_attempts'] as num?) ?? 0;
      totalRushingYards += (game['rushing_yards'] as num?) ?? 0;
      totalRushingTds += (game['rushing_tds'] as num?) ?? 0;
      
      // Receiving stats
      totalTargets += (game['targets'] as num?) ?? 0;
      totalReceptions += (game['receptions'] as num?) ?? 0;
      totalReceivingYards += (game['receiving_yards'] as num?) ?? 0;
      totalReceivingTds += (game['receiving_tds'] as num?) ?? 0;
      
      // Fantasy points
      totalFantasyPoints += (game['fantasy_points_ppr'] as num?) ?? 0;
    }
    
    // Calculate aggregated stats
    aggregated['games'] = gamesPlayed;
    aggregated['pass_attempts'] = totalPassAttempts;
    aggregated['completions'] = totalCompletions;
    aggregated['passing_yards'] = totalPassingYards;
    aggregated['passing_tds'] = totalPassingTds;
    aggregated['interceptions'] = totalInterceptions;
    aggregated['completion_pct'] = totalPassAttempts > 0 ? totalCompletions / totalPassAttempts : 0;
    aggregated['yards_per_attempt'] = totalPassAttempts > 0 ? totalPassingYards / totalPassAttempts : 0;
    
    aggregated['rush_attempts'] = totalRushAttempts;
    aggregated['rushing_yards'] = totalRushingYards;
    aggregated['rushing_tds'] = totalRushingTds;
    aggregated['yards_per_carry'] = totalRushAttempts > 0 ? totalRushingYards / totalRushAttempts : 0;
    
    aggregated['targets'] = totalTargets;
    aggregated['receptions'] = totalReceptions;
    aggregated['receiving_yards'] = totalReceivingYards;
    aggregated['receiving_tds'] = totalReceivingTds;
    aggregated['catch_rate'] = totalTargets > 0 ? totalReceptions / totalTargets : 0;
    aggregated['yards_per_reception'] = totalReceptions > 0 ? totalReceivingYards / totalReceptions : 0;
    
    aggregated['fantasy_points_ppr'] = totalFantasyPoints;
    aggregated['fantasy_points_per_game'] = gamesPlayed > 0 ? totalFantasyPoints / gamesPlayed : 0;
    
    return aggregated;
  }

  /// Get game details for a specific game
  Future<Map<String, dynamic>?> getGameDetails(String gameId) async {
    final allData = await loadGameLevelStats();
    
    final gameData = allData.where((game) => game['game_id'] == gameId).toList();
    
    if (gameData.isEmpty) return null;
    
    // Get game context from first row
    final firstRow = gameData.first;
    
    return {
      'game_id': gameId,
      'season': firstRow['season'],
      'week': firstRow['week'],
      'game_date': firstRow['game_date'],
      'home_team': firstRow['home_team'],
      'away_team': firstRow['away_team'],
      'home_score': firstRow['home_score'],
      'away_score': firstRow['away_score'],
      'temp': firstRow['temp'],
      'wind': firstRow['wind'],
      'roof': firstRow['roof'],
      'surface': firstRow['surface'],
      'spread_line': firstRow['spread_line'],
      'total_line': firstRow['total_line'],
      'div_game': firstRow['div_game'],
      'overtime': firstRow['overtime'],
      'players': gameData,
    };
  }

  /// Get all unique games from the dataset
  Future<List<Map<String, dynamic>>> getAllGames() async {
    final allData = await loadGameLevelStats();
    
    final gameMap = <String, Map<String, dynamic>>{};
    
    for (final row in allData) {
      final gameId = row['game_id'] as String?;
      if (gameId != null && !gameMap.containsKey(gameId)) {
        gameMap[gameId] = {
          'game_id': gameId,
          'season': row['season'],
          'week': row['week'],
          'game_date': row['game_date'],
          'home_team': row['home_team'],
          'away_team': row['away_team'],
          'home_score': row['home_score'],
          'away_score': row['away_score'],
        };
      }
    }
    
    final games = gameMap.values.toList();
    games.sort((a, b) {
      final weekA = a['week'] as num? ?? 0;
      final weekB = b['week'] as num? ?? 0;
      return weekA.compareTo(weekB);
    });
    
    return games;
  }

  /// Search players by name
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final allData = await loadGameLevelStats();
    final queryLower = query.toLowerCase();
    
    final playerMap = <String, Map<String, dynamic>>{};
    
    for (final row in allData) {
      final playerId = row['player_id'] as String?;
      final playerName = row['player_name'] as String? ?? '';
      
      if (playerId != null && 
          playerName.toLowerCase().contains(queryLower) &&
          !playerMap.containsKey(playerId)) {
        playerMap[playerId] = {
          'player_id': playerId,
          'player_name': playerName,
          'position': row['position'],
          'team': row['team'],
        };
      }
    }
    
    return playerMap.values.toList();
  }

  /// Get players by position
  Future<List<Map<String, dynamic>>> getPlayersByPosition(String position) async {
    final allData = await loadGameLevelStats();
    
    final playerMap = <String, Map<String, dynamic>>{};
    
    for (final row in allData) {
      final playerId = row['player_id'] as String?;
      final playerPosition = row['position'] as String? ?? '';
      
      if (playerId != null && 
          playerPosition == position &&
          !playerMap.containsKey(playerId)) {
        playerMap[playerId] = {
          'player_id': playerId,
          'player_name': row['player_name'],
          'position': row['position'],
          'team': row['team'],
        };
      }
    }
    
    return playerMap.values.toList();
  }

  /// Clear cache
  void clearCache() {
    _dataCache.clear();
  }
}