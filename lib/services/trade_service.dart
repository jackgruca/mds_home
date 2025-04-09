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

extension NumExtension on double {
  bool between(double min, double max) {
    return this >= min && this <= max;
  }
}

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
  final double tradeFrequency;
  
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
    this.userTeam,
    this.enableUserTradeConfirmation = true,
    this.tradeRandomnessFactor = 0.5,
    this.enableQBPremium = true,
    this.tradeFrequency = 0.5,
  }) {
    // Initialize team-specific data
    _initializeTeamData();
  }
  
  // Method to initialize team data for trade evaluation
  void _initializeTeamData() {
    _generateTeamSpecificGrades();
    _updateTeamPickPositions();
  }
  
  // Keep track of player selection
  void recordPlayerSelection(Player player) {
    _recentSelections.add(player);
    
    // Keep only most recent 15 selections
    if (_recentSelections.length > 15) {
      _recentSelections.removeAt(0);
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

  void _logTradeOffers(
    int pickNumber, 
    String teamName, 
    List<TradeInterest> interestedTeams, 
    bool qbSpecific
  ) {
    debugPrint("\n==== TRADE OFFER DEBUG ====");
    debugPrint("Pick #$pickNumber | Team: $teamName | QB Specific: $qbSpecific");
    debugPrint("Interested Teams: ${interestedTeams.length}");
    
    for (var interest in interestedTeams) {
      debugPrint("- ${interest.teamName}:");
      debugPrint("  Player: ${interest.targetPlayer.name} (${interest.targetPlayer.position})");
      debugPrint("  Player Rank: ${interest.targetPlayer.rank}");
      debugPrint("  Interest Level: ${interest.interestLevel.toStringAsFixed(2)}");
    }
    debugPrint("==========================\n");
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
    
    // Step 1: Identify valuable players available at this pick
    List<Player> valuablePlayers = _identifyValuablePlayers(pickNumber, qbSpecific);
    
    if (valuablePlayers.isEmpty) {
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Step 2: Find teams that might want to trade up
    List<TradeInterest> interestedTeams = _findTeamsInterestedInTradingUp(pickNumber, valuablePlayers, qbSpecific);

    _logTradeOffers(pickNumber, currentPick.teamName, interestedTeams, qbSpecific);
    
    if (interestedTeams.isEmpty) {
      return TradeOffer(
        packages: [],
        pickNumber: pickNumber,
        isUserInvolved: isUsersPick,
      );
    }
    
    // Step 3: Generate trade packages from interested teams
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
      // Calculate value threshold based on randomness parameters influenced by trade frequency
      double randMult = _random.nextDouble() * 0.25 * tradeFrequency - 0.05;  // Range from -0.05 to 0.20, scaled by trade frequency
      double randAdd = _random.nextDouble() * 8 * tradeFrequency - 2;  // Range from -2 to 6, scaled by trade frequency
      
      // Debug output
      debugPrint("\n==== TRADE VALUE THRESHOLD ====");
      debugPrint("Pick #$pickNumber threshold: value > ${randMult.toStringAsFixed(2)}*pick + ${randAdd.toStringAsFixed(2)}");
      debugPrint("Minimum value required: ${(randMult * pickNumber + randAdd).toStringAsFixed(2)}");
      
      // Calculate dynamic value threshold
      double valueThreshold = randMult * pickNumber + randAdd;
      
      return availablePlayers
          .where((p) {
            // Basic value formula: (pick number) - (player rank)
            int playerValue = pickNumber - p.rank;
            
            // Apply position premium
            if (_premiumPositions.contains(p.position)) {
              // Premium positions get a significant boost (e.g. QB, EDGE, OT)
              playerValue += 10;
              
              // Extra boost for QBs if QB premium is enabled
              if (p.position == 'QB' && enableQBPremium) {
                playerValue += 5;
              }
            } else if (_secondaryPositions.contains(p.position)) {
              // Secondary positions get a smaller boost
              playerValue += 5;
            }
            
            // Debug output for some players
            if (p.rank <= pickNumber + 20) {
              debugPrint("Player: ${p.name} (${p.position}), Rank: ${p.rank}, Value: ${playerValue.toStringAsFixed(1)}, Threshold: ${valueThreshold.toStringAsFixed(1)}");
            }
            
            // Return true if player has sufficient value
            return playerValue > valueThreshold;
          })
          .toList();
    }
  }

// Find teams interested in trading up
  List<TradeInterest> _findTeamsInterestedInTradingUp(int pickNumber, List<Player> valuablePlayers, bool qbSpecific) {
    List<TradeInterest> interestedTeams = [];
    
    // If no valuable players, no interested teams
    if (valuablePlayers.isEmpty) {
      debugPrint("No valuable players found for pick #$pickNumber");
      return interestedTeams;
    }
    
    // Get pick round to determine how far down the needs list to look
    int round = DraftValueService.getRoundForPick(pickNumber);
    int needsToConsider = round + 2;  // Consider needs based on round+2
    
    debugPrint("\n==== TRADE INTEREST DEBUG ====");
    debugPrint("Pick #$pickNumber | Round: $round | Considering top $needsToConsider needs");
    debugPrint("Valuable Players: ${valuablePlayers.map((p) => '${p.name} (${p.position})').join(', ')}");
    
    // Check if the current team would want to stay based on valuable players
    final currentTeam = draftOrder.firstWhere(
      (pick) => pick.pickNumber == pickNumber,
      orElse: () => throw Exception('Pick number $pickNumber not found')
    ).teamName;
    
    // Get current team needs
    final currentTeamNeed = _getTeamNeeds(currentTeam);
    
    // Check if current team has a main need for any valuable player position
    if (currentTeamNeed != null) {
      bool hasMainNeed = false;
      for (var player in valuablePlayers) {
        int needIndex = currentTeamNeed.needs.indexOf(player.position);
        // If position is in the team's top needs (determined by round+2), they likely stay
        if (needIndex != -1 && needIndex < needsToConsider) {
          hasMainNeed = true;
          debugPrint("Current team ($currentTeam) has a main need for ${player.position} at index $needIndex");
          break;
        }
      }
      
      // If current team has a main need for any valuable player position, they're less likely to trade
      if (hasMainNeed && _random.nextDouble() < 0.7) {  // 70% chance to stay if they have a need
        debugPrint("Current team ($currentTeam) wants to stay due to a main need position");
        // User teams get special treatment - generate offers anyway
        if (userTeam != null && userTeam == currentTeam) {
          debugPrint("But generating offers anyway since this is the user's team");
        } else {
          return interestedTeams;  // Return empty list - no trade
        }
      }
    }
    
    // Loop through all teams with picks after the current pick
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      
      // Skip current team and teams without future picks
      if (teamName == currentTeam || !_teamCurrentPickPosition.containsKey(teamName)) {
        continue;
      }
      
      // Skip if team's next pick is before current pick (unlikely but for safety)
      final teamNextPick = _teamCurrentPickPosition[teamName] ?? 999;
      if (teamNextPick <= pickNumber) {
        continue;
      }
      
      // Check if team has a need for any of the valuable players
      for (var player in valuablePlayers) {
        int needIndex = teamNeed.needs.indexOf(player.position);
        
        // Only interested if position is in their main needs (determined by round+2)
        if (needIndex != -1 && needIndex < needsToConsider) {
          // Calculate interest based on position value and need index
          double interestLevel = 0.7 - (needIndex * 0.1);  // Higher interest for higher needs
          
          // Increase interest for premium positions
          if (_premiumPositions.contains(player.position)) {
            interestLevel += 0.2;  // Premium position bonus
            
            // Extra bonus for QBs if enabled
            if (player.position == "QB" && enableQBPremium) {
              interestLevel += 0.2;
            }
          } else if (_secondaryPositions.contains(player.position)) {
            interestLevel += 0.1;  // Secondary position bonus
          }
          
          // Randomize interest to prevent all teams from behaving the same
          interestLevel += (_random.nextDouble() * 0.2) - 0.1;  // Add -0.1 to 0.1 randomness
          
          // Normalize interest level to 0.0-1.0 range
          interestLevel = max(0.0, min(1.0, interestLevel));
          
          // Teams must have significant interest to trade up
          if (interestLevel > 0.5) {  // Only consider teams with >50% interest
            interestedTeams.add(
              TradeInterest(
                teamName: teamName,
                targetPlayer: player,
                nextPickNumber: teamNextPick,
                interestLevel: interestLevel
              )
            );
            
            debugPrint("Team $teamName interested in ${player.name} (${player.position}) with interest level ${interestLevel.toStringAsFixed(2)}");
            break;  // Team found a player they want, no need to check others
          }
        }
      }
    }
    
    // Sort teams by interest level (highest first)
    interestedTeams.sort((a, b) => b.interestLevel.compareTo(a.interestLevel));
    
    debugPrint("Total interested teams: ${interestedTeams.length}");
    debugPrint("==========================\n");
    
    return interestedTeams;
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
    final targetTeam = targetPick.teamName;
    
    debugPrint("\n==== GENERATING TRADE PACKAGES ====");
    debugPrint("Target Pick: #$targetPickNum ($targetTeam) - Value: ${targetValue.toStringAsFixed(1)}");
    
    for (final interest in interestedTeams) {
      // Get team name and their picks
      final offeringTeam = interest.teamName;
      final teamPicksOriginal = draftOrder
          .where((pick) => pick.teamName == offeringTeam && !pick.isSelected && pick.pickNumber > targetPickNum)
          .toList();
      
      if (teamPicksOriginal.isEmpty) {
        debugPrint("Team $offeringTeam has no available picks after #$targetPickNum - skipping");
        continue;
      }
      
      // Sort picks by pick number (ascending)
      final teamPicks = List<DraftPick>.from(teamPicksOriginal)
        ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
      
      // Get the earliest (best) pick
      final bestPick = teamPicks.first;
      final bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
      
      // Debug info
      debugPrint("\nTeam $offeringTeam's best pick: #${bestPick.pickNumber} (Value: ${bestPickValue.toStringAsFixed(1)})");
      debugPrint("Target value needed: ${targetValue.toStringAsFixed(1)} points");
      
      // Check if best pick is within 90% of target value
      double valueDiff = targetValue - bestPickValue;
      double valueRatio = bestPickValue / targetValue;
      
      if (valueRatio < 0.9) {
        // Best pick doesn't meet minimum threshold (90%)
        // Need to add more picks to reach at least 90% of target value
        
        // Calculate how much additional value is needed to reach 90-100% of target
        double minAdditionalValueNeeded = targetValue * 0.9 - bestPickValue;
        double maxAdditionalValueNeeded = targetValue - bestPickValue;
        
        debugPrint("Base value ratio: ${(valueRatio * 100).toStringAsFixed(1)}% - Need additional ${minAdditionalValueNeeded.toStringAsFixed(1)}-${maxAdditionalValueNeeded.toStringAsFixed(1)} points");
        
        // Try to build a package with additional picks
        TradePackage? package = _buildPackageWithAdditionalPicks(
          offeringTeam,
          targetTeam,
          [bestPick],
          teamPicks.sublist(1),  // All picks except the best one
          bestPickValue,
          targetValue,
          minAdditionalValueNeeded,
          maxAdditionalValueNeeded,
          targetPickNum
        );
        
        if (package != null) {
          packages.add(package);
          debugPrint("✓ Generated package for $offeringTeam: ${package.picksOffered.map((p) => '#${p.pickNumber}').join(', ')} (${package.totalValueOffered.toStringAsFixed(1)} points)");
        } else {
          debugPrint("✗ Could not build a valid package for $offeringTeam");
        }
      } else if (valueRatio > 1.2) {
        // Best pick is worth more than 120% of target value
        // Need to request additional pick(s) from target team to balance
        
        // Calculate how much return value is needed to balance trade (bring down to 100-120%)
        double minReturnValueNeeded = bestPickValue - targetValue * 1.2;
        double maxReturnValueNeeded = bestPickValue - targetValue;
        
        debugPrint("Base value ratio: ${(valueRatio * 100).toStringAsFixed(1)}% - Need return value of ${minReturnValueNeeded.toStringAsFixed(1)}-${maxReturnValueNeeded.toStringAsFixed(1)} points");
        
        // Get target team's remaining picks (all except the one being traded)
        final targetTeamPicks = draftOrder
            .where((pick) => pick.teamName == targetTeam && !pick.isSelected && pick.pickNumber != targetPickNum)
            .toList()
            ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
        
        if (targetTeamPicks.isNotEmpty) {
          // Try to build a balanced package
          TradePackage? package = _buildBalancedPackage(
            offeringTeam,
            targetTeam,
            bestPick,
            targetPick,
            targetTeamPicks,
            minReturnValueNeeded,
            maxReturnValueNeeded
          );
          
          if (package != null) {
            packages.add(package);
            
            // Debug the finalized package
            String additionalPicksInfo = package.additionalTargetPicks.isNotEmpty ? 
                ", plus #${package.additionalTargetPicks.map((p) => p.pickNumber).join(', ')}" : "";
            
            debugPrint("✓ Generated balanced package: $offeringTeam gives #${bestPick.pickNumber} for #${targetPick.pickNumber}$additionalPicksInfo");
          } else {
            debugPrint("✗ Could not build a balanced package");
          }
        } else {
          debugPrint("✗ Target team has no additional picks to balance trade");
        }
      } else {
        // Value is already in the sweet spot (90-120%)
        // Create a simple 1-for-1 package
        TradePackage package = TradePackage(
          teamOffering: offeringTeam,
          teamReceiving: targetTeam,
          picksOffered: [bestPick],
          targetPick: targetPick,
          additionalTargetPicks: const [],
          totalValueOffered: bestPickValue,
          targetPickValue: targetValue,
        );
        
        packages.add(package);
        debugPrint("✓ Generated simple package: $offeringTeam gives #${bestPick.pickNumber} for #${targetPick.pickNumber} (${(valueRatio * 100).toStringAsFixed(1)}% value)");
      }
    }

    // Apply QB premium if applicable
    if (isQBTrade && packages.isNotEmpty && enableQBPremium) {
      // QB trades historically have a higher premium
      double qbPremiumFactor = 1.2 + (_random.nextDouble() * 0.3); // 1.2 to 1.5
      
      debugPrint("\nApplying QB premium factor: ${qbPremiumFactor.toStringAsFixed(2)}");
      
      // Apply the premium to each package's offered value
      for (var i = 0; i < packages.length; i++) {
        final package = packages[i];
        packages[i] = TradePackage(
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
          forceAccept: package.forceAccept,
          futureDraftRounds: package.futureDraftRounds,
          targetFutureDraftRounds: package.targetFutureDraftRounds,
        );
      }
    }
    
    // Sort packages by value ratio (highest first)
    packages.sort((a, b) => (b.totalValueOffered / b.targetPickValue)
        .compareTo(a.totalValueOffered / a.targetPickValue));
    
    // Select at most 3 packages in a weighted fashion
    List<TradePackage> selectedPackages = [];
    if (packages.length <= 3) {
      selectedPackages = packages;
    } else {
      // Always include the best package
      selectedPackages.add(packages[0]);
      
      // Pick up to 2 more packages with weighted randomness
      List<TradePackage> remainingPackages = packages.sublist(1);
      
      // Pick a second package with weighted randomness (earlier packages more likely)
      if (remainingPackages.isNotEmpty) {
        int index = _weightedRandomIndex(remainingPackages.length);
        selectedPackages.add(remainingPackages[index]);
        remainingPackages.removeAt(index);
        
        // Pick a third package if available
        if (remainingPackages.isNotEmpty) {
          index = _weightedRandomIndex(remainingPackages.length);
          selectedPackages.add(remainingPackages[index]);
        }
      }
    }

    debugPrint("\nFinal packages:");
    for (int i = 0; i < selectedPackages.length; i++) {
      var package = selectedPackages[i];
      double ratio = package.totalValueOffered / package.targetPickValue;
      debugPrint("${i+1}. ${package.teamOffering} offers ${package.picksOffered.map((p) => '#${p.pickNumber}').join(', ')} (${package.totalValueOffered.toStringAsFixed(1)} pts, ${(ratio * 100).toStringAsFixed(1)}%)");
    }
    debugPrint("==========================\n");
    
    return selectedPackages;
  }
  
  // Helper method to select a random index with higher probability for earlier indices
  int _weightedRandomIndex(int length) {
    // Generate random value 0-1
    double r = _random.nextDouble();
    
    // Weighted probabilities favoring earlier indices
    if (length <= 2) {
      return r < 0.7 ? 0 : 1;
    } else {
      // For 3+ items, use 60/30/10 split
      if (r < 0.6) return 0;
      if (r < 0.9) return 1;
      return _random.nextInt(length - 2) + 2; // Random pick from remaining
    }
  }
  
  // Try to build a package with additional picks to meet value requirements
  TradePackage? _buildPackageWithAdditionalPicks(
    String offeringTeam,
    String targetTeam,
    List<DraftPick> basePicks,
    List<DraftPick> additionalPicks,
    double baseValue,
    double targetValue,
    double minAdditionalValue,
    double maxAdditionalValue,
    int targetPickNum
  ) {
    // Calculate current value
    double currentValue = baseValue;
    List<DraftPick> selectedPicks = List.from(basePicks);
    List<int> futureDraftRounds = [];
    
    // Try to add current-year picks first to reach target value
    if (additionalPicks.isNotEmpty) {
      // Sort by value (highest first) to try highest value picks first
      additionalPicks.sort((a, b) => 
        DraftValueService.getValueForPick(a.pickNumber)
            .compareTo(DraftValueService.getValueForPick(b.pickNumber)) * -1
      );
      
      for (var pick in additionalPicks) {
        double pickValue = DraftValueService.getValueForPick(pick.pickNumber);
        
        // Add pick if it helps reach target without exceeding max
        if (currentValue + pickValue <= targetValue * 1.3) {
          selectedPicks.add(pick);
          currentValue += pickValue;
          debugPrint("  Added pick #${pick.pickNumber} (${pickValue.toStringAsFixed(1)} pts)");
          
          // If we've reached minimum value, we can stop
          if (currentValue >= targetValue * 0.9) {
            break;
          }
        }
      }
    }
    
    // If we still haven't reached min value, try adding future picks
    if (currentValue < targetValue * 0.9) {
      // Calculate how much more value is needed
      double stillNeeded = (targetValue * 0.9) - currentValue;
      debugPrint("  Still need ${stillNeeded.toStringAsFixed(1)} points - considering future picks");
      
      // Add future picks in order of decreasing value until we reach target
      for (int round = 1; round <= 7; round++) {
        // Calculate future pick value
        double futurePickValue = FuturePick.forRound(offeringTeam, round).value;
        
        if (futurePickValue > 0 && currentValue + futurePickValue <= targetValue * 1.3) {
          // Add future pick
          futureDraftRounds.add(round);
          currentValue += futurePickValue;
          debugPrint("  Added future ${_getRoundText(round)} round pick (${futurePickValue.toStringAsFixed(1)} pts)");
          
          // If we've reached minimum value, we can stop
          if (currentValue >= targetValue * 0.9) {
            break;
          }
        }
      }
    }
    
    // Check if we reached the minimum threshold
    if (currentValue < targetValue * 0.9) {
      debugPrint("  ✗ Could not reach minimum value threshold (${(targetValue * 0.9).toStringAsFixed(1)} pts)");
      return null;
    }
    
    // Create and return the package
    String? futurePickDescription;
    double? futurePickValue;
    
    if (futureDraftRounds.isNotEmpty) {
      // Create description for future picks
      List<String> futurePicks = futureDraftRounds.map((round) => "${_getRoundText(round)} round").toList();
      futurePickDescription = "Future ${futurePicks.join(" and ")} pick${futurePicks.length > 1 ? 's' : ''}";
      
      // Calculate total future value
      futurePickValue = futureDraftRounds.map((round) => 
        FuturePick.forRound(offeringTeam, round).value
      ).fold(0.0, (sum, value) => sum! + value);
    }
    
    return TradePackage(
      teamOffering: offeringTeam,
      teamReceiving: targetTeam,
      picksOffered: selectedPicks,
      targetPick: draftOrder.firstWhere(
        (pick) => pick.pickNumber == targetPickNum,
        orElse: () => throw Exception('Target pick number $targetPickNum not found in draft order'),
      ),
      additionalTargetPicks: const [],
      totalValueOffered: currentValue,
      targetPickValue: targetValue,
      includesFuturePick: futureDraftRounds.isNotEmpty,
      futurePickDescription: futurePickDescription,
      futurePickValue: futurePickValue,
      futureDraftRounds: futureDraftRounds.isNotEmpty ? futureDraftRounds : null,
    );
  }

  // Build a balanced package where the offering team gives more value than needed
  TradePackage? _buildBalancedPackage(
    String offeringTeam,
    String targetTeam,
    DraftPick offeringPick,
    DraftPick targetPick,
    List<DraftPick> targetTeamPicks,
    double minReturnValueNeeded,
    double maxReturnValueNeeded
  ) {
    // Calculate values
    double offeringPickValue = DraftValueService.getValueForPick(offeringPick.pickNumber);
    double targetPickValue = DraftValueService.getValueForPick(targetPick.pickNumber);
    
    // Sort target team picks by value (highest first)
    targetTeamPicks.sort((a, b) => 
      DraftValueService.getValueForPick(a.pickNumber)
          .compareTo(DraftValueService.getValueForPick(b.pickNumber)) * -1
    );
    
    // Try to find a pick or combination of picks that meets the value requirements
    List<DraftPick> additionalTargetPicks = [];
    double returnValue = 0.0;
    
    for (var pick in targetTeamPicks) {
      double pickValue = DraftValueService.getValueForPick(pick.pickNumber);
      
      // If this pick on its own is within range, use it
      if (pickValue >= minReturnValueNeeded && pickValue <= maxReturnValueNeeded) {
        additionalTargetPicks = [pick];
        returnValue = pickValue;
        debugPrint("  Found single balancing pick #${pick.pickNumber} (${pickValue.toStringAsFixed(1)} pts)");
        break;
      }
      
      // If this pick is less than min, try adding it and continue searching
      if (pickValue < minReturnValueNeeded) {
        additionalTargetPicks.add(pick);
        returnValue += pickValue;
        debugPrint("  Added balancing pick #${pick.pickNumber} (${pickValue.toStringAsFixed(1)} pts)");
        
        // If we've reached the range, stop
        if (returnValue >= minReturnValueNeeded && returnValue <= maxReturnValueNeeded) {
          break;
        }
      }
    }
    
    // If we couldn't find a good combination with current picks, try adding future picks
    List<int> targetFutureDraftRounds = [];
    if (returnValue < minReturnValueNeeded) {
      debugPrint("  Need more value from future picks");
      
      // Start with lower rounds as they're less valuable
      for (int round = 7; round >= 1; round--) {
        if (returnValue >= minReturnValueNeeded) break;
        
        // Calculate future pick value
        double futurePickValue = FuturePick.forRound(targetTeam, round).value;
        
        if (futurePickValue > 0 && returnValue + futurePickValue <= maxReturnValueNeeded * 1.1) {
          // Add future pick
          targetFutureDraftRounds.add(round);
          returnValue += futurePickValue;
          debugPrint("  Added future ${_getRoundText(round)} round pick from $targetTeam (${futurePickValue.toStringAsFixed(1)} pts)");
        }
      }
    }
    
    // Check if we reached the minimum threshold
    if (returnValue < minReturnValueNeeded) {
      debugPrint("  ✗ Could not reach minimum return value (${minReturnValueNeeded.toStringAsFixed(1)} pts)");
      return null;
    }
    
    // Create the description for future picks if any
    String? targetFuturePicksDesc;
    if (targetFutureDraftRounds.isNotEmpty) {
      List<String> targetFuturePicks = targetFutureDraftRounds
          .map((round) => "${_getRoundText(round)} round")
          .toList();
      targetFuturePicksDesc = "Future ${targetFuturePicks.join(" and ")} pick${targetFuturePicks.length > 1 ? 's' : ''}";
    }
    
    // Create and return the package
    return TradePackage(
      teamOffering: offeringTeam,
      teamReceiving: targetTeam,
      picksOffered: [offeringPick],
      targetPick: targetPick,
      additionalTargetPicks: additionalTargetPicks,
      totalValueOffered: offeringPickValue,
      targetPickValue: targetPickValue,
      targetReceivedFuturePicks: targetFuturePicksDesc != null ? [targetFuturePicksDesc] : null,
      targetFutureDraftRounds: targetFutureDraftRounds.isNotEmpty ? targetFutureDraftRounds : null,
    );
  }
  
  /// Helper function to get ordinal text for a round number
  String _getRoundText(int round) {
    if (round == 1) return "1st";
    if (round == 2) return "2nd";
    if (round == 3) return "3rd";
    return "${round}th";
  }

 /// Process a user trade proposal with realistic acceptance criteria
  bool evaluateTradeProposal(TradePackage proposal) {
    // If force accept is enabled, automatically return true
    if (proposal.forceAccept) {
      return true;
    }
    
    // Core decision factors
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
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
    
    // 4. QB-specific adjustments
    if (enableQBPremium) {
      double qbFactor = 0;
      // Check if there are valuable QBs available at this pick
      for (var player in availablePlayers) {
        if (player.position == "QB" && player.rank <= pickNumber + 10) {
          qbFactor = 0.2; // 20% less likely to accept if top QB available
          break;
        }
      }
      acceptanceProbability -= qbFactor;
    }
    
    // 5. Apply round-based modifiers
    int round = DraftValueService.getRoundForPick(proposal.targetPick.pickNumber);
    if (round >= 4) {
      // Increase acceptance in later rounds (teams care less)
      double roundBonus = (round - 3) * 0.05; // 5% increase per round after 3
      acceptanceProbability += roundBonus;
    }
    
    // 6. Add randomness
    final randomFactor = (_random.nextDouble() * tradeRandomnessFactor) - (tradeRandomnessFactor / 2);
    acceptanceProbability += randomFactor;
    
    // Ensure probability is within 0-1 range
    acceptanceProbability = max(0.05, min(0.95, acceptanceProbability));
    
    // Debug output
    debugPrint("\n==== TRADE PROPOSAL EVALUATION ====");
    debugPrint("Team ${proposal.teamReceiving} evaluating offer from ${proposal.teamOffering}");
    debugPrint("Value: ${proposal.totalValueOffered.toStringAsFixed(1)} for ${proposal.targetPickValue.toStringAsFixed(1)} (${(valueRatio * 100).toStringAsFixed(1)}%)");
    debugPrint("Final acceptance probability: ${(acceptanceProbability * 100).toStringAsFixed(1)}%");
    debugPrint("Random roll: ${(_random.nextDouble() * 100).toStringAsFixed(1)}%");
    
    // Make final decision
    return _random.nextDouble() < acceptanceProbability;
  }

  /// Overloaded version of evaluateTradeProposal that accepts a pre-calculated value ratio
  bool evaluateTradeProposalWithAdjustedValue(TradePackage proposal, double preCalculatedValueRatio) {
    // Core decision factors
    final valueRatio = preCalculatedValueRatio; // Use the adjusted value ratio
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
    
    // 4. QB-specific adjustments
    if (enableQBPremium) {
      double qbFactor = 0;
      // Check if there are valuable QBs available at this pick
      for (var player in availablePlayers) {
        if (player.position == "QB" && player.rank <= pickNumber + 10) {
          qbFactor = 0.15; // 15% less likely to accept if top QB available
          break;
        }
      }
      acceptanceProbability -= qbFactor;
    }
    
    // 5. Apply round-based modifiers
    int round = DraftValueService.getRoundForPick(proposal.targetPick.pickNumber);
    if (round >= 4) {
      // Increase acceptance in later rounds (teams care less)
      double roundBonus = (round - 3) * 0.05; // 5% increase per round after 3
      acceptanceProbability += roundBonus;
    }
    
    // 6. Add randomness
    final randomFactor = (_random.nextDouble() * tradeRandomnessFactor) - (tradeRandomnessFactor / 2);
    acceptanceProbability += randomFactor;
    
    // Ensure probability is within 0-1 range
    acceptanceProbability = max(0.05, min(0.95, acceptanceProbability));
    
    // Debug output
    debugPrint("\n==== COUNTER OFFER EVALUATION ====");
    debugPrint("Team ${proposal.teamReceiving} evaluating counter from ${proposal.teamOffering}");
    debugPrint("Adjusted Value Ratio: ${(valueRatio * 100).toStringAsFixed(1)}%");
    debugPrint("Final acceptance probability: ${(acceptanceProbability * 100).toStringAsFixed(1)}%");
    debugPrint("Random roll: ${(_random.nextDouble() * 100).toStringAsFixed(1)}%");
    
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
    int round = DraftValueService.getRoundForPick(pickNumber);
    int needsToConsider = round + 2;  // Look at needs based on round+2
    
    // Check if any top players match team's main needs
    for (var player in availablePlayers.take(5)) {
      int needIndex = teamNeeds.needs.indexOf(player.position);
      if (needIndex >= 0 && needIndex < needsToConsider) {
        // This is a main need position
        double needAdjustment = -0.15 + (needIndex * 0.03);  // -0.15 for top need, less for lower needs
        debugPrint("Team $teamName has ${player.position} as need #${needIndex+1} - adjustment ${needAdjustment.toStringAsFixed(2)}");
        return probability + needAdjustment;
      }
    }
    
    return probability;
  }
  
  /// Process a counter offer with leverage premium applied
  bool evaluateCounterOffer(TradePackage originalOffer, TradePackage counterOffer) {
    // Force accept if enabled
    if (counterOffer.forceAccept) {
      return true;
    }

    // Print detailed information for debugging
    debugPrint("===== EVALUATING COUNTER OFFER =====");
    debugPrint("Original offer from ${originalOffer.teamOffering} to ${originalOffer.teamReceiving}");
    debugPrint("Counter offer from ${counterOffer.teamOffering} to ${counterOffer.teamReceiving}");

    // Check teams are flipped (basic sanity check)
    if (originalOffer.teamOffering == counterOffer.teamReceiving &&
        originalOffer.teamReceiving == counterOffer.teamOffering) {
      
      // Check if the main picks are flipped
      bool picksFlipped = false;
      
      // Find if main pick numbers are flipped (original offer's target = counter offer's offered picks)
      for (var offeredPick in counterOffer.picksOffered) {
        if (offeredPick.pickNumber == originalOffer.targetPick.pickNumber) {
          picksFlipped = true;
          debugPrint("✓ Found exact pick match: original target #${originalOffer.targetPick.pickNumber} = counter offered #${offeredPick.pickNumber}");
          break;
        }
      }
      
      // If the picks are flipped, auto-accept with 100% probability
      if (picksFlipped) {
        debugPrint("✓✓✓ AUTO-ACCEPTING COUNTER OFFER");
        return true;
      }
      
      // Extremely lenient check - just require the teams to be flipped
      // and make sure the picks exist on both sides
      if (counterOffer.picksOffered.isNotEmpty && originalOffer.picksOffered.isNotEmpty) {
        debugPrint("✓✓ AUTO-ACCEPTING COUNTER OFFER (lenient mode)");
        return true;
      }
    }
    
    // Calculate leverage premium based on pick position
    double basePremium = 1.0;
    
    // If this is a counter to an AI-initiated offer, the user has leverage
    if (originalOffer.teamOffering != counterOffer.teamOffering && 
        originalOffer.teamReceiving == counterOffer.teamOffering) {
      
      // Determine leverage based on pick positions
      int originalTargetPick = originalOffer.targetPick.pickNumber;
      
      // Higher premium for earlier picks (rounds 1-2)
      if (originalTargetPick <= 32) {
        // Up to 25% premium for first round
        basePremium = 1.25;
      } else if (originalTargetPick <= 64) {
        // Up to 20% premium for second round  
        basePremium = 1.2;
      } else if (originalTargetPick <= 105) {
        // Up to 15% premium for third round
        basePremium = 1.15;
      } else {
        // Standard 10% premium for later rounds
        basePremium = 1.1;
      }
      
      debugPrint("Calculated leverage premium: ${basePremium.toStringAsFixed(2)}");
    }

    // Apply the premium to the value ratio
    final valueRatio = counterOffer.totalValueOffered / counterOffer.targetPickValue;
    final adjustedValueRatio = valueRatio * basePremium;
    debugPrint("Value ratio: ${valueRatio.toStringAsFixed(2)}, Adjusted with premium: ${adjustedValueRatio.toStringAsFixed(2)}");
    
    // Check if counter offer improves value (original AI offer is better for user)
    if (_isImprovedCounterOffer(originalOffer, counterOffer)) {
      debugPrint("Counter offer is an improved offer - automatic accept");
      return true;
    }
    
    // Use the adjusted ratio for evaluation
    return evaluateTradeProposalWithAdjustedValue(counterOffer, adjustedValueRatio);
  }

  /// Check if the counter offer is better for the AI team but still reasonable
  bool _isImprovedCounterOffer(TradePackage originalOffer, TradePackage counterOffer) {
    // Teams must be flipped
    if (originalOffer.teamOffering != counterOffer.teamReceiving ||
        originalOffer.teamReceiving != counterOffer.teamOffering) {
      return false;
    }
    
    // Original offer value ratio
    double originalRatio = originalOffer.totalValueOffered / originalOffer.targetPickValue;
    
    // Counter offer value ratio
    double counterRatio = counterOffer.totalValueOffered / counterOffer.targetPickValue;
    
    // For debugging
    debugPrint("Original ratio: ${originalRatio.toStringAsFixed(2)}, Counter ratio: ${counterRatio.toStringAsFixed(2)}");
    
    // Accept if counter offer improves value by 10-20% but doesn't exceed 125% total
    bool isImproved = counterRatio > originalRatio && counterRatio <= 1.25;
    bool isReasonable = (counterRatio - originalRatio) <= 0.2; // Allow up to 20% increase
    
    debugPrint("Is improved? $isImproved, Is reasonable? $isReasonable");
    
    return isImproved && isReasonable;
  }

  /// Generate realistic rejection reason for a trade
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
      
      // Get pick round to determine how far down the needs list to look
      int round = DraftValueService.getRoundForPick(proposal.targetPick.pickNumber);
      int needsToConsider = round + 2;
      
      for (var player in topPlayers) {
        int needIndex = teamNeed.needs.indexOf(player.position);
        if (needIndex != -1 && needIndex < needsToConsider) {
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

  // Get team needs
  TeamNeed? _getTeamNeeds(String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      return null;
    }
  }
}

// Trading interest class moved outside the service
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