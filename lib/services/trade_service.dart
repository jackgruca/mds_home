import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../models/trade_offer.dart';
import '../models/future_pick.dart';
import 'draft_value_service.dart';

/// Configuration for team trading behaviors
class TeamTradingProfile {
  // Core tendencies (0.0 to 1.0 scale)
  final double tradeUpAggression;    // How aggressive in trading up
  final double tradeDownWillingness; // How willing to trade down
  final double valueConsciousness;   // How much they care about fair value
  final double futurePickAffinity;   // Preference for future picks
  final double riskTolerance;        // Willingness to make risky trades
  
  const TeamTradingProfile({
    this.tradeUpAggression = 0.5,
    this.tradeDownWillingness = 0.5,
    this.valueConsciousness = 0.5,
    this.futurePickAffinity = 0.5,
    this.riskTolerance = 0.5,
  });
}

/// Configuration for how position scarcity affects trade behavior
class PositionScarcityConfig {
  // The number of recent picks to consider when measuring position runs
  final int recentPicksWindow;
  
  // How much to increase interest when position scarcity is detected
  final double scarcityMultiplier;
  
  // How quickly scarcity effect decays after each pick
  final double scarcityDecayRate;
  
  const PositionScarcityConfig({
    this.recentPicksWindow = 10,
    this.scarcityMultiplier = 1.5,
    this.scarcityDecayRate = 0.8,
  });
}

/// Service responsible for generating and evaluating trade offers
class TradeService {
  // Core draft data
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  final List<Player> availablePlayers;
  final String? userTeam;
  
  // Configuration
  final double randomnessFactor;
  final bool enableQBPremium;
  final Random _random;
  
  // Position importance and division relationships
  final Map<String, double> positionImportance;
  final Map<String, List<String>> divisionTeams;
  
  // Market state tracking
  final Map<String, double> _positionScarcity = {};
  final List<Player> _recentSelections = [];
  final Map<String, int> _teamTradeCount = {};
  final Map<String, double> _tradeFatigue = {};
  final List<TradePackage> _recentTrades = [];
  
  // Team trading profiles
  final Map<String, TeamTradingProfile> _teamProfiles;
  
  // Default values for position importance if not provided
  static const Map<String, double> _defaultPositionImportance = {
    'QB': 1.5,  // Most important
    'OT': 1.3, 
    'EDGE': 1.3,
    'CB': 1.2,
    'WR': 1.15,
    'DT': 1.05,
    'S': 1.0,
    'TE': 0.95,
    'IOL': 0.95,
    'LB': 0.9,
    'RB': 0.85, // Least important
  };
  
  // Scarcity configuration
  final PositionScarcityConfig scarcityConfig;
  
  TradeService({
    required this.draftOrder,
    required this.teamNeeds,
    required this.availablePlayers,
    this.userTeam,
    this.randomnessFactor = 0.5,
    this.enableQBPremium = true,
    Map<String, double>? customPositionImportance,
    Map<String, TeamTradingProfile>? teamProfiles,
    Map<String, List<String>>? divisionTeams,
    this.scarcityConfig = const PositionScarcityConfig(),
    Random? random,
  }) : 
    positionImportance = customPositionImportance ?? _defaultPositionImportance,
    _teamProfiles = teamProfiles ?? {},
    divisionTeams = divisionTeams ?? {},
    _random = random ?? Random();
  
  /// Record a player selection to update position scarcity tracking
  void recordSelection(Player player) {
    _recentSelections.add(player);
    
    // Keep only most recent selections based on config
    if (_recentSelections.length > scarcityConfig.recentPicksWindow) {
      _recentSelections.removeAt(0);
    }
    
    _updatePositionScarcity();
  }

  /// Calculate base acceptance probability from value ratio
  double _calculateBaseAcceptanceProbability(double valueRatio) {
    if (valueRatio >= 1.2) return 0.9;      // Excellent value (90%)
    else if (valueRatio >= 1.1) return 0.8; // Very good value (80%)
    else if (valueRatio >= 1.05) return 0.7; // Good value (70%)
    else if (valueRatio >= 1.0) return 0.6;  // Fair value (60%)
    else if (valueRatio >= 0.97) return 0.4; // Slightly below value (40%)
    else if (valueRatio >= 0.95) return 0.2; // Below value (20%)
    else return 0.05;                        // Poor value (5%)
  }

