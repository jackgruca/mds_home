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
      fantasyPpg: _parseDouble(row[26]) ?? 0.0,
      passYpg: _parseDouble(row[27]) ?? 0.0,
      rushYpg: _parseDouble(row[28]) ?? 0.0,
      recYpg: _parseDouble(row[29]) ?? 0.0,
      totalTds: _parseInt(row[30]) ?? 0,
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