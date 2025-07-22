
class StatPrediction {
  final String playerId;
  final String playerName;
  final String position;
  final String team;
  
  // Current Year Stats
  final double tgtShare;
  final int wrRank;
  final double points;
  final int numYards;
  final int numTD;
  final int numRec;
  final int numGames;
  
  // Next Year Predictions (editable)
  double nyTgtShare;
  int nyWrRank;
  double nyPoints;
  int nySeasonYards;
  int nyNumTD;
  int nyNumRec;
  int nyNumGames;
  
  // Tier Classifications
  final int passOffenseTier;
  final int qbTier;
  final int? passFreqTier;
  final int? epaTier;
  
  // Customization tracking
  bool isEdited;
  final Map<String, dynamic> originalValues;
  
  StatPrediction({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.tgtShare,
    required this.wrRank,
    required this.points,
    required this.numYards,
    required this.numTD,
    required this.numRec,
    required this.numGames,
    required this.nyTgtShare,
    required this.nyWrRank,
    required this.nyPoints,
    required this.nySeasonYards,
    required this.nyNumTD,
    required this.nyNumRec,
    required this.nyNumGames,
    required this.passOffenseTier,
    required this.qbTier,
    this.passFreqTier,
    this.epaTier,
    this.isEdited = false,
    Map<String, dynamic>? originalValues,
  }) : originalValues = originalValues ?? {
    'nyTgtShare': nyTgtShare,
    'nyWrRank': nyWrRank,
    'nyPoints': nyPoints,
    'nySeasonYards': nySeasonYards,
    'nyNumTD': nyNumTD,
    'nyNumRec': nyNumRec,
    'nyNumGames': nyNumGames,
  };

  // Create from CSV row
  factory StatPrediction.fromCsvRow(Map<String, dynamic> row) {
    return StatPrediction(
      playerId: row['receiver_player_id'] ?? '',
      playerName: row['receiver_player_name'] ?? row['player_name'] ?? row['player'] ?? '',
      position: row['position'] ?? '',
      team: row['posteam'] ?? row['team'] ?? '',
      tgtShare: _parseDouble(row['tgt_share'] ?? row['tgtShare']),
      wrRank: _parseInt(row['wr_rank'] ?? row['wrRank']),
      points: _parseDouble(row['points']),
      numYards: _parseInt(row['numYards'] ?? row['seasonYards']),
      numTD: _parseInt(row['numTD']),
      numRec: _parseInt(row['numRec']),
      numGames: _parseInt(row['numGames']),
      nyTgtShare: _parseDouble(row['NY_tgtShare'] ?? row['NY_tgt_share']),
      nyWrRank: _parseInt(row['NY_wr_rank'] ?? row['NY_wrRank']),
      nyPoints: _parseDouble(row['NY_points']),
      nySeasonYards: _parseInt(row['NY_seasonYards']),
      nyNumTD: _parseInt(row['NY_numTD'] ?? 0), // Default to 0 if not present
      nyNumRec: _parseInt(row['NY_numRec'] ?? 0), // Default to 0 if not present  
      nyNumGames: _parseInt(row['NY_numGames']),
      passOffenseTier: _parseInt(row['passOffenseTier']),
      qbTier: _parseInt(row['qbTier']),
      passFreqTier: _parseIntNullable(row['NY_passFreqTier'] ?? row['passFreqTier']),
      epaTier: _parseIntNullable(row['epaTier']),
    );
  }

