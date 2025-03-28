// lib/services/advanced_package_generator.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/trade_package.dart';
import '../models/future_pick.dart';
import '../models/trade_motivation.dart';
import 'draft_value_service.dart';
import 'team_classification.dart';
import 'position_value_tracker.dart';

/// Generates optimized trade packages based on actual NFL draft trade patterns
class AdvancedPackageGenerator {
  // Random generator for stochasticity
  final Random _random = Random();
  
  // Configuration
  final double baseValueTarget;
  final int maxPicksInPackage;
  final bool enableFuturePicks;
  final bool enableParityHelper;
  final bool enforceRealismConstraints;
  
  // Value thresholds
  final double minValueRatio;
  final double maxValueRatio;
  final double idealValueRatio;
  
  // Position value tracker
  final PositionValueTracker? positionTracker;
  
  // Known trade patterns based on historical data
  final Map<String, List<List<int>>> _historicalTradePatterns = {
    // Patterns for top 10 picks
    'top_10': [
      [1, 1, 3],      // Current 1st + future 1st + 3rd round
      [1, 1],         // Current 1st + future 1st
      [1, 2, 4],      // Current 1st + 2nd + 4th
      [1, 2, 3, 4],   // Current 1st + 2nd + 3rd + 4th
    ],
    
    // Patterns for picks 11-20
    'mid_1st': [
      [1, 3],         // Current 1st + 3rd
      [1, 4],         // Current 1st + 4th
      [2, 2],         // Two 2nd round picks
      [2, 3, 5],      // 2nd + 3rd + 5th
    ],
    
    // Patterns for picks 21-32
    'late_1st': [
      [2, 3],         // 2nd + 3rd
      [2, 4, 6],      // 2nd + 4th + 6th
      [2, 4],         // 2nd + 4th
      [1, 5],         // Future 1st + 5th (less common)
    ],
    
    // Patterns for early 2nd round
    'early_2nd': [
      [2, 4],         // 2nd + 4th 
      [3, 3],         // Two 3rd round picks
      [3, 4, 5],      // 3rd + 4th + 5th
    ],
    
    // Patterns for mid-to-late 2nd round
    'late_2nd': [
      [3, 4],         // 3rd + 4th
      [3, 5, 6],      // 3rd + 5th + 6th
      [3, 6],         // 3rd + 6th
    ],
    
    // Patterns for 3rd round
    '3rd': [
      [4, 5],         // 4th + 5th
      [4, 6],         // 4th + 6th
      [4, 7, 7],      // 4th + two 7ths
    ],
    
    // Patterns for day 3 (rounds 4-7)
    'day_3': [
      [5, 6],         // 5th + 6th
      [6, 7],         // 6th + 7th
      [5, 7],         // 5th + 7th
      [1, 6],         // Future 5th + 6th
      [1],            // Future 4th
    ],
  };
  
  // Constructor
  AdvancedPackageGenerator({
    this.baseValueTarget = 1.0,
    this.maxPicksInPackage = 3,
    this.enableFuturePicks = true,
    this.enableParityHelper = true,
    this.enforceRealismConstraints = true,
    this.minValueRatio = 0.9,
    this.maxValueRatio = 1.15,
    this.idealValueRatio = 1.05,
    this.positionTracker,
  });
  
