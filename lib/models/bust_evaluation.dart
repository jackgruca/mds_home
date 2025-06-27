// lib/models/bust_evaluation.dart
class BustEvaluationPlayer {
  final String gsisId;
  final String playerName;
  final String position;
  final String team;
  final int draftRound;
  final int rookieYear;
  final int leagueYear;
  final int seasonsPlayed;
  
  // Career stats (actual)
  final double careerRecYds;
  final double careerTargets;
  final double careerReceptions;
  final double careerRecTd;
  final double careerCarries;
  final double careerRushYds;
  final double careerRushTd;
  final double careerAttempts;
  final double careerPassYds;
  final double careerPassTd;
  final double careerInt;
  final double careerFumbles;
  
  // Expected career stats (peer averages)
  final double expectedRecYds;
  final double expectedTargets;
  final double expectedReceptions;
  final double expectedRecTd;
  final double expectedCarries;
  final double expectedRushYds;
  final double expectedRushTd;
  final double expectedAttempts;
  final double expectedPassYds;
  final double expectedPassTd;
  final double expectedInt;
  final double expectedFumbles;
  
  // Performance ratios
  final double? recYdsRatio;
  final double? targetsRatio;
  final double? receptionsRatio;
  final double? recTdRatio;
  final double? carriesRatio;
  final double? rushYdsRatio;
  final double? rushTdRatio;
  final double? attemptsRatio;
  final double? passYdsRatio;
  final double? passTdRatio;
  final double? intRatio;
  final double? fumblesRatio;
  
  final double? performanceScore;
  final String bustCategory;

  BustEvaluationPlayer({
    required this.gsisId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.draftRound,
    required this.rookieYear,
    required this.leagueYear,
    required this.seasonsPlayed,
    required this.careerRecYds,
    required this.careerTargets,
    required this.careerReceptions,
    required this.careerRecTd,
    required this.careerCarries,
    required this.careerRushYds,
    required this.careerRushTd,
    required this.careerAttempts,
    required this.careerPassYds,
    required this.careerPassTd,
    required this.careerInt,
    required this.careerFumbles,
    required this.expectedRecYds,
    required this.expectedTargets,
    required this.expectedReceptions,
    required this.expectedRecTd,
    required this.expectedCarries,
    required this.expectedRushYds,
    required this.expectedRushTd,
    required this.expectedAttempts,
    required this.expectedPassYds,
    required this.expectedPassTd,
    required this.expectedInt,
    required this.expectedFumbles,
    this.recYdsRatio,
    this.targetsRatio,
    this.receptionsRatio,
    this.recTdRatio,
    this.carriesRatio,
    this.rushYdsRatio,
    this.rushTdRatio,
    this.attemptsRatio,
    this.passYdsRatio,
    this.passTdRatio,
    this.intRatio,
    this.fumblesRatio,
    this.performanceScore,
    required this.bustCategory,
  });

