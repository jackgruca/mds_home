class PlayerInfo {
  final String playerId;
  final String fullName;
  final String position;
  final String positionGroup;
  final String team;
  final int? jerseyNumber;
  final String? height;
  final int? weight;
  final int? yearsExp;
  final String? status;
  final String? college;
  final String? displayName;
  
  // Season stats
  final int games;
  final int completions;
  final int attempts;
  final int passingYards;
  final int passingTds;
  final int interceptions;
  final int carries;
  final int rushingYards;
  final int rushingTds;
  final int receptions;
  final int targets;
  final int receivingYards;
  final int receivingTds;
  final double fantasyPointsPpr;
  final double fantasyPpg;
  final double passYpg;
  final double rushYpg;
  final double recYpg;
  final int totalTds;
  
  // EPA (Expected Points Added) metrics
  final double passingEpaTotal;
  final double passingEpaPerPlay;
  final int passingPlays;
  final double rushingEpaTotal;
  final double rushingEpaPerPlay;
  final int rushingPlays;
  final double receivingEpaTotal;
  final double receivingEpaPerPlay;
  final int receivingPlays;
  final double totalEpa;
  
  // Next Gen Stats metrics
  // Passing NGS
  final double ngsAvgTimeToThrow;
  final double ngsAvgCompletedAirYards;
  final double ngsAvgIntendedAirYards;
  final double ngsCompletionPctAboveExpectation;
  final double ngsAggressiveness;
  final double ngsMaxCompletedAirDistance;
  
  // Rushing NGS
  final double ngsEfficiency;
  final double ngsPctAttemptsGteEightDefenders;
  final double ngsAvgTimeToLos;
  final double ngsExpectedRushYards;
  final double ngsRushYardsOverExpected;
  final double ngsRushPctAboveExpectation;
  
  // Receiving NGS
  final double ngsAvgCushion;
  final double ngsAvgSeparation;
  final double ngsRecAvgIntendedAirYards;
  final double ngsPctShareIntendedAirYards;
  final double ngsCatchPercentage;
  final double ngsAvgYac;
  final double ngsAvgExpectedYac;
  final double ngsAvgYacAboveExpectation;

  PlayerInfo({
    required this.playerId,
    required this.fullName,
    required this.position,
    required this.positionGroup,
    required this.team,
    this.jerseyNumber,
    this.height,
    this.weight,
    this.yearsExp,
    this.status,
    this.college,
    this.displayName,
    required this.games,
    required this.completions,
    required this.attempts,
    required this.passingYards,
    required this.passingTds,
    required this.interceptions,
    required this.carries,
    required this.rushingYards,
    required this.rushingTds,
    required this.receptions,
    required this.targets,
    required this.receivingYards,
    required this.receivingTds,
    required this.fantasyPointsPpr,
    required this.fantasyPpg,
    required this.passYpg,
    required this.rushYpg,
    required this.recYpg,
    required this.totalTds,
    required this.passingEpaTotal,
    required this.passingEpaPerPlay,
    required this.passingPlays,
    required this.rushingEpaTotal,
    required this.rushingEpaPerPlay,
    required this.rushingPlays,
    required this.receivingEpaTotal,
    required this.receivingEpaPerPlay,
    required this.receivingPlays,
    required this.totalEpa,
    required this.ngsAvgTimeToThrow,
    required this.ngsAvgCompletedAirYards,
    required this.ngsAvgIntendedAirYards,
    required this.ngsCompletionPctAboveExpectation,
    required this.ngsAggressiveness,
    required this.ngsMaxCompletedAirDistance,
    required this.ngsEfficiency,
    required this.ngsPctAttemptsGteEightDefenders,
    required this.ngsAvgTimeToLos,
    required this.ngsExpectedRushYards,
    required this.ngsRushYardsOverExpected,
    required this.ngsRushPctAboveExpectation,
    required this.ngsAvgCushion,
    required this.ngsAvgSeparation,
    required this.ngsRecAvgIntendedAirYards,
    required this.ngsPctShareIntendedAirYards,
    required this.ngsCatchPercentage,
    required this.ngsAvgYac,
    required this.ngsAvgExpectedYac,
    required this.ngsAvgYacAboveExpectation,
  });

  factory PlayerInfo.fromCsvRow(List<dynamic> row) {
    return PlayerInfo(
      playerId: row[0].toString(),
      fullName: row[1].toString(),
      position: row[2].toString(),
      positionGroup: row[3].toString(),
      team: row[4].toString(),
      jerseyNumber: _parseInt(row[5]),
      height: row[6]?.toString(),
      weight: _parseInt(row[7]),
      yearsExp: _parseInt(row[8]),
      status: row[9]?.toString(),
      college: row[10]?.toString(),
      displayName: row[11]?.toString(),
      games: _parseInt(row[12]) ?? 0,
      completions: _parseInt(row[13]) ?? 0,
      attempts: _parseInt(row[14]) ?? 0,
      passingYards: _parseInt(row[15]) ?? 0,
      passingTds: _parseInt(row[16]) ?? 0,
      interceptions: _parseInt(row[17]) ?? 0,
      carries: _parseInt(row[18]) ?? 0,
      rushingYards: _parseInt(row[19]) ?? 0,
      rushingTds: _parseInt(row[20]) ?? 0,
      receptions: _parseInt(row[21]) ?? 0,
      targets: _parseInt(row[22]) ?? 0,
      receivingYards: _parseInt(row[23]) ?? 0,
      receivingTds: _parseInt(row[24]) ?? 0,
      fantasyPointsPpr: _parseDouble(row[25]) ?? 0.0,
      fantasyPpg: _parseDouble(row[61]) ?? 0.0,
      passYpg: _parseDouble(row[62]) ?? 0.0,
      rushYpg: _parseDouble(row[63]) ?? 0.0,
      recYpg: _parseDouble(row[64]) ?? 0.0,
      totalTds: _parseInt(row[65]) ?? 0,
      passingEpaTotal: _parseDouble(row[27]) ?? 0.0,
      passingEpaPerPlay: _parseDouble(row[28]) ?? 0.0,
      passingPlays: _parseInt(row[29]) ?? 0,
      rushingEpaTotal: _parseDouble(row[31]) ?? 0.0,
      rushingEpaPerPlay: _parseDouble(row[32]) ?? 0.0,
      rushingPlays: _parseInt(row[33]) ?? 0,
      receivingEpaTotal: _parseDouble(row[35]) ?? 0.0,
      receivingEpaPerPlay: _parseDouble(row[36]) ?? 0.0,
      receivingPlays: _parseInt(row[37]) ?? 0,
      totalEpa: _parseDouble(row[66]) ?? 0.0,
      ngsAvgTimeToThrow: _parseDouble(row[67]) ?? 0.0,
      ngsAvgCompletedAirYards: _parseDouble(row[68]) ?? 0.0,
      ngsAvgIntendedAirYards: _parseDouble(row[69]) ?? 0.0,
      ngsCompletionPctAboveExpectation: _parseDouble(row[70]) ?? 0.0,
      ngsAggressiveness: _parseDouble(row[71]) ?? 0.0,
      ngsMaxCompletedAirDistance: _parseDouble(row[72]) ?? 0.0,
      ngsEfficiency: _parseDouble(row[73]) ?? 0.0,
      ngsPctAttemptsGteEightDefenders: _parseDouble(row[74]) ?? 0.0,
      ngsAvgTimeToLos: _parseDouble(row[75]) ?? 0.0,
      ngsExpectedRushYards: _parseDouble(row[76]) ?? 0.0,
      ngsRushYardsOverExpected: _parseDouble(row[77]) ?? 0.0,
      ngsRushPctAboveExpectation: _parseDouble(row[78]) ?? 0.0,
      ngsAvgCushion: _parseDouble(row[79]) ?? 0.0,
      ngsAvgSeparation: _parseDouble(row[80]) ?? 0.0,
      ngsRecAvgIntendedAirYards: _parseDouble(row[81]) ?? 0.0,
      ngsPctShareIntendedAirYards: _parseDouble(row[82]) ?? 0.0,
      ngsCatchPercentage: _parseDouble(row[83]) ?? 0.0,
      ngsAvgYac: _parseDouble(row[84]) ?? 0.0,
      ngsAvgExpectedYac: _parseDouble(row[85]) ?? 0.0,
      ngsAvgYacAboveExpectation: _parseDouble(row[86]) ?? 0.0,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null || value.toString().isEmpty || value == 'NA') return null;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null || value.toString().isEmpty || value == 'NA') return null;
    return double.tryParse(value.toString());
  }

  String get displayNameOrFullName => displayName ?? fullName;

  bool get isQuarterback => position == 'QB';
  bool get isRunningBack => positionGroup == 'RB';
  bool get isWideReceiver => position == 'WR';
  bool get isTightEnd => position == 'TE';

  // Search helper
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return fullName.toLowerCase().contains(lowerQuery) ||
           team.toLowerCase().contains(lowerQuery) ||
           position.toLowerCase().contains(lowerQuery) ||
           (displayName?.toLowerCase().contains(lowerQuery) ?? false) ||
           (college?.toLowerCase().contains(lowerQuery) ?? false);
  }
}