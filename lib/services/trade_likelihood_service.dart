// lib/services/trade_likelihood_service.dart

import '../models/nfl_trade/nfl_team_info.dart';
import '../models/nfl_trade/trade_asset.dart';
import 'trade_valuation_service.dart';

class TradeLikelihoodResult {
  final double likelihood;
  final String category;
  final String description;
  final List<String> factors;
  final List<String> suggestions;

  const TradeLikelihoodResult({
    required this.likelihood,
    required this.category,
    required this.description,
    required this.factors,
    required this.suggestions,
  });
}

class TradeImpact {
  final double capImpact;
  final bool exceedsCapSpace;
  final bool requiresRestructuring;
  final List<String> capWarnings;

  const TradeImpact({
    required this.capImpact,
    required this.exceedsCapSpace,
    required this.requiresRestructuring,
    required this.capWarnings,
  });
}

class TradeLikelihoodService {
  
  /// Analyze complete trade scenario and return likelihood
  static Future<TradeLikelihoodResult> analyzeTrade({
    required NFLTeamInfo team1,
    required NFLTeamInfo team2,
    required TeamTradePackage team1Package,
    required TeamTradePackage team2Package,
  }) async {
    
    // Step 1: Calculate trade balance
    double tradeBalance = await TradeValuationService.calculateTradeBalance(team1Package, team2Package);
    
    // Step 2: Analyze cap impact
    TradeImpact team1CapImpact = _analyzeCapImpact(team1, team1Package, team2Package);
    TradeImpact team2CapImpact = _analyzeCapImpact(team2, team2Package, team1Package);
    
    // Step 3: Calculate likelihood components
    double valueLikelihood = _calculateValueLikelihood(tradeBalance);
    double capLikelihood = _calculateCapLikelihood(team1CapImpact, team2CapImpact);
    double philosophyLikelihood = _calculatePhilosophyLikelihood(team1, team2, team1Package, team2Package);
    double needsLikelihood = _calculateNeedsLikelihood(team1, team2, team1Package, team2Package);
    
    // Step 4: Combine factors with weights
    double overallLikelihood = (
      valueLikelihood * 0.4 +        // Value is king
      needsLikelihood * 0.25 +       // Team needs important
      philosophyLikelihood * 0.2 +   // Team philosophy matters
      capLikelihood * 0.15           // Cap space constraints
    ).clamp(0.0, 1.0);
    
    // Step 5: Generate feedback and suggestions
    String category = _getLikelihoodCategory(overallLikelihood);
    String description = _getLikelihoodDescription(overallLikelihood);
    List<String> factors = _generateFactors(valueLikelihood, needsLikelihood, philosophyLikelihood, capLikelihood);
    List<String> suggestions = _generateSuggestions(
      tradeBalance, team1CapImpact, team2CapImpact, team1, team2, team1Package, team2Package
    );
    
    return TradeLikelihoodResult(
      likelihood: overallLikelihood,
      category: category,
      description: description,
      factors: factors,
      suggestions: suggestions,
    );
  }
  
  /// Calculate likelihood based on trade value balance
  static double _calculateValueLikelihood(double tradeBalance) {
    // Perfect balance = 1.0 likelihood
    // Further from balance = lower likelihood
    double deviation = (tradeBalance - 1.0).abs();
    
    if (deviation <= 0.1) return 1.0;   // Within 10% = perfect
    if (deviation <= 0.2) return 0.8;   // Within 20% = good
    if (deviation <= 0.3) return 0.6;   // Within 30% = acceptable
    if (deviation <= 0.5) return 0.3;   // Within 50% = poor
    return 0.1; // Beyond 50% = very unlikely
  }
  
  /// Calculate cap space likelihood
  static double _calculateCapLikelihood(TradeImpact team1Impact, TradeImpact team2Impact) {
    // Hard blocks for teams way over cap
    if (team1Impact.exceedsCapSpace || team2Impact.exceedsCapSpace) {
      return 0.1; // Nearly impossible
    }
    
    // Warnings for teams requiring restructuring
    if (team1Impact.requiresRestructuring || team2Impact.requiresRestructuring) {
      return 0.6; // Possible but difficult
    }
    
    return 1.0; // No cap issues
  }
  
