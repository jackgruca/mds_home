class PlayerWeeklyEpa {
  final int season;
  final int week;
  final String gameId;
  final String playerId;
  final String playerName;
  final String team;
  final String opponent;
  
  // Combined EPA metrics
  final int totalPlays;
  final double totalEpa;
  final double epaPerPlay;
  
  // EPA by type
  final int passingPlays;
  final double passingEpaTotal;
  final double passingEpaPerPlay;
  
  final int rushingPlays;
  final double rushingEpaTotal;
  final double rushingEpaPerPlay;
  
  final int receivingPlays;
  final double receivingEpaTotal;
  final double receivingEpaPerPlay;
  
  // Stat-specific metrics
  // Passing
  final int? completions;
  final int? attempts;
  final int? passingYards;
  final int? passingTds;
  final int? interceptions;
  final int? sacks;
  
  // Rushing
  final int? carries;
  final int? rushingYards;
  final int? rushingTds;
  final int? rushingFirstDowns;
  
  // Receiving
  final int? targets;
  final int? receptions;
  final int? receivingYards;
  final int? receivingTds;
  final int? receivingFirstDowns;

  PlayerWeeklyEpa({
    required this.season,
    required this.week,
    required this.gameId,
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.opponent,
    required this.totalPlays,
    required this.totalEpa,
    required this.epaPerPlay,
    required this.passingPlays,
    required this.passingEpaTotal,
    required this.passingEpaPerPlay,
    required this.rushingPlays,
    required this.rushingEpaTotal,
    required this.rushingEpaPerPlay,
    required this.receivingPlays,
    required this.receivingEpaTotal,
    required this.receivingEpaPerPlay,
    this.completions,
    this.attempts,
    this.passingYards,
    this.passingTds,
    this.interceptions,
    this.sacks,
    this.carries,
    this.rushingYards,
    this.rushingTds,
    this.rushingFirstDowns,
    this.targets,
    this.receptions,
    this.receivingYards,
    this.receivingTds,
    this.receivingFirstDowns,
  });

  factory PlayerWeeklyEpa.fromCsvRow(List<dynamic> row) {
    return PlayerWeeklyEpa(
      season: int.tryParse(row[0].toString()) ?? 0,
      week: int.tryParse(row[1].toString()) ?? 0,
      gameId: row[2].toString(),
      playerId: row[3].toString(),
      playerName: row[4].toString(),
      team: row[5].toString(),
      opponent: row[6].toString(),
      // Combined EPA data
      totalPlays: int.tryParse(row[7].toString()) ?? 0,
      totalEpa: double.tryParse(row[8].toString()) ?? 0.0,
      epaPerPlay: double.tryParse(row[9].toString()) ?? 0.0,
      // EPA by type
      passingPlays: int.tryParse(row[10].toString()) ?? 0,
      passingEpaTotal: double.tryParse(row[11].toString()) ?? 0.0,
      passingEpaPerPlay: double.tryParse(row[12].toString()) ?? 0.0,
      rushingPlays: int.tryParse(row[13].toString()) ?? 0,
      rushingEpaTotal: double.tryParse(row[14].toString()) ?? 0.0,
      rushingEpaPerPlay: double.tryParse(row[15].toString()) ?? 0.0,
      receivingPlays: int.tryParse(row[16].toString()) ?? 0,
      receivingEpaTotal: double.tryParse(row[17].toString()) ?? 0.0,
      receivingEpaPerPlay: double.tryParse(row[18].toString()) ?? 0.0,
      // Traditional stats
      completions: int.tryParse(row[19]?.toString() ?? '0'),
      attempts: int.tryParse(row[20]?.toString() ?? '0'),
      passingYards: int.tryParse(row[21]?.toString() ?? '0'),
      passingTds: int.tryParse(row[22]?.toString() ?? '0'),
      interceptions: int.tryParse(row[23]?.toString() ?? '0'),
      sacks: int.tryParse(row[24]?.toString() ?? '0'),
      carries: int.tryParse(row[25]?.toString() ?? '0'),
      rushingYards: int.tryParse(row[26]?.toString() ?? '0'),
      rushingTds: int.tryParse(row[27]?.toString() ?? '0'),
      rushingFirstDowns: int.tryParse(row[28]?.toString() ?? '0'),
      targets: int.tryParse(row[29]?.toString() ?? '0'),
      receptions: int.tryParse(row[30]?.toString() ?? '0'),
      receivingYards: int.tryParse(row[31]?.toString() ?? '0'),
      receivingTds: int.tryParse(row[32]?.toString() ?? '0'),
      receivingFirstDowns: int.tryParse(row[33]?.toString() ?? '0'),
    );
  }
  
  // Convenience getters
  String get weekDisplay => 'Week $week';
  String get matchupDisplay => '$team @ $opponent';
  
  bool get hasPassingStats => passingPlays > 0;
  bool get hasRushingStats => rushingPlays > 0;
  bool get hasReceivingStats => receivingPlays > 0;
}