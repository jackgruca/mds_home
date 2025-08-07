// lib/models/adp/adp_comparison.dart

import 'package:flutter/material.dart';

enum PerformanceCategory {
  eliteValue,
  goodValue,
  expected,
  mildBust,
  majorBust,
}

class ADPComparison {
  final String player;
  final String position;
  final int season;
  final String scoringFormat;
  
  // ADP data
  final double avgRankNum;
  final int positionRankNum;  // Position ADP rank (e.g., RB5, WR12)
  final Map<String, double?> platformRanks;
  
  // Performance data
  final int? actualRankTotal;
  final int? actualRankPpg;
  final int? actualPositionRankTotal;
  final int? actualPositionRankPpg;
  final double? points;
  final double? ppg;
  final int? gamesPlayed;
  
  // Calculated differences
  final double? diffOverallTotal;
  final double? diffOverallPpg;
  final double? pctDiffTotal;
  final double? pctDiffPpg;
  
  // Performance categories
  final PerformanceCategory? categoryTotal;
  final PerformanceCategory? categoryPpg;

  ADPComparison({
    required this.player,
    required this.position,
    required this.season,
    required this.scoringFormat,
    required this.avgRankNum,
    required this.positionRankNum,
    required this.platformRanks,
    this.actualRankTotal,
    this.actualRankPpg,
    this.actualPositionRankTotal,
    this.actualPositionRankPpg,
    this.points,
    this.ppg,
    this.gamesPlayed,
    this.diffOverallTotal,
    this.diffOverallPpg,
    this.pctDiffTotal,
    this.pctDiffPpg,
    this.categoryTotal,
    this.categoryPpg,
  });

  factory ADPComparison.fromCsvRow(Map<String, dynamic> row) {
    // Helper function to parse numeric values, handling "NA", empty strings, and spaces
    double? parseNum(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      if (str.isEmpty || str == 'NA' || str == 'null') return null;
      return double.tryParse(str);
    }
    
    int? parseInt(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      if (str.isEmpty || str == 'NA' || str == 'null') return null;
      return int.tryParse(str);
    }
    
    // Parse platform ranks
    Map<String, double?> platforms = {};
    final espnRank = parseNum(row['espn_rank_num']);
    if (espnRank != null) platforms['ESPN'] = espnRank;
    
    final sleeperRank = parseNum(row['sleeper_rank_num']);
    if (sleeperRank != null) platforms['Sleeper'] = sleeperRank;
    
    final cbsRank = parseNum(row['cbs_rank_num']);
    if (cbsRank != null) platforms['CBS'] = cbsRank;
    
    final nflRank = parseNum(row['nfl_rank_num']);
    if (nflRank != null) platforms['NFL'] = nflRank;
    
    final rtsRank = parseNum(row['rts_rank_num']);
    if (rtsRank != null) platforms['RTS'] = rtsRank;
    
    final ffcRank = parseNum(row['ffc_rank_num']);
    if (ffcRank != null) platforms['FFC'] = ffcRank;

    // Parse scoring format from the data
    String scoringFormat = row['scoring_format']?.toString().trim() ?? 'ppr';
    
    // Determine which rank and points fields to use based on scoring format
    String rankTotalField = scoringFormat == 'ppr' ? 'rank_overall_ppr_total' : 'rank_overall_std_total';
    String rankPpgField = scoringFormat == 'ppr' ? 'rank_overall_ppr_ppg' : 'rank_overall_std_ppg';
    String pointsField = scoringFormat == 'ppr' ? 'points_ppr' : 'points_std';
    String ppgField = scoringFormat == 'ppr' ? 'ppg_ppr' : 'ppg_std';

    // Determine position rank fields based on scoring format
    String posRankTotalField = scoringFormat == 'ppr' ? 'rank_position_ppr_total' : 'rank_position_std_total';
    String posRankPpgField = scoringFormat == 'ppr' ? 'rank_position_ppr_ppg' : 'rank_position_std_ppg';

    return ADPComparison(
      player: row['player']?.toString().trim() ?? '',
      position: row['position']?.toString().trim() ?? '',
      season: parseInt(row['season']) ?? 0,
      scoringFormat: scoringFormat,
      avgRankNum: parseNum(row['avg_rank_num']) ?? 0.0,
      positionRankNum: parseInt(row['position_rank_num']) ?? 0,
      platformRanks: platforms,
      actualRankTotal: parseInt(row[rankTotalField]),
      actualRankPpg: parseInt(row[rankPpgField]),
      actualPositionRankTotal: parseInt(row[posRankTotalField]),
      actualPositionRankPpg: parseInt(row[posRankPpgField]),
      points: parseNum(row[pointsField]),
      ppg: parseNum(row[ppgField]),
      gamesPlayed: parseInt(row['games_played']),
      diffOverallTotal: parseNum(row['diff_overall_total']),
      diffOverallPpg: parseNum(row['diff_overall_ppg']),
      pctDiffTotal: parseNum(row['pct_diff_overall_total']),
      pctDiffPpg: parseNum(row['pct_diff_overall_ppg']),
      categoryTotal: _parseCategory(row['performance_category_total']?.toString().trim()),
      categoryPpg: _parseCategory(row['performance_category_ppg']?.toString().trim()),
    );
  }

  static PerformanceCategory? _parseCategory(String? category) {
    switch (category) {
      case 'elite_value':
        return PerformanceCategory.eliteValue;
      case 'good_value':
        return PerformanceCategory.goodValue;
      case 'expected':
        return PerformanceCategory.expected;
      case 'mild_bust':
        return PerformanceCategory.mildBust;
      case 'major_bust':
        return PerformanceCategory.majorBust;
      default:
        return null;
    }
  }

  Color getPerformanceColor(bool usePpg) {
    final category = usePpg ? categoryPpg : categoryTotal;
    switch (category) {
      case PerformanceCategory.eliteValue:
        return Colors.green.shade900;
      case PerformanceCategory.goodValue:
        return Colors.green.shade600;
      case PerformanceCategory.expected:
        return Colors.grey.shade600;
      case PerformanceCategory.mildBust:
        return Colors.red.shade400;
      case PerformanceCategory.majorBust:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade400;
    }
  }

  double? getDifference(bool usePpg) => usePpg ? diffOverallPpg : diffOverallTotal;
  
  double? getPctDifference(bool usePpg) => usePpg ? pctDiffPpg : pctDiffTotal;
  
  int? getActualRank(bool usePpg) => usePpg ? actualRankPpg : actualRankTotal;
  
  double? getPoints(bool usePpg) => usePpg ? ppg : points;
  
  // Calculate position difference (ADP position rank vs actual position rank)
  double? getPositionDifference(bool usePpg) {
    final actualPosRank = usePpg ? actualPositionRankPpg : actualPositionRankTotal;
    if (actualPosRank == null) return null;
    return positionRankNum.toDouble() - actualPosRank.toDouble();
  }
  
  // Get actual position rank for display
  int? getActualPositionRank(bool usePpg) => usePpg ? actualPositionRankPpg : actualPositionRankTotal;

  String getPerformanceLabel(bool usePpg) {
    final category = usePpg ? categoryPpg : categoryTotal;
    switch (category) {
      case PerformanceCategory.eliteValue:
        return 'Elite Value';
      case PerformanceCategory.goodValue:
        return 'Good Value';
      case PerformanceCategory.expected:
        return 'Expected';
      case PerformanceCategory.mildBust:
        return 'Mild Bust';
      case PerformanceCategory.majorBust:
        return 'Major Bust';
      default:
        return '-';
    }
  }
}