  /// Generate a realistic trade package
  List<TradePackage> generatePackages({
    required String teamOffering,
    required String teamReceiving,
    required List<DraftPick> availablePicks,
    required DraftPick targetPick,
    List<DraftPick> additionalTargetPicks = const [],
    required TradeMotivation motivation,
    bool isQBDriven = false,
    bool isUserInitiated = false,
    bool isCounterOffer = false,
  }) {
    // Track metrics for debugging
    int totalCombinationsEvaluated = 0;
    int viablePackagesFound = 0;
    
    // Calculate base target value
    double targetValue = DraftValueService.getValueForPick(targetPick.pickNumber);
    for (var additionalPick in additionalTargetPicks) {
      targetValue += DraftValueService.getValueForPick(additionalPick.pickNumber);
    }
    
    // Apply motivation-based value adjustments
    targetValue = _applyMotivationAdjustments(
      targetValue,
      targetPick,
      motivation,
      isQBDriven,
      isUserInitiated,
      isCounterOffer
    );
    
    debugPrint('Generating packages for pick #${targetPick.pickNumber}.');
    debugPrint('Base target value: $targetValue with adjustments applied.');
    
    // Get the pick pattern category
    String patternCategory = _getPatternCategory(targetPick.pickNumber);
    
    // Sort available picks by value (descending)
    List<DraftPick> sortedPicks = List.from(availablePicks);
    sortedPicks.sort((a, b) => 
      DraftValueService.getValueForPick(b.pickNumber).compareTo(
        DraftValueService.getValueForPick(a.pickNumber)
      )
    );
    
    // Generate packages using historical patterns as guides
    List<TradePackage> packages = [];
    
    // 1. Try pattern-based packages first (most realistic)
    if (enforceRealismConstraints) {
      _generatePatternBasedPackages(
        packages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        patternCategory,
        motivation,
        isQBDriven
      );
      
      totalCombinationsEvaluated += _historicalTradePatterns[patternCategory]?.length ?? 0;
      viablePackagesFound = packages.length;
      
      debugPrint('Generated ${packages.length} pattern-based packages.');
    }
    
    // 2. Try optimized combinations if not enough pattern-based packages
    if (packages.length < 3) {
      int additionalPackagesNeeded = 3 - packages.length;
      
      List<TradePackage> optimizedPackages = _generateOptimizedPackages(
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        motivation,
        isQBDriven,
        maxAdditionalPackages: additionalPackagesNeeded
      );
      
      totalCombinationsEvaluated += 100; // Approximate for logging
      viablePackagesFound += optimizedPackages.length;
      packages.addAll(optimizedPackages);
      
      debugPrint('Added ${optimizedPackages.length} optimized packages.');
    }
    
    // 3. Apply future picks if appropriate
    if (enableFuturePicks && packages.length < 2 && _shouldConsiderFuturePicks(targetPick.pickNumber)) {
      List<TradePackage> futurePickPackages = _generateFuturePickPackages(
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        motivation,
        isQBDriven
      );
      
      totalCombinationsEvaluated += 10; // Approximate for logging
      viablePackagesFound += futurePickPackages.length;
      packages.addAll(futurePickPackages);
      
      debugPrint('Added ${futurePickPackages.length} future pick packages.');
    }
    
    // 4. Filter to reasonable range and sort by realism
    packages = _filterAndRankPackages(packages, targetValue);
    
    // For user-initiated offers or counter-offers, adjust acceptable range
    if (isUserInitiated || isCounterOffer) {
      // Users can get away with slightly less value
      packages = packages.where((p) => 
        p.totalValueOffered / targetValue >= minValueRatio * 0.9
      ).toList();
    }
    
    // Apply parity helper for unbalanced trades if enabled
    if (enableParityHelper) {
      packages = _applyParityHelper(packages, targetValue);
    }
    
    // Log statistics
    debugPrint('Total combinations evaluated: $totalCombinationsEvaluated');
    debugPrint('Viable packages found: $viablePackagesFound');
    debugPrint('Final package count: ${packages.length}');
    
    return packages;
  }
  
  /// Apply motivation-based value adjustments
  double _applyMotivationAdjustments(
    double baseValue,
    DraftPick targetPick,
    TradeMotivation motivation,
    bool isQBDriven,
    bool isUserInitiated,
    bool isCounterOffer
  ) {
    double adjustedValue = baseValue;
    
    // 1. Apply motivation-based adjustments
    if (motivation.isTargetingSpecificPlayer) {
      adjustedValue *= 1.05; // 5% premium for specific player targeting
      
      // Additional premium for premium positions
      if (['QB', 'EDGE', 'OT', 'CB'].contains(motivation.targetedPosition)) {
        adjustedValue *= 1.05; // Additional 5% for premium positions
      }
      
      // Extreme premium for QB-driven trades
      if (isQBDriven || motivation.targetedPosition == 'QB') {
        adjustedValue *= 1.1; // 10% premium for QBs
      }
    }
    
    if (motivation.isPreventingRival) {
      adjustedValue *= 1.07; // 7% premium to prevent rival
      
      // Additional premium for division rivals
      if (motivation.isDivisionRival) {
        adjustedValue *= 1.05; // 5% more for division rivals
      }
    }
    
    if (motivation.isTierDropoff) {
      adjustedValue *= 1.08; // 8% premium for tier dropoff urgency
    }
    
    if (motivation.isPositionRun) {
      adjustedValue *= 1.06; // 6% premium during position runs
    }
    
    // 2. Apply user-related adjustments
    if (isUserInitiated) {
      adjustedValue *= 0.95; // 5% discount when user initiates (they have leverage)
    }
    
    if (isCounterOffer) {
      adjustedValue *= 0.93; // 7% discount for counter offers (strong leverage)
    }
    
    // 3. Apply position-based adjustments if position tracker available
    if (positionTracker != null && motivation.targetedPosition.isNotEmpty) {
      // Get the market adjustment for this position
      double marketAdjustment = positionTracker!.getContextAdjustedPremium(
        motivation.targetedPosition, 
        []  // Ideally would pass available players, but we don't have them here
      );
      
      adjustedValue *= marketAdjustment;
    }
    
    // 4. Apply round-based adjustments
    int round = DraftValueService.getRoundForPick(targetPick.pickNumber);
    if (round == 1) {
      if (targetPick.pickNumber <= 10) {
        adjustedValue *= 1.1; // 10% premium for top 10 picks
      } else {
        adjustedValue *= 1.05; // 5% premium for other 1st round picks
      }
    }
    
    return adjustedValue;
  }
  
