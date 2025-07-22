import '../../services/fantasy/vorp_service.dart';

class VORPBigBoardPlayer {
  final String playerId;
  final String playerName;
  final String position;
  final String team;
  final int positionRank;
  final int overallRank;
  final double projectedPoints;
  final double replacementPoints;
  final double vorp;
  final String vorpTier;
  final int vorpTierColor;
  final int? tier;
  final Map<String, dynamic> originalRankings;

  VORPBigBoardPlayer({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.positionRank,
    required this.overallRank,
    required this.projectedPoints,
    required this.replacementPoints,
    required this.vorp,
    required this.vorpTier,
    required this.vorpTierColor,
    this.tier,
    required this.originalRankings,
  });

  factory VORPBigBoardPlayer.fromVORPPlayer(VORPPlayer vorpPlayer, int overallRank) {
    final vorpTier = VORPService.getVORPTier(vorpPlayer.vorp);
    
    return VORPBigBoardPlayer(
      playerId: vorpPlayer.playerId,
      playerName: vorpPlayer.playerName,
      position: vorpPlayer.position,
      team: vorpPlayer.team,
      positionRank: vorpPlayer.rank,
      overallRank: overallRank,
      projectedPoints: vorpPlayer.projectedPoints,
      replacementPoints: vorpPlayer.replacementPoints,
      vorp: vorpPlayer.vorp,
      vorpTier: vorpTier,
      vorpTierColor: VORPService.getVORPTierColor(vorpTier),
      tier: vorpPlayer.tier,
      originalRankings: vorpPlayer.additionalData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'team': team,
      'positionRank': positionRank,
      'overallRank': overallRank,
      'projectedPoints': projectedPoints,
      'replacementPoints': replacementPoints,
      'vorp': vorp,
      'vorpTier': vorpTier,
      'vorpTierColor': vorpTierColor,
      'tier': tier,
      ...originalRankings,
    };
  }

  /// Get display name for the position rank
  String get positionRankDisplay => '${position.toUpperCase()}$positionRank';

  /// Get formatted VORP string
  String get vorpDisplay => vorp >= 0 ? '+${vorp.toStringAsFixed(1)}' : vorp.toStringAsFixed(1);

  /// Get formatted projected points
  String get projectedPointsDisplay => projectedPoints.toStringAsFixed(1);

  /// Check if player is above replacement level
  bool get isAboveReplacement => vorp > 0;

  /// Get position priority for draft strategy
  int get positionPriority {
    switch (position.toLowerCase()) {
      case 'qb':
        return 4;
      case 'rb':
        return 1;
      case 'wr':
        return 2;
      case 'te':
        return 3;
      default:
        return 5;
    }
  }
}

class VORPBigBoard {
  final List<VORPBigBoardPlayer> players;
  final Map<String, int> leagueSettings;
  final String scoringSystem;
  final DateTime generatedAt;
  final Map<String, double>? customWeights;
  final bool usingCustomWeights;

  VORPBigBoard({
    required this.players,
    required this.leagueSettings,
    required this.scoringSystem,
    required this.generatedAt,
    this.customWeights,
    this.usingCustomWeights = false,
  });

  factory VORPBigBoard.fromVORPBoard(
    VORPBoard vorpBoard, {
    Map<String, double>? customWeights,
    bool usingCustomWeights = false,
  }) {
    final sortedPlayers = vorpBoard.sortedByVORP;
    final bigBoardPlayers = <VORPBigBoardPlayer>[];

    for (int i = 0; i < sortedPlayers.length; i++) {
      final player = VORPBigBoardPlayer.fromVORPPlayer(sortedPlayers[i], i + 1);
      bigBoardPlayers.add(player);
    }

    return VORPBigBoard(
      players: bigBoardPlayers,
      leagueSettings: vorpBoard.leagueSettings,
      scoringSystem: vorpBoard.scoringSystem,
      generatedAt: vorpBoard.generatedAt,
      customWeights: customWeights,
      usingCustomWeights: usingCustomWeights,
    );
  }

  /// Get players by VORP tier
  List<VORPBigBoardPlayer> getPlayersByTier(String tier) {
    return players.where((p) => p.vorpTier == tier).toList();
  }

  /// Get players by position
  List<VORPBigBoardPlayer> getPlayersByPosition(String position) {
    return players.where((p) => p.position.toLowerCase() == position.toLowerCase()).toList();
  }

  /// Get top N players
  List<VORPBigBoardPlayer> getTopPlayers(int count) {
    return players.take(count).toList();
  }

  /// Get players above replacement level
  List<VORPBigBoardPlayer> getAboveReplacementPlayers() {
    return players.where((p) => p.isAboveReplacement).toList();
  }

  /// Get replacement level players for each position
  Map<String, VORPBigBoardPlayer?> getReplacementLevelPlayers() {
    final result = <String, VORPBigBoardPlayer?>{};
    
    for (final position in ['qb', 'rb', 'wr', 'te']) {
      final positionPlayers = getPlayersByPosition(position);
      if (positionPlayers.isNotEmpty) {
        // Find player closest to replacement level (VORP ~ 0)
        positionPlayers.sort((a, b) => a.vorp.abs().compareTo(b.vorp.abs()));
        result[position] = positionPlayers.first;
      }
    }
    
    return result;
  }

