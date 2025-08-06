// lib/models/adp/adp_data.dart

class ADPData {
  final String player;
  final String position;
  final int season;
  final String scoringFormat; // 'ppr' or 'standard'
  final int positionRankNum;
  final double avgRankNum;
  
  // Platform-specific ranks
  final double? espnRankNum;
  final double? sleeperRankNum;
  final double? cbsRankNum;
  final double? nflRankNum;
  final double? rtsRankNum;
  final double? ffcRankNum;

  ADPData({
    required this.player,
    required this.position,
    required this.season,
    required this.scoringFormat,
    required this.positionRankNum,
    required this.avgRankNum,
    this.espnRankNum,
    this.sleeperRankNum,
    this.cbsRankNum,
    this.nflRankNum,
    this.rtsRankNum,
    this.ffcRankNum,
  });

  factory ADPData.fromCsvRow(Map<String, dynamic> row, String scoringFormat) {
    return ADPData(
      player: row['player'] ?? '',
      position: row['position'] ?? '',
      season: int.tryParse(row['season']?.toString() ?? '') ?? 0,
      scoringFormat: scoringFormat,
      positionRankNum: int.tryParse(row['position_rank_num']?.toString() ?? '') ?? 0,
      avgRankNum: double.tryParse(row['avg_rank_num']?.toString() ?? '') ?? 0.0,
      espnRankNum: double.tryParse(row['espn_rank_num']?.toString() ?? ''),
      sleeperRankNum: double.tryParse(row['sleeper_rank_num']?.toString() ?? ''),
      cbsRankNum: double.tryParse(row['cbs_rank_num']?.toString() ?? ''),
      nflRankNum: double.tryParse(row['nfl_rank_num']?.toString() ?? ''),
      rtsRankNum: double.tryParse(row['rts_rank_num']?.toString() ?? ''),
      ffcRankNum: double.tryParse(row['ffc_rank_num']?.toString() ?? ''),
    );
  }

  Map<String, double?> get platformRanks => {
    if (espnRankNum != null) 'ESPN': espnRankNum,
    if (sleeperRankNum != null) 'Sleeper': sleeperRankNum,
    if (cbsRankNum != null) 'CBS': cbsRankNum,
    if (nflRankNum != null) 'NFL': nflRankNum,
    if (rtsRankNum != null) 'RTS': rtsRankNum,
    if (ffcRankNum != null) 'FFC': ffcRankNum,
  };
}