// lib/services/trade_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../models/trade_offer.dart';
import '../models/future_pick.dart';
import 'draft_value_service.dart';

/// Service responsible for generating and evaluating trade offers with improved realism
class TradeService {
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  final List<Player> availablePlayers;
  final Random _random = Random();
  final String? userTeam;
  
  // Configurable parameters
  final bool enableUserTradeConfirmation;
  final double tradeRandomnessFactor;
  final bool enableQBPremium;
  
  // Team-specific trading tendencies
  final Map<String, TradingTendency> _teamTendencies = {
    'NE': TradingTendency(tradeDownBias: 0.7, valueSeeker: 0.9), // Patriots love trading down for value
    'PHI': TradingTendency(tradeUpBias: 0.7, aggressiveness: 0.7), // Eagles often trade up
    'LV': TradingTendency(tradeUpBias: 0.6, aggressiveness: 0.8), // Raiders aggressive with trades
    'BAL': TradingTendency(tradeDownBias: 0.6, valueSeeker: 0.7), // Ravens collect picks
    'SF': TradingTendency(tradeUpBias: 0.7, aggressiveness: 0.6), // 49ers target specific players
    'SEA': TradingTendency(tradeDownBias: 0.7, valueSeeker: 0.6), // Seahawks trade down often
    'GB': TradingTendency(tradeDownBias: 0.7, valueSeeker: 0.7), // Packers prefer more picks
    'KC': TradingTendency(tradeUpBias: 0.6, aggressiveness: 0.6), // Chiefs target specific talent
    'BUF': TradingTendency(tradeUpBias: 0.6, aggressiveness: 0.6), // Bills can be aggressive
    'MIA': TradingTendency(tradeUpBias: 0.7, aggressiveness: 0.7), // Dolphins historically aggressive
    'MIN': TradingTendency(tradeActivityLevel: 0.7), // Vikings active traders
    'DAL': TradingTendency(tradeActivityLevel: 0.6), // Cowboys moderate activity
    // Add more teams with specific tendencies as needed
  };
  
  // Position market volatility - tracks "runs" on positions
  final Map<String, double> _positionMarketVolatility = {};
  
  // Recent selections to detect position runs
  final List<Player> _recentSelections = [];
  
  // Team-specific data for realistic behavior
  final Map<String, Map<int, double>> _teamSpecificGrades = {};
  final Map<String, int> _teamCurrentPickPosition = {};
  
  // Premium positions that are valued more highly
  final Set<String> _premiumPositions = {
    'QB', 'OT', 'EDGE', 'CB', 'WR', 'CB | WR'
  };
  
  // Secondary value positions
  final Set<String> _secondaryPositions = {
    'DT', 'S', 'TE', 'IOL', 'LB'
  };
  
  TradeService({
    required this.draftOrder,
    required this.teamNeeds,
    required this.availablePlayers,
    this.userTeam, // Keep accepting single team
    this.enableUserTradeConfirmation = true,
    this.tradeRandomnessFactor = 0.5,
    this.enableQBPremium = true,
  }) {
    // Initialize team-specific data
    _initializeTeamData();
  }
  
  // Method to initialize team data for trade evaluation
  void _initializeTeamData() {
    _generateTeamSpecificGrades();
    _updateTeamPickPositions();
  }
  
  // Keep track of player selection to detect position runs
  void recordPlayerSelection(Player player) {
    _recentSelections.add(player);
    
    // Keep only most recent 15 selections
    if (_recentSelections.length > 15) {
      _recentSelections.removeAt(0);
    }
    
    // Update position market volatility
    _updatePositionMarketVolatility();
  }
  
  // Update position market volatility based on recent selections
  void _updatePositionMarketVolatility() {
    // Reset volatility (will decay over time)
    for (var key in _positionMarketVolatility.keys) {
      _positionMarketVolatility[key] = (_positionMarketVolatility[key] ?? 0) * 0.7;
    }
    
    // Count positions in recent selections
    Map<String, int> recentPositionCounts = {};
    for (var player in _recentSelections.take(10)) {
      recentPositionCounts[player.position] = (recentPositionCounts[player.position] ?? 0) + 1;
    }
    
    // Update volatility based on recent selection patterns
    for (var entry in recentPositionCounts.entries) {
      // A position run increases volatility
      if (entry.value >= 2) {
        double volatilityIncrease = entry.value * 0.15; // Each pick increases volatility by 15%
        _positionMarketVolatility[entry.key] = (_positionMarketVolatility[entry.key] ?? 0) + volatilityIncrease;
      }
    }
  }
  
