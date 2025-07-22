import '../../widgets/rankings/filter_panel.dart';

/// Service for filtering ranking data based on user criteria
class FilterService {
  
  /// Apply filters to a list of player rankings
  static List<Map<String, dynamic>> applyFilters(
    List<Map<String, dynamic>> players,
    FilterQuery query,
  ) {
    if (!query.hasActiveFilters) {
      return players;
    }

    return players.where((player) {
      // Player name filter
      if (query.playerNameQuery != null && query.playerNameQuery!.isNotEmpty) {
        final playerName = _getPlayerName(player).toLowerCase();
        final searchQuery = query.playerNameQuery!.toLowerCase();
        if (!playerName.contains(searchQuery)) {
          return false;
        }
      }

      // Team filter
      if (query.selectedTeams.isNotEmpty) {
        final playerTeam = _getPlayerTeam(player);
        if (!query.selectedTeams.contains(playerTeam)) {
          return false;
        }
      }

      // Tier filter
      if (query.selectedTiers.isNotEmpty) {
        final playerTier = _getPlayerTier(player);
        if (!query.selectedTiers.contains(playerTier)) {
          return false;
        }
      }

      // Season filter
      if (query.selectedSeasons.isNotEmpty) {
        final playerSeason = _getPlayerSeason(player);
        if (playerSeason != null && !query.selectedSeasons.contains(playerSeason)) {
          return false;
        }
      }

      // Stat range filters
      for (final entry in query.statFilters.entries) {
        final statKey = entry.key;
        final rangeFilter = entry.value;
        
        if (!rangeFilter.hasFilter) continue;
        
        final statValue = _getStatValue(player, statKey);
        if (statValue == null || !rangeFilter.matches(statValue)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get available teams from player list
  static List<String> getAvailableTeams(List<Map<String, dynamic>> players) {
    final teams = <String>{};
    for (final player in players) {
      final team = _getPlayerTeam(player);
      if (team.isNotEmpty) {
        teams.add(team);
      }
    }
    final teamList = teams.toList();
    teamList.sort();
    return teamList;
  }

  /// Get available seasons from player list
  static List<int> getAvailableSeasons(List<Map<String, dynamic>> players) {
    final seasons = <int>{};
    for (final player in players) {
      final season = _getPlayerSeason(player);
      if (season != null) {
        seasons.add(season);
      }
    }
    final seasonList = seasons.toList();
    seasonList.sort((a, b) => b.compareTo(a)); // Newest first
    return seasonList;
  }

  /// Get statistics that can be filtered (numeric only)
  static Map<String, Map<String, dynamic>> getFilterableStats(
    Map<String, Map<String, dynamic>> allStatFields,
  ) {
    return Map.fromEntries(
      allStatFields.entries.where((entry) {
        final format = entry.value['format'] as String?;
        return format != null && 
               format != 'string' && 
               !_isIdentifierField(entry.key);
      }),
    );
  }

  /// Get stat ranges for a field across all players
  static Map<String, double> getStatRange(
    List<Map<String, dynamic>> players,
    String statField,
  ) {
    final values = <double>[];
    
    for (final player in players) {
      final value = _getStatValue(player, statField);
      if (value != null && value.isFinite) {
        values.add(value);
      }
    }
    
    if (values.isEmpty) {
      return {'min': 0.0, 'max': 0.0};
    }
    
    values.sort();
    return {
      'min': values.first,
      'max': values.last,
    };
  }

  /// Create a filter query with commonly used filters
  static FilterQuery createQuickFilter({
    String? playerName,
    List<String>? teams,
    List<int>? tiers,
    int? season,
  }) {
    return FilterQuery(
      playerNameQuery: playerName,
      selectedTeams: teams ?? [],
      selectedTiers: tiers ?? [],
      selectedSeasons: season != null ? [season] : [],
    );
  }

  // Helper methods

  static String _getPlayerName(Map<String, dynamic> player) {
    return player['fantasy_player_name']?.toString() ?? 
           player['player_name']?.toString() ?? 
           player['receiver_player_name']?.toString() ?? 
           '';
  }

  static String _getPlayerTeam(Map<String, dynamic> player) {
    return player['posteam']?.toString() ?? 
           player['team']?.toString() ?? 
           '';
  }

  static int _getPlayerTier(Map<String, dynamic> player) {
    final tier = player['tier'] ?? player['qbTier'] ?? player['qb_tier'];
    if (tier is int) return tier;
    if (tier is String) return int.tryParse(tier) ?? 1;
    return 1;
  }

  static int? _getPlayerSeason(Map<String, dynamic> player) {
    final season = player['season'];
    if (season is int) return season;
    if (season is String) return int.tryParse(season);
    return null;
  }

  static double? _getStatValue(Map<String, dynamic> player, String statKey) {
    final value = player[statKey];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _isIdentifierField(String field) {
    const identifierFields = {
      'myRankNum',
      'rank_number',
      'player_name',
      'fantasy_player_name',
      'receiver_player_name',
      'passer_player_name',
      'posteam',
      'team',
      'tier',
      'qbTier',
      'qb_tier',
      'season',
      'player_id',
      'fantasy_player_id',
      'receiver_player_id',
      'passer_player_id',
      'position',
      'player_position',
      'id',
    };
    return identifierFields.contains(field);
  }

  /// Generate filter summary text
  static String generateFilterSummary(FilterQuery query) {
    final summaryParts = <String>[];
    
    if (query.playerNameQuery?.isNotEmpty ?? false) {
      summaryParts.add('Name: "${query.playerNameQuery}"');
    }
    
    if (query.selectedTeams.isNotEmpty) {
      if (query.selectedTeams.length == 1) {
        summaryParts.add('Team: ${query.selectedTeams.first}');
      } else {
        summaryParts.add('Teams: ${query.selectedTeams.length} selected');
      }
    }
    
    if (query.selectedTiers.isNotEmpty) {
      if (query.selectedTiers.length == 1) {
        summaryParts.add('Tier: ${query.selectedTiers.first}');
      } else {
        summaryParts.add('Tiers: ${query.selectedTiers.length} selected');
      }
    }
    
    if (query.selectedSeasons.isNotEmpty) {
      if (query.selectedSeasons.length == 1) {
        summaryParts.add('Season: ${query.selectedSeasons.first}');
      } else {
        summaryParts.add('Seasons: ${query.selectedSeasons.length} selected');
      }
    }
    
    if (query.statFilters.isNotEmpty) {
      summaryParts.add('${query.statFilters.length} stat filter(s)');
    }
    
    if (summaryParts.isEmpty) {
      return 'No filters applied';
    }
    
    return summaryParts.join(' • ');
  }
}