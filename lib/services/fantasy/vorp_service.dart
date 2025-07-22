import 'historical_points_service.dart';

class VORPPlayer {
  final String playerId;
  final String playerName;
  final String position;
  final String team;
  final int rank;
  final double projectedPoints;
  final double replacementPoints;
  final double vorp;
  final int? tier;
  final Map<String, dynamic> additionalData;

  VORPPlayer({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.rank,
    required this.projectedPoints,
    required this.replacementPoints,
    required this.vorp,
    this.tier,
    this.additionalData = const {},
  });

  factory VORPPlayer.fromPlayerData(
    Map<String, dynamic> playerData,
    double projectedPoints,
    double replacementPoints,
  ) {
    final vorp = projectedPoints - replacementPoints;
    
    return VORPPlayer(
      playerId: playerData['player_id'] ?? playerData['fantasy_player_id'] ?? '',
      playerName: playerData['fantasy_player_name'] ?? 
                  playerData['player_name'] ?? 
                  playerData['passer_player_name'] ?? 
                  playerData['receiver_player_name'] ?? 
                  'Unknown',
      position: (playerData['position'] ?? '').toString().toLowerCase(),
      team: playerData['posteam'] ?? playerData['team'] ?? '',
      rank: playerData['myRankNum'] ?? playerData['rank'] ?? 0,
      projectedPoints: projectedPoints,
      replacementPoints: replacementPoints,
      vorp: vorp,
      tier: playerData['tier'] ?? playerData['qbTier'] ?? playerData['rbTier'],
      additionalData: Map<String, dynamic>.from(playerData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'team': team,
      'rank': rank,
      'projectedPoints': projectedPoints,
      'replacementPoints': replacementPoints,
      'vorp': vorp,
      'tier': tier,
      ...additionalData,
    };
  }
}

class VORPBoard {
  final List<VORPPlayer> players;
  final Map<String, int> leagueSettings;
  final String scoringSystem;
  final DateTime generatedAt;

  VORPBoard({
    required this.players,
    required this.leagueSettings,
    required this.scoringSystem,
    required this.generatedAt,
  });

  /// Get players sorted by VORP (highest first)
  List<VORPPlayer> get sortedByVORP {
    final sorted = List<VORPPlayer>.from(players);
    sorted.sort((a, b) => b.vorp.compareTo(a.vorp));
    return sorted;
  }

  /// Get players by position
  List<VORPPlayer> getPlayersByPosition(String position) {
    return players.where((p) => p.position.toLowerCase() == position.toLowerCase()).toList();
  }

  /// Get top N players by VORP
  List<VORPPlayer> getTopPlayersByVORP(int count) {
    return sortedByVORP.take(count).toList();
  }

  /// Get replacement level players for each position
  Map<String, VORPPlayer?> getReplacementLevelPlayers() {
    final result = <String, VORPPlayer?>{};
    
    for (final position in ['qb', 'rb', 'wr', 'te']) {
      final positionPlayers = getPlayersByPosition(position);
      if (positionPlayers.isNotEmpty) {
        final replacementRank = HistoricalPointsService.getReplacementRank(position, leagueSettings);
        final replacementPlayer = positionPlayers
            .where((p) => p.rank == replacementRank)
            .firstOrNull;
        result[position] = replacementPlayer;
      }
    }
    
    return result;
  }
}

class VORPService {
  /// Calculate VORP for a list of players
  /// 
  /// [players] - List of player data maps from rankings
  /// [leagueSettings] - League configuration (teams, roster spots, etc.)
  /// [scoringSystem] - Fantasy scoring system ('ppr', 'standard', 'half_ppr')
  /// 
  /// Returns a VORPBoard with calculated VORP values for all players
  static VORPBoard calculateVORP(
    List<Map<String, dynamic>> players,
    {Map<String, int>? leagueSettings,
    String scoringSystem = 'ppr'}
  ) {
    final settings = leagueSettings ?? HistoricalPointsService.getDefaultLeagueSettings();
    final vorpPlayers = <VORPPlayer>[];

    // Calculate replacement level points for each position
    final replacementPoints = <String, double>{};
    for (final position in ['qb', 'rb', 'wr', 'te']) {
      replacementPoints[position] = HistoricalPointsService.getReplacementLevelPoints(
        position, 
        settings, 
        scoringSystem: scoringSystem
      );
    }

    // Convert each player's rank to projected points and calculate VORP
    for (final playerData in players) {
      final position = (playerData['position'] ?? '').toString().toLowerCase();
      final rank = playerData['myRankNum'] ?? playerData['rank'];

      if (position.isNotEmpty && rank != null && replacementPoints.containsKey(position)) {
        try {
          final projectedPoints = HistoricalPointsService.rankToPoints(
            position, 
            rank, 
            scoringSystem: scoringSystem
          );

          final vorpPlayer = VORPPlayer.fromPlayerData(
            playerData,
            projectedPoints,
            replacementPoints[position]!,
          );

          vorpPlayers.add(vorpPlayer);
        } catch (e) {
          // Skip players with invalid data
          continue;
        }
      }
    }

    return VORPBoard(
      players: vorpPlayers,
      leagueSettings: settings,
      scoringSystem: scoringSystem,
      generatedAt: DateTime.now(),
    );
  }