  // Method to update each team's current pick position
  void _updateTeamPickPositions() {
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      final teamPicks = draftOrder
          .where((p) => p.teamName == teamName && !p.isSelected)
          .toList();
      
      if (teamPicks.isNotEmpty) {
        teamPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
        _teamCurrentPickPosition[teamName] = teamPicks.first.pickNumber;
      }
    }
  }  
  
  // Generate team-specific grades for player evaluations
  void _generateTeamSpecificGrades() {
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      final grades = <int, double>{};
      
      for (var player in availablePlayers) {
        // Base grade is inverse of rank (lower rank = higher grade)
        double baseGrade = 100.0 - player.rank;
        if (baseGrade < 0) baseGrade = 0;
        
        // Teams value their need positions more (up to +20%)
        int needIndex = teamNeed.needs.indexOf(player.position);
        double needBonus = (needIndex != -1) ? (0.2 * (10 - min(needIndex, 9))) : 0;
        
        // Premium positions get additional value
        double positionBonus = 0.0;
        if (_premiumPositions.contains(player.position)) {
          positionBonus = 0.15; // 15% premium for elite positions
        } else if (_secondaryPositions.contains(player.position)) {
          positionBonus = 0.05; // 5% premium for secondary positions
        }
        
        // QB-specific adjustment
        if (player.position == 'QB' && enableQBPremium) {
          positionBonus += 0.2; // Additional 20% premium for QBs
          
          // Extra value for top QBs
          if (player.rank <= 15) {
            positionBonus += 0.15; // Another 15% for top QBs
          }
        }
        
        // Team-specific randomness (±15%)
        double randomFactor = 0.85 + (_random.nextDouble() * 0.3);
        
        // Final team-specific grade
        grades[player.id] = baseGrade * (1 + needBonus + positionBonus) * randomFactor;
      }
      
      _teamSpecificGrades[teamName] = grades;
    }
  }
  
  /// Generate trade offers for a specific pick with realistic behavior
  TradeOffer generateTradeOffersForPick(int pickNumber, {bool qbSpecific = false}) {
    // Update team pick positions as they may have changed
    _updateTeamPickPositions();
    
    // Get the current pick
    final currentPick = draftOrder.firstWhere(
      (pick) => pick.pickNumber == pickNumber,
      orElse: () => throw Exception('Pick number $pickNumber not found in draft order'),
    );
    
    // Check if this involves the user team
    final bool isUsersPick = currentPick.teamName == userTeam;
    
    // IMPORTANT: We now generate trade offers even for user team picks
    // Instead of returning an empty list as before
    
    // Step 1: Identify valuable players available at this pick
    List<Player> valuablePlayers = _identifyValuablePlayers(pickNumber, qbSpecific);
    
    if (valuablePlayers.isEmpty) {
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Step 2: Determine if the current team sees value at this pick
    bool currentTeamWantsToStay = _currentTeamWantsToStay(currentPick, valuablePlayers);
    
    // Even if the team wants to stay, allow trades with some probability
    // This probability is higher for user team picks to ensure user gets offers
    double tradeAnywayProb = isUsersPick ? 0.9 : 0.3;
    bool allowTradeAnyway = _random.nextDouble() < tradeAnywayProb;
    
    if (currentTeamWantsToStay && !allowTradeAnyway && !isUsersPick) {
      // Team wants to make their pick
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Step 3: Find teams that might want to trade up
    List<TradeInterest> interestedTeams = _findTeamsInterestedInTradingUp(pickNumber, valuablePlayers, qbSpecific);
    
    if (interestedTeams.isEmpty) {
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Step 4: Generate trade packages from interested teams
    final packages = _generateTradePackages(
      interestedTeams,
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
  
  // Identify valuable players available at this pick
  List<Player> _identifyValuablePlayers(int pickNumber, bool qbSpecific) {
    if (qbSpecific) {
      // Focus specifically on QB prospects
      return availablePlayers
          .where((p) => p.position == "QB" && p.rank <= pickNumber + 15)
          .toList();
    } else {
      // Calculate threshold based on pick position
      int thresholdAdjustment;
      if (pickNumber <= 10) thresholdAdjustment = 15;         // Top 10 pick
      else if (pickNumber <= 32) thresholdAdjustment = 20;    // 1st round
      else if (pickNumber <= 64) thresholdAdjustment = 25;    // 2nd round
      else if (pickNumber <= 100) thresholdAdjustment = 30;   // 3rd round
      else thresholdAdjustment = 35;                         // Later rounds
      
      return availablePlayers
          .where((p) => p.rank <= pickNumber + thresholdAdjustment)
          .toList();
    }
  }
  
  // Determine if the current team sees value in staying at their pick
  bool _currentTeamWantsToStay(DraftPick currentPick, List<Player> valuablePlayers) {
  // Get the team's needs
  final currentTeamNeeds = _getTeamNeeds(currentPick.teamName);
  if (currentTeamNeeds == null) return false;
  
  // Check for QB-specific logic first (highest priority)
  bool hasQBNeed = currentTeamNeeds.needs.take(3).contains("QB");
  
  if (hasQBNeed) {
    // Check for valuable QB available
    for (var player in valuablePlayers) {
      if (player.position == "QB" && player.rank <= currentPick.pickNumber + 10) {
        // Early pick with QB need and valuable QB available = almost never trade out
        if (currentPick.pickNumber <= 15) {
          return _random.nextDouble() < 0.98; // 98% chance to stay
        } else if (currentPick.pickNumber <= 32) {
          return _random.nextDouble() < 0.95; // 95% chance to stay
        } else {
          return _random.nextDouble() < 0.9; // 90% chance to stay
        }
      }
    }
  }
  
  // Check for high-value players at other premium positions of need
  for (var player in valuablePlayers.take(3)) {
    // Top 3 available players at position of need = high value
    if (currentTeamNeeds.needs.take(3).contains(player.position)) {
      // Stronger desire to stay for premium positions
      if (_premiumPositions.contains(player.position)) {
        // For premium positions with top pick, very unlikely to trade out
        if (currentPick.pickNumber <= 15) {
          return _random.nextDouble() < 0.9; // 90% chance to stay
        } else {
          return _random.nextDouble() < 0.8; // 80% chance to stay
        }
      } else if (_secondaryPositions.contains(player.position)) {
        return _random.nextDouble() < 0.7; // 70% chance to stay
      } else {
        return _random.nextDouble() < 0.6; // 60% chance to stay
      }
    }
  }
  
  // Check if team is the user's team - allow more trade offers
  if (userTeam != null && userTeam!.contains(currentPick.teamName)) {
    return false; // Generate offers for user regardless
  }
    
    // Default moderate chance to stay
    return _random.nextDouble() < 0.4;
  }
  
  // Find teams interested in trading up
  List<TradeInterest> _findTeamsInterestedInTradingUp(int pickNumber, List<Player> valuablePlayers, bool qbSpecific) {
    List<TradeInterest> interestedTeams = [];
    
    // Loop through all teams looking for trade interest
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      
      // Skip if team has no picks or its next pick is before current pick
      if (!_teamCurrentPickPosition.containsKey(teamName)) continue;
      final teamNextPick = _teamCurrentPickPosition[teamName] ?? 999;
      if (teamNextPick <= pickNumber) continue;
      
      // Get team's trade tendencies
      final tendency = _getTeamTradingTendency(teamName);
      
      // Base trade activity level - can be adjusted by team tendencies
      double tradeActivityBase = 0.3;  // Base 30% chance of considering trading
      
      // Adjust by team's activity level
      tradeActivityBase *= tendency.tradeActivityLevel;
      
      // Early round adjustments (more activity)
      int round = DraftValueService.getRoundForPick(pickNumber);
      if (round == 1) tradeActivityBase *= 1.5;      // 50% more trades in 1st round
      else if (round == 2) tradeActivityBase *= 1.3; // 30% more trades in 2nd round
      
      // Adjust for trade-up tendencies if team has it
      if (tendency.tradeUpBias > 0.5) {
        tradeActivityBase *= tendency.tradeUpBias * 1.3;
      }
      
      // Check if team will consider trading at all
      if (_random.nextDouble() > tradeActivityBase) continue;
      
      // Evaluate each valuable player to see if team would trade up
      for (var player in valuablePlayers) {
        double playerGrade = _getTeamPlayerGrade(teamName, player);
        
        // Calculate interest factors
        double interestLevel = _calculateTradeUpInterest(
          teamName, 
          teamNeed, 
          player, 
          pickNumber, 
          teamNextPick,
          playerGrade,
          qbSpecific
        );
        
        // Teams must have significant interest to trade up
        if (interestLevel > 0.6) {
          interestedTeams.add(
            TradeInterest(
              teamName: teamName,
              targetPlayer: player,
              nextPickNumber: teamNextPick,
              interestLevel: interestLevel
            )
          );
          break; // Team found a player they want, no need to check others
        }
      }
    }
    
    return interestedTeams;
  }
  
// Inside _calculateTradeUpInterest method
double _calculateTradeUpInterest(
  String teamName,
  TeamNeed teamNeed, 
  Player player,
  int targetPickNumber,
  int teamNextPick,
  double playerGrade,
  bool qbSpecific
) {
  double interestLevel = 0.0;
  
  // Calculate round for this team's pick - renamed to 'teamPickRound' to avoid conflict
  int teamPickRound = DraftValueService.getRoundForPick(teamNextPick);
  
  // Get needs based on round (only consider round+3 needs)
  int needsToConsider = min(teamPickRound + 3, teamNeed.needs.length);
  
  // Check if QB is within the needs to consider for this team
  bool qbInConsideration = false;
  int qbNeedIndex = -1;
  for (int i = 0; i < needsToConsider; i++) {
    if (i < teamNeed.needs.length && teamNeed.needs[i] == "QB") {
      qbInConsideration = true;
      qbNeedIndex = i;
      break;
    }
  }
  
  // 1. Need-based interest: Higher interest for positions of need
  int needIndex = teamNeed.needs.indexOf(player.position);
  if (needIndex != -1 && needIndex < needsToConsider) {
    // Greater boost for top needs
    interestLevel += 0.7 - (needIndex * 0.1);
  } else {
    // Some small base interest even for non-needs
    interestLevel += 0.1;
  }
  
  // Original code continues...
  
  // 5. QB specific adjustments: Teams highly value QBs
  if (player.position == "QB" && qbInConsideration) {
    // Even higher premium for QB-specific trades
    if (qbSpecific) {
      interestLevel += 0.5;
    } else {
      interestLevel += 0.3;
    }
    
    // Top QBs are even more valuable
    if (player.rank <= 15) {
      interestLevel += 0.25;
    }
    
    // Additional boost based on QB need priority
    if (qbNeedIndex < 3) {
      interestLevel += 0.2; // Extra boost for top-3 need
    }
  }
  
  // 9. Round-specific adjustments - using original round variable from method
  int targetRound = DraftValueService.getRoundForPick(targetPickNumber);
  if (targetRound == 1) {
    interestLevel += 0.1;  // More trades in round 1
  } else if (targetRound >= 5) {
    interestLevel -= 0.2;  // Fewer trades in late rounds
  }
  
  // Rest of method continues...
  
  return max(0.0, min(1.0, interestLevel));
}
  
  // Check if other teams between current pick and team's next pick want same position
  bool _competitorsWantSamePosition(String position, int currentPick, int teamNextPick) {
    int competitorCount = 0;
    
    for (int pickNum = currentPick + 1; pickNum < teamNextPick; pickNum++) {
      try {
        // Find the team with this pick
        final competitor = draftOrder.firstWhere(
          (pick) => pick.pickNumber == pickNum && !pick.isSelected,
          orElse: () => throw Exception('Pick not found')
        );
        
        // Get team needs
        final needs = _getTeamNeeds(competitor.teamName);
        if (needs == null) continue;
        
        // Check if this position is a top need
        if (needs.needs.take(3).contains(position)) {
          competitorCount++;
          
          // If multiple competitors want this position, it's a clear threat
          if (competitorCount >= 2) return true;
        }
      } catch (e) {
        // Skip if pick not found
        continue;
      }
    }
    
    // Return true if at least one competitor wants the position
    return competitorCount > 0;
  }
  
  // Generate realistic trade packages for interested teams
  List<TradePackage> _generateTradePackages(
    List<TradeInterest> interestedTeams,
    DraftPick targetPick,
    double targetValue,
    bool isQBTrade
  ) {
    final packages = <TradePackage>[];
    final int targetPickNum = targetPick.pickNumber;
    
    for (final interest in interestedTeams) {
      // Get team name and their picks
      final team = interest.teamName;
      final teamPicksOriginal = draftOrder
          .where((pick) => pick.teamName == team && !pick.isSelected && pick.pickNumber != targetPick.pickNumber)
          .toList();
      
      if (teamPicksOriginal.isEmpty) continue;
      
      // Sort picks by pick number (ascending)
      final teamPicks = List<DraftPick>.from(teamPicksOriginal)
        ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
      
      // Get the earliest (best) pick
      final bestPick = teamPicks.first;
      final bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
      
      // Get team's trade tendency
      final tendency = _getTeamTradingTendency(team);
      
      // Determine trade strategy based on pick position and team tendencies
      List<TradePackage> potentialPackages = [];
      
      // FIRST ROUND STRATEGIES (Pick 1-32)
      if (targetPickNum <= 32) {
        potentialPackages.addAll(_generateFirstRoundPackages(
          team,
          teamPicks,
          targetPick,
          targetValue,
          bestPick,
          bestPickValue,
          interest,
          tendency
        ));
      }
      // SECOND ROUND STRATEGIES (Pick 33-64)
      else if (targetPickNum <= 64) {
        potentialPackages.addAll(_generateSecondRoundPackages(
          team,
          teamPicks,
          targetPick,
          targetValue,
          bestPick,
          bestPickValue,
          interest,
          tendency
        ));
      }
      // DAY 3 STRATEGIES (Pick 65+)
      else {
        potentialPackages.addAll(_generateDayThreePackages(
          team,
          teamPicks,
          targetPick,
          targetValue,
          bestPick,
          bestPickValue,
          interest,
          tendency
        ));
      }
      
      // Apply QB premium if applicable
      if (isQBTrade && potentialPackages.isNotEmpty && enableQBPremium) {
        // QB trades historically have a higher premium
        double qbPremiumFactor = 1.2 + (_random.nextDouble() * 0.3); // 1.2 to 1.5 (increased)
        
        // Apply the premium to each package's offered value
        for (var i = 0; i < potentialPackages.length; i++) {
          final package = potentialPackages[i];
          potentialPackages[i] = TradePackage(
            teamOffering: package.teamOffering,
            teamReceiving: package.teamReceiving,
            picksOffered: package.picksOffered,
            targetPick: package.targetPick,
            additionalTargetPicks: package.additionalTargetPicks,
            totalValueOffered: package.totalValueOffered * qbPremiumFactor,
            targetPickValue: package.targetPickValue,
            includesFuturePick: package.includesFuturePick,
            futurePickDescription: package.futurePickDescription,
            futurePickValue: package.futurePickValue,
            targetReceivedFuturePicks: package.targetReceivedFuturePicks,
          );
        }
      }   
      // Filter packages based on value considerations
      potentialPackages = _filterPackagesByValue(potentialPackages, targetValue, tendency);
      
      // Add the best package to our return list if we have any
      if (potentialPackages.isNotEmpty) {
        potentialPackages.sort((a, b) => b.valueDifferential.compareTo(a.valueDifferential));
        
        // Value-seeking teams care more about getting fair deals
        if (tendency.valueSeeker > 0.5) {
          // Find the most balanced trade (closest to fair value)
          potentialPackages.sort((a, b) => 
            (a.valueDifferential.abs()).compareTo(b.valueDifferential.abs())
          );
        }
        
        packages.add(potentialPackages.first);
      }
    }
    
    return packages;
  }
  
  // Generate first round trade packages (picks 1-32)
  List<TradePackage> _generateFirstRoundPackages(
    String team,
    List<DraftPick> teamPicks,
    DraftPick targetPick,
    double targetValue,
    DraftPick bestPick,
    double bestPickValue,
    TradeInterest interest,
    TradingTendency tendency
  ) {
    List<TradePackage> packages = [];
    
    // In the top half of Round 1, teams often trade current + future 1st
    if (targetPick.pickNumber <= 16) {
      // For top-10 picks, teams often include future picks
      if (targetPick.pickNumber <= 10) {
        // Strategy 1: Future 1st round pick package
        final futurePick = FuturePick.forRound(team, 1);
        
        if (bestPickValue + futurePick.value >= targetValue * 0.8) {
          packages.add(TradePackage(
            teamOffering: team,
            teamReceiving: targetPick.teamName,
            picksOffered: [bestPick],
            targetPick: targetPick,
            totalValueOffered: bestPickValue + futurePick.value,
            targetPickValue: targetValue,
            includesFuturePick: true,
            futurePickDescription: futurePick.description,
            futurePickValue: futurePick.value,
          ));
        }
      }
      
      // Strategy 2: Multiple current year picks (most common for first round)
      if (teamPicks.length >= 2) {
        // Try at least the first 3 combinations of picks
        for (int i = 0; i < min(teamPicks.length - 1, 3); i++) {
          final firstPick = teamPicks[i];
          final firstValue = DraftValueService.getValueForPick(firstPick.pickNumber);
          
          for (int j = i + 1; j < min(teamPicks.length, i + 4); j++) {
            final secondPick = teamPicks[j];
            final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
            final combinedValue = firstValue + secondValue;
            
            // Teams commonly slightly overpay for first round picks
            if (combinedValue >= targetValue * 0.85) {
              packages.add(TradePackage(
                teamOffering: team,
                teamReceiving: targetPick.teamName,
                picksOffered: [firstPick, secondPick],
                targetPick: targetPick,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
            }
            // If not enough value, try adding a third pick
            else if (teamPicks.length > j + 1) {
              for (int k = j + 1; k < min(teamPicks.length, j + 3); k++) {
                final thirdPick = teamPicks[k];
                final thirdValue = DraftValueService.getValueForPick(thirdPick.pickNumber);
                final threePickValue = combinedValue + thirdValue;
                
                if (threePickValue >= targetValue * 0.85) {
                  packages.add(TradePackage(
                    teamOffering: team,
                    teamReceiving: targetPick.teamName,
                    picksOffered: [firstPick, secondPick, thirdPick],
                    targetPick: targetPick,
                    totalValueOffered: threePickValue,
                    targetPickValue: targetValue,
                  ));
                  break;  // Found a good three-pick package
                }
              }
            }
          }
        }
      }
    }
    // In the bottom half of Round 1, slightly different strategies
    else {
      // Strategy 1: Current year first round pick + mid-round pick
      if (teamPicks.length >= 2) {
        for (int i = 0; i < min(teamPicks.length - 1, 2); i++) {
          final firstPick = teamPicks[i];
          final firstValue = DraftValueService.getValueForPick(firstPick.pickNumber);
          
          for (int j = i + 1; j < min(teamPicks.length, i + 5); j++) {
            final secondPick = teamPicks[j];
            final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
            final combinedValue = firstValue + secondValue;
            
            if (combinedValue >= targetValue * 0.85) {
              packages.add(TradePackage(
                teamOffering: team,
                teamReceiving: targetPick.teamName,
                picksOffered: [firstPick, secondPick],
                targetPick: targetPick,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
              break;  // Found a good package
            }
          }
        }
      }
      
      // Strategy 2: Future round pick strategy
      final futurePick = FuturePick.forRound(team, 2);  // Future 2nd rounder
      
      if (bestPickValue + futurePick.value >= targetValue * 0.85) {
        packages.add(TradePackage(
          teamOffering: team,
          teamReceiving: targetPick.teamName,
          picksOffered: [bestPick],
          targetPick: targetPick,
          totalValueOffered: bestPickValue + futurePick.value,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: futurePick.description,
          futurePickValue: futurePick.value,
        ));
      }
    }
    
    return packages;
  }
  
  // Generate second round trade packages (picks 33-64)
  List<TradePackage> _generateSecondRoundPackages(
    String team,
    List<DraftPick> teamPicks,
    DraftPick targetPick,
    double targetValue,
    DraftPick bestPick,
    double bestPickValue,
    TradeInterest interest,
    TradingTendency tendency
  ) {
    List<TradePackage> packages = [];
    
    // Strategy 1: Two-pick package (most common for 2nd round)
    if (teamPicks.length >= 2) {
      // Try with first pick + one additional pick
      final firstPick = teamPicks[0];
      final firstValue = DraftValueService.getValueForPick(firstPick.pickNumber);
      
      for (int i = 1; i < min(teamPicks.length, 5); i++) {
        final secondPick = teamPicks[i];
        final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
        final combinedValue = firstValue + secondValue;
        
        if (combinedValue >= targetValue * 0.85) {
          packages.add(TradePackage(
            teamOffering: team,
            teamReceiving: targetPick.teamName,
            picksOffered: [firstPick, secondPick],
            targetPick: targetPick,
            totalValueOffered: combinedValue,
            targetPickValue: targetValue,
          ));
          break;  // Found a good package
        }
      }
    }
    
    // Strategy 2: Pick + Future pick
    final futureRound = _random.nextInt(2) + 3;  // Future 3rd or 4th round pick
    final futurePick = FuturePick.forRound(team, futureRound);
    
    if (bestPickValue + futurePick.value >= targetValue * 0.85) {
      packages.add(TradePackage(
        teamOffering: team,
        teamReceiving: targetPick.teamName,
        picksOffered: [bestPick],
        targetPick: targetPick,
        totalValueOffered: bestPickValue + futurePick.value,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: futurePick.description,
        futurePickValue: futurePick.value,
      ));
    }
    
    // Strategy 3: Single pick if close in value (often happens in 2nd round)
    if (bestPickValue >= targetValue * 1) {
      packages.add(TradePackage(
        teamOffering: team,
        teamReceiving: targetPick.teamName,
        picksOffered: [bestPick],
        targetPick: targetPick,
        totalValueOffered: bestPickValue,
        targetPickValue: targetValue,
      ));
    }
    
    return packages;
  }
  
  // Generate Day 3 trade packages (picks 65+)
  List<TradePackage> _generateDayThreePackages(
    String team,
    List<DraftPick> teamPicks,
    DraftPick targetPick,
    double targetValue,
    DraftPick bestPick,
    double bestPickValue,
    TradeInterest interest,
    TradingTendency tendency
  ) {
    List<TradePackage> packages = [];
    
    // Strategy 1: Simple pick swap (common in later rounds)
    if (bestPickValue >= targetValue * 1) {
      packages.add(TradePackage(
        teamOffering: team,
        teamReceiving: targetPick.teamName,
        picksOffered: [bestPick],
        targetPick: targetPick,
        totalValueOffered: bestPickValue,
        targetPickValue: targetValue,
      ));
    }
    
    // Strategy 2: Two-pick package (also common)
    if (teamPicks.length >= 2) {
      final secondPick = teamPicks[1];
      final combinedValue = bestPickValue + 
                            DraftValueService.getValueForPick(secondPick.pickNumber);
      
      if (combinedValue >= targetValue * 0.85) {
        packages.add(TradePackage(
          teamOffering: team,
          teamReceiving: targetPick.teamName,
          picksOffered: [bestPick, secondPick],
          targetPick: targetPick,
          totalValueOffered: combinedValue,
          targetPickValue: targetValue,
        ));
      }
    }
    
    return packages;
  }
  
  // Filter packages based on value considerations
  List<TradePackage> _filterPackagesByValue(
    List<TradePackage> packages,
    double targetValue,
    TradingTendency tendency
  ) {
    // Define acceptable value ranges based on team tendencies
    double minValueThreshold;
    double maxValueThreshold;
    
    if (tendency.valueSeeker > 0.7) {
      // Value seekers want very fair trades
      minValueThreshold = 0.95;
      maxValueThreshold = 1.1;
    } else if (tendency.valueSeeker > 0.5) {
      // Moderate value seekers
      minValueThreshold = 0.9;
      maxValueThreshold = 1.2;
    } else if (tendency.aggressiveness > 0.7) {
      // Aggressive teams willing to overpay
      minValueThreshold = 0.85;
      maxValueThreshold = 1.3;
    } else {
      // Default behavior
      minValueThreshold = 0.85;
      maxValueThreshold = 1.25;
    }
    
    // Return packages within acceptable value range
    return packages.where((package) {
      double valueRatio = package.totalValueOffered / targetValue;
      return valueRatio >= minValueThreshold && valueRatio <= maxValueThreshold;
    }).toList();
  }
  
  /// Determine if a counter offer should include a leverage premium
  /// Returns the premium multiplier (1.0 means no premium)
  double calculateLeveragePremium(TradePackage originalOffer, TradePackage counterOffer) {
    // If this is a counter to an AI-initiated offer, the user has leverage
    if (originalOffer.teamOffering != counterOffer.teamOffering && 
        originalOffer.teamReceiving == counterOffer.teamReceiving) {
      
      // Base premium is 5-10% additional value acceptance
      double basePremium = 1.08; // 8% baseline premium
      
      // Higher premium for earlier picks (rounds 1-2)
      if (originalOffer.targetPick.pickNumber <= 64) {
        // Up to 15% premium for early rounds
        return basePremium + 0.07; // 15% total
      }
      
      return basePremium;
    }
    
    // No premium for regular offers (not counters)
    return 1.0;
  }

  /// Process a counter offer with leverage premium applied
  bool evaluateCounterOffer(TradePackage originalOffer, TradePackage counterOffer) {
    // Calculate the leverage premium
    double leveragePremium = calculateLeveragePremium(originalOffer, counterOffer);
    
    // Apply the premium to the acceptance probability calculation
    final valueRatio = counterOffer.totalValueOffered / counterOffer.targetPickValue;
    
    // The premium effectively reduces the value needed for acceptance
    final adjustedValueRatio = valueRatio * leveragePremium;
    
    // Now use the adjusted ratio for the regular evaluation
    return evaluateTradeProposalWithAdjustedValue(counterOffer, adjustedValueRatio);
  }
/// Process a user trade proposal with realistic acceptance criteria
bool evaluateTradeProposal(TradePackage proposal) {
  // Get team tendencies
  final tendency = _getTeamTradingTendency(proposal.teamReceiving);
  
  // Core decision factors
  final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
  final pickNumber = proposal.targetPick.pickNumber;
  
  // 1. Value-based acceptance probability
  double acceptanceProbability = _calculateBaseAcceptanceProbability(valueRatio);
  
  // 2. Adjust for pick position premium
  acceptanceProbability = _adjustForPickPositionPremium(acceptanceProbability, pickNumber);
  
  // More adjustments...
  
  // Make final decision
  return _random.nextDouble() < acceptanceProbability;
}

  /// Overloaded version of evaluateTradeProposal that accepts a pre-calculated value ratio
  bool evaluateTradeProposalWithAdjustedValue(TradePackage proposal, double preCalculatedValueRatio) {
    // Get team tendencies
    final tendency = _getTeamTradingTendency(proposal.teamReceiving);
    
    // Core decision factors
    final valueRatio = preCalculatedValueRatio; // Use the provided ratio
    final pickNumber = proposal.targetPick.pickNumber;
    
    // 1. Value-based acceptance probability
    double acceptanceProbability = _calculateBaseAcceptanceProbability(valueRatio);
    
    // 2. Adjust for pick position premium
    acceptanceProbability = _adjustForPickPositionPremium(acceptanceProbability, pickNumber);

    // 3. Adjust for team needs
    acceptanceProbability = _adjustForTeamNeeds(
      acceptanceProbability, 
      proposal.teamReceiving, 
      proposal.targetPick.pickNumber
    );
    
    // 4. Adjust for package composition
    acceptanceProbability = _adjustForPackageComposition(
      acceptanceProbability, 
      proposal, 
      tendency
    );
    
    // 5. QB-specific adjustments
    final qbNeedLevel = _getQBNeedLevel(proposal.teamReceiving);
    if (qbNeedLevel > 0) {
      // Teams with QB needs have different values for picks
      acceptanceProbability = _adjustForQBNeeds(
        acceptanceProbability, 
        proposal,
        qbNeedLevel
      );
    }
    
    // 6. Adjust for team-specific tendencies
    acceptanceProbability = _adjustForTeamTendencies(
      acceptanceProbability,
      proposal,
      tendency
    );
    
    // 7. Apply round-based modifiers (fewer trades in later rounds)
    int round = DraftValueService.getRoundForPick(proposal.targetPick.pickNumber);
    if (round >= 4) {
      // Reduce trade probability in later rounds
      double roundPenalty = (round - 3) * 0.07; // 7% reduction per round after 3
      acceptanceProbability -= roundPenalty;
    }
    
    // 8. Add randomness
    final randomFactor = (_random.nextDouble() * tradeRandomnessFactor) - (tradeRandomnessFactor / 2);
    acceptanceProbability += randomFactor;
    
    // Ensure probability is within 0-1 range
    acceptanceProbability = max(0.05, min(0.95, acceptanceProbability));
    
    // Make final decision
    return _random.nextDouble() < acceptanceProbability;
  }
  
  // Get base acceptance probability based on value ratio
  double _calculateBaseAcceptanceProbability(double valueRatio) {
    if (valueRatio >= 1.2) {
      return 0.9;  // Excellent value (90% acceptance)
    } else if (valueRatio >= 1.1) {
      return 0.8;  // Very good value (80% acceptance)
    } else if (valueRatio >= 1.05) {
      return 0.7;  // Good value (70% acceptance)
    } else if (valueRatio >= 1.0) {
      return 0.6;  // Fair value (60% acceptance)
    } else if (valueRatio >= 0.95) {
      return 0.5;  // Slightly below value (50% acceptance)
    } else if (valueRatio >= 0.9) {
      return 0.3;  // Below value (30% acceptance)
    } else if (valueRatio >= 0.85) {
      return 0.15; // Poor value (15% acceptance)
    } else {
      return 0.05; // Very poor value (5% acceptance)
    }
  }
  
  // Adjust acceptance probability based on pick position
  double _adjustForPickPositionPremium(double probability, int pickNumber) {
    if (pickNumber <= 5) {
      return probability - 0.2;  // Top 5 picks have premium
    } else if (pickNumber <= 10) {
      return probability - 0.15; // Top 10 picks have significant premium
    } else if (pickNumber <= 15) {
      return probability - 0.1;  // Top half of 1st round has moderate premium
    } else if (pickNumber <= 32) {
      return probability - 0.05; // 1st round picks have slight premium
    }
    return probability;
  }
  
  // Adjust for team needs - less likely to trade if good player available
  double _adjustForTeamNeeds(double probability, String teamName, int pickNumber) {
    final teamNeeds = _getTeamNeeds(teamName);
    if (teamNeeds == null) return probability;
    
    // Check top available players to see if they match needs
    final topPlayers = availablePlayers.take(3).toList();
    bool topNeedPlayerAvailable = false;
    
    for (var player in topPlayers) {
      if (teamNeeds.needs.take(3).contains(player.position)) {
        topNeedPlayerAvailable = true;
        
        // Even stronger effect for premium positions
        if (_premiumPositions.contains(player.position)) {
          return probability - 0.25; // Major reduction
        }
        
        break;
      }
    }
    
    return topNeedPlayerAvailable ? probability - 0.15 : probability;
  }
  
  // Adjust based on package composition
  double _adjustForPackageComposition(
    double probability, 
    TradePackage proposal,
    TradingTendency tendency
  ) {
    // Check if team is rebuilding (more likely to want multiple picks)
    bool isRebuildingTeam = _isTeamRebuilding(proposal.teamReceiving);
    
    // Multiple picks packages more attractive to rebuilding teams
    if (isRebuildingTeam && proposal.picksOffered.length > 1) {
      probability += 0.1;
    }
    
    // Future pick preferences
    if (proposal.includesFuturePick) {
      // Rebuilding teams like future picks
      if (isRebuildingTeam) {
        probability += 0.1;
      } else {
        // Win-now teams less interested in future picks
        probability -= 0.05;
      }
    }
    
    return probability;
  }
  
  // Adjust for QB needs (quarterback-needy teams value related picks differently)
  double _adjustForQBNeeds(double probability, TradePackage proposal, double qbNeedLevel) {
    // Check if any top QBs are available
    bool topQBAvailable = availablePlayers
        .where((p) => p.position == "QB" && p.rank <= 15)
        .isNotEmpty;
    
    // If top QB available and team has QB need, they're less likely to trade down
    if (topQBAvailable && proposal.teamOffering == proposal.targetPick.teamName) {
      // Trading down with top QB available - less likely
      return probability - (0.2 * qbNeedLevel);
    }
    
    return probability;
  }
  
  // Adjust for team trading tendencies
  double _adjustForTeamTendencies(
    double probability,
    TradePackage proposal,
    TradingTendency tendency
  ) {
    // Is team trading up or down?
    bool isTradingDown = proposal.teamReceiving == proposal.targetPick.teamName;
    
    if (isTradingDown) {
      // Team is trading down - apply trade-down bias
      if (tendency.tradeDownBias > 0.5) {
        probability += (tendency.tradeDownBias - 0.5) * 0.3; // Up to +15% more likely
      } else if (tendency.tradeDownBias < 0.5) {
        probability -= (0.5 - tendency.tradeDownBias) * 0.3; // Up to -15% less likely
      }
    } else {
      // Team is trading up - apply trade-up bias
      if (tendency.tradeUpBias > 0.5) {
        probability += (tendency.tradeUpBias - 0.5) * 0.3; // Up to +15% more likely
      } else if (tendency.tradeUpBias < 0.5) {
        probability -= (0.5 - tendency.tradeUpBias) * 0.3; // Up to -15% less likely
      }
    }
    
    // Value-seeking teams are more sensitive to value disparities
    if (tendency.valueSeeker > 0.5) {
      double valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
      if (valueRatio < 0.95) {
        // Value seekers strongly dislike unfavorable trades
        probability -= (tendency.valueSeeker - 0.5) * 0.4 * (0.95 - valueRatio) * 20;
      } else if (valueRatio > 1.05) {
        // Value seekers love favorable trades
        probability += (tendency.valueSeeker - 0.5) * 0.4 * (valueRatio - 1.05) * 10;
      }
    }
    
    // Aggressive teams more likely to make trades in general
    if (tendency.aggressiveness > 0.5) {
      probability += (tendency.aggressiveness - 0.5) * 0.2; // Up to +10% more likely
    }
    
    return probability;
  }
  
  // Get team-specific player grade
  double _getTeamPlayerGrade(String teamName, Player player) {
    return _teamSpecificGrades[teamName]?[player.id] ?? 100.0 - player.rank;
  }
  
  // Get team needs
  TeamNeed? _getTeamNeeds(String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      return null;
    }
  }
  
  // Check if team is in rebuilding mode
  bool _isTeamRebuilding(String teamName) {
    // Very simple heuristic - teams with many needs are rebuilding
    final needs = _getTeamNeeds(teamName);
    return needs != null && needs.needs.length >= 5;
  }
  
  // Get QB need level (0.0 to 1.0)
  double _getQBNeedLevel(String teamName) {
    final needs = _getTeamNeeds(teamName);
    if (needs == null) return 0.0;
    
    // Check position in needs list
    int qbNeedIndex = needs.needs.indexOf('QB');
    if (qbNeedIndex == -1) return 0.0;
    
    // Higher need if QB is at top of need list
    return 1.0 - (qbNeedIndex * 0.2);
  }
  
  // Get team trading tendency (with defaults if not specified)
  TradingTendency _getTeamTradingTendency(String teamName) {
    // Try exact match first
    if (_teamTendencies.containsKey(teamName)) {
      return _teamTendencies[teamName]!;
    }
    
    // Try to match team abbreviation
    for (var entry in _teamTendencies.entries) {
      if (teamName.contains(entry.key) || entry.key.contains(teamName)) {
        return entry.value;
      }
    }
    
    // Return default tendency if not found
    return TradingTendency();
  }
  
  /// Generate potential rejection reason for a trade
  String getTradeRejectionReason(TradePackage proposal) {
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    final teamNeed = _getTeamNeeds(proposal.teamReceiving);
    
    // 1. Value-based rejections
    if (valueRatio < 0.85) {
      final options = [
        "The offer doesn't provide sufficient draft value.",
        "We need more compensation to move down from this position.",
        "That offer falls short of our valuation of this pick.",
        "We're looking for significantly more value to make this move.",
        "Our draft value models show this proposal undervalues our pick.",
        "The value gap is too significant for us to consider this deal."
      ];
      return options[_random.nextInt(options.length)];
    }
    
    // 2. Slightly below market value
    else if (valueRatio < 0.95) {
      final options = [
        "We're close, but we need a bit more value to make this deal work.",
        "The offer is slightly below what we're looking for.",
        "We'd need a little more compensation to justify moving back.",
        "Interesting offer, but not quite enough value for us.",
        "Our analytics team suggests we need slightly better compensation.",
        "The trade offers good value, but we're looking for a bit more in return."
      ];
      return options[_random.nextInt(options.length)];
    }
    
    // 3. Need-based rejections (when value is fair but team has needs)
    else if (teamNeed != null && teamNeed.needs.isNotEmpty) {
      // Check if there are players available that match team needs
      final topPlayers = availablePlayers.take(5).toList();
      bool hasNeedMatch = false;
      String matchedPosition = "";
      
      for (var player in topPlayers) {
        if (teamNeed.needs.take(3).contains(player.position)) {
          hasNeedMatch = true;
          matchedPosition = player.position;
          break;
        }
      }
      
      if (hasNeedMatch) {
        final options = [
          "We have our eye on a specific player at this position.",
          "We believe we can address a key roster need with this selection.",
          "Our scouts are high on a player that should be available here.",
          "We have immediate needs that we're planning to address with this pick.",
          "Our draft board has fallen favorably, and we're targeting a player at this spot."
        ];
        
        // Sometimes mention the position specifically
        if (_random.nextBool() && matchedPosition.isNotEmpty) {
          options.add("We're looking to add a $matchedPosition with this selection.");
          options.add("Our team has identified $matchedPosition as a priority in this draft.");
        }
        
        return options[_random.nextInt(options.length)];
      }
    }
    
    // 4. Position-specific concerns
    final pickNumber = proposal.targetPick.pickNumber;
    if (pickNumber <= 15) {
      // Early picks often involve premium positions
      final premiumPositionOptions = [
        "We're targeting a blue-chip talent at a premium position with this pick.",
        "Our front office values the opportunity to select a game-changing player here.",
        "We believe there's a franchise cornerstone available at this position.",
        "Our draft strategy is built around making this selection.",
        "The player we're targeting has too much potential for us to move down."
      ];
      return premiumPositionOptions[_random.nextInt(premiumPositionOptions.length)];
    }
    
    // 5. Future pick preferences (when teams want current picks)
    else if (proposal.includesFuturePick) {
      final options = [
        "We're focused on building our roster now rather than acquiring future assets.",
        "We prefer more immediate draft capital over future picks.",
        "Our preference is for picks in this year's draft.",
        "We're not looking to add future draft capital at this time.",
        "Our team is in win-now mode and we need immediate contributors."
      ];
      return options[_random.nextInt(options.length)];
    }
    
    // 6. Generic rejections for when value is fair but team still declines
    else {
      final options = [
        "After careful consideration, we've decided to stay put and make our selection.",
        "We've received several offers and are going in a different direction.",
        "We're comfortable with our draft position and plan to make our pick.",
        "Our draft board has fallen favorably, so we're keeping the pick.",
        "We don't see enough value in moving back from this position.",
        "The timing isn't right for us on this deal.",
        "We've decided to pass on this opportunity."
      ];
      return options[_random.nextInt(options.length)];
    }
  }
}

/// Trading tendency for teams to create realistic behavior
class TradingTendency {
  // How likely the team is to trade down (1.0 = very likely, 0.0 = very unlikely)
  final double tradeDownBias;
  
  // How likely the team is to trade up (1.0 = very likely, 0.0 = very unlikely)
  final double tradeUpBias;
  
  // How much the team values getting fair value (1.0 = strict value followers, 0.0 = ignores charts)
  final double valueSeeker;
  
  // How aggressive the team is in making trades (1.0 = very aggressive, 0.0 = very conservative)
  final double aggressiveness;
  
  // Overall level of trade activity (1.0 = very active, 0.0 = very inactive)
  final double tradeActivityLevel;
  
  TradingTendency({
    this.tradeDownBias = 0.5,
    this.tradeUpBias = 0.5,
    this.valueSeeker = 0.5,
    this.aggressiveness = 0.5,
    this.tradeActivityLevel = 0.5,
  });
}

/// Class to track a team's interest in trading up
class TradeInterest {
  final String teamName;
  final Player targetPlayer;
  final int nextPickNumber;
  final double interestLevel;
  
  TradeInterest({
    required this.teamName,
    required this.targetPlayer,
    required this.nextPickNumber,
    required this.interestLevel,
  });
}