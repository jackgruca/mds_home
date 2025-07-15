class PlayerProjection {
  final String playerId;
  final String playerName;
  final String position;
  final String team;
  final int wrRank;
  final double targetShare;
  final double projectedYards;
  final double projectedTDs;
  final double projectedReceptions;
  final double projectedPoints;
  final int playerYear;
  final int passOffenseTier;
  final int qbTier;
  final int runOffenseTier;
  final int epaTier;
  final int passFreqTier;
  final bool isManualEntry;
  final DateTime lastModified;

  const PlayerProjection({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.wrRank,
    required this.targetShare,
    required this.projectedYards,
    required this.projectedTDs,
    required this.projectedReceptions,
    required this.projectedPoints,
    required this.playerYear,
    required this.passOffenseTier,
    required this.qbTier,
    required this.runOffenseTier,
    required this.epaTier,
    required this.passFreqTier,
    this.isManualEntry = false,
    required this.lastModified,
  });

  PlayerProjection copyWith({
    String? playerId,
    String? playerName,
    String? position,
    String? team,
    int? wrRank,
    double? targetShare,
    double? projectedYards,
    double? projectedTDs,
    double? projectedReceptions,
    double? projectedPoints,
    int? playerYear,
    int? passOffenseTier,
    int? qbTier,
    int? runOffenseTier,
    int? epaTier,
    int? passFreqTier,
    bool? isManualEntry,
    DateTime? lastModified,
  }) {
    return PlayerProjection(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      position: position ?? this.position,
      team: team ?? this.team,
      wrRank: wrRank ?? this.wrRank,
      targetShare: targetShare ?? this.targetShare,
      projectedYards: projectedYards ?? this.projectedYards,
      projectedTDs: projectedTDs ?? this.projectedTDs,
      projectedReceptions: projectedReceptions ?? this.projectedReceptions,
      projectedPoints: projectedPoints ?? this.projectedPoints,
      playerYear: playerYear ?? this.playerYear,
      passOffenseTier: passOffenseTier ?? this.passOffenseTier,
      qbTier: qbTier ?? this.qbTier,
      runOffenseTier: runOffenseTier ?? this.runOffenseTier,
      epaTier: epaTier ?? this.epaTier,
      passFreqTier: passFreqTier ?? this.passFreqTier,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'team': team,
      'wrRank': wrRank,
      'targetShare': targetShare,
      'projectedYards': projectedYards,
      'projectedTDs': projectedTDs,
      'projectedReceptions': projectedReceptions,
      'projectedPoints': projectedPoints,
      'playerYear': playerYear,
      'passOffenseTier': passOffenseTier,
      'qbTier': qbTier,
      'runOffenseTier': runOffenseTier,
      'epaTier': epaTier,
      'passFreqTier': passFreqTier,
      'isManualEntry': isManualEntry,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory PlayerProjection.fromJson(Map<String, dynamic> json) {
    return PlayerProjection(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      team: json['team'] as String,
      wrRank: json['wrRank'] as int,
      targetShare: (json['targetShare'] as num).toDouble(),
      projectedYards: (json['projectedYards'] as num).toDouble(),
      projectedTDs: (json['projectedTDs'] as num).toDouble(),
      projectedReceptions: (json['projectedReceptions'] as num).toDouble(),
      projectedPoints: (json['projectedPoints'] as num).toDouble(),
      playerYear: json['playerYear'] as int,
      passOffenseTier: json['passOffenseTier'] as int,
      qbTier: json['qbTier'] as int,
      runOffenseTier: json['runOffenseTier'] as int,
      epaTier: json['epaTier'] as int,
      passFreqTier: json['passFreqTier'] as int,
      isManualEntry: json['isManualEntry'] as bool? ?? false,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  // Factory constructor for creating from CSV data
  factory PlayerProjection.fromCsvRow(Map<String, dynamic> csvRow) {
    return PlayerProjection(
      playerId: csvRow['receiver_player_id']?.toString() ?? '',
      playerName: csvRow['receiver_player_name']?.toString() ?? csvRow['player']?.toString() ?? '',
      position: csvRow['position']?.toString() ?? 'WR',
      team: csvRow['NY_posteam']?.toString() ?? csvRow['posteam']?.toString() ?? '',
      wrRank: int.tryParse(csvRow['NY_wr_rank']?.toString() ?? csvRow['wr_rank']?.toString() ?? '1') ?? 1,
      targetShare: double.tryParse(csvRow['NY_tgtShare']?.toString() ?? csvRow['tgt_share']?.toString() ?? '0') ?? 0.0,
      projectedYards: double.tryParse(csvRow['NY_seasonYards']?.toString() ?? csvRow['numYards']?.toString() ?? '0') ?? 0.0,
      projectedTDs: double.tryParse(csvRow['numTD']?.toString() ?? '0') ?? 0.0,
      projectedReceptions: double.tryParse(csvRow['numRec']?.toString() ?? '0') ?? 0.0,
      projectedPoints: double.tryParse(csvRow['NY_points']?.toString() ?? csvRow['points']?.toString() ?? '0') ?? 0.0,
      playerYear: int.tryParse(csvRow['NY_playerYear']?.toString() ?? csvRow['playerYear']?.toString() ?? '1') ?? 1,
      passOffenseTier: int.tryParse(csvRow['NY_passOffenseTier']?.toString() ?? csvRow['passOffenseTier']?.toString() ?? '4') ?? 4,
      qbTier: int.tryParse(csvRow['NY_qbTier']?.toString() ?? csvRow['qbTier']?.toString() ?? '4') ?? 4,
      runOffenseTier: int.tryParse(csvRow['runOffenseTier']?.toString() ?? '4') ?? 4,
      epaTier: int.tryParse(csvRow['epaTier']?.toString() ?? '4') ?? 4,
      passFreqTier: int.tryParse(csvRow['NY_passFreqTier']?.toString() ?? '4') ?? 4,
      isManualEntry: false,
      lastModified: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PlayerProjection(playerName: $playerName, team: $team, wrRank: $wrRank, targetShare: ${(targetShare * 100).toStringAsFixed(1)}%, projectedPoints: ${projectedPoints.toStringAsFixed(1)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProjection && other.playerId == playerId;
  }

  @override
  int get hashCode => playerId.hashCode;
} 