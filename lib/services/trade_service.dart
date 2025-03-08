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

/// Service responsible for generating and evaluating trade offers
class TradeService {
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  final List<Player> availablePlayers;
  final Random _random = Random();
  final String? userTeam;
  
  // Configurable parameters
  final bool enableUserTradeConfirmation;
  final double tradeRandomnessFactor;
  
  // Team-specific data for realistic behavior
  final Map<String, Map<int, double>> _teamSpecificGrades = {};
  final Map<String, int> _teamCurrentPickPosition = {};
  
  TradeService({
    required this.draftOrder,
    required this.teamNeeds,
    required this.availablePlayers,
    this.userTeam,
    this.enableUserTradeConfirmation = true,
    this.tradeRandomnessFactor = 0.5,
  }) {
    // Initialize team-specific grades
    _initializeTeamGrades();
  }
  
  // Method to initialize team grades and positions
  void _initializeTeamGrades() {
    _generateTeamSpecificGrades();
    _updateTeamPickPositions();
  }
  
  // Method to update each team's current pick position
  void _updateTeamPickPositions() {
    for (var teamName in teamNeeds.map((tn) => tn.teamName).toSet()) {
      final teamPicks = draftOrder
          .where((p) => p.teamName == teamName && !p.isSelected)
          .toList();
      
      if (teamPicks.isNotEmpty) {
        teamPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
        _teamCurrentPickPosition[teamName] = teamPicks.first.pickNumber;
      }
    }
  }  
  
