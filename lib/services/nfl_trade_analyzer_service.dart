// lib/services/nfl_trade_analyzer_service.dart

import 'dart:math';
import '../models/nfl_trade/nfl_player.dart';
import '../models/nfl_trade/nfl_team_info.dart';
import '../models/nfl_trade/trade_scenario.dart';

class NFLTradeAnalyzerService {
  // Draft pick values (using a simplified version of your draft value system)
  static const Map<int, double> _draftPickValues = {
    // 1st round picks (in millions of value)
    1: 45.0, 2: 42.0, 3: 39.0, 4: 36.0, 5: 34.0,
    10: 28.0, 15: 22.0, 20: 18.0, 25: 15.0, 32: 12.0,
    // 2nd round picks
    33: 10.0, 40: 8.5, 50: 7.0, 64: 5.5,
    // 3rd round picks
    65: 4.5, 80: 3.5, 96: 2.8,
    // Later rounds
    97: 2.2, 128: 1.8, 160: 1.2, 200: 0.8, 250: 0.5,
  };

  /// Analyze a potential trade scenario
  static TradeScenario analyzeTradeScenario({
    required NFLPlayer player,
    required NFLTeamInfo currentTeam,
    required NFLTeamInfo targetTeam,
    required TradePackage proposedPackage,
  }) {
    // Calculate fair value score
    double fairValueScore = _calculateFairValueScore(player, proposedPackage);
    
    // Calculate likelihood score
    double likelihoodScore = _calculateLikelihoodScore(
      player, 
      currentTeam, 
      targetTeam, 
      proposedPackage
    );
    
    // Generate reasoning
    String reasoning = _generateReasoning(player, currentTeam, targetTeam, fairValueScore, likelihoodScore);
    
    // Generate considerations
    List<String> considerations = _generateConsiderations(player, currentTeam, targetTeam, proposedPackage);

    return TradeScenario(
      player: player,
      currentTeam: currentTeam,
      targetTeam: targetTeam,
      proposedPackage: proposedPackage,
      fairValueScore: fairValueScore,
      likelihoodScore: likelihoodScore,
      reasoning: reasoning,
      considerations: considerations,
    );
  }

  /// Calculate how fair the trade value is (0-1 score)
  static double _calculateFairValueScore(NFLPlayer player, TradePackage package) {
    double playerValue = player.positionAdjustedValue;
    double packageValue = package.totalValue;
    
    // Calculate the ratio of package value to player value
    double valueRatio = packageValue / playerValue;
    
    // Ideal ratio is around 1.0, score decreases as it gets further away
    if (valueRatio >= 0.9 && valueRatio <= 1.1) {
      return 1.0; // Perfect value match
    } else if (valueRatio >= 0.8 && valueRatio <= 1.2) {
      return 0.8; // Good value match
    } else if (valueRatio >= 0.7 && valueRatio <= 1.3) {
      return 0.6; // Acceptable value match
    } else if (valueRatio >= 0.6 && valueRatio <= 1.4) {
      return 0.4; // Poor value match
    } else {
      return 0.2; // Very poor value match
    }
  }