  factory BustEvaluationPlayer.fromMap(Map<String, dynamic> map) {
    return BustEvaluationPlayer(
      gsisId: map['gsis_id'] ?? '',
      playerName: map['player_name'] ?? '',
      position: map['position'] ?? '',
      team: map['team'] ?? '',
      draftRound: (map['draft_round'] ?? 0).toInt(),
      rookieYear: (map['rookie_year'] ?? 0).toInt(),
      leagueYear: (map['league_year'] ?? 0).toInt(),
      seasonsPlayed: (map['seasons_played'] ?? 0).toInt(),
      careerRecYds: (map['career_rec_yds'] ?? 0).toDouble(),
      careerTargets: (map['career_targets'] ?? 0).toDouble(),
      careerReceptions: (map['career_receptions'] ?? 0).toDouble(),
      careerRecTd: (map['career_rec_td'] ?? 0).toDouble(),
      careerCarries: (map['career_carries'] ?? 0).toDouble(),
      careerRushYds: (map['career_rush_yds'] ?? 0).toDouble(),
      careerRushTd: (map['career_rush_td'] ?? 0).toDouble(),
      careerAttempts: (map['career_attempts'] ?? 0).toDouble(),
      careerPassYds: (map['career_pass_yds'] ?? 0).toDouble(),
      careerPassTd: (map['career_pass_td'] ?? 0).toDouble(),
      careerInt: (map['career_int'] ?? 0).toDouble(),
      careerFumbles: (map['career_fumbles'] ?? 0).toDouble(),
      expectedRecYds: (map['expected_rec_yds'] ?? 0).toDouble(),
      expectedTargets: (map['expected_targets'] ?? 0).toDouble(),
      expectedReceptions: (map['expected_receptions'] ?? 0).toDouble(),
      expectedRecTd: (map['expected_rec_td'] ?? 0).toDouble(),
      expectedCarries: (map['expected_carries'] ?? 0).toDouble(),
      expectedRushYds: (map['expected_rush_yds'] ?? 0).toDouble(),
      expectedRushTd: (map['expected_rush_td'] ?? 0).toDouble(),
      expectedAttempts: (map['expected_attempts'] ?? 0).toDouble(),
      expectedPassYds: (map['expected_pass_yds'] ?? 0).toDouble(),
      expectedPassTd: (map['expected_pass_td'] ?? 0).toDouble(),
      expectedInt: (map['expected_int'] ?? 0).toDouble(),
      expectedFumbles: (map['expected_fumbles'] ?? 0).toDouble(),
      recYdsRatio: map['rec_yds_ratio']?.toDouble(),
      targetsRatio: map['targets_ratio']?.toDouble(),
      receptionsRatio: map['receptions_ratio']?.toDouble(),
      recTdRatio: map['rec_td_ratio']?.toDouble(),
      carriesRatio: map['carries_ratio']?.toDouble(),
      rushYdsRatio: map['rush_yds_ratio']?.toDouble(),
      rushTdRatio: map['rush_td_ratio']?.toDouble(),
      attemptsRatio: map['attempts_ratio']?.toDouble(),
      passYdsRatio: map['pass_yds_ratio']?.toDouble(),
      passTdRatio: map['pass_td_ratio']?.toDouble(),
      intRatio: map['int_ratio']?.toDouble(),
      fumblesRatio: map['fumbles_ratio']?.toDouble(),
      performanceScore: map['performance_score']?.toDouble(),
      bustCategory: map['bust_category'] ?? 'Insufficient Data',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gsis_id': gsisId,
      'player_name': playerName,
      'position': position,
      'team': team,
      'draft_round': draftRound,
      'rookie_year': rookieYear,
      'league_year': leagueYear,
      'seasons_played': seasonsPlayed,
      'career_rec_yds': careerRecYds,
      'career_targets': careerTargets,
      'career_receptions': careerReceptions,
      'career_rec_td': careerRecTd,
      'career_carries': careerCarries,
      'career_rush_yds': careerRushYds,
      'career_rush_td': careerRushTd,
      'career_attempts': careerAttempts,
      'career_pass_yds': careerPassYds,
      'career_pass_td': careerPassTd,
      'career_int': careerInt,
      'career_fumbles': careerFumbles,
      'expected_rec_yds': expectedRecYds,
      'expected_targets': expectedTargets,
      'expected_receptions': expectedReceptions,
      'expected_rec_td': expectedRecTd,
      'expected_carries': expectedCarries,
      'expected_rush_yds': expectedRushYds,
      'expected_rush_td': expectedRushTd,
      'expected_attempts': expectedAttempts,
      'expected_pass_yds': expectedPassYds,
      'expected_pass_td': expectedPassTd,
      'expected_int': expectedInt,
      'expected_fumbles': expectedFumbles,
      'rec_yds_ratio': recYdsRatio,
      'targets_ratio': targetsRatio,
      'receptions_ratio': receptionsRatio,
      'rec_td_ratio': recTdRatio,
      'carries_ratio': carriesRatio,
      'rush_yds_ratio': rushYdsRatio,
      'rush_td_ratio': rushTdRatio,
      'attempts_ratio': attemptsRatio,
      'pass_yds_ratio': passYdsRatio,
      'pass_td_ratio': passTdRatio,
      'int_ratio': intRatio,
      'fumbles_ratio': fumblesRatio,
      'performance_score': performanceScore,
      'bust_category': bustCategory,
    };
  }

  // Helper methods for display
  String get draftRoundDisplay => 'Round $draftRound';
  
  String get careerSpanDisplay => '$rookieYear-${rookieYear + seasonsPlayed - 1}';
  
  String get peerDescription => 'Compared to ${position}s drafted in Round $draftRound (${rookieYear - 15}-${rookieYear + 5})';
  
  String get expectationSource => 'Expected stats based on $seasonsPlayed-season averages of similar draft picks';
  
  String get performanceSummary {
    if (performanceScore == null) return 'Insufficient data for evaluation';
    
    final score = performanceScore! * 100;
    switch (bustCategory) {
      case 'Steal':
        return 'Significantly outperformed expectations (${score.toStringAsFixed(0)}% of expected)';
      case 'Met Expectations':
        return 'Performed close to expectations (${score.toStringAsFixed(0)}% of expected)';
      case 'Disappointing':
        return 'Underperformed expectations (${score.toStringAsFixed(0)}% of expected)';
      case 'Bust':
        return 'Significantly underperformed expectations (${score.toStringAsFixed(0)}% of expected)';
      default:
        return 'Performance evaluation pending';
    }
  }
  
