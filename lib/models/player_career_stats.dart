class PlayerCareerStats {
  final String playerId;
  final String playerName;
  final String playerDisplayName;
  final String position;
  final String positionGroup;
  final String? headshotUrl;
  final String team;
  final int season;
  final int games;
  
  // Passing stats
  final int completions;
  final int attempts; 
  final int passingYards;
  final int passingTds;
  final int interceptions;
  
  // Rushing stats
  final int carries;
  final int rushingYards;
  final int rushingTds;
  
  // Receiving stats
  final int receptions;
  final int targets;
  final int receivingYards;
  final int receivingTds;
  
  // Fantasy stats
  final double fantasyPointsPpr;
  final double fantasyPpg;
  final double passYpg;
  final double rushYpg;
  final double recYpg;
  final int totalTds;

  PlayerCareerStats({
    required this.playerId,
    required this.playerName,
    required this.playerDisplayName,
    required this.position,
    required this.positionGroup,
    this.headshotUrl,
    required this.team,
    required this.season,
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
  });

  factory PlayerCareerStats.fromCsvRow(List<dynamic> row) {
    return PlayerCareerStats(
      playerId: row[0]?.toString() ?? '',
      playerName: row[1]?.toString() ?? '',
      playerDisplayName: row[2]?.toString() ?? '',
      position: row[3]?.toString() ?? '',
      positionGroup: row[4]?.toString() ?? '',
      headshotUrl: row[5]?.toString(),
      team: row[6]?.toString() ?? '',
      season: int.tryParse(row[7]?.toString() ?? '0') ?? 0,
      games: int.tryParse(row[8]?.toString() ?? '0') ?? 0,
      completions: int.tryParse(row[9]?.toString() ?? '0') ?? 0,
      attempts: int.tryParse(row[10]?.toString() ?? '0') ?? 0,
      passingYards: int.tryParse(row[11]?.toString() ?? '0') ?? 0,
      passingTds: int.tryParse(row[12]?.toString() ?? '0') ?? 0,
      interceptions: int.tryParse(row[13]?.toString() ?? '0') ?? 0,
      carries: int.tryParse(row[14]?.toString() ?? '0') ?? 0,
      rushingYards: int.tryParse(row[15]?.toString() ?? '0') ?? 0,
      rushingTds: int.tryParse(row[16]?.toString() ?? '0') ?? 0,
      receptions: int.tryParse(row[17]?.toString() ?? '0') ?? 0,
      targets: int.tryParse(row[18]?.toString() ?? '0') ?? 0,
      receivingYards: int.tryParse(row[19]?.toString() ?? '0') ?? 0,
      receivingTds: int.tryParse(row[20]?.toString() ?? '0') ?? 0,
      fantasyPointsPpr: double.tryParse(row[21]?.toString() ?? '0') ?? 0.0,
      fantasyPpg: double.tryParse(row[22]?.toString() ?? '0') ?? 0.0,
      passYpg: double.tryParse(row[23]?.toString() ?? '0') ?? 0.0,
      rushYpg: double.tryParse(row[24]?.toString() ?? '0') ?? 0.0,
      recYpg: double.tryParse(row[25]?.toString() ?? '0') ?? 0.0,
      totalTds: int.tryParse(row[26]?.toString() ?? '0') ?? 0,
    );
  }

  // Convenience getters
  bool get isQuarterback => positionGroup == 'QB';
  bool get isRunningBack => positionGroup == 'RB';
  bool get isWideReceiver => positionGroup == 'WR';
  bool get isTightEnd => positionGroup == 'TE';
}