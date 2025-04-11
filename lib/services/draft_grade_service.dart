// lib/services/draft_grade_service.dart

import 'dart:math';

import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../services/draft_value_service.dart';
import 'draft_pick_grade_service.dart';

/// Service responsible for calculating draft pick and team grades
class DraftGradeService {
  // Position value coefficients - how valuable each position is in the NFL draft
  static const Map<String, double> positionValueCoefficients = {
    'QB': 1.5,   // Premium for franchise QBs
    'OT': 1.3,   // Elite offensive tackles
    'EDGE': 1.3, // Elite pass rushers
    'CB': 1.2,   // Cornerbacks
    'WR': 1.15,  // Wide receivers
    'S': 1.1,    // Safeties
    'TE': 1.05,  // Tight ends
    'DT': 1.05,  // Interior defensive line
    'IOL': 1.0,  // Interior offensive line
    'LB': 0.95,  // Linebackers
    'RB': 0.9,   // Running backs typically devalued
    // Default for other positions is 1.0
  };

  // Team need importance factors
  static const Map<int, double> needImportanceFactor = {
    0: 0.25,  // Top need gets 25% boost
    1: 0.2,   // Second need gets 20% boost
    2: 0.15,  // Third need gets 15% boost
    3: 0.1,   // Fourth need gets 10% boost
    4: 0.05,  // Fifth need gets 5% boost
    // Beyond fifth need or not a need: no boost
  };

  /// Calculate individual pick grade with advanced factors
  static Map<String, dynamic> calculatePickGrade(
    DraftPick pick, 
    List<TeamNeed> teamNeeds,
    [bool considerTeamNeeds = true]
  ) {
    if (pick.selectedPlayer == null) {
      return {
        'grade': 'N/A',
        'numericGrade': 0.0,
        'letterGrade': 'N/A',
        'factors': {},
      };
    }

    final player = pick.selectedPlayer!;
    final int pickNumber = pick.pickNumber;
    final int playerRank = player.rank;
    final String position = player.position;
    
    // Base value differential (traditional calculation)
    int baseValueDiff = pickNumber - playerRank;
    
    // Calculate round for expectation adjustment
    int round = DraftValueService.getRoundForPick(pickNumber);
    double roundFactor = getRoundExpectationFactor(round);
    
    // Apply positional value coefficient
    double positionCoefficient = positionValueCoefficients[position] ?? 1.0;
    
    // Apply team need factor if requested
    double needFactor = 1.0;
    int needIndex = -1;
    
    if (considerTeamNeeds) {
      // Find team needs
      TeamNeed? teamNeed = teamNeeds.firstWhere(
        (need) => need.teamName == pick.teamName,
        orElse: () => TeamNeed(teamName: pick.teamName, needs: [])
      );
      
      // Check if position is in team needs
      needIndex = teamNeed.needs.indexOf(position);
      if (needIndex >= 0 && needIndex < 5) {
        needFactor = 1.0 + needImportanceFactor[needIndex]!;
      }
    }
    
    // Calculate the comprehensive grade with all factors
    double adjustedValueDiff = baseValueDiff * positionCoefficient * needFactor * roundFactor;
    
    // Store all the factors that went into the calculation
    Map<String, dynamic> factors = {
      'baseValueDiff': baseValueDiff,
      'positionCoefficient': positionCoefficient,
      'needFactor': needFactor,
      'roundFactor': roundFactor,
      'adjustedValueDiff': adjustedValueDiff,
      'needIndex': needIndex,
      'round': round,
    };
    
    // Convert to letter grade
    String letterGrade = getLetterGrade(adjustedValueDiff);
    
    return {
      'grade': adjustedValueDiff,
      'numericGrade': adjustedValueDiff,
      'letterGrade': letterGrade,
      'factors': factors,
    };
  }

