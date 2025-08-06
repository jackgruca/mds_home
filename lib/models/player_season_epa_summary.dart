class PlayerSeasonEpaSummary {
  final String playerId;
  final String playerName;
  final int season;
  final int games;
  
  // Passing EPA
  final int passingPlaysTotal;
  final double passingEpaTotal;
  final double passingEpaAvg;
  
  // Rushing EPA
  final int rushingPlaysTotal;
  final double rushingEpaTotal;
  final double rushingEpaAvg;
  
  // Receiving EPA
  final int receivingPlaysTotal;
  final double receivingEpaTotal;
  final double receivingEpaAvg;
  
  // Total EPA
  final double totalEpa;

  PlayerSeasonEpaSummary({
    required this.playerId,
    required this.playerName,
    required this.season,
    required this.games,
    required this.passingPlaysTotal,
    required this.passingEpaTotal,
    required this.passingEpaAvg,
    required this.rushingPlaysTotal,
    required this.rushingEpaTotal,
    required this.rushingEpaAvg,
    required this.receivingPlaysTotal,
    required this.receivingEpaTotal,
    required this.receivingEpaAvg,
    required this.totalEpa,
  });

  factory PlayerSeasonEpaSummary.fromCsvRow(List<dynamic> row) {
    return PlayerSeasonEpaSummary(
      playerId: row[0].toString(),
      playerName: row[1].toString(),
      season: int.tryParse(row[2].toString()) ?? 0,
      games: int.tryParse(row[3].toString()) ?? 0,
      passingPlaysTotal: int.tryParse(row[4].toString()) ?? 0,
      passingEpaTotal: double.tryParse(row[5].toString()) ?? 0.0,
      passingEpaAvg: double.tryParse(row[6].toString()) ?? 0.0,
      rushingPlaysTotal: int.tryParse(row[7].toString()) ?? 0,
      rushingEpaTotal: double.tryParse(row[8].toString()) ?? 0.0,
      rushingEpaAvg: double.tryParse(row[9].toString()) ?? 0.0,
      receivingPlaysTotal: int.tryParse(row[10].toString()) ?? 0,
      receivingEpaTotal: double.tryParse(row[11].toString()) ?? 0.0,
      receivingEpaAvg: double.tryParse(row[12].toString()) ?? 0.0,
      totalEpa: double.tryParse(row[13].toString()) ?? 0.0,
    );
  }
  
  // Check if player has stats in each category
  bool get hasPassingStats => passingPlaysTotal > 0;
  bool get hasRushingStats => rushingPlaysTotal > 0;
  bool get hasReceivingStats => receivingPlaysTotal > 0;
  
  // Get primary stat type based on play count
  String get primaryStatType {
    if (passingPlaysTotal >= rushingPlaysTotal && passingPlaysTotal >= receivingPlaysTotal) {
      return "passing";
    } else if (rushingPlaysTotal >= receivingPlaysTotal) {
      return "rushing";
    } else {
      return "receiving";
    }
  }
}