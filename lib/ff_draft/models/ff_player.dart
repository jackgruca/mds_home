class FFPlayer {
  final String id;
  final String name;
  final String position;
  final String team;
  final String? byeWeek;
  final Map<String, dynamic>? stats;
  final int? rank;
  final Map<String, int>? platformRanks;
  final int? consensusRank;
  final bool isFavorite;

  FFPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.team,
    this.byeWeek,
    this.stats,
    this.rank,
    this.platformRanks,
    this.consensusRank,
    this.isFavorite = false,
  });

  // Factory constructor to create a player from JSON
  factory FFPlayer.fromJson(Map<String, dynamic> json) {
    return FFPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      team: json['team'] as String,
      byeWeek: json['byeWeek'] as String?,
      stats: json['stats'] as Map<String, dynamic>?,
      rank: json['rank'] as int?,
      platformRanks: (json['platformRanks'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ),
      consensusRank: json['consensusRank'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  // Convert player to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'team': team,
      'byeWeek': byeWeek,
      'stats': stats,
      'rank': rank,
      'platformRanks': platformRanks,
      'consensusRank': consensusRank,
      'isFavorite': isFavorite,
    };
  }

  int getRankDifference(String platform) {
    if (rank == null || platformRanks == null || !platformRanks!.containsKey(platform)) {
      return 0;
    }
    return (platformRanks![platform] ?? 0) - (rank ?? 0);
  }

  FFPlayer copyWith({
    bool? isFavorite,
  }) {
    return FFPlayer(
      id: id,
      name: name,
      position: position,
      team: team,
      byeWeek: byeWeek,
      stats: stats,
      rank: rank,
      platformRanks: platformRanks,
      consensusRank: consensusRank,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Factory constructor to create an empty player for a specific position
  factory FFPlayer.empty({required String position}) {
    return FFPlayer(
      id: '',
      name: '',
      position: position,
      team: '',
      rank: 9999,
      platformRanks: {},
      consensusRank: 9999,
      stats: {},
    );
  }
} 