  /// Generate description based on team grade
static String _generateTeamGradeDescription(
  String grade, 
  Map<String, dynamic> factors
) {
  // Extract key factors
  double avgWeightedValue = factors['avgWeightedValue'] ?? 0.0;
  double tradeValue = factors['tradeValue'] ?? 0.0;
  
  // Base descriptions for each grade
  switch (grade) {
    case 'A+':
      return 'Exceptional draft with outstanding value across all rounds. '
             'Demonstrated strategic excellence in player selection and trades.';
    case 'A':
      return 'Excellent draft with high-quality picks, especially in early rounds. '
             'Showed strong value assessment and strategic drafting.';
    case 'B+':
      return 'Very good draft with solid value picks and good trade management. '
             'Addressed key team needs effectively.';
    case 'B':
      return 'Solid draft with good value selections. '
             'Demonstrated moderate success in player acquisition.';
    case 'C+':
      return 'Average draft with some promising picks but missed opportunities. '
             'Showed potential but room for improvement.';
    case 'C':
      return 'Below average draft with several reaches and unfilled needs. '
             'Requires more strategic approach in future drafts.';
    case 'D':
      return 'Poor draft with significant value losses and strategic missteps. '
             'Needs substantial improvement in draft strategy.';
    default:
      return 'Draft performance could not be definitively assessed.';
  }
}

/// Calculate team overall grade with a comprehensive approach
static Map<String, dynamic> calculateTeamGrade(
  List<DraftPick> picks,
  List<TradePackage> trades,
  List<TeamNeed> teamNeeds,
  {bool debug = true}
) {
  final StringBuffer debugLog = StringBuffer();
  
  if (debug) {
    debugLog.writeln("\n===== TEAM GRADE CALCULATION DEBUG =====");
  }
  
  if (picks.isEmpty) {
    if (debug) {
      debugLog.writeln("No picks made, returning N/A");
      debugPrint(debugLog.toString());
    }
    
    return {
      'grade': 'N/A',
      'value': 0.0,
      'description': 'No picks made',
      'letterGrade': 'N/A',
      'factors': {},
    };
  }

  // Get team name from first pick
  String teamName = picks.first.teamName;
  
  if (debug) {
    debugLog.writeln("Team: $teamName");
    debugLog.writeln("Total Picks: ${picks.length}");
    debugLog.writeln("Total Trades: ${trades.length}");
  }
  
  // 1. INDIVIDUAL PICK GRADES - Calculate for each pick
  if (debug) debugLog.writeln("\n1. INDIVIDUAL PICK GRADES:");
  
  List<Map<String, dynamic>> pickGrades = [];
  double totalPickScore = 0.0;
  double weightedTotal = 0.0;
  double totalWeight = 0.0;
  List<String> letterGrades = []; // Track letter grades for debugging
  
  for (var pick in picks) {
    if (pick.selectedPlayer == null) continue;
    
    // Calculate pick grade
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds, debug: false);
    double pickScore = gradeInfo['grade'];
    String letterGrade = gradeInfo['letter'];
    letterGrades.add(letterGrade); // Store letter grade
    pickGrades.add(gradeInfo);
    
    // Determine pick weight - much higher for early rounds
    double pickWeight;
    int round = DraftValueService.getRoundForPick(pick.pickNumber);
    
    // Exponentially decreasing weights by round
    if (round == 1) pickWeight = 4.0;      // 1st round: 4x weight
    else if (round == 2) pickWeight = 2.0; // 2nd round: 2x weight
    else if (round == 3) pickWeight = 1.0; // 3rd round: 1x weight
    else if (round == 4) pickWeight = 0.5; // 4th round: 0.5x weight
    else if (round == 5) pickWeight = 0.25; // 5th round: 0.25x weight
    else pickWeight = 0.1;                 // Later rounds: minimal impact
    
    // Extra weight for very early picks
    if (pick.pickNumber <= 10) pickWeight *= 1.5; // Top 10 picks are extra important
    else if (pick.pickNumber <= 20) pickWeight *= 1.2; // Top 20 picks are very important
    
    // Add to totals
    totalPickScore += pickScore;
    weightedTotal += pickScore * pickWeight;
    totalWeight += pickWeight;
    
    if (debug) {
      debugLog.writeln("Pick #${pick.pickNumber} (Round $round): ${pick.selectedPlayer!.name} (${pick.selectedPlayer!.position})");
      debugLog.writeln("  Grade: $letterGrade (${pickScore.toStringAsFixed(1)}) | Weight: ${pickWeight.toStringAsFixed(1)}");
      debugLog.writeln("  Weighted Contribution: ${(pickScore * pickWeight).toStringAsFixed(1)}");
    }
  }
  
