import 'dart:convert';

class CustomPlayerRank {
  final String playerId;
  final String playerName;
  final String position;
  final String team;
  final int originalRank;
  final int customRank;
  final double? projectedPoints;
  final double? vorp;
  final Map<String, dynamic> originalData;

  CustomPlayerRank({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.originalRank,
    required this.customRank,
    this.projectedPoints,
    this.vorp,
    this.originalData = const {},
  });

  factory CustomPlayerRank.fromPlayerData(
    Map<String, dynamic> playerData,
    int customRank,
  ) {
    return CustomPlayerRank(
      playerId: playerData['player_id'] ?? playerData['fantasy_player_id'] ?? '',
      playerName: playerData['fantasy_player_name'] ?? 
                  playerData['player_name'] ?? 
                  playerData['passer_player_name'] ?? 
                  playerData['receiver_player_name'] ?? 
                  'Unknown',
      position: (playerData['position'] ?? '').toString().toLowerCase(),
      team: playerData['posteam'] ?? playerData['team'] ?? '',
      originalRank: playerData['myRankNum'] ?? playerData['rank'] ?? 0,
      customRank: customRank,
      originalData: Map<String, dynamic>.from(playerData),
    );
  }

  factory CustomPlayerRank.fromJson(Map<String, dynamic> json) {
    return CustomPlayerRank(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      team: json['team'] as String,
      originalRank: json['originalRank'] as int,
      customRank: json['customRank'] as int,
      projectedPoints: json['projectedPoints'] as double?,
      vorp: json['vorp'] as double?,
      originalData: Map<String, dynamic>.from(json['originalData'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'team': team,
      'originalRank': originalRank,
      'customRank': customRank,
      'projectedPoints': projectedPoints,
      'vorp': vorp,
      'originalData': originalData,
    };
  }

  CustomPlayerRank copyWith({
    String? playerId,
    String? playerName,
    String? position,
    String? team,
    int? originalRank,
    int? customRank,
    double? projectedPoints,
    double? vorp,
    Map<String, dynamic>? originalData,
  }) {
    return CustomPlayerRank(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      position: position ?? this.position,
      team: team ?? this.team,
      originalRank: originalRank ?? this.originalRank,
      customRank: customRank ?? this.customRank,
      projectedPoints: projectedPoints ?? this.projectedPoints,
      vorp: vorp ?? this.vorp,
      originalData: originalData ?? this.originalData,
    );
  }
}

class CustomPositionRanking {
  final String id;
  final String? userId; // for future auth
  final String position;
  final String name;
  final List<CustomPlayerRank> playerRanks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> leagueSettings;
  final String scoringSystem;

  CustomPositionRanking({
    required this.id,
    this.userId,
    required this.position,
    required this.name,
    required this.playerRanks,
    required this.createdAt,
    required this.updatedAt,
    Map<String, int>? leagueSettings,
    this.scoringSystem = 'ppr',
  }) : leagueSettings = leagueSettings ?? {
    'teams': 12,
    'qb': 1,
    'rb': 2,
    'wr': 2,
    'te': 1,
    'flex': 1,
  };

  factory CustomPositionRanking.fromJson(Map<String, dynamic> json) {
    return CustomPositionRanking(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      position: json['position'] as String,
      name: json['name'] as String,
      playerRanks: (json['playerRanks'] as List<dynamic>)
          .map((e) => CustomPlayerRank.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      leagueSettings: Map<String, int>.from(json['leagueSettings'] ?? {}),
      scoringSystem: json['scoringSystem'] as String? ?? 'ppr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'position': position,
      'name': name,
      'playerRanks': playerRanks.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'leagueSettings': leagueSettings,
      'scoringSystem': scoringSystem,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory CustomPositionRanking.fromJsonString(String jsonString) {
    return CustomPositionRanking.fromJson(jsonDecode(jsonString));
  }

  CustomPositionRanking copyWith({
    String? id,
    String? userId,
    String? position,
    String? name,
    List<CustomPlayerRank>? playerRanks,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, int>? leagueSettings,
    String? scoringSystem,
  }) {
    return CustomPositionRanking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      position: position ?? this.position,
      name: name ?? this.name,
      playerRanks: playerRanks ?? this.playerRanks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      leagueSettings: leagueSettings ?? this.leagueSettings,
      scoringSystem: scoringSystem ?? this.scoringSystem,
    );
  }

  /// Get players sorted by custom rank
  List<CustomPlayerRank> get sortedPlayers {
    final sorted = List<CustomPlayerRank>.from(playerRanks);
    sorted.sort((a, b) => a.customRank.compareTo(b.customRank));
    return sorted;
  }

  /// Get top N players by custom rank
  List<CustomPlayerRank> getTopPlayers(int count) {
    return sortedPlayers.take(count).toList();
  }

  /// Get player by ID
  CustomPlayerRank? getPlayerById(String playerId) {
    try {
      return playerRanks.firstWhere((p) => p.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  /// Update a player's custom rank
  CustomPositionRanking updatePlayerRank(String playerId, int newRank) {
    final updatedRanks = playerRanks.map((player) {
      if (player.playerId == playerId) {
        return player.copyWith(customRank: newRank);
      }
      return player;
    }).toList();

    return copyWith(
      playerRanks: updatedRanks,
      updatedAt: DateTime.now(),
    );
  }

  /// Reorder players based on new positions
  CustomPositionRanking reorderPlayers(List<String> orderedPlayerIds) {
    final updatedRanks = <CustomPlayerRank>[];
    
    for (int i = 0; i < orderedPlayerIds.length; i++) {
      final playerId = orderedPlayerIds[i];
      final player = getPlayerById(playerId);
      if (player != null) {
        updatedRanks.add(player.copyWith(customRank: i + 1));
      }
    }

    return copyWith(
      playerRanks: updatedRanks,
      updatedAt: DateTime.now(),
    );
  }

  /// Get summary statistics
  Map<String, dynamic> getSummary() {
    if (playerRanks.isEmpty) return {};

    final playersWithVORP = playerRanks.where((p) => p.vorp != null).toList();
    final vorpValues = playersWithVORP.map((p) => p.vorp!).toList();
    vorpValues.sort();

    return {
      'totalPlayers': playerRanks.length,
      'playersWithVORP': playersWithVORP.length,
      'topPlayer': playerRanks.isNotEmpty ? sortedPlayers.first.playerName : null,
      'avgVORP': vorpValues.isNotEmpty ? vorpValues.reduce((a, b) => a + b) / vorpValues.length : 0.0,
      'maxVORP': vorpValues.isNotEmpty ? vorpValues.last : 0.0,
      'minVORP': vorpValues.isNotEmpty ? vorpValues.first : 0.0,
    };
  }
}

class CustomBigBoard {
  final String id;
  final String name;
  final String? userId;
  final Map<String, CustomPositionRanking> positionRankings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> leagueSettings;
  final String scoringSystem;

  CustomBigBoard({
    required this.id,
    required this.name,
    this.userId,
    required this.positionRankings,
    required this.createdAt,
    required this.updatedAt,
    Map<String, int>? leagueSettings,
    this.scoringSystem = 'ppr',
  }) : leagueSettings = leagueSettings ?? {
    'teams': 12,
    'qb': 1,
    'rb': 2,
    'wr': 2,
    'te': 1,
    'flex': 1,
  };

  factory CustomBigBoard.fromJson(Map<String, dynamic> json) {
    final positionRankingsMap = <String, CustomPositionRanking>{};
    final positionRankingsJson = json['positionRankings'] as Map<String, dynamic>;
    
    for (final entry in positionRankingsJson.entries) {
      positionRankingsMap[entry.key] = 
          CustomPositionRanking.fromJson(entry.value as Map<String, dynamic>);
    }

    return CustomBigBoard(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String?,
      positionRankings: positionRankingsMap,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      leagueSettings: Map<String, int>.from(json['leagueSettings'] ?? {}),
      scoringSystem: json['scoringSystem'] as String? ?? 'ppr',
    );
  }

  Map<String, dynamic> toJson() {
    final positionRankingsJson = <String, dynamic>{};
    for (final entry in positionRankings.entries) {
      positionRankingsJson[entry.key] = entry.value.toJson();
    }

    return {
      'id': id,
      'name': name,
      'userId': userId,
      'positionRankings': positionRankingsJson,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'leagueSettings': leagueSettings,
      'scoringSystem': scoringSystem,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory CustomBigBoard.fromJsonString(String jsonString) {
    return CustomBigBoard.fromJson(jsonDecode(jsonString));
  }

  /// Get all players across positions sorted by VORP
  List<CustomPlayerRank> getAllPlayersSortedByVORP() {
    final allPlayers = <CustomPlayerRank>[];
    for (final ranking in positionRankings.values) {
      allPlayers.addAll(ranking.playerRanks);
    }
    
    allPlayers.sort((a, b) {
      final aVORP = a.vorp ?? double.negativeInfinity;
      final bVORP = b.vorp ?? double.negativeInfinity;
      return bVORP.compareTo(aVORP); // Descending order
    });
    
    return allPlayers;
  }

  /// Check if all required positions have rankings
  bool get isComplete {
    final requiredPositions = ['qb', 'rb', 'wr', 'te'];
    return requiredPositions.every((pos) => positionRankings.containsKey(pos));
  }

  /// Get summary across all positions
  Map<String, dynamic> getSummary() {
    final allPlayers = getAllPlayersSortedByVORP();
    final playersWithVORP = allPlayers.where((p) => p.vorp != null).toList();
    
    return {
      'totalPlayers': allPlayers.length,
      'playersWithVORP': playersWithVORP.length,
      'positionsIncluded': positionRankings.keys.toList(),
      'isComplete': isComplete,
      'topOverallPlayer': allPlayers.isNotEmpty ? allPlayers.first.playerName : null,
    };
  }
}