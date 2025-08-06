// lib/models/adp/player_performance.dart

class PlayerPerformance {
  final String? playerId;
  final String player;
  final String position;
  final int season;
  final int gamesPlayed;
  
  // Points and PPG
  final double pointsPpr;
  final double ppgPpr;
  final double pointsStd;
  final double ppgStd;
  
  // Rankings
  final int rankOverallPprTotal;
  final int rankOverallPprPpg;
  final int rankOverallStdTotal;
  final int rankOverallStdPpg;
  final int rankPositionPprTotal;
  final int rankPositionPprPpg;
  final int rankPositionStdTotal;
  final int rankPositionStdPpg;

  PlayerPerformance({
    this.playerId,
    required this.player,
    required this.position,
    required this.season,
    required this.gamesPlayed,
    required this.pointsPpr,
    required this.ppgPpr,
    required this.pointsStd,
    required this.ppgStd,
    required this.rankOverallPprTotal,
    required this.rankOverallPprPpg,
    required this.rankOverallStdTotal,
    required this.rankOverallStdPpg,
    required this.rankPositionPprTotal,
    required this.rankPositionPprPpg,
    required this.rankPositionStdTotal,
    required this.rankPositionStdPpg,
  });

  factory PlayerPerformance.fromCsvRow(Map<String, dynamic> row) {
    return PlayerPerformance(
      playerId: row['player_id']?.toString(),
      player: row['player'] ?? '',
      position: row['position'] ?? '',
      season: int.tryParse(row['season']?.toString() ?? '') ?? 0,
      gamesPlayed: int.tryParse(row['games_played']?.toString() ?? '') ?? 0,
      pointsPpr: double.tryParse(row['points_ppr']?.toString() ?? '') ?? 0.0,
      ppgPpr: double.tryParse(row['ppg_ppr']?.toString() ?? '') ?? 0.0,
      pointsStd: double.tryParse(row['points_std']?.toString() ?? '') ?? 0.0,
      ppgStd: double.tryParse(row['ppg_std']?.toString() ?? '') ?? 0.0,
      rankOverallPprTotal: int.tryParse(row['rank_overall_ppr_total']?.toString() ?? '') ?? 0,
      rankOverallPprPpg: int.tryParse(row['rank_overall_ppr_ppg']?.toString() ?? '') ?? 0,
      rankOverallStdTotal: int.tryParse(row['rank_overall_std_total']?.toString() ?? '') ?? 0,
      rankOverallStdPpg: int.tryParse(row['rank_overall_std_ppg']?.toString() ?? '') ?? 0,
      rankPositionPprTotal: int.tryParse(row['rank_position_ppr_total']?.toString() ?? '') ?? 0,
      rankPositionPprPpg: int.tryParse(row['rank_position_ppr_ppg']?.toString() ?? '') ?? 0,
      rankPositionStdTotal: int.tryParse(row['rank_position_std_total']?.toString() ?? '') ?? 0,
      rankPositionStdPpg: int.tryParse(row['rank_position_std_ppg']?.toString() ?? '') ?? 0,
    );
  }

  int getRankForScoring(String scoringFormat, bool usePpg) {
    if (scoringFormat == 'ppr') {
      return usePpg ? rankOverallPprPpg : rankOverallPprTotal;
    } else {
      return usePpg ? rankOverallStdPpg : rankOverallStdTotal;
    }
  }

  double getPointsForScoring(String scoringFormat, bool usePpg) {
    if (scoringFormat == 'ppr') {
      return usePpg ? ppgPpr : pointsPpr;
    } else {
      return usePpg ? ppgStd : pointsStd;
    }
  }
}