// lib/models/nfl_trade/trade_scenario.dart

import 'nfl_player.dart';
import 'nfl_team_info.dart';

class TradeScenario {
  final NFLPlayer player;
  final NFLTeamInfo currentTeam;
  final NFLTeamInfo targetTeam;
  final TradePackage proposedPackage;
  final double fairValueScore; // 0-1, how fair the trade is
  final double likelihoodScore; // 0-1, how likely trade is to happen
  final String reasoning;
  final List<String> considerations;

  const TradeScenario({
    required this.player,
    required this.currentTeam,
    required this.targetTeam,
    required this.proposedPackage,
    required this.fairValueScore,
    required this.likelihoodScore,
    required this.reasoning,
    required this.considerations,
  });

  // Check if trade is realistic (likelihood > 0.3)
  bool get isRealistic => likelihoodScore > 0.3;

  // Check if trade is fair value (score > 0.7)
  bool get isFairValue => fairValueScore > 0.7;

  // Get overall trade grade
  TradeGrade get tradeGrade {
    double overallScore = (fairValueScore + likelihoodScore) / 2;
    if (overallScore >= 0.8) return TradeGrade.excellent;
    if (overallScore >= 0.7) return TradeGrade.good;
    if (overallScore >= 0.5) return TradeGrade.fair;
    if (overallScore >= 0.3) return TradeGrade.poor;
    return TradeGrade.unrealistic;
  }

  @override
  String toString() => '${player.name} to ${targetTeam.teamName} - ${tradeGrade.name}';
}

class TradePackage {
  final List<int> draftPicks; // pick numbers
  final List<NFLPlayer> players; // additional players
  final double totalValue; // estimated total value in millions
  final bool includesSalaryRelief; // if current team gets cap relief
  final double capSavings; // amount of cap space freed up

  const TradePackage({
    required this.draftPicks,
    required this.players,
    required this.totalValue,
    this.includesSalaryRelief = false,
    this.capSavings = 0.0,
  });

  // Check if package is draft pick heavy
  bool get isDraftHeavy => draftPicks.length >= 2;

  // Check if package includes premium picks (1st or 2nd round)
  bool get hasPremiumPicks => draftPicks.any((pick) => pick <= 64);

  // Get description of the package
  String get description {
    List<String> components = [];
    
    if (draftPicks.isNotEmpty) {
      components.add('${draftPicks.length} draft pick${draftPicks.length > 1 ? 's' : ''}');
    }
    
    if (players.isNotEmpty) {
      components.add('${players.length} player${players.length > 1 ? 's' : ''}');
    }
    
    return components.join(' + ');
  }

  @override
  String toString() => description;
}

enum TradeGrade {
  excellent,
  good,
  fair,
  poor,
  unrealistic,
}

extension TradeGradeExtension on TradeGrade {
  String get displayName => switch (this) {
    TradeGrade.excellent => 'Excellent',
    TradeGrade.good => 'Good',
    TradeGrade.fair => 'Fair',
    TradeGrade.poor => 'Poor',
    TradeGrade.unrealistic => 'Unrealistic',
  };

  String get description => switch (this) {
    TradeGrade.excellent => 'Highly realistic and fair value trade',
    TradeGrade.good => 'Realistic trade with good value',
    TradeGrade.fair => 'Possible trade but may need adjustments',
    TradeGrade.poor => 'Unlikely to be accepted as proposed',
    TradeGrade.unrealistic => 'Very unlikely to happen',
  };
}