  /// Generate packages based on historical trade patterns
  void _generatePatternBasedPackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    String patternCategory,
    TradeMotivation motivation,
    bool isQBDriven
  ) {
    // Get patterns for this category
    List<List<int>> patterns = _historicalTradePatterns[patternCategory] ?? [];
    
    // Group picks by round
    Map<int, List<DraftPick>> picksByRound = {};
    for (var pick in sortedPicks) {
      int round = DraftValueService.getRoundForPick(pick.pickNumber);
      if (!picksByRound.containsKey(round)) {
        picksByRound[round] = [];
      }
      picksByRound[round]!.add(pick);
    }
    
    // Try each pattern
    for (var pattern in patterns) {
      List<DraftPick> packagePicks = [];
      bool patternValid = true;
      double packageValue = 0;
      bool usesFuturePick = false;
      String? futurePickDescription;
      double futurePickValue = 0;
      
      // Process each round in the pattern
      for (var round in pattern) {
        if (round == 1 && pattern.indexOf(round) == 1) {
          // This is a future 1st round pick
          if (enableFuturePicks) {
            usesFuturePick = true;
            var futurePick = FuturePick.forRound(teamOffering, 1);
            futurePickDescription = futurePick.description;
            futurePickValue = futurePick.value;
            packageValue += futurePickValue;
          } else {
            patternValid = false;
            break;
          }
        } 
        else if (round == 1 && pattern.length >= 2 && pattern[1] == 1) {
          // Current 1st + future 1st pattern
          if (picksByRound.containsKey(round) && picksByRound[round]!.isNotEmpty) {
            var pick = picksByRound[round]!.first;
            packagePicks.add(pick);
            packageValue += DraftValueService.getValueForPick(pick.pickNumber);
            
            // Mark the pick as used by removing it
            picksByRound[round]!.remove(pick);
            
            if (enableFuturePicks) {
              usesFuturePick = true;
              var futurePick = FuturePick.forRound(teamOffering, 1);
              futurePickDescription = futurePick.description;
              futurePickValue = futurePick.value;
              packageValue += futurePickValue;
            } else {
              patternValid = false;
              break;
            }
          } else {
            patternValid = false;
            break;
          }
        }
        else if (picksByRound.containsKey(round) && picksByRound[round]!.isNotEmpty) {
          // Regular current year pick
          var pick = picksByRound[round]!.first;
          packagePicks.add(pick);
          packageValue += DraftValueService.getValueForPick(pick.pickNumber);
          
          // Mark the pick as used by removing it
          picksByRound[round]!.remove(pick);
        } else {
          // Don't have a pick in this round
          patternValid = false;
          break;
        }
      }
      
      // If pattern is valid and value is reasonable, create package
      if (patternValid) {
        double valueRatio = packageValue / targetValue;
        if (valueRatio >= minValueRatio && valueRatio <= maxValueRatio) {
          packages.add(TradePackage(
            teamOffering: teamOffering,
            teamReceiving: teamReceiving,
            picksOffered: packagePicks,
            targetPick: targetPick,
            additionalTargetPicks: additionalTargetPicks,
            totalValueOffered: packageValue,
            targetPickValue: targetValue,
            includesFuturePick: usesFuturePick,
            futurePickDescription: futurePickDescription,
            futurePickValue: futurePickValue,
          ));
        }
      }
      
      // Restore picks for next pattern
      picksByRound.clear();
      for (var pick in sortedPicks) {
        int round = DraftValueService.getRoundForPick(pick.pickNumber);
        if (!picksByRound.containsKey(round)) {
          picksByRound[round] = [];
        }
        picksByRound[round]!.add(pick);
      }
    }
  }
  
  /// Get pattern category based on pick number
  String _getPatternCategory(int pickNumber) {
    if (pickNumber <= 10) return 'top_10';
    if (pickNumber <= 20) return 'mid_1st';
    if (pickNumber <= 32) return 'late_1st';
    if (pickNumber <= 48) return 'early_2nd';
    if (pickNumber <= 64) return 'late_2nd';
    if (pickNumber <= 105) return '3rd';
    return 'day_3';
  }
  
  /// Whether to consider future picks for a given pick position
  bool _shouldConsiderFuturePicks(int pickNumber) {
    // Future picks are more common in certain ranges
    if (pickNumber <= 15) return true;   // Very common for top picks
    if (pickNumber <= 32) return true;   // Common for 1st round
    if (pickNumber <= 64) return _random.nextDouble() < 0.5;  // 50% for 2nd round
    return _random.nextDouble() < 0.2;   // 20% for later rounds
  }
  
  /// Generate packages using optimized combinations
  List<TradePackage> _generateOptimizedPackages(
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TradeMotivation motivation,
    bool isQBDriven,
    {int maxAdditionalPackages = 3}
  ) {
    List<TradePackage> optimizedPackages = [];
    
    // Calculate acceptable value range
    double minValue = targetValue * minValueRatio;
    double maxValue = targetValue * maxValueRatio;
    double idealValue = targetValue * idealValueRatio;
    
    // Try single pick packages first (simplest)
    for (var pick in sortedPicks) {
      double pickValue = DraftValueService.getValueForPick(pick.pickNumber);
      if (pickValue >= minValue && pickValue <= maxValue) {
        optimizedPackages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [pick],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: pickValue,
          targetPickValue: targetValue,
        ));
        
        // If we have enough packages, stop
        if (optimizedPackages.length >= maxAdditionalPackages) {
          return optimizedPackages;
        }
      }
    }
    
    // Try two-pick combinations if needed
    if (maxPicksInPackage >= 2 && optimizedPackages.length < maxAdditionalPackages) {
      for (int i = 0; i < sortedPicks.length; i++) {
        double value1 = DraftValueService.getValueForPick(sortedPicks[i].pickNumber);
        if (value1 > maxValue) continue; // Skip if first pick alone exceeds max
        
        for (int j = i + 1; j < sortedPicks.length; j++) {
          double value2 = DraftValueService.getValueForPick(sortedPicks[j].pickNumber);
          double combinedValue = value1 + value2;
          
          if (combinedValue >= minValue && combinedValue <= maxValue) {
            optimizedPackages.add(TradePackage(
              teamOffering: teamOffering,
              teamReceiving: teamReceiving,
              picksOffered: [sortedPicks[i], sortedPicks[j]],
              targetPick: targetPick,
              additionalTargetPicks: additionalTargetPicks,
              totalValueOffered: combinedValue,
              targetPickValue: targetValue,
            ));
            
            // If we have enough packages, stop
            if (optimizedPackages.length >= maxAdditionalPackages) {
              return optimizedPackages;
            }
          }
        }
      }
    }
    
    // Try three-pick combinations if needed
    if (maxPicksInPackage >= 3 && optimizedPackages.length < maxAdditionalPackages) {
      // Limit the search space for performance
      int maxCombinations = 100;
      int combinationsChecked = 0;
      
      for (int i = 0; i < sortedPicks.length; i++) {
        double value1 = DraftValueService.getValueForPick(sortedPicks[i].pickNumber);
        if (value1 > maxValue) continue; // Skip if first pick alone exceeds max
        
        for (int j = i + 1; j < sortedPicks.length; j++) {
          double value2 = DraftValueService.getValueForPick(sortedPicks[j].pickNumber);
          double twoPickValue = value1 + value2;
          
          if (twoPickValue > maxValue) continue; // Skip if two picks exceed max
          
          for (int k = j + 1; k < sortedPicks.length; k++) {
            combinationsChecked++;
            if (combinationsChecked > maxCombinations) break;
            
            double value3 = DraftValueService.getValueForPick(sortedPicks[k].pickNumber);
            double combinedValue = twoPickValue + value3;
            
            if (combinedValue >= minValue && combinedValue <= maxValue) {
              optimizedPackages.add(TradePackage(
                teamOffering: teamOffering,
                teamReceiving: teamReceiving,
                picksOffered: [sortedPicks[i], sortedPicks[j], sortedPicks[k]],
                targetPick: targetPick,
                additionalTargetPicks: additionalTargetPicks,
                totalValueOffered: combinedValue,
                targetPickValue: targetValue,
              ));
              
              // If we have enough packages, stop
              if (optimizedPackages.length >= maxAdditionalPackages) {
                return optimizedPackages;
              }
            }
          }
        }
      }
    }
    
    return optimizedPackages;
  }
  
  /// Generate packages with future picks
  List<TradePackage> _generateFuturePickPackages(
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    TradeMotivation motivation,
    bool isQBDriven
  ) {
    List<TradePackage> futurePickPackages = [];
    
    // Calculate acceptable value range
    double minValue = targetValue * minValueRatio;
    double maxValue = targetValue * maxValueRatio;
    
    // Different strategies based on pick position
    int targetPickNumber = targetPick.pickNumber;
    
    // For top 10 picks - often include a future 1st
    if (targetPickNumber <= 10) {
      _generateTopPickFuturePackages(
        futurePickPackages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        minValue,
        maxValue
      );
    }
    // First round picks (11-32)
    else if (targetPickNumber <= 32) {
      _generateFirstRoundFuturePackages(
        futurePickPackages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        minValue,
        maxValue
      );
    }
    // Day 2 picks (33-105)
    else if (targetPickNumber <= 105) {
      _generateDayTwoFuturePackages(
        futurePickPackages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        minValue,
        maxValue
      );
    }
    // Day 3 picks
    else {
      _generateDayThreeFuturePackages(
        futurePickPackages,
        teamOffering,
        teamReceiving,
        sortedPicks,
        targetPick,
        additionalTargetPicks,
        targetValue,
        minValue,
        maxValue
      );
    }
    
    return futurePickPackages;
  }
  
  /// Helper for top pick future packages
  void _generateTopPickFuturePackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    double minValue,
    double maxValue
  ) {
    if (sortedPicks.isEmpty) return;
    
    // For top picks, first try current 1st + future 1st
    DraftPick? firstRoundPick;
    for (var pick in sortedPicks) {
      if (DraftValueService.getRoundForPick(pick.pickNumber) == 1) {
        firstRoundPick = pick;
        break;
      }
    }
    
    if (firstRoundPick != null) {
      // Create future 1st round pick
      FuturePick futurePick = FuturePick.forRound(teamOffering, 1);
      double packageValue = DraftValueService.getValueForPick(firstRoundPick.pickNumber) + 
                           futurePick.value;
      
      if (packageValue >= minValue && packageValue <= maxValue) {
        packages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [firstRoundPick],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: packageValue,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: futurePick.description,
          futurePickValue: futurePick.value,
        ));
      }
      
      // If not enough, try adding a mid-round pick
      if (packageValue < minValue && sortedPicks.length >= 2) {
        for (int i = 0; i < sortedPicks.length; i++) {
          if (sortedPicks[i] == firstRoundPick) continue;
          
          double additionalValue = DraftValueService.getValueForPick(sortedPicks[i].pickNumber);
          double totalValue = packageValue + additionalValue;
          
          if (totalValue >= minValue && totalValue <= maxValue) {
            packages.add(TradePackage(
              teamOffering: teamOffering,
              teamReceiving: teamReceiving,
              picksOffered: [firstRoundPick, sortedPicks[i]],
              targetPick: targetPick,
              additionalTargetPicks: additionalTargetPicks,
              totalValueOffered: totalValue,
              targetPickValue: targetValue,
              includesFuturePick: true,
              futurePickDescription: futurePick.description,
              futurePickValue: futurePick.value,
            ));
            break;
          }
        }
      }
    }
    
    // Also try current high pick + future 2nd
    if (sortedPicks.isNotEmpty) {
      DraftPick bestPick = sortedPicks.first;
      FuturePick futurePick = FuturePick.forRound(teamOffering, 2);
      
      double packageValue = DraftValueService.getValueForPick(bestPick.pickNumber) + 
                         futurePick.value;
      
      if (packageValue >= minValue && packageValue <= maxValue) {
        packages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [bestPick],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: packageValue,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: futurePick.description,
          futurePickValue: futurePick.value,
        ));
      }
    }
  }
  
  /// Helper for first round future packages
  void _generateFirstRoundFuturePackages(
    List<TradePackage> packages,
    String teamOffering,
    String teamReceiving,
    List<DraftPick> sortedPicks,
    DraftPick targetPick,
    List<DraftPick> additionalTargetPicks,
    double targetValue,
    double minValue,
    double maxValue
  ) {
    if (sortedPicks.isEmpty) return;
    
    // For first round, try current pick + future 2nd or 3rd
    DraftPick bestPick = sortedPicks.first;
    
    // Try with a future 2nd
    FuturePick future2nd = FuturePick.forRound(teamOffering, 2);
    double packageValue = DraftValueService.getValueForPick(bestPick.pickNumber) + 
                       future2nd.value;
    
    if (packageValue >= minValue && packageValue <= maxValue) {
      packages.add(TradePackage(
        teamOffering: teamOffering,
        teamReceiving: teamReceiving,
        picksOffered: [bestPick],
        targetPick: targetPick,
        additionalTargetPicks: additionalTargetPicks,
        totalValueOffered: packageValue,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: future2nd.description,
        futurePickValue: future2nd.value,
      ));
    }
    
    // Try with a future 3rd if 2nd wasn't enough
    if (packageValue < minValue) {
      FuturePick future3rd = FuturePick.forRound(teamOffering, 3);
      double alternateValue = DraftValueService.getValueForPick(bestPick.pickNumber) + 
                           future3rd.value;
      
      if (alternateValue >= minValue && alternateValue <= maxValue) {
        packages.add(TradePackage(
          teamOffering: teamOffering,
          teamReceiving: teamReceiving,
          picksOffered: [bestPick],
          targetPick: targetPick,
          additionalTargetPicks: additionalTargetPicks,
          totalValueOffered: alternateValue,
          targetPickValue: targetValue,
          includesFuturePick: true,
          futurePickDescription: future3rd.description,
          futurePickValue: future3rd.value,
        ));
      }
    }
  }
  /// Generate Day 2 future pick packages (picks 33-105)