  /// Calculate VORP using custom weights for consensus rankings
  /// 
  /// [players] - List of player data with consensus rankings
  /// [customWeights] - Map of platform weights for consensus calculation
  /// [leagueSettings] - League configuration
  /// [scoringSystem] - Fantasy scoring system
  static VORPBoard calculateVORPWithCustomWeights(
    List<Map<String, dynamic>> players,
    Map<String, double> customWeights,
    {Map<String, int>? leagueSettings,
    String scoringSystem = 'ppr'}
  ) {
    // Apply custom weights to calculate consensus rankings
    final weightedPlayers = _applyCustomWeights(players, customWeights);
    
    return calculateVORP(
      weightedPlayers,
      leagueSettings: leagueSettings,
      scoringSystem: scoringSystem,
    );
  }

  /// Apply custom weights to player rankings to create weighted consensus
  static List<Map<String, dynamic>> _applyCustomWeights(
    List<Map<String, dynamic>> players,
    Map<String, double> weights,
  ) {
    final weightedPlayers = <Map<String, dynamic>>[];

    for (final player in players) {
      final playerCopy = Map<String, dynamic>.from(player);
      double weightedSum = 0.0;
      double totalWeight = 0.0;

      // Calculate weighted average of platform rankings
      for (final entry in weights.entries) {
        final platform = entry.key;
        final weight = entry.value;
        final rankKey = _getPlatformRankKey(platform);
        
        if (player.containsKey(rankKey) && player[rankKey] != null) {
          final rank = player[rankKey] as num;
          weightedSum += rank * weight;
          totalWeight += weight;
        }
      }

      if (totalWeight > 0) {
        final consensusRank = (weightedSum / totalWeight).round();
        playerCopy['myRankNum'] = consensusRank;
        playerCopy['CustomConsensusRank'] = consensusRank;
      }

      weightedPlayers.add(playerCopy);
    }

    // Re-sort by consensus rank
    weightedPlayers.sort((a, b) {
      final aRank = a['myRankNum'] ?? a['rank'] ?? 999;
      final bRank = b['myRankNum'] ?? b['rank'] ?? 999;
      return aRank.compareTo(bRank);
    });

    return weightedPlayers;
  }

  /// Get the ranking field key for a platform
  static String _getPlatformRankKey(String platform) {
    switch (platform.toLowerCase()) {
      case 'pff':
        return 'pffRank';
      case 'cbs':
        return 'cbsRank';
      case 'espn':
        return 'espnRank';
      case 'fftoday':
        return 'fftodayRank';
      case 'footballguys':
        return 'footballguysRank';
      case 'yahoo':
        return 'yahooRank';
      case 'nfl':
        return 'nflRank';
      default:
        return '${platform}Rank';
    }
  }

  /// Get VORP tiers for better visualization
  /// 
  /// Tiers based on VORP values:
  /// - Elite: VORP > 80
  /// - High: VORP 50-80
  /// - Solid: VORP 20-50
  /// - Decent: VORP 5-20
  /// - Replacement: VORP 0-5
  /// - Below Replacement: VORP < 0
  static String getVORPTier(double vorp) {
    if (vorp > 80) return 'Elite';
    if (vorp > 50) return 'High';
    if (vorp > 20) return 'Solid';
    if (vorp > 5) return 'Decent';
    if (vorp > 0) return 'Replacement';
    return 'Below Replacement';
  }

  /// Get color for VORP tier visualization
  static int getVORPTierColor(String tier) {
    switch (tier) {
      case 'Elite':
        return 0xFF4CAF50; // Green
      case 'High':
        return 0xFF8BC34A; // Light Green
      case 'Solid':
        return 0xFF2196F3; // Blue
      case 'Decent':
        return 0xFFFF9800; // Orange
      case 'Replacement':
        return 0xFF9E9E9E; // Grey
      case 'Below Replacement':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Default Grey
    }
  }

  /// Export VORP board to CSV-like structure
  static List<Map<String, dynamic>> exportVORPBoard(VORPBoard board) {
    return board.sortedByVORP.map((player) => {
      'Rank': board.sortedByVORP.indexOf(player) + 1,
      'Player': player.playerName,
      'Position': player.position.toUpperCase(),
      'Team': player.team,
      'Position Rank': player.rank,
      'Projected Points': player.projectedPoints.toStringAsFixed(1),
      'Replacement Points': player.replacementPoints.toStringAsFixed(1),
      'VORP': player.vorp.toStringAsFixed(1),
      'VORP Tier': getVORPTier(player.vorp),
      'Tier': player.tier ?? '',
    }).toList();
  }
}