  /// Update position scarcity metrics based on recent selections
  void _updatePositionScarcity() {
    // Decay all existing scarcity values
    _positionScarcity.forEach((position, value) {
      _positionScarcity[position] = value * scarcityConfig.scarcityDecayRate;
    });
    
    // Count positions in recent selections
    final positionCounts = <String, int>{};
    for (final player in _recentSelections) {
      positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
    }
    
    // Update scarcity based on recent selection patterns
    positionCounts.forEach((position, count) {
      if (count >= 2) {
        final scarcityIncrease = count * 0.2; // Each pick increases scarcity
        _positionScarcity[position] = (_positionScarcity[position] ?? 0) + scarcityIncrease;
      }
    });
  }
  
  /// Get the current position scarcity level (0.0 to 1.0+)
  double getPositionScarcity(String position) {
    return _positionScarcity[position] ?? 0.0;
  }
  
  /// Get team's trading profile (with defaults if not explicitly defined)
  TeamTradingProfile _getTeamProfile(String teamName) {
    if (_teamProfiles.containsKey(teamName)) {
      return _teamProfiles[teamName]!;
    }
    
    // Apply rough defaults based on team abbreviation patterns
    if (teamName.contains('NE') || teamName.contains('BAL') || teamName.contains('SEA')) {
      return const TeamTradingProfile(
        tradeDownWillingness: 0.7,
        valueConsciousness: 0.8,
      );
    } else if (teamName.contains('PHI') || teamName.contains('SF') || teamName.contains('LV')) {
      return const TeamTradingProfile(
        tradeUpAggression: 0.7,
        riskTolerance: 0.7,
      );
    }
    
    // Default behaviors
    return const TeamTradingProfile();
  }
  
  /// Check if two teams are division rivals
  bool _areDivisionRivals(String team1, String team2) {
    for (final division in divisionTeams.values) {
      if (division.contains(team1) && division.contains(team2)) {
        return true;
      }
    }
    return false;
  }
  
