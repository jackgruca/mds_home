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
  final double? dynamicValue;
  final Map<String, double>? contextScores;
  final List<String>? tags;

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
    this.dynamicValue,
    this.contextScores,
    this.tags,
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
      dynamicValue: json['dynamicValue'] as double?,
      contextScores: (json['contextScores'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      tags: (json['tags'] as List?)?.cast<String>(),
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
      'dynamicValue': dynamicValue,
      'contextScores': contextScores,
      'tags': tags,
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
    double? dynamicValue,
    Map<String, double>? contextScores,
    List<String>? tags,
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
      dynamicValue: dynamicValue ?? this.dynamicValue,
      contextScores: contextScores ?? this.contextScores,
      tags: tags ?? this.tags,
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
      dynamicValue: 0.0,
      contextScores: {},
      tags: [],
    );
  }

  // Dynamic value and context methods
  double getContextScore(String context) {
    return contextScores?[context] ?? 0.0;
  }

  bool hasTag(String tag) {
    return tags?.contains(tag) ?? false;
  }

  List<String> get allTags => tags ?? [];

  // Value comparison methods
  bool isValuePick(int currentPick) {
    final expected = consensusRank ?? rank ?? 999;
    return expected > currentPick + 5;
  }

  bool isReach(int currentPick) {
    final expected = consensusRank ?? rank ?? 999;
    return expected < currentPick - 10;
  }

  bool isEliteTier() {
    final rankToCheck = consensusRank ?? rank ?? 999;
    return rankToCheck <= 12;
  }

  bool isTopTier() {
    final rankToCheck = consensusRank ?? rank ?? 999;
    return rankToCheck <= 36;
  }

  bool isStarterTier() {
    final rankToCheck = consensusRank ?? rank ?? 999;
    return rankToCheck <= 100;
  }

  // Position-specific helpers
  bool get isSkillPosition => ['RB', 'WR', 'TE'].contains(position);
  bool get isFlexEligible => ['RB', 'WR', 'TE'].contains(position);
  bool get isPassCatcher => ['WR', 'TE'].contains(position);

  // Risk assessment
  bool get isRookie => hasTag('rookie');
  bool get isInjuryRisk => hasTag('injury_risk');
  bool get isHighUpside => hasTag('high_upside');
  bool get isSafeFloor => hasTag('safe_floor');

  // Projected points helpers
  double get projectedPoints {
    final points = stats?['projectedPoints'];
    if (points is num) return points.toDouble();
    return 0.0;
  }

  // ADP helpers
  double get adp {
    final adpValue = stats?['adp'];
    if (adpValue is num) return adpValue.toDouble();
    return (consensusRank ?? rank ?? 999).toDouble();
  }

  // Display helpers
  String get displayRank {
    final rankToShow = consensusRank ?? rank;
    return rankToShow != null ? '#$rankToShow' : 'Unranked';
  }

  String get positionRank {
    final posRank = stats?['Position Rank'];
    return posRank != null ? '$position$posRank' : position;
  }
} 