  // Helper methods for parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Update methods
  StatPrediction copyWith({
    String? playerId,
    String? playerName,
    String? position,
    String? team,
    double? tgtShare,
    int? wrRank,
    double? points,
    int? numYards,
    int? numTD,
    int? numRec,
    int? numGames,
    double? nyTgtShare,
    int? nyWrRank,
    double? nyPoints,
    int? nySeasonYards,
    int? nyNumTD,
    int? nyNumRec,
    int? nyNumGames,
    int? passOffenseTier,
    int? qbTier,
    int? passFreqTier,
    int? epaTier,
    bool? isEdited,
    Map<String, dynamic>? originalValues,
  }) {
    return StatPrediction(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      position: position ?? this.position,
      team: team ?? this.team,
      tgtShare: tgtShare ?? this.tgtShare,
      wrRank: wrRank ?? this.wrRank,
      points: points ?? this.points,
      numYards: numYards ?? this.numYards,
      numTD: numTD ?? this.numTD,
      numRec: numRec ?? this.numRec,
      numGames: numGames ?? this.numGames,
      nyTgtShare: nyTgtShare ?? this.nyTgtShare,
      nyWrRank: nyWrRank ?? this.nyWrRank,
      nyPoints: nyPoints ?? this.nyPoints,
      nySeasonYards: nySeasonYards ?? this.nySeasonYards,
      nyNumTD: nyNumTD ?? this.nyNumTD,
      nyNumRec: nyNumRec ?? this.nyNumRec,
      nyNumGames: nyNumGames ?? this.nyNumGames,
      passOffenseTier: passOffenseTier ?? this.passOffenseTier,
      qbTier: qbTier ?? this.qbTier,
      passFreqTier: passFreqTier ?? this.passFreqTier,
      epaTier: epaTier ?? this.epaTier,
      isEdited: isEdited ?? this.isEdited,
      originalValues: originalValues ?? this.originalValues,
    );
  }

  // Update a specific next year stat
  StatPrediction updateNyStat(String statName, dynamic value) {
    switch (statName) {
      case 'nyTgtShare':
        return copyWith(nyTgtShare: _parseDouble(value), isEdited: true);
      case 'nyWrRank':
        return copyWith(nyWrRank: _parseInt(value), isEdited: true);
      case 'nyPoints':
        return copyWith(nyPoints: _parseDouble(value), isEdited: true);
      case 'nySeasonYards':
        return copyWith(nySeasonYards: _parseInt(value), isEdited: true);
      case 'nyNumTD':
        return copyWith(nyNumTD: _parseInt(value), isEdited: true);
      case 'nyNumRec':
        return copyWith(nyNumRec: _parseInt(value), isEdited: true);
      case 'nyNumGames':
        return copyWith(nyNumGames: _parseInt(value), isEdited: true);
      default:
        return this;
    }
  }

  // Reset to original values
  StatPrediction resetToOriginal() {
    return copyWith(
      nyTgtShare: originalValues['nyTgtShare'],
      nyWrRank: originalValues['nyWrRank'],
      nyPoints: originalValues['nyPoints'],
      nySeasonYards: originalValues['nySeasonYards'],
      nyNumTD: originalValues['nyNumTD'],
      nyNumRec: originalValues['nyNumRec'],
      nyNumGames: originalValues['nyNumGames'],
      isEdited: false,
    );
  }

  // Get tier description
  String getTierDescription(String tierType) {
    switch (tierType) {
      case 'passOffense':
        return _getTierLabel(passOffenseTier);
      case 'qb':
        return _getTierLabel(qbTier);
      case 'passFreq':
        return passFreqTier != null ? _getTierLabel(passFreqTier!) : 'N/A';
      case 'epa':
        return epaTier != null ? _getTierLabel(epaTier!) : 'N/A';
      default:
        return 'N/A';
    }
  }

  String _getTierLabel(int tier) {
    switch (tier) {
      case 1:
        return 'Elite';
      case 2:
        return 'Good';
      case 3:
        return 'Average';
      case 4:
        return 'Below Avg';
      case 5:
        return 'Poor';
      default:
        return 'Unranked';
    }
  }

  // Export to map for integration with other systems
  Map<String, dynamic> toMap() {
    return {
      'receiver_player_id': playerId,
      'receiver_player_name': playerName,
      'position': position,
      'posteam': team,
      'tgt_share': tgtShare,
      'wr_rank': wrRank,
      'points': points,
      'numYards': numYards,
      'numTD': numTD,
      'numRec': numRec,
      'numGames': numGames,
      'NY_tgtShare': nyTgtShare,
      'NY_wr_rank': nyWrRank,
      'NY_points': nyPoints,
      'NY_seasonYards': nySeasonYards,
      'NY_numTD': nyNumTD,
      'NY_numRec': nyNumRec,
      'NY_numGames': nyNumGames,
      'passOffenseTier': passOffenseTier,
      'qbTier': qbTier,
      'passFreqTier': passFreqTier,
      'epaTier': epaTier,
      'isEdited': isEdited,
    };
  }

  @override
  String toString() {
    return 'StatPrediction{playerName: $playerName, position: $position, team: $team, isEdited: $isEdited}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatPrediction &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId;

  @override
  int get hashCode => playerId.hashCode;
}