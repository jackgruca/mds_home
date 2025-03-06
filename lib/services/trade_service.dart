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
      // Skip if this is the same team as the target pick
      if (team == targetPick.teamName) continue;
      
      // Find available picks from this team
      final availablePicks = draftOrder.where((pick) => 
        pick.teamName == team && !pick.isSelected && pick.pickNumber != targetPick.pickNumber
      ).toList();
      
      if (availablePicks.isEmpty) continue;
      
      // Sort by pick number (ascending)
      availablePicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
      
      // First pick is the primary pick in the offer
      final primaryPick = availablePicks.first;
      final primaryValue = DraftValueService.getValueForPick(primaryPick.pickNumber);
      final remainingValue = targetValue - primaryValue;
      
      // If the primary pick is close enough in value, offer just that
      if (primaryValue >= targetValue * 0.9) {
        packages.add(TradePackage(
          teamOffering: team,
          teamReceiving: targetPick.teamName,
          picksOffered: [primaryPick],
          targetPick: targetPick,
          totalValueOffered: primaryValue,
          targetPickValue: targetValue,
        ));
        continue;
      }
      
      // Otherwise, try to add a second pick if needed
      List<DraftPick> picksOffered = [primaryPick];
      double totalValue = primaryValue;
      
      // Try to find a second pick that fills the value gap
      if (availablePicks.length > 1) {
        for (int i = 1; i < availablePicks.length; i++) {
          final secondPick = availablePicks[i];
          final secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
          
          // Check if this pick is appropriate value (30% to 150% of needed value)
          if (secondValue >= remainingValue * 0.3 && secondValue <= remainingValue * 1.5) {
            picksOffered.add(secondPick);
            totalValue += secondValue;
            break;
          }
        }
      }
      
      // If we still don't have enough value, consider a future pick
      if (totalValue < targetValue * 0.9) {
        // Estimate team strength (for future pick value)
        final teamStrength = _estimateTeamStrength(team);
        final futurePick = FuturePick.estimate(team, teamStrength);
        
        packages.add(TradePackage(
          teamOffering: team,
          teamReceiving: targetPick.teamName,
          picksOffered: picksOffered,
          targetPick: targetPick,
          totalValueOffered: totalValue + futurePick.value,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: futurePick.description,
          futurePickValue: futurePick.value,
        ));
      } else {
        // Package is good enough without future picks
        packages.add(TradePackage(
          teamOffering: team,
          teamReceiving: targetPick.teamName,
          picksOffered: picksOffered,
          targetPick: targetPick,
          totalValueOffered: totalValue,
          targetPickValue: targetValue,
        ));
      }
    }
    
    // Sort packages by total value offered (descending)
    packages.sort((a, b) => b.totalValueOffered.compareTo(a.totalValueOffered));
    
    return packages;
  }
  
  /// Execute a trade by swapping teams for the picks
  void executeTrade(TradePackage package) {
    final targetPickNumber = package.targetPick.pickNumber;
    final teamReceiving = package.teamReceiving;
    final teamOffering = package.teamOffering;
    
    // Update the target pick to belong to the offering team
    for (var pick in draftOrder) {
      if (pick.pickNumber == targetPickNumber) {
        // TODO: Add a way to modify the team name in DraftPick class
        // For now we'll handle this via a callback or event
        break;
      }
    }
    
    // Update the offered picks to belong to the receiving team
    for (var offeredPick in package.picksOffered) {
      for (var pick in draftOrder) {
        if (pick.pickNumber == offeredPick.pickNumber) {
          // TODO: Add a way to modify the team name in DraftPick class
          break;
        }
      }
    }
    
    // Record the trade information
    // TODO: Implement trade history tracking
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