  List<String> getSimilarPlayerExamples() {
    switch (position) {
      case 'WR':
        if (draftRound <= 2) {
          return ['DeAndre Hopkins (R1)', 'Keenan Allen (R3)', 'Michael Thomas (R2)'];
        } else {
          return ['Julian Edelman (R7)', 'Antonio Brown (R6)', 'Tyreek Hill (R5)'];
        }
      case 'RB':
        if (draftRound <= 2) {
          return ['Derrick Henry (R2)', 'Alvin Kamara (R3)', 'Nick Chubb (R2)'];
        } else {
          return ['Phillip Lindsay (UDFA)', 'James Robinson (UDFA)', 'Austin Ekeler (UDFA)'];
        }
      case 'TE':
        if (draftRound <= 2) {
          return ['T.J. Hockenson (R1)', 'Evan Engram (R1)', 'Noah Fant (R1)'];
        } else {
          return ['Travis Kelce (R3)', 'George Kittle (R5)', 'Mark Andrews (R3)'];
        }
      case 'QB':
        if (draftRound <= 2) {
          return ['Josh Allen (R1)', 'Lamar Jackson (R1)', 'Dak Prescott (R4)'];
        } else {
          return ['Tom Brady (R6)', 'Russell Wilson (R3)', 'Kirk Cousins (R4)'];
        }
      default:
        return [];
    }
  }

  String get bustEmoji {
    switch (bustCategory) {
      case 'Steal':
        return '🔥';
      case 'Met Expectations':
        return '✅';
      case 'Disappointing':
        return '⚠️';
      case 'Bust':
        return '💀';
      default:
        return '❓';
    }
  }

  // Get primary stats based on position - split into left and right sections for QB/RB
  List<BustStatComparison> getPrimaryStats() {
    return getLeftSideStats() + getRightSideStats();
  }

  // Get left side stats for position
  List<BustStatComparison> getLeftSideStats() {
    switch (position) {
      case 'QB':
        return [
          BustStatComparison(
            label: 'Passing Yards',
            actual: careerPassYds,
            expected: expectedPassYds,
            ratio: passYdsRatio,
          ),
          BustStatComparison(
            label: 'Passing TDs',
            actual: careerPassTd,
            expected: expectedPassTd,
            ratio: passTdRatio,
          ),
          BustStatComparison(
            label: 'Interceptions',
            actual: careerInt,
            expected: expectedInt,
            ratio: intRatio,
            isLowerBetter: true, // Less is better for INTs
          ),
          BustStatComparison(
            label: 'Pass Attempts',
            actual: careerAttempts,
            expected: expectedAttempts,
            ratio: attemptsRatio,
          ),
        ];
      case 'RB':
        return [
          BustStatComparison(
            label: 'Rushing Yards',
            actual: careerRushYds,
            expected: expectedRushYds,
            ratio: rushYdsRatio,
          ),
          BustStatComparison(
            label: 'Rushing TDs',
            actual: careerRushTd,
            expected: expectedRushTd,
            ratio: rushTdRatio,
          ),
          BustStatComparison(
            label: 'Carries',
            actual: careerCarries,
            expected: expectedCarries,
            ratio: carriesRatio,
          ),
          BustStatComparison(
            label: 'Fumbles',
            actual: careerFumbles,
            expected: expectedFumbles,
            ratio: fumblesRatio,
            isLowerBetter: true, // Less is better for fumbles
          ),
        ];
      case 'WR':
      case 'TE':
        return [
          BustStatComparison(
            label: 'Receiving Yards',
            actual: careerRecYds,
            expected: expectedRecYds,
            ratio: recYdsRatio,
          ),
          BustStatComparison(
            label: 'Receptions',
            actual: careerReceptions,
            expected: expectedReceptions,
            ratio: receptionsRatio,
          ),
          BustStatComparison(
            label: 'Receiving TDs',
            actual: careerRecTd,
            expected: expectedRecTd,
            ratio: recTdRatio,
          ),
          BustStatComparison(
            label: 'Targets',
            actual: careerTargets,
            expected: expectedTargets,
            ratio: targetsRatio,
          ),
        ];
      default:
        return [];
    }
  }

