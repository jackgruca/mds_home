// lib/services/trade_value_calculator.dart
// Clean trade value calculation system

import 'dart:math';

class TradeValueCalculator {
  /// Calculate a player's overall trade value score (0-100)
  /// Rank-led weighted blend with elite bonus
  static double calculateTradeValue({
    required String position,
    required int positionRanking,  // 1..N (1 = best)
    required int tier,             // 1..5
    required int age,
    required double teamNeed,      // 0.0-1.0
    required String teamStatus,    // retained for future use
    double? positionPercentile,    // 0-100 if available
  }) {
    // Percentiles 0..1
    final double p = _resolvePercentile(positionRanking, positionPercentile); // raw percentile
    final double pNonLinear = pow(p, 2.0).toDouble(); // harder to hit elite
    final double posPct = _positionImportancePercentile(position); // 0..1
    final double n = teamNeed.clamp(0.0, 1.0);
    final double a = _agePercent(age, position); // 0..1

    // Weights (sum = 1.0)
    const double wRank = 0.66;
    const double wPos = 0.14;
    const double wNeed = 0.12;
    const double wAge = 0.08;

    double base = 100.0 * (wRank * pNonLinear + wPos * posPct + wNeed * n + wAge * a);

    // Elite bonus for truly top players at premium positions
    base += _eliteBonusPoints(positionRanking, age, position);

    return base.clamp(0.0, 100.0);
  }

  static double _resolvePercentile(int ranking, double? percentile) {
    if (percentile != null && percentile > 0) return (percentile.clamp(0, 100)) / 100.0;
    // If unknown, approximate assuming ~100 players
    return (max(1, 101 - ranking) / 100.0).clamp(0.01, 1.0);
  }

  /// Map position to an importance percentile (0..1)
  static double _positionImportancePercentile(String position) {
    switch (position.toUpperCase()) {
      case 'QB':
        return 1.00;
      case 'EDGE':
      case 'DE':
        return 0.85;
      case 'OT':
      case 'CB':
        return 0.80;
      case 'WR':
        return 0.70;
      case 'DT':
      case 'IDL':
        return 0.60;
      case 'S':
      case 'LB':
        return 0.55;
      case 'TE':
        return 0.50;
      case 'RB':
      case 'OG':
      case 'C':
        return 0.45;
      default:
        return 0.50;
    }
  }

  /// Age percent 0..1 (1.0 at peak window for position)
  static double _agePercent(int age, String position) {
    final Map<String, List<int>> peaks = {
      'QB': [26, 33], 'RB': [22, 26], 'WR': [24, 29], 'TE': [25, 30],
      'EDGE': [24, 29], 'DE': [24, 29], 'DT': [25, 30], 'IDL': [25, 30], 'LB': [24, 29],
      'CB': [23, 28], 'S': [24, 30], 'OT': [26, 32], 'OG': [26, 32], 'C': [27, 33],
    };
    final key = position.toUpperCase();
    final p = peaks[key] ?? [24, 29];
    final start = p[0], end = p[1];

    if (age <= start) {
      // Scale from 0.7 at 22 up to just below 1.0 at start
      final delta = (age - 22).clamp(0, start - 22);
      return (0.70 + 0.03 * delta).clamp(0.70, 0.98);
    }
    if (age >= end) {
      final over = (age - end).clamp(0, 10);
      return (1.0 - 0.06 * over).clamp(0.40, 1.0);
    }
    return 1.0; // inside peak
  }

  static double _eliteBonusPoints(int ranking, int age, String position) {
    final bool ageOk = position.toUpperCase() == 'QB' ? age <= 31 : age <= 28;
    if (!ageOk) return 0.0;
    if (ranking == 1) return 5.0;
    if (ranking <= 3) return 3.0;
    if (ranking <= 5) return 2.0;
    return 0.0;
  }

  /// Detailed breakdown for UI/debug
  static Map<String, dynamic> getValueBreakdown({
    required String position,
    required int positionRanking,
    required int tier, // currently unused, reserved
    required int age,
    required double teamNeed,
    required String teamStatus,
    double? positionPercentile,
  }) {
    final double p = _resolvePercentile(positionRanking, positionPercentile);
    final double pNonLinear = pow(p, 2.0).toDouble();
    final double posPct = _positionImportancePercentile(position);
    final double n = teamNeed.clamp(0.0, 1.0);
    final double a = _agePercent(age, position);

    const double wRank = 0.66;
    const double wPos = 0.14;
    const double wNeed = 0.12;
    const double wAge = 0.08;

    final double rankPts = 100.0 * wRank * pNonLinear;
    final double posPts = 100.0 * wPos * posPct;
    final double needPts = 100.0 * wNeed * n;
    final double agePts = 100.0 * wAge * a;
    final double bonus = _eliteBonusPoints(positionRanking, age, position);
    final double base = rankPts + posPts + needPts + agePts;
    final double finalValue = (base + bonus).clamp(0.0, 100.0);

    return {
      'rank_percentile': p,
      'rank_points': rankPts,
      'position_importance': posPct,
      'position_points': posPts,
      'need': n,
      'need_points': needPts,
      'age_percent': a,
      'age_points': agePts,
      'bonus': bonus,
      'base_points': base,
      'final_value': finalValue,
    };
  }

  /// Convert trade value score to draft pick equivalent
  static String getDraftCapitalEquivalent(double tradeValue) {
    if (tradeValue >= 95) return "Two 1sts + great player";
    if (tradeValue >= 90) return "Two 1sts";
    if (tradeValue >= 80) return "Late 1st + 2nd";
    if (tradeValue >= 70) return "1st round pick";
    if (tradeValue >= 60) return "Early 2nd";
    if (tradeValue >= 50) return "2nd";
    if (tradeValue >= 40) return "3rd";
    if (tradeValue >= 30) return "4th-5th";
    return "Late round pick";
  }
}