  // Calculate weighted average score from picks
  double avgPickScore = totalWeight > 0 ? weightedTotal / totalWeight : 0.0;
  
  if (debug) {
    debugLog.writeln("\nTotal Pick Score: ${totalPickScore.toStringAsFixed(1)}");
    debugLog.writeln("Total Weight: ${totalWeight.toStringAsFixed(1)}");
    debugLog.writeln("Weighted Total: ${weightedTotal.toStringAsFixed(1)}");
    debugLog.writeln("WEIGHTED AVERAGE PICK SCORE: ${avgPickScore.toStringAsFixed(2)}");
    debugLog.writeln("Individual Letter Grades: ${letterGrades.join(', ')}");
  }
  
  // 2. TRADE VALUE ASSESSMENT - Separate component
  if (debug) debugLog.writeln("\n2. TRADE VALUE ASSESSMENT:");
  
  double tradeGradeScore = 6.0; // Default "B-" trade grade (neutral)
  double tradeFactor = 0.0;     // How much trades impact overall grade
  
  if (trades.isEmpty) {
    if (debug) debugLog.writeln("No trades executed - using neutral trade grade (6.0)");
  } else {
    double totalTradeValue = 0.0;
    double tradeCount = 0;
    
    for (var trade in trades) {
      double tradeValue = 0.0;
      
      // Determine value based on team's role in trade
      if (trade.teamOffering == teamName) {
        // Team traded up - assess the value given vs received
        tradeValue = (trade.valueDifferential / trade.targetPickValue) * 10;
        tradeCount++;
        
        if (debug) {
          debugLog.writeln("Trade Up: $teamName received pick #${trade.targetPick.pickNumber}");
          debugLog.writeln("  Value Differential: ${trade.valueDifferential.toStringAsFixed(1)} (${(trade.valueDifferential / trade.targetPickValue * 100).toStringAsFixed(1)}%)");
          debugLog.writeln("  Trade Value Score: ${tradeValue.toStringAsFixed(2)}");
        }
      } else if (trade.teamReceiving == teamName) {
        // Team traded down - assess the value received vs given up
        tradeValue = (trade.valueDifferential / trade.targetPickValue) * 10;
        tradeCount++;
        
        if (debug) {
          debugLog.writeln("Trade Down: $teamName gave up pick #${trade.targetPick.pickNumber}");
          debugLog.writeln("  Value Differential: ${trade.valueDifferential.toStringAsFixed(1)} (${(trade.valueDifferential / trade.targetPickValue * 100).toStringAsFixed(1)}%)");
          debugLog.writeln("  Trade Value Score: ${tradeValue.toStringAsFixed(2)}");
        }
      }
      
      totalTradeValue += tradeValue;
    }
    
    // Average trade value and convert to grade score
    if (tradeCount > 0) {
      double avgTradeValue = totalTradeValue / tradeCount;
      
      // Convert to grade score (0-10 scale)
      tradeGradeScore = 6.0 + avgTradeValue;
      
      // Ensure it stays in reasonable range
      tradeGradeScore = max(0.0, min(10.0, tradeGradeScore));
      
      // Calculate trade impact factor - more impactful if multiple trades
      tradeFactor = min(0.3, 0.15 * tradeCount);
      
      if (debug) {
        debugLog.writeln("Total Trade Count: $tradeCount");
        debugLog.writeln("Average Trade Value: ${avgTradeValue.toStringAsFixed(2)}");
        debugLog.writeln("TRADE GRADE SCORE: ${tradeGradeScore.toStringAsFixed(2)}");
        debugLog.writeln("Trade Factor (weight in final grade): ${tradeFactor.toStringAsFixed(2)}");
      }
    }
  }
  