  // Get right side stats for position
  List<BustStatComparison> getRightSideStats() {
    switch (position) {
      case 'QB':
        return [
          BustStatComparison(
            label: 'Rushing Yards',
            actual: careerRushYds,
            expected: expectedRushYds,
            ratio: rushYdsRatio,
          ),
          BustStatComparison(
            label: 'Rushing TDs',
            actual: careerRushTd,
            expected: expectedRushTd,
            ratio: rushTdRatio,
          ),
          BustStatComparison(
            label: 'Rush Attempts',
            actual: careerCarries,
            expected: expectedCarries,
            ratio: carriesRatio,
          ),
          BustStatComparison(
            label: 'Fumbles',
            actual: careerFumbles,
            expected: expectedFumbles,
            ratio: fumblesRatio,
            isLowerBetter: true, // Less is better for fumbles
          ),
        ];
      case 'RB':
        return [
          BustStatComparison(
            label: 'Receiving Yards',
            actual: careerRecYds,
            expected: expectedRecYds,
            ratio: recYdsRatio,
          ),
          BustStatComparison(
            label: 'Receptions',
            actual: careerReceptions,
            expected: expectedReceptions,
            ratio: receptionsRatio,
          ),
          BustStatComparison(
            label: 'Receiving TDs',
            actual: careerRecTd,
            expected: expectedRecTd,
            ratio: recTdRatio,
          ),
          BustStatComparison(
            label: 'Targets',
            actual: careerTargets,
            expected: expectedTargets,
            ratio: targetsRatio,
          ),
        ];
      case 'WR':
      case 'TE':
        return []; // No right side for WR/TE
      default:
        return [];
    }
  }

  // Validation method to check if calculations are correct
  Map<String, dynamic> validateCalculations() {
    final issues = <String>[];
    final calculations = <String, Map<String, double>>{};
    
    // Check receiving yards ratio
    if (expectedRecYds > 0) {
      final calculated = careerRecYds / expectedRecYds;
      final stored = recYdsRatio ?? 0;
      calculations['recYdsRatio'] = {'calculated': calculated, 'stored': stored};
      if ((calculated - stored).abs() > 0.01) {
        issues.add('Receiving yards ratio mismatch: calculated $calculated vs stored $stored');
      }
    }
    
    // Check receptions ratio
    if (expectedReceptions > 0) {
      final calculated = careerReceptions / expectedReceptions;
      final stored = receptionsRatio ?? 0;
      calculations['receptionsRatio'] = {'calculated': calculated, 'stored': stored};
      if ((calculated - stored).abs() > 0.01) {
        issues.add('Receptions ratio mismatch: calculated $calculated vs stored $stored');
      }
    }
    
    // Check receiving TDs ratio
    if (expectedRecTd > 0) {
      final calculated = careerRecTd / expectedRecTd;
      final stored = recTdRatio ?? 0;
      calculations['recTdRatio'] = {'calculated': calculated, 'stored': stored};
      if ((calculated - stored).abs() > 0.01) {
        issues.add('Receiving TDs ratio mismatch: calculated $calculated vs stored $stored');
      }
    }
    
    // Check targets ratio
    if (expectedTargets > 0) {
      final calculated = careerTargets / expectedTargets;
      final stored = targetsRatio ?? 0;
      calculations['targetsRatio'] = {'calculated': calculated, 'stored': stored};
      if ((calculated - stored).abs() > 0.01) {
        issues.add('Targets ratio mismatch: calculated $calculated vs stored $stored');
      }
    }
    
    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'calculations': calculations,
    };
  }
}

class BustStatComparison {
  final String label;
  final double actual;
  final double expected;
  final double? ratio;
  final bool isLowerBetter;

  BustStatComparison({
    required this.label,
    required this.actual,
    required this.expected,
    this.ratio,
    this.isLowerBetter = false,
  });

  double get percentage => ratio != null ? (ratio! * 100) : 0;
  
  String get percentageDisplay => '${percentage.toStringAsFixed(0)}%';
  
  bool get isOverPerforming => isLowerBetter ? (ratio ?? 1) < 1 : (ratio ?? 1) > 1;
  
  bool get isSignificantlyOver => isLowerBetter ? (ratio ?? 1) < 0.8 : (ratio ?? 1) > 1.2;
  
  bool get isSignificantlyUnder => isLowerBetter ? (ratio ?? 1) > 1.2 : (ratio ?? 1) < 0.8;
}

class BustTimelineData {
  final String gsisId;
  final String playerName;
  final String position;
  final int leagueYear;
  final int seasonsPlayed;
  final double? performanceScore;
  final String bustCategory;

  BustTimelineData({
    required this.gsisId,
    required this.playerName,
    required this.position,
    required this.leagueYear,
    required this.seasonsPlayed,
    this.performanceScore,
    required this.bustCategory,
  });

  factory BustTimelineData.fromMap(Map<String, dynamic> map) {
    return BustTimelineData(
      gsisId: map['gsis_id'] ?? '',
      playerName: map['player_name'] ?? '',
      position: map['position'] ?? '',
      leagueYear: (map['league_year'] ?? 0).toInt(),
      seasonsPlayed: (map['seasons_played'] ?? 0).toInt(),
      performanceScore: map['performance_score']?.toDouble(),
      bustCategory: map['bust_category'] ?? 'Insufficient Data',
    );
  }
} 