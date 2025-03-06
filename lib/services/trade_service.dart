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
  
  TradeService({
    required this.draftOrder,
    required this.teamNeeds,
    required this.availablePlayers,
    this.userTeam,
    this.enableUserTradeConfirmation = true,
    this.tradeRandomnessFactor = 0.5,
  });

  /// Generate trade offers for a specific pick
  TradeOffer generateTradeOffersForPick(int pickNumber, {bool qbSpecific = false}) {
    // Get the current pick
    final currentPick = draftOrder.firstWhere(
      (pick) => pick.pickNumber == pickNumber,
      orElse: () => throw Exception('Pick number $pickNumber not found in draft order'),
    );
    
    // Skip if this is a user team's pick and we're not forcing trade offers
    if (currentPick.teamName == userTeam && !qbSpecific) {
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: true,
      );
    }
    
    // Step 1: Identify valuable players available at this pick
    final valuablePlayers = _identifyValuablePlayers(pickNumber, qbSpecific);
    if (valuablePlayers.isEmpty) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Step 2: Find teams interested in these players
    final interestedTeams = _findInterestedTeams(valuablePlayers);
    if (interestedTeams.isEmpty) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Step 3: Check if the current team also needs these positions
    final currentTeamNeeds = _getTeamNeeds(currentPick.teamName);
    final positionsOfInterest = valuablePlayers.map((p) => p.position).toSet().toList();
    
    // Skip if current team also needs these positions (unless it's QB-specific logic)
    if (!qbSpecific && 
        currentTeamNeeds != null && 
        positionsOfInterest.any((pos) => currentTeamNeeds.needs.contains(pos))) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Step 4: Create trade packages from interested teams
    final packages = _createTradePackages(
      interestedTeams, 
      currentPick, 
      DraftValueService.getValueForPick(pickNumber)
    );
    
    // Check if the user is involved in any packages
    final isUserInvolved = currentPick.teamName == userTeam || 
                          packages.any((p) => p.teamOffering == userTeam);
    
    return TradeOffer(
      packages: packages,
      pickNumber: pickNumber,
      isUserInvolved: isUserInvolved,
    );
  }

  /// Identify valuable players that would be available at this pick
  List<Player> _identifyValuablePlayers(int pickNumber, bool qbSpecific) {
    if (qbSpecific) {
      // For QB-specific logic, only look for QBs near this pick
      final qbs = availablePlayers.where((p) => 
        p.position == "QB" && p.rank < pickNumber + _getRandomAddValue() + 5
      ).toList();
      return qbs;
    }
    
    // For general trade logic, look for players with high value relative to pick
    final threshold = pickNumber + _getRandomMultValue() * pickNumber + _getRandomAddValue();
    return availablePlayers.where((p) => p.rank < threshold).toList();
  }

  /// Find teams interested in the valuable players
  List<String> _findInterestedTeams(List<Player> valuablePlayers) {
    if (valuablePlayers.isEmpty) return [];
    
    final positions = valuablePlayers.map((p) => p.position).toSet().toList();
    final interested = <String>{};
    
    // Consider team needs based on draft round
    final round = (valuablePlayers.first.rank / 32).ceil();
    final needDepth = min(3 + round, 10);  // Look at more needs in later rounds
    
    for (var teamNeed in teamNeeds) {
      // Check if any of the player positions match team needs
      for (int i = 0; i < min(needDepth, teamNeed.needs.length); i++) {
        if (positions.contains(teamNeed.needs[i])) {
          interested.add(teamNeed.teamName);
          break;
        }
      }
    }
    
    return interested.toList();
  }

  /// Create trade packages from interested teams
  List<TradePackage> _createTradePackages(
    List<String> interestedTeams, 
    DraftPick targetPick,
    double targetValue
  ) {
    final packages = <TradePackage>[];
    
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
      
      // First pick is the primary pick in the offer
      final primaryPick = availablePicks.first;
      final primaryValue = DraftValueService.getValueForPick(primaryPick.pickNumber);
      
      // Different trade package structures
      List<TradePackage> potentialPackages = [];
      
      // 1. Simple one-pick trade
      if (primaryValue >= targetValue) {
        potentialPackages.add(TradePackage(
          teamOffering: team,
          teamReceiving: targetPick.teamName,
          picksOffered: [primaryPick],
          targetPick: targetPick,
          totalValueOffered: primaryValue,
          targetPickValue: targetValue,
        ));
      }
      
      // 2. Two-pick package
      if (availablePicks.length >= 2 && primaryValue < targetValue) {
        for (int i = 1; i < min(availablePicks.length, 5); i++) {
          final secondPick = availablePicks[i];
          final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
          final combinedValue = primaryValue + secondValue;
          
          if (combinedValue >= targetValue * 0.9 && combinedValue <= targetValue * 1.3) {
            potentialPackages.add(TradePackage(
              teamOffering: team,
              teamReceiving: targetPick.teamName,
              picksOffered: [primaryPick, secondPick],
              targetPick: targetPick,
              totalValueOffered: combinedValue,
              targetPickValue: targetValue,
            ));
          }
        }
      }
      
      // 3. Three-pick package (if needed)
      if (availablePicks.length >= 3 && potentialPackages.isEmpty) {
        for (int i = 1; i < min(availablePicks.length, 4); i++) {
          for (int j = i + 1; j < min(availablePicks.length, 7); j++) {
            final secondPick = availablePicks[i];
            final thirdPick = availablePicks[j];
            final combinedValue = primaryValue + 
                                DraftValueService.getValueForPick(secondPick.pickNumber) +
                                DraftValueService.getValueForPick(thirdPick.pickNumber);
            
            if (combinedValue >= targetValue * 0.9 && combinedValue <= targetValue * 1.3) {
              potentialPackages.add(TradePackage(
                teamOffering: team,
                teamReceiving: targetPick.teamName,
                picksOffered: [primaryPick, secondPick, thirdPick],
                targetPick: targetPick,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
            }
          }
        }
      }
      
      // Add the best package to the result
      if (potentialPackages.isNotEmpty) {
        // Sort by fairness (closest to target value)
        potentialPackages.sort((a, b) => 
          (a.totalValueOffered - targetValue).abs().compareTo(
            (b.totalValueOffered - targetValue).abs()));
        
        packages.add(potentialPackages.first);
      }
    }
    
    return packages;
  }
  
  /// Check if a trade should be accepted based on value and randomness
  bool shouldAcceptTrade(TradePackage package) {
    // Random factor to introduce variability in decision making
    final randomFactor = _random.nextDouble() * tradeRandomnessFactor;
    
    // Base acceptance on value plus random factor
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    
    // Teams are more likely to accept trades that favor them
    if (valueRatio >= 0.95 + randomFactor) {
      return true;
    }
    
    // QB-specific logic: Teams are more aggressive for QBs
    if (package.targetPick.pickNumber < 16) {  // First half of 1st round
      final availableQBs = availablePlayers.where((p) => p.position == "QB").toList();
      if (availableQBs.isNotEmpty && availableQBs.first.rank < 10) {
        // More willing to accept slightly unfavorable trades for top QBs
        return valueRatio >= 0.9 + randomFactor;
      }
    }
    
    return false;
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
  
  // Randomization helper functions (similar to your R code)
  double _getRandomAddValue() {
    return _random.nextDouble() * 10 - 4; // Range from -4 to 6
  }
  
  double _getRandomMultValue() {
    return _random.nextDouble() * 0.3 + 0.01; // Range from 0.01 to 0.3
  }
}