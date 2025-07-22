class CustomPlayerRank {
  final String playerId;
  final String playerName;
  final String team;
  final int customRank;
  final double projectedPoints;
  final double vorp;

  const CustomPlayerRank({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.customRank,
    required this.projectedPoints,
    required this.vorp,
  });

  factory CustomPlayerRank.fromJson(Map<String, dynamic> json) {
    return CustomPlayerRank(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      team: json['team'] as String,
      customRank: json['customRank'] as int,
      projectedPoints: (json['projectedPoints'] as num).toDouble(),
      vorp: (json['vorp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'team': team,
      'customRank': customRank,
      'projectedPoints': projectedPoints,
      'vorp': vorp,
    };
  }

  CustomPlayerRank copyWith({
    String? playerId,
    String? playerName,
    String? team,
    int? customRank,
    double? projectedPoints,
    double? vorp,
  }) {
    return CustomPlayerRank(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      team: team ?? this.team,
      customRank: customRank ?? this.customRank,
      projectedPoints: projectedPoints ?? this.projectedPoints,
      vorp: vorp ?? this.vorp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomPlayerRank &&
           other.playerId == playerId &&
           other.playerName == playerName &&
           other.team == team &&
           other.customRank == customRank &&
           other.projectedPoints == projectedPoints &&
           other.vorp == vorp;
  }

  @override
  int get hashCode {
    return Object.hash(
      playerId,
      playerName,
      team,
      customRank,
      projectedPoints,
      vorp,
    );
  }

  @override
  String toString() {
    return 'CustomPlayerRank(playerId: $playerId, playerName: $playerName, team: $team, customRank: $customRank, projectedPoints: $projectedPoints, vorp: $vorp)';
  }
}

class CustomPositionRanking {
  final String id;
  final String userId; // for future auth
  final String position;
  final String name;
  final List<CustomPlayerRank> playerRanks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomPositionRanking({
    required this.id,
    required this.userId,
    required this.position,
    required this.name,
    required this.playerRanks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomPositionRanking.fromJson(Map<String, dynamic> json) {
    return CustomPositionRanking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      position: json['position'] as String,
      name: json['name'] as String,
      playerRanks: (json['playerRanks'] as List<dynamic>)
          .map((e) => CustomPlayerRank.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
    };
  }

  CustomPositionRanking copyWith({
    String? id,
    String? userId,
    String? position,
    String? name,
    List<CustomPlayerRank>? playerRanks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomPositionRanking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      position: position ?? this.position,
      name: name ?? this.name,
      playerRanks: playerRanks ?? this.playerRanks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomPositionRanking &&
           other.id == id &&
           other.userId == userId &&
           other.position == position &&
           other.name == name &&
           other.playerRanks == playerRanks &&
           other.createdAt == createdAt &&
           other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      position,
      name,
      playerRanks,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomPositionRanking(id: $id, userId: $userId, position: $position, name: $name, playerRanks: ${playerRanks.length} players, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class CustomBigBoard {
  final String id;
  final String name;
  final Map<String, CustomPositionRanking> positionRankings;
  final List<CustomPlayerRank> aggregatedPlayers;
  final DateTime createdAt;

  const CustomBigBoard({
    required this.id,
    required this.name,
    required this.positionRankings,
    required this.aggregatedPlayers,
    required this.createdAt,
  });

  factory CustomBigBoard.fromJson(Map<String, dynamic> json) {
    return CustomBigBoard(
      id: json['id'] as String,
      name: json['name'] as String,
      positionRankings: (json['positionRankings'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
              key, CustomPositionRanking.fromJson(value as Map<String, dynamic>))),
      aggregatedPlayers: (json['aggregatedPlayers'] as List<dynamic>)
          .map((e) => CustomPlayerRank.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'positionRankings': positionRankings
          .map((key, value) => MapEntry(key, value.toJson())),
      'aggregatedPlayers': aggregatedPlayers.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CustomBigBoard copyWith({
    String? id,
    String? name,
    Map<String, CustomPositionRanking>? positionRankings,
    List<CustomPlayerRank>? aggregatedPlayers,
    DateTime? createdAt,
  }) {
    return CustomBigBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      positionRankings: positionRankings ?? this.positionRankings,
      aggregatedPlayers: aggregatedPlayers ?? this.aggregatedPlayers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomBigBoard &&
           other.id == id &&
           other.name == name &&
           other.positionRankings == positionRankings &&
           other.aggregatedPlayers == aggregatedPlayers &&
           other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      positionRankings,
      aggregatedPlayers,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'CustomBigBoard(id: $id, name: $name, positions: ${positionRankings.keys.join(', ')}, players: ${aggregatedPlayers.length}, createdAt: $createdAt)';
  }
}