  // 3. NEEDS ASSESSMENT - How well did team address its needs
  if (debug) debugLog.writeln("\n3. NEEDS ASSESSMENT:");

  double needsGradeScore = 6.0; // Default "B-" needs grade
  double needsFactor = 0.2;     // How much needs impact overall grade

  // Find team needs
  TeamNeed? teamNeed = teamNeeds.firstWhere(
    (need) => need.teamName == teamName,
    orElse: () => TeamNeed(teamName: teamName, needs: [])
  );

  // BUGFIX: Get the original needs from CSV data
  List<String> originalNeeds = [];

  // Get original needs from the TeamNeed object's raw data
  for (var need in teamNeed.toList().sublist(2)) { // Skip index and team name
    if (need != null && need.toString().isNotEmpty && need.toString() != '-') {
      originalNeeds.add(need.toString());
    }
  }

  if (debug) {
    debugLog.writeln("Original Team Needs (from CSV): ${originalNeeds.join(', ')}");
  }

  if (originalNeeds.isNotEmpty) {
    // Count how many top needs were addressed
    Set<String> addressedNeeds = {};
    for (var pick in picks) {
      if (pick.selectedPlayer != null) {
        addressedNeeds.add(pick.selectedPlayer!.position);
      }
    }
    
    if (debug) {
      debugLog.writeln("Positions Drafted: ${addressedNeeds.join(', ')}");
    }
    
    // Calculate needs satisfaction
    int topNeedsCount = min(5, originalNeeds.length); // Consider top 5 needs
    int weightedNeedsScore = 0;
    
    for (int i = 0; i < topNeedsCount; i++) {
      if (i < originalNeeds.length && addressedNeeds.contains(originalNeeds[i])) {
        // Higher weight for addressing top needs
        int positionBonus = 0;
        if (i == 0) {
          positionBonus = 2;  // Double credit for top need
          if (debug) debugLog.writeln("✓ Addressed TOP need (${originalNeeds[i]}): +2 points");
        } else if (i == 1) {
          positionBonus = 2;  // Double credit for second need
          if (debug) debugLog.writeln("✓ Addressed SECOND need (${originalNeeds[i]}): +2 points");
        } else {
          positionBonus = 1;
          if (debug) debugLog.writeln("✓ Addressed need #${i+1} (${originalNeeds[i]}): +1 point");
        }
        weightedNeedsScore += positionBonus;
      } else if (i < originalNeeds.length) {
        if (debug) debugLog.writeln("✗ Did NOT address need #${i+1} (${originalNeeds[i]})");
      }
    }
    
    // Calculate score (base 6, +0.5 for each weighted need addressed)
    double needsSatisfactionScore = 6.0 + (weightedNeedsScore * 0.5);
    
    // Ensure it stays in reasonable range
    needsGradeScore = max(0.0, min(10.0, needsSatisfactionScore));
    
    if (debug) {
      debugLog.writeln("Weighted Needs Score: $weightedNeedsScore");
      debugLog.writeln("NEEDS GRADE SCORE: ${needsGradeScore.toStringAsFixed(2)}");
    }
  }
  
  // 4. COMBINE ALL COMPONENTS - Weighted by importance
  if (debug) debugLog.writeln("\n4. FINAL GRADE CALCULATION:");
  