  /// Generate trade offers for a specific pick
  TradeOffer generateTradeOffersForPick(int pickNumber, {bool qbSpecific = false}) {
    // Get current pick information
    final currentPick = draftOrder.firstWhere(
      (pick) => pick.pickNumber == pickNumber,
      orElse: () => throw Exception('Pick #$pickNumber not found'),
    );
    
    // Check if user's pick for UI handling
    final isUsersPick = currentPick.teamName == userTeam;
    
    // Find valuable players available at this pick
    final valuablePlayers = _identifyValuablePlayers(pickNumber, qbSpecific);
    if (valuablePlayers.isEmpty) {
      return TradeOffer(
        packages: const [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Find teams interested in trading up to this pick
    final tradeInterests = _findInterestedTeams(
      pickNumber, 
      currentPick.teamName, 
      valuablePlayers, 
      qbSpecific
    );
    
    if (tradeInterests.isEmpty) {
      return TradeOffer(
        packages: const [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Generate trade packages from interested teams
    final packages = _generateTradePackages(
      tradeInterests,
      currentPick,
      DraftValueService.getValueForPick(pickNumber),
      qbSpecific
    );
    
    return TradeOffer(
      packages: packages,
      pickNumber: pickNumber,
      isUserInvolved: isUsersPick || packages.any((p) => p.teamOffering == userTeam),
    );
  }
    /// Adjust based on team profile
  double _adjustForTeamProfile(
    double probability,
    TradePackage proposal,
    TeamTradingProfile profile
  ) {
    // Trading down preference
    if (proposal.teamReceiving == proposal.targetPick.teamName) {
      // Team is trading down
      probability += (profile.tradeDownWillingness - 0.5) * 0.3;
    } else {
      // Team is trading up
      probability -= (0.7 - profile.tradeUpAggression) * 0.3;
    }
    
    // Value consciousness affects sensitivity to value ratio
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    if (profile.valueConsciousness > 0.6) {
      if (valueRatio < 0.98) {
        // Value-conscious teams dislike unfavorable trades
        probability -= (profile.valueConsciousness - 0.5) * 0.6;
      } else if (valueRatio > 1.05) {
        // Value-conscious teams like favorable trades
        probability += (profile.valueConsciousness - 0.5) * 0.4;
      }
    }
    
    // Risk tolerance affects willingness to make trades
    probability += (profile.riskTolerance - 0.5) * 0.2;
    
    return probability;
  }
  
  /// Adjust for exceptional value players available at pick
  double _adjustForExceptionalPlayers(double probability, int pickNumber) {
    // Check for exceptional value at the current pick
    for (final player in availablePlayers.take(5)) {
      final valueGap = pickNumber - player.rank;
      
      // Significant talent available reduces trade probability
      if (valueGap >= 12 && player.rank <= 20) {
        return probability - 0.3; // Major reduction
      } else if (valueGap >= 8 && player.rank <= 32) {
        return probability - 0.2; // Significant reduction
      }
      
      // Premium positions with good value also reduce probability
      if (positionImportance[player.position] != null && 
          positionImportance[player.position]! > 1.2 && 
          valueGap > 5) {
        return probability - 0.2;
      }
    }
    
    return probability;
  }
  
  /// Generate a realistic rejection reason for a declined trade
  String getTradeRejectionReason(TradePackage proposal) {
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    final teamNeedsList = teamNeeds.where(
      (need) => need.teamName == proposal.teamReceiving
    ).toList();
    final teamNeed = teamNeedsList.isNotEmpty ? teamNeedsList.first : null;
    
    // Value-based rejections
    if (valueRatio < 0.95) {
      final reasons = [
        "The offer doesn't provide sufficient draft value.",
        "We need more compensation to move down from this position.",
        "That offer falls short of our valuation of this pick.",
        "We're looking for significantly more value to make this move.",
        "Our draft value models show this proposal undervalues our pick."
      ];
      return reasons[_random.nextInt(reasons.length)];
    }
    
    // Slightly below market value
    if (valueRatio < 0.98) {
      final reasons = [
        "We're close, but we need a bit more value to make this deal work.",
        "The offer is slightly below what we're looking for.",
        "We'd need a little more compensation to justify moving back.",
        "Interesting offer, but not quite enough value for us."
      ];
      return reasons[_random.nextInt(reasons.length)];
    }
    
    // Need-based rejections (target player available)
    if (teamNeed != null) {
      final topPlayers = availablePlayers.take(5).toList();
      String matchedPosition = "";
      
      for (final player in topPlayers) {
        if (teamNeed.needs.take(3).contains(player.position)) {
          matchedPosition = player.position;
          
          final reasons = [
            "We have our eye on a specific player at this position.",
            "We believe we can address a key roster need with this selection.",
            "Our scouts are high on a player that should be available here."
          ];
          
          // Sometimes mention the position specifically
          if (_random.nextBool() && matchedPosition.isNotEmpty) {
            reasons.add("We're looking to add a $matchedPosition with this selection.");
          }
          
          return reasons[_random.nextInt(reasons.length)];
        }
      }
    }
    
    // Exceptional value available
    for (final player in availablePlayers.take(5)) {
      if (proposal.targetPick.pickNumber - player.rank >= 10 && player.rank <= 20) {
        final reasons = [
          "There's a highly ranked player available that we're targeting with this pick.",
          "We've identified exceptional value at this position in the draft.",
          "Our draft board shows a premium talent falling to this pick that we can't pass up."
        ];
        return reasons[_random.nextInt(reasons.length)];
      }
    }
    
    // Future pick preference issues
    if (proposal.includesFuturePick) {
      final profile = _getTeamProfile(proposal.teamReceiving);
      if (profile.futurePickAffinity < 0.4) {
        final reasons = [
          "We're focused on building our roster now rather than acquiring future assets.",
          "We prefer more immediate draft capital over future picks.",
          "Our preference is for picks in this year's draft."
        ];
        return reasons[_random.nextInt(reasons.length)];
      }
    }
    
    // Generic rejections
    final reasons = [
      "After careful consideration, we've decided to stay put and make our selection.",
      "We've received several offers and are going in a different direction.",
      "We're comfortable with our draft position and plan to make our pick.",
      "Our draft board has fallen favorably, so we're keeping the pick."
    ];
    return reasons[_random.nextInt(reasons.length)];
  }
  
  // Record trade completion for market dynamics
  void recordTradeExecution(TradePackage trade) {
    // Update trade count for each team
    _teamTradeCount[trade.teamOffering] = (_teamTradeCount[trade.teamOffering] ?? 0) + 1;
    _teamTradeCount[trade.teamReceiving] = (_teamTradeCount[trade.teamReceiving] ?? 0) + 1;
    
    // Update fatigue for teams that just traded
    _tradeFatigue[trade.teamOffering] = (_tradeFatigue[trade.teamOffering] ?? 0) + 0.3;
    
    // Teams that traded down may be more likely to trade down again
    if (trade.teamReceiving == trade.targetPick.teamName) {
      _tradeFatigue[trade.teamReceiving] = (_tradeFatigue[trade.teamReceiving] ?? 0) - 0.1;
    }
    
    // Add to recent trades
    _recentTrades.add(trade);
    if (_recentTrades.length > 5) {
      _recentTrades.removeAt(0);
    }
    
    // Decay fatigue values for all teams
    for (final team in _tradeFatigue.keys.toList()) {
      final currentFatigue = _tradeFatigue[team] ?? 0;
      if (currentFatigue > 0) {
        _tradeFatigue[team] = max(0, currentFatigue - 0.05);
      } else if (currentFatigue < 0) {
        _tradeFatigue[team] = min(0, currentFatigue + 0.05);
      }
    }
  }
  
  // Get current fatigue level for a team
  double getTeamFatigue(String teamName) {
    return _tradeFatigue[teamName] ?? 0.0;
  }

  /// Identify valuable players available at a specific pick
  List<Player> _identifyValuablePlayers(int pickNumber, bool qbSpecific) {
    if (qbSpecific) {
      // Only look for QBs in QB-specific trades
      return availablePlayers
        .where((p) => p.position == 'QB' && p.rank <= pickNumber + 15)
        .toList();
    }
    
    // Calculate threshold based on pick position
    int threshold;
    if (pickNumber <= 10) threshold = 15;        // Top 10 picks
    else if (pickNumber <= 32) threshold = 20;   // First round
    else if (pickNumber <= 64) threshold = 25;   // Second round
    else if (pickNumber <= 100) threshold = 30;  // Third round
    else threshold = 35;                         // Later rounds
    
    return availablePlayers
      .where((p) => p.rank <= pickNumber + threshold)
      .toList();
  }
    /// Generate later round (65+) trade packages
  List<TradePackage> _generateLaterRoundPackages(
    String teamName,
    List<DraftPick> teamPicks,
    DraftPick targetPick,
    double requiredValue,
    DraftPick bestPick,
    TeamTradingProfile profile
  ) {
    final List<TradePackage> packages = [];
    final String targetTeam = targetPick.teamName;
    
    // Strategy 1: Simple pick swap (common in later rounds)
    if (DraftValueService.getValueForPick(bestPick.pickNumber) >= requiredValue * 0.95) {
      packages.add(TradePackage(
        teamOffering: teamName,
        teamReceiving: targetTeam,
        picksOffered: [bestPick],
        targetPick: targetPick,
        totalValueOffered: DraftValueService.getValueForPick(bestPick.pickNumber),
        targetPickValue: requiredValue,
      ));
    }
    
    // Strategy 2: Two-pick package (also common in later rounds)
    if (teamPicks.length >= 2) {
      final secondPick = teamPicks[1];
      final combinedValue = DraftValueService.getValueForPick(bestPick.pickNumber) + 
                           DraftValueService.getValueForPick(secondPick.pickNumber);
      
      if (combinedValue >= requiredValue * 0.95) {
        packages.add(TradePackage(
          teamOffering: teamName,
          teamReceiving: targetTeam,
          picksOffered: [bestPick, secondPick],
          targetPick: targetPick,
          totalValueOffered: combinedValue,
          targetPickValue: requiredValue,
        ));
      }
    }
    
    return packages;
  }


  
  /// Find teams interested in trading up
  List<TradeInterest> _findInterestedTeams(
    int pickNumber, 
    String pickOwner, 
    List<Player> availablePlayers,
    bool qbSpecific
  ) {
    final List<TradeInterest> interests = [];
    
    // Loop through all teams to find interest
    for (final teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      
      // Skip pick owner and user team for simpler logic (user trades handled separately)
      if (teamName == pickOwner || teamName == userTeam) continue;
      
      // Find team's next pick
      final teamPicks = draftOrder.where(
        (pick) => pick.teamName == teamName && !pick.isSelected && pick.pickNumber > pickNumber
      ).toList();
      
      if (teamPicks.isEmpty) continue;
      teamPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
      final nextPick = teamPicks.first;
      
      // Calculate trade fatigue
      final fatigue = _tradeFatigue[teamName] ?? 0.0;
      if (fatigue > 0.5 && _random.nextDouble() < fatigue) {
        continue; // Skip due to trade fatigue
      }
      
      // For division rivals, reduce trade probability
      if (_areDivisionRivals(teamName, pickOwner)) {
        if (_random.nextDouble() < 0.7) {
          continue; // 70% chance to skip divisional trades
        }
      }
      
      // Calculate team's need-based interest in available players
      for (final player in availablePlayers) {
        final interestLevel = _calculateTradeInterest(
          teamName,
          teamNeed,
          player,
          pickNumber,
          nextPick.pickNumber,
          qbSpecific
        );
        
        if (interestLevel > 0.6) { // Threshold for trade interest
          interests.add(TradeInterest(
            teamName: teamName,
            targetPlayer: player,
            nextPickNumber: nextPick.pickNumber,
            interestLevel: interestLevel
          ));
          break; // One target player per team is enough
        }
      }
    }
    
    return interests;
  }

    /// Adjust acceptance probability based on pick position
  double _adjustForPickPosition(double probability, int pickNumber) {
    if (pickNumber <= 5) return probability - 0.2;      // Top 5 picks premium
    else if (pickNumber <= 10) return probability - 0.15; // Top 10 picks premium  
    else if (pickNumber <= 15) return probability - 0.1;  // Top 15 picks premium
    else if (pickNumber <= 32) return probability - 0.05; // 1st round premium
    else return probability;
  }
  
  /// Adjust for team needs - less likely to trade if player matches top needs
  double _adjustForTeamNeeds(double probability, String teamName, int pickNumber) {
    final teamNeedsList = teamNeeds.where(
      (need) => need.teamName == teamName
    ).toList();
    
    if (teamNeedsList.isEmpty) return probability;
    final teamNeed = teamNeedsList.first;
    
    // Check top available players to see if they match needs
    final topPlayers = availablePlayers.take(5).toList();
    bool topNeedPlayerAvailable = false;
    
    for (final player in topPlayers) {
      if (teamNeed.needs.take(3).contains(player.position)) {
        topNeedPlayerAvailable = true;
        
        // Extra reduction for premium positions
        if (positionImportance[player.position] != null && 
            positionImportance[player.position]! > 1.1) {
          return probability - 0.25; // Major reduction
        }
        
        break;
      }
    }
    
    return topNeedPlayerAvailable ? probability - 0.15 : probability;
  }
  
  /// Adjust based on package composition
  double _adjustForPackageComposition(
    double probability, 
    TradePackage proposal,
    TeamTradingProfile profile
  ) {
    // Multiple picks are attractive for teams valuing quantity
    if (proposal.picksOffered.length > 1 && profile.tradeDownWillingness > 0.6) {
      probability += 0.1;
    }
    
    // Future pick preferences
    if (proposal.includesFuturePick) {
      probability += (profile.futurePickAffinity - 0.5) * 0.3;
    }
    
    return probability;
  }
  
  /// Filter packages based on acceptable value ranges
  List<TradePackage> _filterPackagesByValue(
    List<TradePackage> packages,
    double targetValue,
    TeamTradingProfile profile
  ) {
    // Define acceptable value range based on team profile
    double minThreshold;
    double maxThreshold;
    
    if (profile.valueConsciousness > 0.7) {
      // Value-conscious teams want fair trades
      minThreshold = 0.98;
      maxThreshold = 1.1;
    } else if (profile.valueConsciousness > 0.5) {
      // Moderate value consciousness
      minThreshold = 0.95;
      maxThreshold = 1.15;
    } else if (profile.riskTolerance > 0.7) {
      // Risk-tolerant teams may overpay
      minThreshold = 0.95;
      maxThreshold = 1.25;
    } else {
      // Default behavior
      minThreshold = 0.95;
      maxThreshold = 1.2;
    }
    
    return packages.where((package) {
      final valueRatio = package.totalValueOffered / targetValue;
      return valueRatio >= minThreshold && valueRatio <= maxThreshold;
    }).toList();
  }
  
  /// Evaluate if a proposed trade should be accepted
  bool evaluateTradeProposal(TradePackage proposal) {
    final String receivingTeam = proposal.teamReceiving;
    final double valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    final int pickNumber = proposal.targetPick.pickNumber;
    final profile = _getTeamProfile(receivingTeam);
    
    // 1. Base acceptance probability based on value ratio
    double acceptanceProbability = _calculateBaseAcceptanceProbability(valueRatio);
    
    // 2. Pick position premium adjustment
    acceptanceProbability = _adjustForPickPosition(acceptanceProbability, pickNumber);
    
    // 3. Team needs adjustment
    acceptanceProbability = _adjustForTeamNeeds(
      acceptanceProbability,
      receivingTeam,
      pickNumber
    );
    
    // 4. Rivalry adjustment - reduce probability for division rivals
    if (_areDivisionRivals(proposal.teamOffering, receivingTeam)) {
      acceptanceProbability -= 0.15; // 15% less likely to accept rival trades
    }
    
    // 5. Package composition adjustment
    acceptanceProbability = _adjustForPackageComposition(
      acceptanceProbability,
      proposal,
      profile
    );
    
    // 6. Team profile adjustments
    acceptanceProbability = _adjustForTeamProfile(
      acceptanceProbability,
      proposal,
      profile
    );
    
    // 7. Check for exceptional value players
    acceptanceProbability = _adjustForExceptionalPlayers(
      acceptanceProbability,
      pickNumber
    );
    
    // 8. Add randomness
    final randomAdjustment = (randomnessFactor * _random.nextDouble() * 0.2) - (randomnessFactor * 0.1);
    acceptanceProbability += randomAdjustment;
    
    // Ensure probability is within 0-1 range
    acceptanceProbability = max(0.0, min(1.0, acceptanceProbability));
    
    // Make final decision
    return _random.nextDouble() < acceptanceProbability;
  }
  

  /// Calculate team's interest in trading up for a player
  double _calculateTradeInterest(
    String teamName,
    TeamNeed teamNeed,
    Player player,
    int targetPickNumber,
    int teamNextPick,
    bool qbSpecific
  ) {
    double interest = 0.0;
    final profile = _getTeamProfile(teamName);
    
    // Get team's trade fatigue
    final fatigue = _tradeFatigue[teamName] ?? 0.0;
    
    // 1. Need-based interest
    final needIndex = teamNeed.needs.indexOf(player.position);
    if (needIndex != -1) {
      // Higher value for top needs
      interest += max(0.0, 0.6 - (needIndex * 0.1));
    } else {
      // Small base interest for non-needs
      interest += 0.1;
    }
    
    // 2. Value-based interest
    final rankDiff = teamNextPick - player.rank;
    if (rankDiff > 15) {
      interest += 0.3; // Significant value
    } else if (rankDiff > 10) {
      interest += 0.2; // Good value
    } else if (rankDiff > 5) {
      interest += 0.1; // Some value
    }
    
    // 3. Position importance
    final posWeight = positionImportance[player.position] ?? 1.0;
    interest += (posWeight - 1.0) * 0.3; // Adjust by position importance
    
    // 4. Position scarcity factor
    final scarcity = getPositionScarcity(player.position);
    interest += scarcity * 0.3; // Scarcity increases interest
    
    // 5. Player rank importance (top players generate more interest)
    if (player.rank <= 5) {
      interest += 0.3; // Elite player
    } else if (player.rank <= 15) {
      interest += 0.2; // Premium player
    } else if (player.rank <= 32) {
      interest += 0.1; // First round talent
    }
    
    // 6. QB-specific adjustments
    if (player.position == 'QB') {
      if (qbSpecific) {
        interest += 0.3; // QB-specific trade interest
      } else if (needIndex != -1 && needIndex <= 2) {
        interest += 0.2; // QB is a top need
      }
      
      // Top QBs get more interest
      if (player.rank <= 10) {
        interest += 0.2;
      }
    }
    
    // 7. Check competition for the player (other teams with same need)
    if (_competitorsExistForPosition(player.position, targetPickNumber, teamNextPick)) {
      interest += 0.2; // Competition increases urgency
    }
    
    // 8. Apply team profile modifiers
    interest += (profile.tradeUpAggression - 0.5) * 0.4; // Trade up tendency
    interest -= fatigue * 0.3; // Reduce interest with fatigue
    
    // 9. Add controlled randomness
    interest += (_random.nextDouble() * 0.2) - 0.1; // ±0.1 randomness
    
    return max(0.0, min(1.0, interest));
  }
  
  /// Check if competitors exist for a position between two pick ranges
  bool _competitorsExistForPosition(String position, int currentPick, int teamNextPick) {
    int competitors = 0;
    
    for (int i = currentPick + 1; i < teamNextPick; i++) {
      // Find pick at this position
      final competitorPicks = draftOrder.where(
        (pick) => pick.pickNumber == i && !pick.isSelected
      ).toList();
      
      if (competitorPicks.isEmpty) continue;
      final competitorPick = competitorPicks.first;
      
      // Check team needs
      final competitorNeedsList = teamNeeds.where(
        (needs) => needs.teamName == competitorPick.teamName
      ).toList();
      
      if (competitorNeedsList.isEmpty) continue;
      final competitorNeeds = competitorNeedsList.first;
      
      // Check if position is in top needs
      if (competitorNeeds.needs.take(3).contains(position)) {
        competitors++;
        if (competitors >= 2) return true;
      }
    }
    
    return competitors > 0;
  }
  
  /// Generate appropriate trade packages based on team interests
  List<TradePackage> _generateTradePackages(
    List<TradeInterest> interests,
    DraftPick targetPick,
    double targetValue,
    bool isQBTrade
  ) {
    final List<TradePackage> packages = [];
    final Set<String> processedTeams = {}; // Track teams we've processed to avoid duplicates
    
    for (final interest in interests) {
      final teamName = interest.teamName;
      
      // Skip if we've already processed this team
      if (processedTeams.contains(teamName)) continue;
      processedTeams.add(teamName);
      
      final teamProfile = _getTeamProfile(teamName);
      
      // Get team's available picks
      final teamPicks = draftOrder
        .where((pick) => pick.teamName == teamName && !pick.isSelected)
        .toList()
        ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
      
      if (teamPicks.isEmpty) continue;
      
      // Start with team's best (earliest) pick
      final bestPick = teamPicks.first;
      final bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
      
      // Determine value required for the trade
      double requiredValue = targetValue;
      
      // Adjust for QB premium
      if (isQBTrade && enableQBPremium && interest.targetPlayer.position == 'QB') {
        requiredValue *= 1.15; // 15% premium for QB trades
      }
      
      // Skip if team can't offer enough value
      final totalTeamValue = teamPicks
        .map((pick) => DraftValueService.getValueForPick(pick.pickNumber))
        .fold(0.0, (a, b) => a + b);
      
      if (totalTeamValue < requiredValue * 0.95) continue;
      
      // Generate packages based on pick position
      List<TradePackage> candidatePackages = [];
      
      // First round trade strategies (picks 1-32)
      if (targetPick.pickNumber <= 32) {
        candidatePackages.addAll(_generateFirstRoundPackages(
          teamName,
          teamPicks,
          targetPick,
          requiredValue,
          bestPick,
          teamProfile
        ));
      }
      // Second round trade strategies (picks 33-64)
      else if (targetPick.pickNumber <= 64) {
        candidatePackages.addAll(_generateSecondRoundPackages(
          teamName,
          teamPicks,
          targetPick,
          requiredValue,
          bestPick,
          teamProfile
        ));
      }
      // Later round strategies (picks 65+)
      else {
        candidatePackages.addAll(_generateLaterRoundPackages(
          teamName,
          teamPicks,
          targetPick,
          requiredValue,
          bestPick,
          teamProfile
        ));
      }
      
      // Filter packages by acceptable value range
      candidatePackages = _filterPackagesByValue(
        candidatePackages, 
        requiredValue,
        teamProfile
      );
      
      // Add best package if any viable packages exist
      if (candidatePackages.isNotEmpty) {
        // Sort by value differential (prefer most balanced trades)
        candidatePackages.sort((a, b) {
          // Value-conscious teams prefer fair trades
          if (teamProfile.valueConsciousness > 0.7) {
            return a.valueDifferential.abs().compareTo(b.valueDifferential.abs());
          }
          // Otherwise prefer highest value trades
          return b.valueDifferential.compareTo(a.valueDifferential);
        });
        
        packages.add(candidatePackages.first);
      }
    }
    
    return packages;
  }
  
}

/// Class to track team's interest in trading up
class TradeInterest {
  final String teamName;
  final Player targetPlayer;
  final int nextPickNumber;
  final double interestLevel;
  
  const TradeInterest({
    required this.teamName,
    required this.targetPlayer,
    required this.nextPickNumber,
    required this.interestLevel,
  });
}
