import 'ff_player.dart';

class FFPlatformRanks {
  final String platform;
  final String scoringSystem;
  final Map<String, int> playerRanks; // playerId -> rank
  final DateTime lastUpdated;

  FFPlatformRanks({
    required this.platform,
    required this.scoringSystem,
    required this.playerRanks,
    required this.lastUpdated,
  });

  // Factory constructor to create rankings from JSON
  factory FFPlatformRanks.fromJson(Map<String, dynamic> json) {
    return FFPlatformRanks(
      platform: json['platform'] as String,
      scoringSystem: json['scoringSystem'] as String,
      playerRanks: Map<String, int>.from(json['playerRanks'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // Convert rankings to JSON
  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'scoringSystem': scoringSystem,
      'playerRanks': playerRanks,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Get rank for a player
  int? getPlayerRank(String playerId) {
    return playerRanks[playerId];
  }

  // Get rank difference between two platforms
  int? getRankDifference(String playerId, FFPlatformRanks otherPlatform) {
    final thisRank = getPlayerRank(playerId);
    final otherRank = otherPlatform.getPlayerRank(playerId);
    
    if (thisRank == null || otherRank == null) return null;
    return thisRank - otherRank;
  }

  // Get players with significant rank differences
  List<String> getPlayersWithRankDifferences(
    FFPlatformRanks otherPlatform, {
    int minDifference = 5,
  }) {
    return playerRanks.keys.where((playerId) {
      final diff = getRankDifference(playerId, otherPlatform);
      return diff != null && diff.abs() >= minDifference;
    }).toList();
  }

  // Get top N players by rank
  List<String> getTopPlayers(int n) {
    final sortedPlayers = playerRanks.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sortedPlayers.take(n).map((e) => e.key).toList();
  }

  // Get players by position with their ranks
  Map<String, int> getPlayersByPosition(String position, List<FFPlayer> allPlayers) {
    final positionPlayers = allPlayers.where((p) => p.position == position);
    return Map.fromEntries(
      positionPlayers.map((p) => MapEntry(p.id, playerRanks[p.id] ?? 999))
    );
  }
} 