  // BUGFIX: Adjust factors based on team size and number of picks
  // For teams with fewer picks, emphasize pick quality more
  double pickFactor = 1.0 - tradeFactor - needsFactor;
  
  // For teams with 3 or fewer picks, adjust the weighting
  if (picks.length <= 3) {
    pickFactor = 0.7; // 70% weight on pick quality
    needsFactor = 0.2; // 20% weight on needs addressed
    tradeFactor = 0.1; // 10% weight on trades (unless no trades)
    
    if (trades.isEmpty) {
      pickFactor = 0.8; // Increase pick factor if no trades
      tradeFactor = 0.0;
    }
    
    if (debug) {
      debugLog.writeln("Team has ${picks.length} picks - adjusting component weights");
      debugLog.writeln("Adjusted Pick Factor: ${pickFactor.toStringAsFixed(2)}");
      debugLog.writeln("Adjusted Needs Factor: ${needsFactor.toStringAsFixed(2)}");
      debugLog.writeln("Adjusted Trade Factor: ${tradeFactor.toStringAsFixed(2)}");
    }
  }
  
  double pickComponent = avgPickScore * pickFactor;
  double tradeComponent = tradeGradeScore * tradeFactor;
  double needsComponent = needsGradeScore * needsFactor;
  
  double finalScore = pickComponent + tradeComponent + needsComponent;
  
  // BUGFIX: Ensure grade isn't drastically worse than individual pick grades
  String expectedGradeFromPickScore = getTeamLetterGrade(avgPickScore);
  double minimumScoreThreshold = 0.0;
  
  // If all picks are B- or better, ensure final grade is at least B-
  if (letterGrades.every((grade) => 
      grade == 'B-' || grade == 'B' || grade == 'B+' || 
      grade == 'A-' || grade == 'A' || grade == 'A+')) {
    minimumScoreThreshold = 6.0; // B- threshold
    if (debug) {
      debugLog.writeln("All picks are B- or better, ensuring team grade is at least B-");
    }
  }
  // If all picks are C+ or better, ensure final grade is at least C+
  else if (letterGrades.every((grade) => 
      grade == 'C+' || grade == 'B-' || grade == 'B' || grade == 'B+' || 
      grade == 'A-' || grade == 'A' || grade == 'A+')) {
    minimumScoreThreshold = 5.5; // C+ threshold
    if (debug) {
      debugLog.writeln("All picks are C+ or better, ensuring team grade is at least C+");
    }
  }
  
  // Apply minimum threshold if needed
  if (finalScore < minimumScoreThreshold) {
    double originalScore = finalScore;
    finalScore = minimumScoreThreshold;
    if (debug) {
      debugLog.writeln("Applied minimum grade threshold: ${originalScore.toStringAsFixed(2)} → ${finalScore.toStringAsFixed(2)}");
    }
  }
  
  if (debug) {
    debugLog.writeln("Pick Component: ${avgPickScore.toStringAsFixed(2)} × ${pickFactor.toStringAsFixed(2)} = ${pickComponent.toStringAsFixed(2)}");
    debugLog.writeln("Trade Component: ${tradeGradeScore.toStringAsFixed(2)} × ${tradeFactor.toStringAsFixed(2)} = ${tradeComponent.toStringAsFixed(2)}");
    debugLog.writeln("Needs Component: ${needsGradeScore.toStringAsFixed(2)} × ${needsFactor.toStringAsFixed(2)} = ${needsComponent.toStringAsFixed(2)}");
    debugLog.writeln("FINAL SCORE: ${finalScore.toStringAsFixed(2)}");
    debugLog.writeln("Expected Grade from Pick Score: $expectedGradeFromPickScore");
  }
  
  // 5. DETERMINE FINAL GRADE - Convert score to letter grade
  String finalGrade = getTeamLetterGrade(finalScore);
  
  if (debug) {
    debugLog.writeln("FINAL LETTER GRADE: $finalGrade");
    debugLog.writeln("===== END TEAM GRADE CALCULATION =====\n");
    debugPrint(debugLog.toString());
  }
  
