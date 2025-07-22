import 'player_projection.dart';

class TeamProjections {
  final String teamCode;
  final String teamName;
  final List<PlayerProjection> players;
  final int passOffenseTier;
  final int qbTier;
  final int runOffenseTier;
  final int passFreqTier;
  final DateTime lastModified;

  const TeamProjections({
    required this.teamCode,
    required this.teamName,
    required this.players,
    required this.passOffenseTier,
    required this.qbTier,
    required this.runOffenseTier,
    required this.passFreqTier,
    required this.lastModified,
  });

  // Calculate total target share for the team
  double get totalTargetShare {
    return players.fold(0.0, (sum, player) => sum + player.targetShare);
  }

  // Get total projected points for the team
  double get totalProjectedPoints {
    return players.fold(0.0, (sum, player) => sum + player.projectedPoints);
  }

  // Get players sorted by WR rank
  List<PlayerProjection> get playersByRank {
    final sortedPlayers = List<PlayerProjection>.from(players);
    sortedPlayers.sort((a, b) => a.wrRank.compareTo(b.wrRank));
    return sortedPlayers;
  }

  // Get players sorted by projected points (descending)
  List<PlayerProjection> get playersByProjectedPoints {
    final sortedPlayers = List<PlayerProjection>.from(players);
    sortedPlayers.sort((a, b) => b.projectedPoints.compareTo(a.projectedPoints));
    return sortedPlayers;
  }

  // Get players sorted by target share (descending)
  List<PlayerProjection> get playersByTargetShare {
    final sortedPlayers = List<PlayerProjection>.from(players);
    sortedPlayers.sort((a, b) => b.targetShare.compareTo(a.targetShare));
    return sortedPlayers;
  }

  // Get top WRs (typically top 6 for projections)
  List<PlayerProjection> getTopWRs([int count = 6]) {
    return playersByRank.take(count).toList();
  }

  // Add or update a player
  TeamProjections addOrUpdatePlayer(PlayerProjection player) {
    final updatedPlayers = List<PlayerProjection>.from(players);
    final existingIndex = updatedPlayers.indexWhere((p) => p.playerId == player.playerId);
    
    if (existingIndex != -1) {
      updatedPlayers[existingIndex] = player;
    } else {
      updatedPlayers.add(player);
    }

    return copyWith(
      players: updatedPlayers,
      lastModified: DateTime.now(),
    );
  }

  // Remove a player
  TeamProjections removePlayer(String playerId) {
    final updatedPlayers = players.where((p) => p.playerId != playerId).toList();
    return copyWith(
      players: updatedPlayers,
      lastModified: DateTime.now(),
    );
  }

  // Update team context (QB tier, offense tier, etc.)
  TeamProjections updateTeamContext({
    int? passOffenseTier,
    int? qbTier,
    int? runOffenseTier,
    int? passFreqTier,
  }) {
    return copyWith(
      passOffenseTier: passOffenseTier ?? this.passOffenseTier,
      qbTier: qbTier ?? this.qbTier,
      runOffenseTier: runOffenseTier ?? this.runOffenseTier,
      passFreqTier: passFreqTier ?? this.passFreqTier,
      lastModified: DateTime.now(),
    );
  }

  // Normalize target shares to a specific total (e.g., 0.95 for 95%)
  TeamProjections normalizeTargetShares([double targetTotal = 0.95]) {
    if (players.isEmpty || totalTargetShare == 0) return this;
    
    final multiplier = targetTotal / totalTargetShare;
    final updatedPlayers = players.map((player) {
      return player.copyWith(
        targetShare: player.targetShare * multiplier,
        lastModified: DateTime.now(),
      );
    }).toList();

    return copyWith(
      players: updatedPlayers,
      lastModified: DateTime.now(),
    );
  }

  // Rebalance WR ranks based on target share
  TeamProjections rebalanceWRRanks() {
    final sortedByTargetShare = playersByTargetShare;
    final updatedPlayers = <PlayerProjection>[];
    
    for (int i = 0; i < sortedByTargetShare.length; i++) {
      final player = sortedByTargetShare[i];
      final newRank = i + 1;
      updatedPlayers.add(player.copyWith(
        wrRank: newRank,
        lastModified: DateTime.now(),
      ));
    }

    return copyWith(
      players: updatedPlayers,
      lastModified: DateTime.now(),
    );
  }

  TeamProjections copyWith({
    String? teamCode,
    String? teamName,
    List<PlayerProjection>? players,
    int? passOffenseTier,
    int? qbTier,
    int? runOffenseTier,
    int? passFreqTier,
    DateTime? lastModified,
  }) {
    return TeamProjections(
      teamCode: teamCode ?? this.teamCode,
      teamName: teamName ?? this.teamName,
      players: players ?? this.players,
      passOffenseTier: passOffenseTier ?? this.passOffenseTier,
      qbTier: qbTier ?? this.qbTier,
      runOffenseTier: runOffenseTier ?? this.runOffenseTier,
      passFreqTier: passFreqTier ?? this.passFreqTier,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamCode': teamCode,
      'teamName': teamName,
      'players': players.map((p) => p.toJson()).toList(),
      'passOffenseTier': passOffenseTier,
      'qbTier': qbTier,
      'runOffenseTier': runOffenseTier,
      'passFreqTier': passFreqTier,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory TeamProjections.fromJson(Map<String, dynamic> json) {
    return TeamProjections(
      teamCode: json['teamCode'] as String,
      teamName: json['teamName'] as String,
      players: (json['players'] as List)
          .map((p) => PlayerProjection.fromJson(p as Map<String, dynamic>))
          .toList(),
      passOffenseTier: json['passOffenseTier'] as int,
      qbTier: json['qbTier'] as int,
      runOffenseTier: json['runOffenseTier'] as int,
      passFreqTier: json['passFreqTier'] as int,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  @override
  String toString() {
    return 'TeamProjections(team: $teamCode, players: ${players.length}, totalTargetShare: ${(totalTargetShare * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamProjections && other.teamCode == teamCode;
  }

  @override
  int get hashCode => teamCode.hashCode;
} 