void _generateDayTwoFuturePackages(
  List<TradePackage> packages,
  String teamOffering,
  String teamReceiving,
  List<DraftPick> sortedPicks,
  DraftPick targetPick,
  List<DraftPick> additionalTargetPicks,
  double targetValue,
  double minValue,
  double maxValue
) {
  if (sortedPicks.isEmpty) return;
  
  // Find team's best pick
  DraftPick bestPick = sortedPicks.first;
  double bestPickValue = DraftValueService.getValueForPick(bestPick.pickNumber);
  
  // For day 2, common to include future mid-round picks (3rd-4th)
  int futureRound = _random.nextInt(2) + 3; // 3rd or 4th round
  FuturePick futurePick = FuturePick.forRound(teamOffering, futureRound);
  
  // Check if best pick + future pick is enough
  double packageValue = bestPickValue + futurePick.value;
  if (packageValue >= minValue && packageValue <= maxValue) {
    packages.add(TradePackage(
      teamOffering: teamOffering,
      teamReceiving: teamReceiving,
      picksOffered: [bestPick],
      targetPick: targetPick,
      additionalTargetPicks: additionalTargetPicks,
      totalValueOffered: packageValue,
      targetPickValue: targetValue,
      includesFuturePick: true,
      futurePickDescription: futurePick.description,
      futurePickValue: futurePick.value,
    ));
  }
  
  // If that's not enough and we have more picks, try adding a second current pick
  if (packageValue < minValue && sortedPicks.length > 1) {
    for (int i = 1; i < min(sortedPicks.length, 5); i++) {
      DraftPick secondPick = sortedPicks[i];
      double secondValue = DraftValueService.getValueForPick(secondPick.pickNumber);
      double totalValue = packageValue + secondValue;
      
      if (totalValue >= minValue && totalValue <= maxValue) {
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
          futurePickValue: futurePick.value,
        ));
        break; // Found a good combination
      }
    }
  }
}

