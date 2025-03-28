// lib/services/trade_package_optimizer.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/trade_package.dart';
import '../models/future_pick.dart';
import '../models/trade_motivation.dart';
import 'draft_value_service.dart';
import 'team_classification.dart';

/// Class responsible for generating optimized trade packages
class TradePackageOptimizer {
  final Random _random = Random();
  
  // Configuration parameters
  final double minAcceptableValueRatio;
  final double maxAcceptableValueRatio;
  final int maxPicksInPackage;
  final bool enableFuturePicks;
  final bool applyParityHelper;
  
  // Round-specific value modifiers (premium for early rounds)
  final Map<int, double> _roundValueModifiers = {
    1: 1.1,   // 10% premium for 1st round
    2: 1.05,  // 5% premium for 2nd round
    3: 1.0,   // No modifier for 3rd round
    4: 0.95,  // 5% discount for 4th round
    5: 0.9,   // 10% discount for 5th round
    6: 0.85,  // 15% discount for 6th round
    7: 0.8,   // 20% discount for 7th round
  };
  
  // Position value modifiers
  final Map<String, double> _positionValueModifiers = {
    'QB': 1.3,     // Quarterbacks carry highest premium
    'OT': 1.15,    // Offensive tackles are premium
    'EDGE': 1.15,  // Edge rushers are premium
    'CB': 1.1,     // Cornerbacks are valuable
    'WR': 1.1,     // Wide receivers are valuable
    'DL': 1.05,    // Defensive line
    'TE': 1.0,     // Tight ends
    'S': 1.0,      // Safeties
    'IOL': 0.95,   // Interior offensive line
    'LB': 0.95,    // Linebackers
    'RB': 0.9,     // Running backs typically devalued
  };
  
  // Division rival premium - trade within division costs more
  static const double _divisionRivalPremium = 1.15; // 15% premium
  
  // Counter offer discount - when user initiates, they have leverage
  static const double _counterOfferDiscount = 0.9; // 10% discount
  
  TradePackageOptimizer({
    this.minAcceptableValueRatio = 0.85,
    this.maxAcceptableValueRatio = 1.2,
    this.maxPicksInPackage = 3,
    this.enableFuturePicks = true,
    this.applyParityHelper = true,
  });
  
  /// Generate optimized trade packages based on motivation and team context
  List<TradePackage> generatePackages({
    required String teamOffering,
    required String teamReceiving,
    required List<DraftPick> availablePicks,
    required DraftPick targetPick,
    List<DraftPick> additionalTargetPicks = const [],
    bool isUserInitiated = false,
    bool isQBDriven = false,
    bool canIncludeFuturePicks = true,
    TradeMotivation? motivation,
  }) {
    // Calculate raw target value
    double targetValue = DraftValueService.getValueForPick(targetPick.pickNumber);
    
    // Add value of any additional target picks
    for (var pick in additionalTargetPicks) {
      targetValue += DraftValueService.getValueForPick(pick.pickNumber);
    }
    
    // Apply round-based modifier
    int round = DraftValueService.getRoundForPick(targetPick.pickNumber);
    double roundModifier = _roundValueModifiers[round] ?? 1.0;
    targetValue *= roundModifier;
    
    // Apply position premium if targeting specific position
    if (motivation != null && 
        motivation.isTargetingSpecificPlayer && 
        motivation.targetedPosition.isNotEmpty) {
      double positionModifier = _positionValueModifiers[motivation.targetedPosition] ?? 1.0;
      targetValue *= positionModifier;
    }
    
    // Apply QB premium if applicable
    if (isQBDriven) {
      targetValue *= 1.2; // 20% premium for QB-driven trades
    }
    
    // Apply division rival premium
    bool isDivisionRival = TeamClassification.areDivisionRivals(teamOffering, teamReceiving);
    if (isDivisionRival) {
      targetValue *= _divisionRivalPremium;
    }
    
    // Apply counter offer discount (when user has leverage)
    if (isUserInitiated) {
      targetValue *= _counterOfferDiscount;
    }
    
    // Sort picks by value (descending)
    List<DraftPick> sortedPicks = List.from(availablePicks);
    sortedPicks.sort((a, b) => 
      DraftValueService.getValueForPick(b.pickNumber).compareTo(
        DraftValueService.getValueForPick(a.pickNumber)
      )
    );
    
    // Generate packages with different strategies
    List<TradePackage> packages = [];
    
    // 1. Try single pick packages (common for close picks)
    _generateSinglePickPackages(
      packages,
      teamOffering,
      teamReceiving,
      sortedPicks,
      targetPick,
      additionalTargetPicks,
      targetValue
    );
    
    // 2. Try two-pick combinations
    if (maxPicksInPackage >= 2) {
      _generateTwoPickPackages(
        packages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue
      );
    }
    
    // 3. Try three-pick combinations if allowed
    if (maxPicksInPackage >= 3) {
      _generateThreePickPackages(
        packages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue
      );
    }
    
    // 4. Try packages with future picks
    if (enableFuturePicks && canIncludeFuturePicks) {
      _generateFuturePickPackages(
        packages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        TeamClassification.getTeamStatus(teamOffering)
      );
    }
    
    // Filter packages by acceptable value ratio
    packages = packages.where((package) {
      double valueRatio = package.totalValueOffered / targetValue;
      return valueRatio >= minAcceptableValueRatio && 
             valueRatio <= maxAcceptableValueRatio;
    }).toList();
    
    // Apply parity helper for unbalanced trades if enabled
    if (applyParityHelper) {
      packages = _applyParityHelper(packages, targetValue);
    }
    
    // Sort packages by quality (how close to 1.0 ratio)
    packages.sort((a, b) {
      double ratioA = a.totalValueOffered / targetValue;
      double ratioB = b.totalValueOffered / targetValue;
      return (ratioA - 1.0).abs().compareTo((ratioB - 1.0).abs());
    });
    
    // Keep a reasonable number of packages
    const int maxPackagesToReturn = 5;
    if (packages.length > maxPackagesToReturn) {
      packages = packages.take(maxPackagesToReturn).toList();
    }
    
    return packages;
  }
  