  /// Calculate philosophy likelihood (team building approach)
  static double _calculatePhilosophyLikelihood(
    NFLTeamInfo team1, NFLTeamInfo team2,
    TeamTradePackage team1Package, TeamTradePackage team2Package
  ) {
    double team1Score = _getTeamPhilosophyScore(team1, team2Package);
    double team2Score = _getTeamPhilosophyScore(team2, team1Package);
    
    return (team1Score + team2Score) / 2.0;
  }
  
  /// Get philosophy score for a team receiving a package
  static double _getTeamPhilosophyScore(NFLTeamInfo team, TeamTradePackage incomingPackage) {
    bool hasPlayers = incomingPackage.assets.any((asset) => asset is PlayerAsset);
    bool hasPicks = incomingPackage.assets.any((asset) => asset is DraftPickAsset);
    
    switch (team.philosophy) {
      case TeamPhilosophy.winNow:
        // Win-now teams prefer proven players
        return hasPlayers ? 0.9 : 0.4;
        
      case TeamPhilosophy.buildThroughDraft:
        // Build through draft teams prefer picks and young players  
        if (hasPicks) return 0.9;
        if (hasPlayers) {
          // Check if incoming players are young
          bool hasYoungPlayers = incomingPackage.assets
              .whereType<PlayerAsset>()
              .any((asset) => asset.player.age <= 26);
          return hasYoungPlayers ? 0.8 : 0.3;
        }
        return 0.5;
        
      case TeamPhilosophy.balanced:
        // Balanced teams consider both
        return 0.7;
        
      case TeamPhilosophy.analytics:
        // Analytics teams focus on pure value
        return 0.8;
        
      case TeamPhilosophy.aggressive:
        // Aggressive teams willing to make big moves
        return 0.8;
        
      case TeamPhilosophy.rebuild:
        // Rebuilding teams prefer picks and young players
        if (hasPicks) return 0.9;
        if (hasPlayers) {
          // Check if incoming players are young
          bool hasYoungPlayers = incomingPackage.assets
              .whereType<PlayerAsset>()
              .any((asset) => asset.player.age <= 26);
          return hasYoungPlayers ? 0.8 : 0.3;
        }
        return 0.5;
    }
  }
  
  /// Calculate needs-based likelihood
  static double _calculateNeedsLikelihood(
    NFLTeamInfo team1, NFLTeamInfo team2,
    TeamTradePackage team1Package, TeamTradePackage team2Package
  ) {
    double team1NeedsScore = _calculateTeamNeedsScore(team1, team2Package);
    double team2NeedsScore = _calculateTeamNeedsScore(team2, team1Package);
    
    return (team1NeedsScore + team2NeedsScore) / 2.0;
  }
  