  /// Generate team-specific player grades that slightly differ from consensus rankings
  void _generateTeamSpecificGrades() {
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      final grades = <int, double>{};
      
      for (var player in availablePlayers) {
        // Base grade is inverse of rank (lower rank = higher grade)
        double baseGrade = 100.0 - player.rank;
        if (baseGrade < 0) baseGrade = 0;
        
        // Teams value their need positions more (up to +15%)
        int needIndex = teamNeed.needs.indexOf(player.position);
        double needBonus = (needIndex != -1) ? (0.15 * (10 - min(needIndex, 9))) : 0;
        
        // Team-specific randomness (±10%)
        double randomFactor = 0.9 + (_random.nextDouble() * 0.2);
        
        // Final team-specific grade
        grades[player.id] = baseGrade * (1 + needBonus) * randomFactor;
      }
      
      _teamSpecificGrades[teamName] = grades;
    }
  }
  
  /// Get a team's grade for a specific player
  double _getTeamGradeForPlayer(String teamName, Player player) {
    if (!_teamSpecificGrades.containsKey(teamName)) {
      return 100.0 - player.rank; // Default to consensus ranking if no team grade exists
    }
    
    return _teamSpecificGrades[teamName]?[player.id] ?? (100.0 - player.rank);
  }
  
  /// Detect if there's a run on a specific position
  bool _isPositionRunHappening(String position) {
    // Check last 5 picks
    int recentSelections = 0;
    int positionCount = 0;
    
    final selectedPicks = draftOrder.where((p) => p.isSelected).toList();
    
    // Sort by pick number to analyze in order
    selectedPicks.sort((a, b) => b.pickNumber.compareTo(a.pickNumber));
    
    for (var pick in selectedPicks) {
      if (recentSelections >= 5) break;
      recentSelections++;
      
      if (pick.selectedPlayer?.position == position) {
        positionCount++;
      }
    }
    
    // If 2+ of the last 5 picks were the same position, it's a run
    return positionCount >= 2;
  }
  
  /// Calculate remaining talent at a position
  int _remainingTalentAtPosition(String position, int thresholdRank) {
    return availablePlayers
      .where((p) => p.position == position && p.rank <= thresholdRank)
      .length;
  }
  
  /// Check if teams ahead might take the player
  bool _competitorsMightTakePlayer(Player player, int currentPick, int targetPick) {
    // Look at each team between current and target
    for (int pickNum = currentPick + 1; pickNum < targetPick; pickNum++) {
      final teamWithPick = draftOrder.firstWhere(
        (p) => p.pickNumber == pickNum && !p.isSelected,
        orElse: () => throw Exception("Pick not found")
      );
      
      // Get team needs
      final needs = _getTeamNeeds(teamWithPick.teamName);
      if (needs == null) continue;
      
      // If this position is in their top 3 needs, they might take the player
      if (needs.needs.take(3).contains(player.position)) {
        return true;
      }
    }
    return false;
  }
  
  /// Determine if a player is valuable enough to trade up for
  bool _isPlayerWorthTradingFor(Player player, TeamNeed teamNeed, int currentPickNumber) {
    // Priority based on team needs
    int needPriority = teamNeed.needs.indexOf(player.position);
    if (needPriority == -1) needPriority = 100; // Not in needs
    
    // Basic value: How much higher is player ranked than current pick
    double valueGap = (currentPickNumber - player.rank).toDouble();
    
    // Value threshold varies by need priority
    double valueThreshold;
    if (needPriority < 2) {
      // Top 2 needs - willing to move for smaller value gaps
      valueThreshold = 3 + (_random.nextDouble() * 5); // 3-8 spots
    } else if (needPriority < 5) {
      // Medium needs - require more value
      valueThreshold = 7 + (_random.nextDouble() * 7); // 7-14 spots
    } else {
      // Low or no need - require significant value
      valueThreshold = 12 + (_random.nextDouble() * 10); // 12-22 spots
    }
    
    // Teams value higher-ranked positions more (QB, LT, EDGE, etc.)
    if (["QB", "OT", "EDGE", "WR", "CB"].contains(player.position)) {
      valueThreshold *= 0.8; // 20% lower threshold for premium positions
    }
    
    // QB-specific logic: Teams highly value QBs especially early
    if (player.position == "QB" && player.rank <= 20) {
      valueThreshold *= 0.7; // Even more aggressive for top QBs
    }
    
    return valueGap > valueThreshold;
  }
  
  /// Generate trade offers for a specific pick with realistic behavior
  TradeOffer generateTradeOffersForPick(int pickNumber, {bool qbSpecific = false}) {
    // Update team pick positions (as they may have changed)
    _updateTeamPickPositions();
    
    // Get the current pick
    final currentPick = draftOrder.firstWhere(
      (pick) => pick.pickNumber == pickNumber,
      orElse: () => throw Exception('Pick number $pickNumber not found in draft order'),
    );
    final bool isUserPick = currentPick.teamName == userTeam;

    // Skip if this is a user team's pick and we're not forcing trade offers
    if (currentPick.teamName == userTeam && !qbSpecific) {
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: true,
      );
    }
    
    // Check if the team with the pick has a valuable player available
    // Step 1: Identify valuable players
    List<Player> valuablePlayers = [];
    
    // For QB-specific logic, focus on QBs
    if (qbSpecific) {
      valuablePlayers = availablePlayers
          .where((p) => p.position == "QB" && p.rank <= pickNumber + 10)
          .toList();
    } else {
      // For general trades, look at all positions
      // Threshold varies depending on pick position
      int thresholdAdjustment;
      if (pickNumber <= 10) thresholdAdjustment = 12;
      else if (pickNumber <= 32) thresholdAdjustment = 15;
      else if (pickNumber <= 100) thresholdAdjustment = 18;
      else thresholdAdjustment = 20;
      
      valuablePlayers = availablePlayers
          .where((p) => p.rank <= pickNumber + thresholdAdjustment)
          .toList();
    }
    
    if (valuablePlayers.isEmpty) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Check if current team would want any of these valuable players
    final currentTeamNeeds = _getTeamNeeds(currentPick.teamName);
    bool hasValueForCurrentTeam = false;
    
    if (currentTeamNeeds != null) {
      for (var player in valuablePlayers.take(5)) {
        // Check if any top available player is at a position of need
        if (currentTeamNeeds.needs.take(3).contains(player.position)) {
          hasValueForCurrentTeam = true;
          break;
        }
      }
    }
    
    // If current team sees value, they're less likely to trade down
    // Still allow some trades (teams sometimes trade down even with good players available)
    if (hasValueForCurrentTeam && _random.nextDouble() > 0.2) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Step 2: Find teams that might be interested in trading up
    final interestedTeams = <String>[];
    
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      
      // Skip if team has no picks
      if (!_teamCurrentPickPosition.containsKey(teamName)) continue;
      
      // Skip if team's next pick is before current pick (they wouldn't trade up)
      final teamNextPick = _teamCurrentPickPosition[teamName] ?? 999;
      if (teamNextPick <= pickNumber) continue;
      
      // Skip user team if appropriate
      if (userTeam != null && teamName == userTeam && !enableUserTradeConfirmation) {
        continue;
      }
      
      // Check each valuable player to see if this team would trade up for them
      for (var player in valuablePlayers) {
        // Skip if player doesn't fill a need for this team
        if (!teamNeed.needs.contains(player.position)) continue;
        
        // Calculate probability of trading up for this player
        double tradeUpProb = 0.0;
        
        // 1. Check if player fills a significant need
        int needPriority = teamNeed.needs.indexOf(player.position);
        bool isTopNeed = needPriority >= 0 && needPriority < 3;
        if (isTopNeed) tradeUpProb += 0.3;
        
        // 2. Check if player offers good value
        bool isGoodValue = _isPlayerWorthTradingFor(player, teamNeed, pickNumber);
        if (isGoodValue) tradeUpProb += 0.3;
        
        // 3. Check if there's a position run happening
        bool isPositionRun = _isPositionRunHappening(player.position);
        if (isPositionRun) tradeUpProb += 0.2;
        
        // 4. Check positional scarcity
        int remainingTalent = _remainingTalentAtPosition(player.position, pickNumber + 15);
        bool isPositionScarce = remainingTalent < 3;
        if (isPositionScarce) tradeUpProb += 0.2;
        
        // 5. Check if competitors might take the player
        bool competitorsAhead = false;
        if (teamNextPick > pickNumber) {
          competitorsAhead = _competitorsMightTakePlayer(player, pickNumber, teamNextPick);
        }
        if (competitorsAhead) tradeUpProb += 0.2;
        
        // Adjust for premium positions
        if (["QB", "OT", "EDGE", "CB"].contains(player.position)) {
          tradeUpProb += 0.1;
        }
        
        // Add randomness (±0.15)
        tradeUpProb += (_random.nextDouble() * 0.3) - 0.15;
        
        // Cap probability at 90%
        tradeUpProb = min(0.9, max(0.0, tradeUpProb));
        
        // Decide if team wants to trade up
        if (_random.nextDouble() < tradeUpProb) {
          interestedTeams.add(teamName);
          break; // Found a player worth trading up for
        }
      }
    }
    
    if (interestedTeams.isEmpty) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Step 3: Create trade packages from interested teams
    final packages = _createRealisticTradePackages(
      interestedTeams, 
      currentPick, 
      DraftValueService.getValueForPick(pickNumber),
      qbSpecific
    );
    
    // Check if the user is involved in any packages
    final isUserInvolved = currentPick.teamName == userTeam || 
                          packages.any((p) => p.teamOffering == userTeam);
    
    return TradeOffer(
      packages: packages,
      pickNumber: pickNumber,
      isUserInvolved: isUserPick || packages.any((p) => p.teamOffering == userTeam),
    );
  }
  
  /// Create realistic trade packages that match actual NFL trading patterns
  List<TradePackage> _createRealisticTradePackages(
    List<String> interestedTeams,
    DraftPick targetPick,
    double targetValue,
    bool isQBTrade
  ) {
    final packages = <TradePackage>[];
    final int targetPickNum = targetPick.pickNumber;
    
    for (final team in interestedTeams) {
      // Skip if this is the same team
      if (team == targetPick.teamName) continue;
      
      // Get available picks from this team
      final availablePicks = draftOrder
          .where((pick) => pick.teamName == team && !pick.isSelected && pick.pickNumber != targetPick.pickNumber)
          .toList();
      
      if (availablePicks.isEmpty) continue;
      
      // Sort by pick number (ascending)
      availablePicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
      
      // Get the earliest (best) available pick
      final bestPick = availablePicks.first;
      final bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
      
      // Track the team's strategies for this trade
      List<TradePackage> teamStrategies = [];
      
      // Different strategies based on target pick position
      
      // ----- TOP 10 PICK STRATEGIES -----
      if (targetPickNum <= 10) {
        // Strategy 1: First round pick + future first
        if (bestPick.pickNumber <= 32) {
          // Calculate the future pick value (first round)
          final teamStrength = _estimateTeamStrength(team);
          final futurePick = FuturePick.estimate(team, teamStrength);
          
          // Determine if value is enough
          if (bestPickValue + futurePick.value >= targetValue * 0.85) {
            teamStrategies.add(TradePackage(
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
        
        // Strategy 2: Multiple picks package (most common for top 10)
        if (availablePicks.length >= 2) {
          // Try different pick combinations (preferring earlier picks)
          for (int i = 0; i < min(availablePicks.length - 1, 3); i++) {
            final firstPick = availablePicks[i];
            final firstValue = DraftValueService.getValueForPick(firstPick.pickNumber);
            
            // Try paired with each subsequent pick
            for (int j = i + 1; j < min(availablePicks.length, i + 5); j++) {
              final secondPick = availablePicks[j];
              final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
              final combinedValue = firstValue + secondValue;
              
              // If we have enough value, create the package
              if (combinedValue >= targetValue * 0.85) {
                teamStrategies.add(TradePackage(
                  teamOffering: team,
                  teamReceiving: targetPick.teamName,
                  picksOffered: [firstPick, secondPick],
                  targetPick: targetPick,
                  totalValueOffered: combinedValue,
                  targetPickValue: targetValue,
                ));
              }
              // If not enough value, try adding a third pick
              else if (availablePicks.length > j + 1) {
                for (int k = j + 1; k < min(availablePicks.length, j + 5); k++) {
                  final thirdPick = availablePicks[k];
                  final thirdValue = DraftValueService.getValueForPick(thirdPick.pickNumber);
                  final threePickValue = combinedValue + thirdValue;
                  
                  if (threePickValue >= targetValue * 0.85) {
                    teamStrategies.add(TradePackage(
                      teamOffering: team,
                      teamReceiving: targetPick.teamName,
                      picksOffered: [firstPick, secondPick, thirdPick],
                      targetPick: targetPick,
                      totalValueOffered: threePickValue,
                      targetPickValue: targetValue,
                    ));
                    break; // Found a good three-pick package
                  }
                }
              }
            }
          }
        }
      }
      
      // ----- FIRST ROUND (11-32) STRATEGIES -----
      else if (targetPickNum <= 32) {
        // Strategy 1: Pick + Future pick
        final teamStrength = _estimateTeamStrength(team);
        // Teams often trade future 1st rounders for mid-1st, future 2nd for late 1st
        final futureRound = targetPickNum <= 20 ? 1 : 2;
        final futurePick = futureRound == 1
            ? FuturePick.estimate(team, teamStrength)
            : FuturePick.forRound(team, 2);
        
        if (bestPickValue + futurePick.value >= targetValue * 0.85) {
          teamStrategies.add(TradePackage(
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
        
        // Strategy 2: Current pick + additional pick(s)
        if (availablePicks.length >= 2) {
          // Try to make packages with 2 picks (most common)
          for (int i = 1; i < min(availablePicks.length, 5); i++) {
            final secondPick = availablePicks[i];
            final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
            final combinedValue = bestPickValue + secondValue;
            
            if (combinedValue >= targetValue * 0.85) {
              teamStrategies.add(TradePackage(
                teamOffering: team,
                teamReceiving: targetPick.teamName,
                picksOffered: [bestPick, secondPick],
                targetPick: targetPick,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
            }
          }
          
          // Try 3-pick packages for certain value ranges
          if (teamStrategies.isEmpty && availablePicks.length >= 3) {
            final secondPick = availablePicks[1];
            final thirdPick = availablePicks[2];
            final combinedValue = bestPickValue + 
                                DraftValueService.getValueForPick(secondPick.pickNumber) +
                                DraftValueService.getValueForPick(thirdPick.pickNumber);
            
            if (combinedValue >= targetValue * 0.85) {
              teamStrategies.add(TradePackage(
                teamOffering: team,
                teamReceiving: targetPick.teamName,
                picksOffered: [bestPick, secondPick, thirdPick],
                targetPick: targetPick,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
            }
          }
        }
      }
      
      // ----- DAY 2 (33-100) STRATEGIES -----
      else if (targetPickNum <= 100) {
        // Day 2 trades are typically simpler - usually a team's current pick 
        // plus a mid-to-late round pick to balance value
        
        if (availablePicks.length >= 2) {
          // Try simple 2-pick packages (most common for day 2)
          for (int i = 1; i < min(availablePicks.length, 4); i++) {
            final secondPick = availablePicks[i];
            final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
            final combinedValue = bestPickValue + secondValue;
            
            if (combinedValue >= targetValue * 0.85 && combinedValue <= targetValue * 1.2) {
              teamStrategies.add(TradePackage(
                teamOffering: team,
                teamReceiving: targetPick.teamName,
                picksOffered: [bestPick, secondPick],
                targetPick: targetPick,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
            }
          }
        }
        
        // Sometimes teams just swap picks when close in value
        if (bestPickValue >= targetValue) {
          teamStrategies.add(TradePackage(
            teamOffering: team,
            teamReceiving: targetPick.teamName,
            picksOffered: [bestPick],
            targetPick: targetPick,
            totalValueOffered: bestPickValue,
            targetPickValue: targetValue,
          ));
        }
        
        // Occasionally future picks are involved (usually 4th round or later)
        if (teamStrategies.isEmpty && bestPickValue >= targetValue * 0.8) {
          final futureRound = _random.nextInt(3) + 4; // Future 4th-6th
          final futurePick = FuturePick.forRound(team, futureRound);
          
          teamStrategies.add(TradePackage(
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
      
      // ----- DAY 3 (101+) STRATEGIES -----
      else {
        // Very simple trades in later rounds
        // Usually just pick swaps with minimal additional value
        
        if (bestPickValue >= targetValue) {
          teamStrategies.add(TradePackage(
            teamOffering: team,
            teamReceiving: targetPick.teamName,
            picksOffered: [bestPick],
            targetPick: targetPick,
            totalValueOffered: bestPickValue,
            targetPickValue: targetValue,
          ));
        }
        
        // Sometimes simple 2-pick combinations
        if (availablePicks.length >= 2 && bestPickValue < targetValue) {
          final secondPick = availablePicks[1];
          final combinedValue = bestPickValue + DraftValueService.getValueForPick(secondPick.pickNumber);
          
          if (combinedValue >= targetValue * 0.9) {
            teamStrategies.add(TradePackage(
              teamOffering: team,
              teamReceiving: targetPick.teamName,
              picksOffered: [bestPick, secondPick],
              targetPick: targetPick,
              totalValueOffered: combinedValue,
              targetPickValue: targetValue,
            ));
          }
        }
      }
      
      // Apply QB premium for QB-specific trades
      if (isQBTrade && teamStrategies.isNotEmpty) {
        // QB trades often have "overpayment" due to position importance
        // Historical data shows 10-25% premium
        final qbPremium = 1.0 + (_random.nextDouble() * 0.15 + 0.1); // 1.1 to 1.25
        
        // Apply premium to all strategies
        teamStrategies = teamStrategies.map((package) {
          return TradePackage(
            teamOffering: package.teamOffering,
            teamReceiving: package.teamReceiving,
            picksOffered: package.picksOffered,
            targetPick: package.targetPick,
            totalValueOffered: package.totalValueOffered * qbPremium,
            targetPickValue: package.targetPickValue,
            includesFuturePick: package.includesFuturePick,
            futurePickDescription: package.futurePickDescription,
            futurePickValue: package.futurePickValue,
          );
        }).toList();
      }
      
      // Select the best strategy for this team to offer
      if (teamStrategies.isNotEmpty) {
        // Sort strategies by quality
        if (isQBTrade) {
          // For QB trades, prioritize highest total value
          teamStrategies.sort((a, b) => 
            b.totalValueOffered.compareTo(a.totalValueOffered)
          );
        } else {
          // For regular trades, prioritize closest to fair value
          teamStrategies.sort((a, b) => 
            (a.totalValueOffered - targetValue).abs().compareTo(
              (b.totalValueOffered - targetValue).abs()
            )
          );
        }
        
        // Add the best strategy to the packages
        packages.add(teamStrategies.first);
      }
    }
    
    return packages;
  }
  
  /// Get the team needs for a team
  TeamNeed? _getTeamNeeds(String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      debugPrint('No team needs found for $teamName');
      return null;
    }
  }
  
  /// Estimate team strength for future pick valuation (1-32 scale)
  /// 1 = strongest team, 32 = weakest team
  int _estimateTeamStrength(String teamName) {
    // This is a simplified estimate - could be enhanced with real team data
    // For now, base it on draft position (earlier pickers are weaker teams)
    final teamPicks = draftOrder.where((pick) => 
      pick.teamName == teamName && pick.round == "1"
    ).toList();
    
    if (teamPicks.isEmpty) return 16; // Middle of the pack
    
    // Lower pick number = weaker team
    return min(32, max(1, teamPicks.first.pickNumber));
  }
  
  // Randomization helper functions
  double _getRandomAddValue() {
    return _random.nextDouble() * 10 - 4; // Range from -4 to 6
  }
  
  double _getRandomMultValue() {
    return _random.nextDouble() * 0.3 + 0.01; // Range from 0.01 to 0.3
  }
}