  /// Generate packages with a single pick
  void _generateSinglePickPackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue
  ) {
    for (var pick in sortedPicks) {
      double pickValue = DraftValueService.getValueForPick(pick.pickNumber);
      
      if (pickValue >= targetValue * minAcceptableValueRatio) {
        packages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [pick],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: pickValue,
          targetPickValue: targetValue,
        ));
      }
    }
  }
  
  /// Generate packages with two picks
  void _generateTwoPickPackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue
  ) {
    if (sortedPicks.length < 2) return;
    
    // Try combinations of two picks
    for (int i = 0; i < sortedPicks.length; i++) {
      DraftPick firstPick = sortedPicks[i];
      double firstValue = DraftValueService.getValueForPick(firstPick.pickNumber);
      
      // Skip if first pick alone exceeds max value
      if (firstValue > targetValue * maxAcceptableValueRatio) continue;
      
      for (int j = i + 1; j < sortedPicks.length; j++) {
        DraftPick secondPick = sortedPicks[j];
        double secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
        double combinedValue = firstValue + secondValue;
        
        // Check if combined value is within acceptable range
        if (combinedValue >= targetValue * minAcceptableValueRatio && 
            combinedValue <= targetValue * maxAcceptableValueRatio) {
          packages.add(TradePackage(
            teamOffering: teamOffering,
            teamReceiving: teamReceiving,
            picksOffered: [firstPick, secondPick],
            targetPick: targetPick,
            additionalTargetPicks: additionalTargetPicks,
            totalValueOffered: combinedValue,
            targetPickValue: targetValue,
          ));
        }
      }
    }
  }
  
  /// Generate packages with three picks
  void _generateThreePickPackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue
  ) {
    if (sortedPicks.length < 3) return;
    
    // Try combinations of three picks
    for (int i = 0; i < sortedPicks.length; i++) {
      DraftPick firstPick = sortedPicks[i];
      double firstValue = DraftValueService.getValueForPick(firstPick.pickNumber);
      
      // Skip if first pick alone exceeds max value
      if (firstValue > targetValue * maxAcceptableValueRatio) continue;
      
      for (int j = i + 1; j < sortedPicks.length; j++) {
        DraftPick secondPick = sortedPicks[j];
        double secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
        double twoPickValue = firstValue + secondValue;
        
        // Skip if two picks already exceed max value
        if (twoPickValue > targetValue * maxAcceptableValueRatio) continue;
        
        for (int k = j + 1; k < sortedPicks.length; k++) {
          DraftPick thirdPick = sortedPicks[k];
          double thirdValue = DraftValueService.getValueForPick(thirdPick.pickNumber);
          double combinedValue = twoPickValue + thirdValue;
          
          // Check if combined value is within acceptable range
          if (combinedValue >= targetValue * minAcceptableValueRatio && 
              combinedValue <= targetValue * maxAcceptableValueRatio) {
            packages.add(TradePackage(
              teamOffering: teamOffering,
              teamReceiving: teamReceiving,
              picksOffered: [firstPick, secondPick, thirdPick],
              targetPick: targetPick,
              additionalTargetPicks: additionalTargetPicks,
              totalValueOffered: combinedValue,
              targetPickValue: targetValue,
            ));
          }
        }
      }
    }
  }
  
  /// Generate packages including future picks
  void _generateFuturePickPackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TeamBuildStatus teamStatus
  ) {
    // Different strategies based on target pick
    int round = DraftValueService.getRoundForPick(targetPick.pickNumber);
    
    // Top 10 picks often involve future 1st rounders
    if (targetPick.pickNumber <= 10) {
      _generateTopPickFuturePackages(
        packages, 
        teamOffering, 
        teamReceiving, 
        sortedPicks, 
        targetPick, 
        additionalTargetPicks, 
        targetValue, 
        teamStatus
      );
    }
    // First round picks (11-32) often involve future 2nd or combination of current picks
    else if (targetPick.pickNumber <= 32) {
      _generateFirstRoundFuturePackages(
        packages, 
        teamOffering, 
        teamReceiving, 
        sortedPicks, 
        targetPick, 
        additionalTargetPicks, 
        targetValue, 
        teamStatus
      );
    }
    // Day 2 picks (33-105) have different patterns
    else if (targetPick.pickNumber <= 105) {
      _generateDayTwoFuturePackages(
        packages, 
        teamOffering, 
        teamReceiving, 
        sortedPicks, 
        targetPick, 
        additionalTargetPicks, 
        targetValue, 
        teamStatus
      );
    }
    // Day 3 picks rarely involve future high picks
    else {
      _generateDayThreeFuturePackages(
        packages, 
        teamOffering, 
        teamReceiving, 
        sortedPicks, 
        targetPick, 
        additionalTargetPicks, 
        targetValue, 
        teamStatus
      );
    }
  }
  
  /// Future pick packages for top 10 selections
  void _generateTopPickFuturePackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TeamBuildStatus teamStatus
  ) {
    // For top 10 picks, often requires current 1st + future 1st
    if (sortedPicks.isEmpty) return;
    
    // Find team's best pick (likely a 1st rounder)
    DraftPick bestPick = sortedPicks.first;
    double bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
    
    // Only proceed if best pick is a 1st or high 2nd rounder
    if (bestPick.pickNumber > 45) return;
    
    // Create a future 1st round pick
    FuturePick futurePick = FuturePick.forRound(teamOffering, 1);
    double futurePickValue = futurePick.value;
    
    // Check if best pick + future 1st is enough
    double combinedValue = bestPickValue + futurePickValue;
    if (combinedValue >= targetValue * minAcceptableValueRatio && 
        combinedValue <= targetValue * maxAcceptableValueRatio) {
      packages.add(TradePackage(
        teamOffering: teamOffering,
        teamReceiving: teamReceiving,
        picksOffered: [bestPick],
        targetPick: targetPick,
        additionalTargetPicks: additionalTargetPicks,
        totalValueOffered: combinedValue,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: futurePick.description,
        futurePickValue: futurePickValue,
      ));
    }
    
    // If that's not enough, try best pick + a mid-rounder + future 1st
    if (sortedPicks.length >= 2 && 
        combinedValue < targetValue * minAcceptableValueRatio) {
      for (int i = 1; i < min(sortedPicks.length, 5); i++) {
        DraftPick secondPick = sortedPicks[i];
        double secondPickValue = DraftValueService.getValueForPick(secondPick.pickNumber);
        double totalValue = bestPickValue + secondPickValue + futurePickValue;
        
        if (totalValue >= targetValue * minAcceptableValueRatio && 
            totalValue <= targetValue * maxAcceptableValueRatio) {
          packages.add(TradePackage(
            teamOffering: teamOffering,
            teamReceiving: teamReceiving,
            picksOffered: [bestPick, secondPick],
            targetPick: targetPick,
            additionalTargetPicks: additionalTargetPicks,
            totalValueOffered: totalValue,
            targetPickValue: targetValue,
            includesFuturePick: true,
            futurePickDescription: futurePick.description,
            futurePickValue: futurePickValue,
          ));
          break; // One combination is enough
        }
      }
    }
    
    // For rebuilding teams, also offer current + future 1st + future 2nd
    if (teamStatus == TeamBuildStatus.rebuilding) {
      FuturePick future2nd = FuturePick.forRound(teamOffering, 2);
      double future2ndValue = future2nd.value;
      double totalValue = bestPickValue + futurePickValue + future2ndValue;
      
      if (totalValue >= targetValue * minAcceptableValueRatio &&
          totalValue <= targetValue * maxAcceptableValueRatio) {
        String futureDescription = "${futurePick.description} and ${future2nd.description}";
        packages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [bestPick],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: totalValue,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: futureDescription,
          futurePickValue: futurePickValue + future2ndValue,
        ));
      }
    }
  }
  
  /// Future pick packages for first round selections (11-32)
  void _generateFirstRoundFuturePackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TeamBuildStatus teamStatus
  ) {
    if (sortedPicks.isEmpty) return;
    
    // Find team's best pick
    DraftPick bestPick = sortedPicks.first;
    double bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
    
    // For later 1st rounders, often a future 2nd is included
    FuturePick futurePick = FuturePick.forRound(teamOffering, 2);
    double futurePickValue = futurePick.value;
    
    // Check if best pick + future 2nd is enough
    double combinedValue = bestPickValue + futurePickValue;
    if (combinedValue >= targetValue * minAcceptableValueRatio && 
        combinedValue <= targetValue * maxAcceptableValueRatio) {
      packages.add(TradePackage(
        teamOffering: teamOffering,
        teamReceiving: teamReceiving,
        picksOffered: [bestPick],
        targetPick: targetPick,
        additionalTargetPicks: additionalTargetPicks,
        totalValueOffered: combinedValue,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: futurePick.description,
        futurePickValue: futurePickValue,
      ));
    }
    
    // If team is win-now, sometimes they'll offer a future 1st for current 1st
    if (teamStatus == TeamBuildStatus.winNow && targetPick.pickNumber <= 32) {
      FuturePick future1st = FuturePick.forRound(teamOffering, 1);
      double future1stValue = future1st.value;
      
      // If the pick is near the current 1st round value, might be enough alone
      if (future1stValue >= targetValue * minAcceptableValueRatio) {
        packages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: future1stValue,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: future1st.description,
          futurePickValue: future1stValue,
        ));
      }
      
      // Or maybe a non-1st rounder + future 1st
      if (sortedPicks.length >= 2 && bestPick.pickNumber > 32) {
        double totalValue = bestPickValue + future1stValue;
        if (totalValue >= targetValue * minAcceptableValueRatio &&
            totalValue <= targetValue * maxAcceptableValueRatio) {
          packages.add(TradePackage(
            teamOffering: teamOffering,
            teamReceiving: teamReceiving,
            picksOffered: [bestPick],
            targetPick: targetPick,
            additionalTargetPicks: additionalTargetPicks,
            totalValueOffered: totalValue,
            targetPickValue: targetValue,
            includesFuturePick: true,
            futurePickDescription: future1st.description,
            futurePickValue: future1stValue,
          ));
        }
      }
    }
  }
  
  /// Future pick packages for day 2 picks (33-105)
  void _generateDayTwoFuturePackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TeamBuildStatus teamStatus
  ) {
    if (sortedPicks.isEmpty) return;
    
    // Find team's best pick
    DraftPick bestPick = sortedPicks.first;
    double bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
    
    // Day 2 often involves future 3rd or 4th rounders
    int futureRound = _random.nextInt(2) + 3; // 3rd or 4th
    FuturePick futurePick = FuturePick.forRound(teamOffering, futureRound);
    double futurePickValue = futurePick.value;
    
    // Check if best pick + future pick is enough
    double combinedValue = bestPickValue + futurePickValue;
    if (combinedValue >= targetValue * minAcceptableValueRatio && 
        combinedValue <= targetValue * maxAcceptableValueRatio) {
      packages.add(TradePackage(
        teamOffering: teamOffering,
        teamReceiving: teamReceiving,
        picksOffered: [bestPick],
        targetPick: targetPick,
        additionalTargetPicks: additionalTargetPicks,
        totalValueOffered: combinedValue,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: futurePick.description,
        futurePickValue: futurePickValue,
      ));
    }
    
    // For early 2nd round, sometimes involves a future 2nd
    if (targetPick.pickNumber <= 50) {
      FuturePick future2nd = FuturePick.forRound(teamOffering, 2);
      double future2ndValue = future2nd.value;
      
      // If the team has a good non-Day 2 pick, might package with future 2nd
      for (var pick in sortedPicks) {
        if (pick.pickNumber <= 32 || pick.pickNumber > 105) {
          double pickValue = DraftValueService.getValueForPick(pick.pickNumber);
          double totalValue = pickValue + future2ndValue;
          
          if (totalValue >= targetValue * minAcceptableValueRatio &&
              totalValue <= targetValue * maxAcceptableValueRatio) {
            packages.add(TradePackage(
              teamOffering: teamOffering,
              teamReceiving: teamReceiving,
              picksOffered: [pick],
              targetPick: targetPick,
              additionalTargetPicks: additionalTargetPicks,
              totalValueOffered: totalValue,
              targetPickValue: targetValue,
              includesFuturePick: true,
              futurePickDescription: future2nd.description,
              futurePickValue: future2ndValue,
            ));
            break;
          }
        }
      }
    }
  }
  
  /// Future pick packages for day 3 picks (106+)
  void _generateDayThreeFuturePackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TeamBuildStatus teamStatus
  ) {
    if (sortedPicks.isEmpty) return;
    
    // Find team's best Day 3 pick
    DraftPick? bestDay3Pick;
    for (var pick in sortedPicks) {
      if (pick.pickNumber > 105) {
        bestDay3Pick = pick;
        break;
      }
    }
    
    // If no Day 3 pick available, use best available
    bestDay3Pick ??= sortedPicks.first;
    
    double bestPickValue = DraftValueService.getValueForPick(bestDay3Pick.pickNumber);
    
    // Day 3 often involves future 5th-7th rounders
    int futureRound = _random.nextInt(3) + 5; // 5th, 6th, or 7th
    FuturePick futurePick = FuturePick.forRound(teamOffering, futureRound);
    double futurePickValue = futurePick.value;
    
    // Check if best pick + future pick is enough
    double combinedValue = bestPickValue + futurePickValue;
    if (combinedValue >= targetValue * minAcceptableValueRatio && 
        combinedValue <= targetValue * maxAcceptableValueRatio) {
      packages.add(TradePackage(
        teamOffering: teamOffering,
        teamReceiving: teamReceiving,
        picksOffered: [bestDay3Pick],
        targetPick: targetPick,
        additionalTargetPicks: additionalTargetPicks,
        totalValueOffered: combinedValue,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: futurePick.description,
        futurePickValue: futurePickValue,
      ));
    }
  }
  
  /// Apply parity helper for unbalanced trades
  List<TradePackage> _applyParityHelper(List<TradePackage> packages, double targetValue) {
    List<TradePackage> adjustedPackages = [];
    
    for (var package in packages) {
      // Check if the offered value is much higher than needed (>120%)
      double valueRatio = package.totalValueOffered / targetValue;
      if (valueRatio > 1.2) {
        // Try to find a smaller pick from the receiving team to balance
        DraftPick targetPick = package.targetPick;
        String receivingTeam = package.teamReceiving;
        
        // Create hypothetical parity picks (don't actually have pick database here)
        // In real implementation, you'd search through available picks
        List<DraftPick> parityOptions = [
          DraftPick(
            pickNumber: targetPick.pickNumber + 100, 
            teamName: receivingTeam, 
            round: (targetPick.pickNumber ~/ 32 + 3).toString()
          ),
          DraftPick(
            pickNumber: targetPick.pickNumber + 70, 
            teamName: receivingTeam, 
            round: (targetPick.pickNumber ~/ 32 + 2).toString()
          ),
          DraftPick(
            pickNumber: targetPick.pickNumber + 40, 
            teamName: receivingTeam, 
            round: (targetPick.pickNumber ~/ 32 + 1).toString()
          ),
        ];
        
        // Find the best pick that brings ratio closest to 1.0
        for (var parityPick in parityOptions) {
          double parityValue = DraftValueService.getValueForPick(parityPick.pickNumber);
          double adjustedValue = package.totalValueOffered - parityValue;
          double newRatio = adjustedValue / targetValue;
          
          // If this brings us closer to 1.0 ratio but still >= 1.0
          if (newRatio >= 1.0 && newRatio < valueRatio) {
            adjustedPackages.add(TradePackage(
              teamOffering: package.teamOffering,
              teamReceiving: package.teamReceiving,
              picksOffered: package.picksOffered,
              targetPick: package.targetPick,
              additionalTargetPicks: [...package.additionalTargetPicks, parityPick],
              totalValueOffered: adjustedValue,
              targetPickValue: targetValue,
              includesFuturePick: package.includesFuturePick,
              futurePickDescription: package.futurePickDescription,
              futurePickValue: package.futurePickValue,
              targetReceivedFuturePicks: package.targetReceivedFuturePicks,
            ));
            break;
          }
          }
    }
    
    // Always keep the original package too
    adjustedPackages.add(package);
    }
    
    return adjustedPackages;
  }
}