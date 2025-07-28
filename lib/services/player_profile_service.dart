import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'game_level_data_service.dart';

/// Service for loading and managing player profile data
class PlayerProfileService {
  static final PlayerProfileService _instance = PlayerProfileService._internal();
  factory PlayerProfileService() => _instance;
  PlayerProfileService._internal();

  final GameLevelDataService _gameDataService = GameLevelDataService();
  
  // Cache for loaded data
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  
  /// Load player profiles from CSV
  Future<List<Map<String, dynamic>>> loadPlayerProfiles() async {
    const cacheKey = 'player_profiles';
    
    if (_dataCache.containsKey(cacheKey)) {
      return _dataCache[cacheKey]!;
    }
    
    try {
      final csvString = await rootBundle.loadString('assets/data/player_profiles.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) {
        throw Exception('Player profiles CSV file is empty');
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
      throw Exception('Failed to load player profiles: $e');
    }
  }

  /// Get complete player profile with stats
  Future<Map<String, dynamic>?> getPlayerProfile(String playerId) async {
    final profiles = await loadPlayerProfiles();
    
    // Debug: Print search info
    print('Looking for player_id: $playerId');
    print('Total profiles loaded: ${profiles.length}');
    
    // Find player profile
    final profile = profiles.where((p) => p['player_id'] == playerId).firstOrNull;
    
    if (profile == null) {
      print('No profile found for player_id: $playerId');
      // Try partial match for debugging
      final partialMatches = profiles.where((p) => 
        p['player_id'].toString().contains(playerId) ||
        p['player_name'].toString().toLowerCase().contains(playerId.toLowerCase())
      ).take(3).toList();
      print('Partial matches found: ${partialMatches.length}');
      for (final match in partialMatches) {
        print('  - ${match['player_id']}: ${match['player_name']}');
      }
    } else {
      print('Found profile: ${profile['player_name']}');
    }
    
    if (profile == null) return null;
    
    // Get season stats and game logs
    final seasonStats = await _gameDataService.getPlayerSeasonStats(playerId);
    final gameLogs = await _gameDataService.getPlayerGameLogs(playerId);
    
    return {
      // Profile information
      'player_id': profile['player_id'],
      'player_name': profile['player_name'],
      'position': profile['position'],
      'team': profile['team'],
      'height': profile['height'],
      'weight': profile['weight'],
      'years_exp': profile['years_exp'],
      'rookie_year': profile['rookie_year'],
      'birth_date': profile['birth_date'],
      'college': profile['college'],
      
      // Stats
      'season_stats': seasonStats,
      'game_logs': gameLogs,
      'games_played': gameLogs.length,
    };
  }

  /// Get basic player info (for hyperlinks and quick access)
  Future<Map<String, dynamic>?> getPlayerBasicInfo(String playerId) async {
    final profiles = await loadPlayerProfiles();
    
    final profile = profiles.where((p) => p['player_id'] == playerId).firstOrNull;
    
    if (profile == null) return null;
    
    return {
      'player_id': profile['player_id'],
      'player_name': profile['player_name'],
      'position': profile['position'],
      'team': profile['team'],
    };
  }

  /// Search players by name across profiles
  Future<List<Map<String, dynamic>>> searchPlayerProfiles(String query) async {
    if (query.trim().isEmpty) return [];
    
    final profiles = await loadPlayerProfiles();
    final queryLower = query.toLowerCase();
    
    return profiles
        .where((profile) {
          final name = (profile['player_name'] as String? ?? '').toLowerCase();
          return name.contains(queryLower);
        })
        .take(20) // Limit results
        .toList();
  }

  /// Get all players by position
  Future<List<Map<String, dynamic>>> getPlayersByPosition(String position) async {
    final profiles = await loadPlayerProfiles();
    
    return profiles
        .where((profile) => profile['position'] == position)
        .toList()
      ..sort((a, b) => (a['player_name'] as String? ?? '')
          .compareTo(b['player_name'] as String? ?? ''));
  }

  /// Get all players by team
  Future<List<Map<String, dynamic>>> getPlayersByTeam(String team) async {
    final profiles = await loadPlayerProfiles();
    
    return profiles
        .where((profile) => profile['team'] == team)
        .toList()
      ..sort((a, b) => (a['player_name'] as String? ?? '')
          .compareTo(b['player_name'] as String? ?? ''));
  }

  /// Get player career statistics (multi-season when available)
  Future<Map<String, dynamic>?> getPlayerCareerStats(String playerId) async {
    // For now, return current season stats
    // This can be expanded when historical data is added
    final seasonStats = await _gameDataService.getPlayerSeasonStats(playerId);
    
    if (seasonStats == null) return null;
    
    return {
      'seasons': [seasonStats], // Array for future multi-season expansion
      'career_totals': seasonStats, // For now, same as current season
    };
  }

  /// Get similar players based on position and performance
  Future<List<Map<String, dynamic>>> getSimilarPlayers(String playerId, {int limit = 5}) async {
    final playerProfile = await getPlayerProfile(playerId);
    
    if (playerProfile == null) return [];
    
    final position = playerProfile['position'] as String?;
    final seasonStats = playerProfile['season_stats'] as Map<String, dynamic>?;
    
    if (position == null || seasonStats == null) return [];
    
    // Get all players at same position
    final samePositionPlayers = await getPlayersByPosition(position);
    
    // For simplicity, return random players from same position
    // In a more sophisticated implementation, this would use statistical similarity
    samePositionPlayers.removeWhere((p) => p['player_id'] == playerId);
    samePositionPlayers.shuffle();
    
    return samePositionPlayers.take(limit).toList();
  }

  /// Generate player URL slug for routing
  String generatePlayerSlug(String playerName) {
    return playerName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  /// Parse player ID from URL parameters
  String? parsePlayerIdFromUrl(String url) {
    // Expected format: /player/[player_id]/[player_name]
    final parts = url.split('/');
    if (parts.length >= 3 && parts[1] == 'player') {
      return parts[2];
    }
    return null;
  }

  /// Get all available teams
  Future<List<String>> getAllTeams() async {
    final profiles = await loadPlayerProfiles();
    
    final teams = profiles
        .map((p) => p['team'] as String?)
        .where((team) => team != null && team.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    
    teams.sort();
    return teams;
  }

  /// Get all available positions
  Future<List<String>> getAllPositions() async {
    final profiles = await loadPlayerProfiles();
    
    final positions = profiles
        .map((p) => p['position'] as String?)
        .where((pos) => pos != null && pos.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    
    positions.sort();
    return positions;
  }

  /// Clear cache
  void clearCache() {
    _dataCache.clear();
  }
}