  /// Get draft strategy insights
  Map<String, dynamic> getDraftInsights() {
    final insights = <String, dynamic>{};
    
    // Position scarcity analysis
    final positionCounts = <String, int>{};
    final positionAboveReplacement = <String, int>{};
    
    for (final player in players) {
      final pos = player.position.toLowerCase();
      positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
      if (player.isAboveReplacement) {
        positionAboveReplacement[pos] = (positionAboveReplacement[pos] ?? 0) + 1;
      }
    }

    insights['positionCounts'] = positionCounts;
    insights['positionAboveReplacement'] = positionAboveReplacement;
    
    // Calculate scarcity index (lower = more scarce)
    final scarcityIndex = <String, double>{};
    for (final pos in positionCounts.keys) {
      final total = positionCounts[pos] ?? 0;
      final aboveReplacement = positionAboveReplacement[pos] ?? 0;
      scarcityIndex[pos] = total > 0 ? aboveReplacement / total : 0.0;
    }
    insights['scarcityIndex'] = scarcityIndex;

    // Top tier analysis
    final elitePlayers = getPlayersByTier('Elite');
    final highPlayers = getPlayersByTier('High');
    
    insights['eliteByPosition'] = _groupByPosition(elitePlayers);
    insights['highByPosition'] = _groupByPosition(highPlayers);
    
    // Value gaps (biggest VORP drops)
    final valueGaps = <Map<String, dynamic>>[];
    for (int i = 0; i < players.length - 1; i++) {
      final current = players[i];
      final next = players[i + 1];
      final gap = current.vorp - next.vorp;
      
      if (gap > 10.0) { // Significant value gap
        valueGaps.add({
          'afterPlayer': current.playerName,
          'afterRank': current.overallRank,
          'beforePlayer': next.playerName,
          'beforeRank': next.overallRank,
          'gap': gap,
        });
      }
    }
    insights['valueGaps'] = valueGaps;

    return insights;
  }

  Map<String, List<VORPBigBoardPlayer>> _groupByPosition(List<VORPBigBoardPlayer> players) {
    final grouped = <String, List<VORPBigBoardPlayer>>{};
    for (final player in players) {
      final pos = player.position.toLowerCase();
      grouped[pos] = (grouped[pos] ?? [])..add(player);
    }
    return grouped;
  }

  /// Export board for analysis
  List<Map<String, dynamic>> exportForAnalysis() {
    return players.map((player) => {
      'Overall_Rank': player.overallRank,
      'Player': player.playerName,
      'Position': player.position.toUpperCase(),
      'Team': player.team,
      'Position_Rank': player.positionRank,
      'Projected_Points': player.projectedPoints,
      'Replacement_Points': player.replacementPoints,
      'VORP': player.vorp,
      'VORP_Tier': player.vorpTier,
      'Above_Replacement': player.isAboveReplacement,
      'Position_Priority': player.positionPriority,
      'Original_Tier': player.tier ?? '',
    }).toList();
  }

  /// Create a copy with updated settings
  VORPBigBoard copyWith({
    Map<String, int>? leagueSettings,
    String? scoringSystem,
    Map<String, double>? customWeights,
    bool? usingCustomWeights,
  }) {
    return VORPBigBoard(
      players: players,
      leagueSettings: leagueSettings ?? this.leagueSettings,
      scoringSystem: scoringSystem ?? this.scoringSystem,
      generatedAt: generatedAt,
      customWeights: customWeights ?? this.customWeights,
      usingCustomWeights: usingCustomWeights ?? this.usingCustomWeights,
    );
  }

  /// Get summary statistics
  Map<String, dynamic> getSummaryStats() {
    if (players.isEmpty) return {};

    final vorpValues = players.map((p) => p.vorp).toList();
    vorpValues.sort();

    return {
      'totalPlayers': players.length,
      'aboveReplacementCount': getAboveReplacementPlayers().length,
      'maxVORP': vorpValues.isNotEmpty ? vorpValues.last : 0.0,
      'minVORP': vorpValues.isNotEmpty ? vorpValues.first : 0.0,
      'medianVORP': vorpValues.isNotEmpty ? vorpValues[vorpValues.length ~/ 2] : 0.0,
      'averageVORP': vorpValues.isNotEmpty ? vorpValues.reduce((a, b) => a + b) / vorpValues.length : 0.0,
      'positionBreakdown': _getPositionBreakdown(),
      'tierBreakdown': _getTierBreakdown(),
    };
  }

  Map<String, int> _getPositionBreakdown() {
    final breakdown = <String, int>{};
    for (final player in players) {
      final pos = player.position.toUpperCase();
      breakdown[pos] = (breakdown[pos] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> _getTierBreakdown() {
    final breakdown = <String, int>{};
    for (final player in players) {
      breakdown[player.vorpTier] = (breakdown[player.vorpTier] ?? 0) + 1;
    }
    return breakdown;
  }
}