  /// Calculate how likely the trade is to happen (0-1 score)
  static double _calculateLikelihoodScore(
    NFLPlayer player, 
    NFLTeamInfo currentTeam, 
    NFLTeamInfo targetTeam, 
    TradePackage package
  ) {
    double score = 0.5; // Start with neutral

    // Current team factors (willingness to trade away)
    score += _calculateCurrentTeamWillingness(player, currentTeam, package);
    
    // Target team factors (willingness to acquire)
    score += _calculateTargetTeamWillingness(player, targetTeam, package);
    
    // Position and contract factors
    score += _calculatePlayerFactors(player);
    
    // Cap space considerations
    score += _calculateCapSpaceFactors(player, currentTeam, targetTeam);
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate current team's willingness to trade the player away
  static double _calculateCurrentTeamWillingness(NFLPlayer player, NFLTeamInfo currentTeam, TradePackage package) {
    double willingness = 0.0;
    
    // Cap space pressure
    if (currentTeam.isCapStrapped && player.annualSalary > 15.0) {
      willingness += 0.2; // More likely to trade expensive players when cap strapped
    }
    
    // Age factors
    switch (player.ageTier) {
      case 'aging':
        willingness += 0.15; // More willing to trade aging players
        break;
      case 'veteran':
        if (currentTeam.status == TeamStatus.rebuilding) {
          willingness += 0.1; // Rebuilding teams trade veterans
        }
        break;
      case 'prime':
        willingness -= 0.1; // Less likely to trade prime players
        break;
      case 'young':
        willingness -= 0.15; // Keep young talent
        break;
    }
    
    // Package value - better packages make teams more willing
    if (package.hasPremiumPicks) {
      willingness += 0.1;
    }
    
    // Team philosophy
    switch (currentTeam.philosophy) {
      case TeamPhilosophy.buildThroughDraft:
        if (package.isDraftHeavy) willingness += 0.1;
        break;
      case TeamPhilosophy.analytics:
        // More likely to trade if getting good value
        double valueRatio = package.totalValue / player.positionAdjustedValue;
        if (valueRatio > 1.1) willingness += 0.15;
        break;
      default:
        break;
    }
    
    return willingness;
  }

  /// Calculate target team's willingness to acquire the player
  static double _calculateTargetTeamWillingness(NFLPlayer player, NFLTeamInfo targetTeam, TradePackage package) {
    double willingness = 0.0;
    
    // Position need
    double needLevel = targetTeam.getNeedLevel(player.positionGroup);
    willingness += needLevel * 0.25; // Up to 0.25 boost for high need
    
    // Cap space availability
    if (targetTeam.hasCapSpace && player.annualSalary <= targetTeam.availableCapSpace * 0.3) {
      willingness += 0.1; // Can afford the player
    } else if (player.annualSalary > targetTeam.availableCapSpace) {
      willingness -= 0.2; // Cannot afford the player
    }
    
    // Team status alignment
    switch (targetTeam.status) {
      case TeamStatus.winNow:
        if (player.ageTier == 'prime' || player.ageTier == 'veteran') {
          willingness += 0.15; // Win-now teams want proven players
        }
        break;
      case TeamStatus.contending:
        if (player.isPremiumPosition) {
          willingness += 0.1; // Contenders want premium position players
        }
        break;
      case TeamStatus.rebuilding:
        if (player.ageTier == 'young') {
          willingness += 0.1; // Rebuilding teams want young players
        } else {
          willingness -= 0.1; // Don't want aging players
        }
        break;
      default:
        break;
    }
    
    // Trading aggressiveness
    willingness += (targetTeam.tradeAggressiveness - 0.5) * 0.2; // -0.1 to +0.1
    
    return willingness;
  }

  /// Calculate player-specific factors
  static double _calculatePlayerFactors(NFLPlayer player) {
    double score = 0.0;
    
    // Premium positions are more likely to be traded
    if (player.isPremiumPosition) {
      score += 0.05;
    }
    
    // Contract situation
    switch (player.contractStatus) {
      case 'franchise':
        score -= 0.1; // Franchise tag makes trades less likely
        break;
      case 'free agent':
        score -= 0.2; // Can't trade free agents
        break;
      case 'rookie':
        if (player.positionRank > 80) {
          score += 0.05; // Trade disappointing rookies
        } else {
          score -= 0.1; // Keep good rookies
        }
        break;
      default:
        break;
    }
    
    // Injury concerns
    if (player.hasInjuryConcerns) {
      score -= 0.1;
    }
    
    // Contract years remaining
    if (player.contractYearsRemaining <= 1) {
      score += 0.1; // More likely to trade players in final year
    }
    
    return score;
  }

  /// Calculate cap space factors
  static double _calculateCapSpaceFactors(NFLPlayer player, NFLTeamInfo currentTeam, NFLTeamInfo targetTeam) {
    double score = 0.0;
    
    // If current team gets cap relief, they're more willing
    if (currentTeam.isCapStrapped && player.annualSalary > 10.0) {
      score += 0.1;
    }
    
    // If target team can easily afford player, they're more willing
    if (targetTeam.availableCapSpace > player.annualSalary * 2) {
      score += 0.1;
    }
    
    return score;
  }

  /// Generate reasoning for the trade likelihood
  static String _generateReasoning(
    NFLPlayer player, 
    NFLTeamInfo currentTeam, 
    NFLTeamInfo targetTeam, 
    double fairValueScore, 
    double likelihoodScore
  ) {
    List<String> reasons = [];
    
    // Value assessment
    if (fairValueScore >= 0.8) {
      reasons.add("Trade offers excellent value");
    } else if (fairValueScore >= 0.6) {
      reasons.add("Trade offers reasonable value");
    } else {
      reasons.add("Trade value is questionable");
    }
    
    // Position need
    double needLevel = targetTeam.getNeedLevel(player.positionGroup);
    if (needLevel >= 0.8) {
      reasons.add("${targetTeam.teamName} has critical need at ${player.position}");
    } else if (needLevel >= 0.5) {
      reasons.add("${targetTeam.teamName} could use help at ${player.position}");
    }
    
    // Cap situation
    if (currentTeam.isCapStrapped && player.annualSalary > 15.0) {
      reasons.add("${currentTeam.teamName} needs cap relief");
    }
    
    // Age/contract factors
    if (player.ageTier == 'aging' && currentTeam.status == TeamStatus.rebuilding) {
      reasons.add("${currentTeam.teamName} likely willing to move aging veterans");
    }
    
    return reasons.join(". ");
  }

  /// Generate trade considerations
  static List<String> _generateConsiderations(
    NFLPlayer player, 
    NFLTeamInfo currentTeam, 
    NFLTeamInfo targetTeam, 
    TradePackage package
  ) {
    List<String> considerations = [];
    
    // Cap space warnings
    if (player.annualSalary > targetTeam.availableCapSpace * 0.5) {
      considerations.add("⚠️ Player salary would use ${((player.annualSalary / targetTeam.availableCapSpace) * 100).round()}% of available cap space");
    }
    
    // Premium position notes
    if (player.isPremiumPosition) {
      considerations.add("💎 Premium position player - teams typically demand high compensation");
    }
    
    // Age curve warnings
    if (player.age >= 30 && player.position == 'RB') {
      considerations.add("📉 Running backs over 30 have steep decline risk");
    }
    
    // Contract situation
    if (player.contractYearsRemaining <= 1) {
      considerations.add("⏰ Player entering final contract year - may seek extension");
    }
    
    // Draft capital impact
    if (package.draftPicks.any((pick) => pick <= 32)) {
      considerations.add("🏈 Trading away first-round pick(s) - significant future asset cost");
    }
    
    // Team building philosophy misalignment
    if (targetTeam.status == TeamStatus.rebuilding && player.ageTier == 'aging') {
      considerations.add("🔧 Player age doesn't align with rebuilding timeline");
    }
    
    return considerations;
  }

  /// Get estimated value for a draft pick
  static double getDraftPickValue(int pickNumber) {
    // Find the closest pick number in our values map
    int closestPick = _draftPickValues.keys.reduce((a, b) => 
      (pickNumber - a).abs() < (pickNumber - b).abs() ? a : b
    );
    
    double baseValue = _draftPickValues[closestPick]!;
    
    // Adjust based on actual pick number vs closest
    if (pickNumber != closestPick) {
      double adjustment = (closestPick - pickNumber) * 0.5;
      baseValue += adjustment;
    }
    
    return max(0.5, baseValue); // Minimum value of $0.5M
  }

  /// Generate multiple trade scenarios for a player
  static List<TradeScenario> generateTradeScenarios(
    NFLPlayer player, 
    NFLTeamInfo currentTeam, 
    List<NFLTeamInfo> potentialTargets
  ) {
    List<TradeScenario> scenarios = [];
    
    for (NFLTeamInfo targetTeam in potentialTargets) {
      // Skip if same team
      if (targetTeam.teamName == currentTeam.teamName) continue;
      
      // Generate different package options
      List<TradePackage> packages = _generateTradePackages(player, targetTeam);
      
      for (TradePackage package in packages) {
        TradeScenario scenario = analyzeTradeScenario(
          player: player,
          currentTeam: currentTeam,
          targetTeam: targetTeam,
          proposedPackage: package,
        );
        scenarios.add(scenario);
      }
    }
    
    // Sort by likelihood score (best scenarios first)
    scenarios.sort((a, b) => b.likelihoodScore.compareTo(a.likelihoodScore));
    
    return scenarios;
  }

  /// Generate realistic trade packages for a player
  static List<TradePackage> _generateTradePackages(NFLPlayer player, NFLTeamInfo targetTeam) {
    List<TradePackage> packages = [];
    double playerValue = player.positionAdjustedValue;
    
    // Package 1: Draft pick heavy (2-3 picks)
    List<int> availablePicks = List.from(targetTeam.availableDraftPicks);
    if (availablePicks.isNotEmpty) {
      availablePicks.sort(); // Sort by pick number (best picks first)
      
      // Try 2-pick package
      if (availablePicks.length >= 2) {
        double pickValue = getDraftPickValue(availablePicks[0]) + getDraftPickValue(availablePicks[1]);
        packages.add(TradePackage(
          draftPicks: availablePicks.take(2).toList(),
          players: [],
          totalValue: pickValue,
        ));
      }
      
      // Try 3-pick package if player is very valuable
      if (availablePicks.length >= 3 && playerValue > 25.0) {
        double pickValue = getDraftPickValue(availablePicks[0]) + 
                          getDraftPickValue(availablePicks[1]) + 
                          getDraftPickValue(availablePicks[2]);
        packages.add(TradePackage(
          draftPicks: availablePicks.take(3).toList(),
          players: [],
          totalValue: pickValue,
        ));
      }
    }
    
    // Package 2: Premium pick + future consideration
    var premiumPicks = availablePicks.where((pick) => pick <= 64).toList();
    if (premiumPicks.isNotEmpty) {
      double pickValue = getDraftPickValue(premiumPicks[0]) + 5.0; // +$5M for future pick
      packages.add(TradePackage(
        draftPicks: [premiumPicks[0]],
        players: [],
        totalValue: pickValue,
      ));
    }
    
    return packages;
  }
}