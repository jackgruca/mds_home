class PlayerWeeklyNgs {
  final int season;
  final int week;
  final String playerId;
  final String playerName;
  final String team;
  final String statType; // "passing", "rushing", or "receiving"
  
  // Rushing NGS
  final double? efficiency;
  final double? percentAttemptsGteEightDefenders;
  final double? avgTimeToLos;
  final double? expectedRushYards;
  final double? rushYardsOverExpected;
  final double? rushPctOverExpected;
  final int? rushAttempts;
  final int? rushYards;
  final int? rushTouchdowns;
  
  // Receiving NGS
  final double? avgCushion;
  final double? avgSeparation;
  final double? avgIntendedAirYards;
  final double? percentShareIntendedAirYards;
  final double? catchPercentage;
  final double? avgYac;
  final double? avgExpectedYac;
  final double? avgYacAboveExpectation;
  final int? targets;
  final int? receptions;
  final int? receivingYards;
  final int? receivingTouchdowns;

  PlayerWeeklyNgs({
    required this.season,
    required this.week,
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.statType,
    this.efficiency,
    this.percentAttemptsGteEightDefenders,
    this.avgTimeToLos,
    this.expectedRushYards,
    this.rushYardsOverExpected,
    this.rushPctOverExpected,
    this.rushAttempts,
    this.rushYards,
    this.rushTouchdowns,
    this.avgCushion,
    this.avgSeparation,
    this.avgIntendedAirYards,
    this.percentShareIntendedAirYards,
    this.catchPercentage,
    this.avgYac,
    this.avgExpectedYac,
    this.avgYacAboveExpectation,
    this.targets,
    this.receptions,
    this.receivingYards,
    this.receivingTouchdowns,
  });

  factory PlayerWeeklyNgs.fromCsvRow(List<dynamic> row) {
    return PlayerWeeklyNgs(
      season: int.tryParse(row[0].toString()) ?? 0,
      week: int.tryParse(row[1].toString()) ?? 0,
      playerId: row[2].toString(),
      playerName: row[3].toString(),
      team: row[4].toString(),
      statType: row[14].toString(),
      // Rushing NGS (columns 5-13)
      efficiency: double.tryParse(row[5]?.toString() ?? ''),
      percentAttemptsGteEightDefenders: double.tryParse(row[6]?.toString() ?? ''),
      avgTimeToLos: double.tryParse(row[7]?.toString() ?? ''),
      expectedRushYards: double.tryParse(row[8]?.toString() ?? ''),
      rushYardsOverExpected: double.tryParse(row[9]?.toString() ?? ''),
      rushPctOverExpected: double.tryParse(row[10]?.toString() ?? ''),
      rushAttempts: int.tryParse(row[11]?.toString() ?? ''),
      rushYards: int.tryParse(row[12]?.toString() ?? ''),
      rushTouchdowns: int.tryParse(row[13]?.toString() ?? ''),
      // Receiving NGS (columns 15-26)
      avgCushion: double.tryParse(row[15]?.toString() ?? ''),
      avgSeparation: double.tryParse(row[16]?.toString() ?? ''),
      avgIntendedAirYards: double.tryParse(row[17]?.toString() ?? ''),
      percentShareIntendedAirYards: double.tryParse(row[18]?.toString() ?? ''),
      catchPercentage: double.tryParse(row[19]?.toString() ?? ''),
      avgYac: double.tryParse(row[20]?.toString() ?? ''),
      avgExpectedYac: double.tryParse(row[21]?.toString() ?? ''),
      avgYacAboveExpectation: double.tryParse(row[22]?.toString() ?? ''),
      targets: int.tryParse(row[23]?.toString() ?? ''),
      receptions: int.tryParse(row[24]?.toString() ?? ''),
      receivingYards: int.tryParse(row[25]?.toString() ?? ''),
      receivingTouchdowns: int.tryParse(row[26]?.toString() ?? ''),
    );
  }
  
  // Convenience getters
  String get weekDisplay => 'Week $week';
  
  bool get hasRushingStats => statType == "rushing";
  bool get hasReceivingStats => statType == "receiving";
  
  // Get key NGS metric based on stat type
  String get keyNgsMetric {
    switch (statType) {
      case 'rushing':
        return rushYardsOverExpected != null ? '${rushYardsOverExpected!.toStringAsFixed(1)} RYOE' : 'N/A';
      case 'receiving':
        return avgYacAboveExpectation != null ? '${avgYacAboveExpectation! > 0 ? '+' : ''}${avgYacAboveExpectation!.toStringAsFixed(1)} YAC+/-' : 'N/A';
      default:
        return 'N/A';
    }
  }
}