  // Generate a description based on the final grade
  String description = generateTeamGradeDescription(finalGrade, {
    'pickGrades': pickGrades,
    'tradeGradeScore': tradeGradeScore,
    'needsGradeScore': needsGradeScore,
    'avgPickScore': avgPickScore,
    'finalScore': finalScore,
    'tradeFactor': tradeFactor,
    'needsFactor': needsFactor,
    'pickFactor': pickFactor
  });
  
  return {
    'grade': finalGrade,
    'value': finalScore,
    'description': description,
    'letterGrade': finalGrade,
    'factors': {
      'avgPickScore': avgPickScore,
      'tradeGradeScore': tradeGradeScore,
      'needsGradeScore': needsGradeScore,
      'finalScore': finalScore,
      'tradeFactor': tradeFactor,
      'needsFactor': needsFactor,
      'pickFactor': pickFactor,
      'totalPicks': picks.length,
      'individualGrades': pickGrades,
      'letterGrades': letterGrades,
      'debugLog': debugLog.toString(), // Store the debug log for later analysis
    },
  };
}
  /// Calculate how well a team addressed their needs
  static double calculateNeedsSatisfactionScore(
    List<DraftPick> picks,
    List<TeamNeed> teamNeeds
  ) {
    if (picks.isEmpty) return 0;
    
    String teamName = picks.first.teamName;
    
    // Find team needs
    TeamNeed? teamNeed = teamNeeds.firstWhere(
      (need) => need.teamName == teamName,
      orElse: () => TeamNeed(teamName: teamName, needs: [])
    );
    
    if (teamNeed.needs.isEmpty) return 5.0; // No needs to address, give average score
    
    // Count how many top needs were addressed
    Set<String> addressedNeeds = {};
    for (var pick in picks) {
      if (pick.selectedPlayer != null) {
        addressedNeeds.add(pick.selectedPlayer!.position);
      }
    }
    
    // Calculate needs satisfaction
    int topNeedsCount = teamNeed.needs.length > 5 ? 5 : teamNeed.needs.length;
    int topNeedsAddressed = 0;
    
    for (int i = 0; i < topNeedsCount; i++) {
      if (addressedNeeds.contains(teamNeed.needs[i])) {
        topNeedsAddressed++;
      }
    }
    
    // Calculate score (0-10 scale)
    double needsSatisfactionScore = (topNeedsAddressed / topNeedsCount) * 10.0;
    
    return needsSatisfactionScore;
  }

  /// Get round-based expectation factor
  static double getRoundExpectationFactor(int round) {
    switch(round) {
      case 1: return 1.0;     // Full expectations for 1st round
      case 2: return 0.85;    // 85% expectations for 2nd round
      case 3: return 0.7;     // 70% expectations for 3rd round
      case 4: return 0.55;    // 55% expectations for 4th round
      case 5: return 0.4;     // 40% expectations for 5th round
      case 6: return 0.3;     // 30% expectations for 6th round
      case 7: return 0.2;     // 20% expectations for 7th round
      default: return 0.1;    // 10% expectations for late rounds
    }
  }

  /// Get pick weight for calculating team grade
  static double getPickWeight(int pickNumber) {
    // Earlier picks should have more weight in the team grade
    if (pickNumber <= 32) return 1.0;      // 1st round
    if (pickNumber <= 64) return 0.8;      // 2nd round
    if (pickNumber <= 96) return 0.6;      // 3rd round
    if (pickNumber <= 128) return 0.4;     // 4th round
    if (pickNumber <= 160) return 0.3;     // 5th round
    if (pickNumber <= 192) return 0.2;     // 6th round
    return 0.1;                            // 7th round and later
  }

  /// Convert numeric grade to letter grade for individual picks
  static String getLetterGrade(double value) {
    if (value >= 25) return 'A+';
    if (value >= 20) return 'A';
    if (value >= 15) return 'B+';
    if (value >= 10) return 'B';
    if (value >= 5) return 'C+';
    if (value >= 0) return 'C';
    if (value >= -10) return 'D';
    return 'F';
  }

  /// Convert numeric grade to letter grade for team overall
  static String getTeamLetterGrade(double score) {
  if (score >= 8.5) return 'A+';
  if (score >= 8.0) return 'A';
  if (score >= 7.5) return 'A-';
  if (score >= 7.0) return 'B+';
  if (score >= 6.5) return 'B';
  if (score >= 6.0) return 'B-';
  if (score >= 5.5) return 'C+';
  if (score >= 5.0) return 'C';
  if (score >= 4.5) return 'C-';
  if (score >= 4.0) return 'D+';
  if (score >= 3.5) return 'D';
  return 'F';
}

  /// Generate description based on team grade
  static String generateTeamGradeDescription(
  String grade, 
  Map<String, dynamic> factors
) {
  final double finalScore = factors['finalScore'] ?? 0.0;
  final double avgPickScore = factors['avgPickScore'] ?? 0.0;
  final double tradeGradeScore = factors['tradeGradeScore'] ?? 0.0;
  final double needsGradeScore = factors['needsGradeScore'] ?? 0.0;
  
  String description = "";
  
  // Overall assessment based on grade
  if (grade.startsWith('A+')) {
    description = "Outstanding draft with exceptional value and strategic decision-making. ";
  } else if (grade.startsWith('A')) {
    description = "Excellent draft with great value selections and solid team-building approach. ";
  } else if (grade.startsWith('B+')) {
    description = "Very good draft with several quality picks addressing key team needs. ";
  } else if (grade.startsWith('B')) {
    description = "Solid draft that balances value and need effectively. ";
  } else if (grade.startsWith('C+')) {
    description = "Average draft with some good selections mixed with missed opportunities. ";
  } else if (grade.startsWith('C')) {
    description = "Below average draft with questionable value decisions. ";
  } else if (grade.startsWith('D')) {
    description = "Poor draft that failed to maximize value or address critical needs. ";
  } else {
    description = "Disappointing draft with major reaches and strategic miscalculations. ";
  }
  
  // Add context about pick quality
  if (avgPickScore >= 8.0) {
    description += "Consistently found excellent value throughout the draft. ";
  } else if (avgPickScore >= 7.0) {
    description += "Made several strong selections with good value. ";
  } else if (avgPickScore >= 6.0) {
    description += "Made mostly solid selections with reasonable value. ";
  } else if (avgPickScore >= 5.0) {
    description += "Pick quality was average with some reaches. ";
  } else {
    description += "Made too many questionable picks with poor value. ";
  }
  
  // Add context about trades if relevant
  if (factors['tradeFactor'] > 0.05) {
    if (tradeGradeScore >= 8.0) {
      description += "Executed trades masterfully to maximize draft capital. ";
    } else if (tradeGradeScore >= 7.0) {
      description += "Made smart trade decisions to improve draft position. ";
    } else if (tradeGradeScore >= 6.0) {
      description += "Trade decisions were generally reasonable. ";
    } else if (tradeGradeScore >= 5.0) {
      description += "Trade execution was questionable in terms of value. ";
    } else {
      description += "Trade decisions significantly hurt draft capital. ";
    }
  }
  
  // Add context about needs
  if (needsGradeScore >= 8.0) {
    description += "Excellently addressed critical team needs.";
  } else if (needsGradeScore >= 7.0) {
    description += "Successfully filled most important team needs.";
  } else if (needsGradeScore >= 6.0) {
    description += "Reasonably addressed several team needs.";
  } else if (needsGradeScore >= 5.0) {
    description += "Failed to address some critical team needs.";
  } else {
    description += "Largely ignored major team needs.";
  }
  
  return description;
}
}