  /// Calculate how well incoming package addresses team needs
  static double _calculateTeamNeedsScore(NFLTeamInfo team, TeamTradePackage incomingPackage) {
    if (incomingPackage.assets.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int playerCount = 0;
    
    for (TradeAsset asset in incomingPackage.assets) {
      if (asset is PlayerAsset) {
        String position = asset.player.position;
        double needLevel = team.positionNeeds[position] ?? 0.5;
        totalScore += needLevel;
        playerCount++;
      }
      // Draft picks are flexible and can address any need
      if (asset is DraftPickAsset) {
        totalScore += 0.7; // Picks are reasonably valuable for any team
        playerCount++;
      }
    }
    
    return playerCount > 0 ? totalScore / playerCount : 0.0;
  }
  
  /// Analyze cap space impact of trade
  static TradeImpact _analyzeCapImpact(
    NFLTeamInfo team,
    TeamTradePackage outgoingPackage,
    TeamTradePackage incomingPackage
  ) {
    double outgoingSalary = _calculatePackageSalary(outgoingPackage);
    double incomingSalary = _calculatePackageSalary(incomingPackage);
    double netCapImpact = incomingSalary - outgoingSalary;
    
    double availableCapSpace = team.availableCapSpace;
    double newCapSpace = availableCapSpace - netCapImpact;
    
    bool exceedsCapSpace = newCapSpace < -10.0; // Hard limit: $10M over
    bool requiresRestructuring = newCapSpace < 0 && newCapSpace >= -10.0; // Soft warning
    
    List<String> warnings = [];
    if (exceedsCapSpace) {
      warnings.add('${team.teamName} would exceed cap space by \$${(-newCapSpace).toStringAsFixed(1)}M');
    } else if (requiresRestructuring) {
      warnings.add('${team.teamName} would need to restructure contracts to create \$${(-newCapSpace).toStringAsFixed(1)}M');
    }
    
    return TradeImpact(
      capImpact: netCapImpact,
      exceedsCapSpace: exceedsCapSpace,
      requiresRestructuring: requiresRestructuring,
      capWarnings: warnings,
    );
  }
  
  /// Calculate salary impact of a trade package
  static double _calculatePackageSalary(TeamTradePackage package) {
    double totalSalary = 0.0;
    
    for (TradeAsset asset in package.assets) {
      if (asset is PlayerAsset) {
        totalSalary += asset.player.annualSalary;
      }
      // Draft picks don't have salary impact in year 1
    }
    
    return totalSalary;
  }
  
  /// Get likelihood category
  static String _getLikelihoodCategory(double likelihood) {
    if (likelihood >= 0.8) return 'Highly Likely';
    if (likelihood >= 0.6) return 'Likely';
    if (likelihood >= 0.4) return 'Possible';
    if (likelihood >= 0.2) return 'Unlikely';
    return 'Very Unlikely';
  }
  
  /// Get likelihood description
  static String _getLikelihoodDescription(double likelihood) {
    if (likelihood >= 0.8) return 'Fair value for both teams with mutual benefit';
    if (likelihood >= 0.6) return 'Reasonable compensation that both teams might consider';
    if (likelihood >= 0.4) return 'May require adjustments to balance value';
    if (likelihood >= 0.2) return 'Uneven value makes trade unlikely';
    return 'Significant imbalance makes trade very improbable';
  }
  
  /// Generate factor explanations
  static List<String> _generateFactors(double value, double needs, double philosophy, double cap) {
    List<String> factors = [];
    
    if (value >= 0.8) {
      factors.add('✅ Excellent value balance');
    } else if (value >= 0.6) {
      factors.add('✅ Good value exchange');
    } else if (value >= 0.4) {
      factors.add('⚠️ Moderate value imbalance');
    } else {
      factors.add('❌ Significant value disparity');
    }
    
    if (needs >= 0.7) {
      factors.add('✅ Addresses team needs well');
    } else if (needs >= 0.5) {
      factors.add('⚠️ Mixed fit for team needs');
    } else {
      factors.add('❌ Poor fit for team needs');
    }
    
    if (cap >= 0.8) {
      factors.add('✅ No cap space issues');
    } else if (cap >= 0.6) {
      factors.add('⚠️ May require contract restructures');
    } else {
      factors.add('❌ Cap space constraints');
    }
    
    return factors;
  }
  
  /// Generate improvement suggestions
  static List<String> _generateSuggestions(
    double tradeBalance,
    TradeImpact team1Impact,
    TradeImpact team2Impact,
    NFLTeamInfo team1,
    NFLTeamInfo team2,
    TeamTradePackage team1Package,
    TeamTradePackage team2Package,
  ) {
    List<String> suggestions = [];
    
    // Value balance suggestions
    if (tradeBalance < 0.8) {
      String receivingTeam = tradeBalance > 1.0 ? team1.teamName : team2.teamName;
      suggestions.add('Consider adding a draft pick to balance value for $receivingTeam');
    } else if (tradeBalance > 1.25) {
      String receivingTeam = tradeBalance > 1.0 ? team2.teamName : team1.teamName;
      suggestions.add('Consider adding a draft pick to balance value for $receivingTeam');
    }
    
    // Cap space suggestions
    if (team1Impact.requiresRestructuring) {
      suggestions.add('${team1.teamName} may need to restructure contracts');
    }
    if (team2Impact.requiresRestructuring) {
      suggestions.add('${team2.teamName} may need to restructure contracts');
    }
    
    // Philosophy suggestions
    if (team1.philosophy == TeamPhilosophy.winNow && 
        team2Package.assets.any((asset) => asset is DraftPickAsset)) {
      suggestions.add('${team1.teamName} (win-now) might prefer proven players over picks');
    }
    
    if ((team2.philosophy == TeamPhilosophy.buildThroughDraft || team2.philosophy == TeamPhilosophy.rebuild) && 
        team1Package.assets.any((asset) => asset is PlayerAsset)) {
      suggestions.add('${team2.teamName} (rebuilding) might prefer picks over veteran players');
    }
    
    return suggestions;
  }
}