/// Generate Day 3 future pick packages (picks 106+)
void _generateDayThreeFuturePackages(
  List<TradePackage> packages,
  String teamOffering,
  String teamReceiving,
  List<DraftPick> sortedPicks,
  DraftPick targetPick,
  List<DraftPick> additionalTargetPicks,
  double targetValue,
  double minValue,
  double maxValue
) {
  if (sortedPicks.isEmpty) return;
  
  // Find a reasonable day 3 pick to offer
  DraftPick? dayThreePick;
  for (var pick in sortedPicks) {
    if (pick.pickNumber > 105) {
      dayThreePick = pick;
      break;
    }
  }
  
  // If no day 3 pick, use best available
  dayThreePick ??= sortedPicks.first;
  
  // For day 3, common to include future late-round picks (5th-7th)
  int futureRound = _random.nextInt(3) + 5; // 5th, 6th, or 7th round
  FuturePick futurePick = FuturePick.forRound(teamOffering, futureRound);
  
  // Check if pick + future pick is enough
  double pickValue = DraftValueService.getValueForPick(dayThreePick.pickNumber);
  double packageValue = pickValue + futurePick.value;
  
  if (packageValue >= minValue && packageValue <= maxValue) {
    packages.add(TradePackage(
      teamOffering: teamOffering,
      teamReceiving: teamReceiving,
      picksOffered: [dayThreePick],
      targetPick: targetPick,
      additionalTargetPicks: additionalTargetPicks,
      totalValueOffered: packageValue,
      targetPickValue: targetValue,
      includesFuturePick: true,
      futurePickDescription: futurePick.description,
      futurePickValue: futurePick.value,
    ));
  }
  
  // For day 3, sometimes a single future pick is used (especially for late rounds)
  if (targetPick.pickNumber > 150) {
    // Just a future 4th or 5th for a late pick
    int soloFutureRound = _random.nextInt(2) + 4; // 4th or 5th
    FuturePick soloFuturePick = FuturePick.forRound(teamOffering, soloFutureRound);
    
    // No current picks, just the future pick
    if (soloFuturePick.value >= minValue && soloFuturePick.value <= maxValue) {
      packages.add(TradePackage(
        teamOffering: teamOffering,
        teamReceiving: teamReceiving,
        picksOffered: [],
        targetPick: targetPick,
        additionalTargetPicks: additionalTargetPicks,
        totalValueOffered: soloFuturePick.value,
        targetPickValue: targetValue,
        includesFuturePick: true,
        futurePickDescription: soloFuturePick.description,
        futurePickValue: soloFuturePick.value,
      ));
    }
  }
}
/// Filter packages to reasonable range and sort by realism/quality
List<TradePackage> _filterAndRankPackages(List<TradePackage> packages, double targetValue) {
  if (packages.isEmpty) return [];

  // Filter to acceptable value range
  List<TradePackage> filtered = packages.where((package) {
    double valueRatio = package.totalValueOffered / targetValue;
    return valueRatio >= minValueRatio && valueRatio <= maxValueRatio;
  }).toList();
  
  if (filtered.isEmpty) return [];
  
  // Sort packages by criteria:
  // 1. Value proximity to ideal ratio
  // 2. Fewer picks preferred (simpler trades)
  // 3. No future picks preferred (more concrete)
  filtered.sort((a, b) {
    // Primary sort: proximity to ideal ratio
    double ratioA = a.totalValueOffered / targetValue;
    double ratioB = b.totalValueOffered / targetValue;
    double diffA = (ratioA - idealValueRatio).abs();
    double diffB = (ratioB - idealValueRatio).abs();
    
    int compValue = diffA.compareTo(diffB);
    if (compValue != 0) return compValue;
    
    // Secondary sort: fewer picks preferred
    int picksA = a.picksOffered.length;
    int picksB = b.picksOffered.length;
    if (picksA != picksB) return picksA.compareTo(picksB);
    
    // Tertiary sort: no future picks preferred
    if (a.includesFuturePick != b.includesFuturePick) {
      return a.includesFuturePick ? 1 : -1;
    }
    
    return 0;
  });
  
  return filtered;
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