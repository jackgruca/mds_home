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
  }
  
  // 1. CONVERT LETTER GRADES TO NUMERIC VALUES (GPA style)
  if (debug) debugLog.writeln("\n1. CONVERTING PICK GRADES TO NUMERIC VALUES:");
  
  double totalWeightedScore = 0.0;
  double totalWeight = 0.0;
  List<String> letterGrades = [];
  
  for (var pick in picks) {
    if (pick.selectedPlayer == null) continue;
    
    // Get the already calculated grade
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds, debug: false);
    String letterGrade = gradeInfo['letter'];
    letterGrades.add(letterGrade);
    
    // Convert letter grade to numeric value (4.0 scale)
    double numericGrade = _letterToNumeric(letterGrade);
    
    // Get round weight
    int round = int.tryParse(pick.round) ?? DraftValueService.getRoundForPick(pick.pickNumber);
    double roundWeight;
    
    // Apply round-based weight
    switch (round) {
      case 1: roundWeight = 1.3; break;
      case 2: roundWeight = 1.2; break;
      case 3: roundWeight = 1.1; break;
      case 4: roundWeight = 1.0; break;
      case 5: roundWeight = 0.9; break;
      case 6: roundWeight = 0.8; break;
      case 7: roundWeight = 0.7; break;
      default: roundWeight = 0.6; break;
    }
    
    // Apply extra weight for top picks
    double pickWeight = roundWeight;
    if (pick.pickNumber <= 10) {
      pickWeight *= 1.2; // 20% more weight for top 10 picks
      if (debug) debugLog.writeln("  Applied top 10 bonus (1.2x)");
    }
    
    // Add to weighted total
    totalWeightedScore += numericGrade * pickWeight;
    totalWeight += pickWeight;
    
    if (debug) {
      debugLog.writeln("Pick #${pick.pickNumber} (Round $round): ${pick.selectedPlayer!.name}");
      debugLog.writeln("  Grade: $letterGrade (${numericGrade.toStringAsFixed(1)} points)");
      debugLog.writeln("  Weight: ${pickWeight.toStringAsFixed(1)}");
      debugLog.writeln("  Weighted Value: ${(numericGrade * pickWeight).toStringAsFixed(1)}");
    }
  }
  
  // Calculate weighted GPA
  double weightedGPA = totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;
  
  if (debug) {
    debugLog.writeln("\nTotal Weighted Score: ${totalWeightedScore.toStringAsFixed(1)}");
    debugLog.writeln("Total Weight: ${totalWeight.toStringAsFixed(1)}");
    debugLog.writeln("Weighted GPA: ${weightedGPA.toStringAsFixed(2)}");
  }
  
  // 2. APPLY TRADE ADJUSTMENT
  double tradeAdjustment = 0.0;
  
  if (trades.isNotEmpty) {
    // Calculate net trade value
    double netTradeValue = 0.0;
    for (var trade in trades) {
      if (trade.teamOffering == teamName) {
        netTradeValue -= trade.valueDifferential;
      } else if (trade.teamReceiving == teamName) {
        netTradeValue += trade.valueDifferential;
      }
    }
    
    // Convert trade value to GPA adjustment (scale appropriately)
    // For example, 50 trade points = 0.5 GPA points
    tradeAdjustment = netTradeValue * 0.01;
    
    // Cap adjustment to prevent huge swings
    tradeAdjustment = tradeAdjustment.clamp(-1.0, 1.0);
    
    if (debug) {
      debugLog.writeln("\nTrade Adjustment: ${tradeAdjustment.toStringAsFixed(2)} GPA points");
    }
  }
  
  // 3. CALCULATE FINAL GPA
  double finalGPA = weightedGPA + tradeAdjustment;
  
  // Ensure minimum grade based on pick quality
  if (letterGrades.every((grade) => _letterToNumeric(grade) >= 3.0)) {
    // If all picks are B or better, ensure at least a B- (2.7)
    finalGPA = max(finalGPA, 2.7);
    if (debug) debugLog.writeln("Applied minimum B- threshold");
  } else if (letterGrades.every((grade) => _letterToNumeric(grade) >= 2.3)) {
    // If all picks are C+ or better, ensure at least a C+ (2.3)
    finalGPA = max(finalGPA, 2.3);
    if (debug) debugLog.writeln("Applied minimum C+ threshold");
  }
  
  // Convert numeric grade back to letter
  String finalGrade = _numericToLetter(finalGPA);
  
  if (debug) {
    debugLog.writeln("\nFinal GPA: ${finalGPA.toStringAsFixed(2)}");
    debugLog.writeln("Final Letter Grade: $finalGrade");
    debugLog.writeln("===== END TEAM GRADE CALCULATION =====\n");
    debugPrint(debugLog.toString());
  }
  
  return {
    'grade': finalGrade,
    'value': finalGPA,
    'description': _generateDescription(finalGrade, letterGrades),
    'letterGrade': finalGrade,
    'factors': {
      'weightedGPA': weightedGPA,
      'tradeAdjustment': tradeAdjustment,
      'finalGPA': finalGPA,
      'individualGrades': letterGrades,
      'debugLog': debugLog.toString(),
    },
  };
}

// Convert letter grade to numeric GPA value
static double _letterToNumeric(String letterGrade) {
  switch (letterGrade) {
    case 'A+': return 4.3;
    case 'A': return 4.0;
    case 'A-': return 3.7;
    case 'B+': return 3.3;
    case 'B': return 3.0;
    case 'B-': return 2.7;
    case 'C+': return 2.3;
    case 'C': return 2.0;
    case 'C-': return 1.7;
    case 'D+': return 1.3;
    case 'D': return 1.0;
    case 'F': return 0.0;
    default: return 2.0; // Default to C
  }
}

// Convert numeric GPA to letter grade
static String _numericToLetter(double numericGrade) {
  if (numericGrade >= 4.3) return 'A+';
  if (numericGrade >= 4.0) return 'A';
  if (numericGrade >= 3.7) return 'A-';
  if (numericGrade >= 3.3) return 'B+';
  if (numericGrade >= 3.0) return 'B';
  if (numericGrade >= 2.7) return 'B-';
  if (numericGrade >= 2.3) return 'C+';
  if (numericGrade >= 2.0) return 'C';
  if (numericGrade >= 1.7) return 'C-';
  if (numericGrade >= 1.3) return 'D+';
  if (numericGrade >= 1.0) return 'D';
  return 'F';
}

// Generate a simple description based on the final grade
static String _generateDescription(String grade, List<String> individualGrades) {
  if (grade.startsWith('A')) {
    return 'Outstanding draft with excellent value selections.';
  } else if (grade.startsWith('B')) {
    return 'Solid draft that effectively balanced value and need.';
  } else if (grade.startsWith('C')) {
    return 'Average draft with some good picks but room for improvement.';
  } else if (grade.startsWith('D')) {
    return 'Below average draft that missed opportunities for better value.';
  } else {
    return 'Poor draft with significant reaches and missed opportunities.';
  }
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
  // Match the exact same boundaries as DraftPickGradeService.getLetterGrade
  if (score >= 9.0) return 'A+';  // Outstanding pick
  if (score >= 8.0) return 'A';    // Excellent pick
  if (score >= 7.0) return 'A-';   // Very good pick
  if (score >= 6.0) return 'B+';   // Good pick
  if (score >= 5.0) return 'B';    // Solid pick
  if (score >= 4.0) return 'B-';   // Decent pick
  if (score >= 3.0) return 'C+';   // Average pick
  if (score >= 2.0) return 'C';    // Mediocre pick
  if (score >= 1.0) return 'C-';   // Below average pick
  if (score >= 0.0) return 'D+';   // Poor pick
  if (score >= -1.0) return 'D';   // Very poor pick
  return 'F';                      // Terrible pick
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
// Helper method to convert letter grade to numeric score for averaging
static double letterGradeToScore(String letterGrade) {
  switch (letterGrade) {
    case 'A+': return 9.5;
    case 'A': return 9.0;
    case 'A-': return 8.5;
    case 'B+': return 8.0;
    case 'B': return 7.0;
    case 'B-': return 6.0;
    case 'C+': return 5.0;
    case 'C': return 4.0;
    case 'C-': return 3.0;
    case 'D+': return 2.0;
    case 'D': return 1.0;
    case 'F': return 0.0;
    default: return 4.0; // Default to C grade
  }
}
}

class TeamNeedsSnapshot {
  static final Map<String, List<String>> _originalNeeds = {};
  
  // Initialize the snapshot with original team needs
  static void initialize(List<TeamNeed> teamNeeds) {
    _originalNeeds.clear();
    
    for (var need in teamNeeds) {
      // Get the raw data from CSV
      List<dynamic> rawData = need.toList();
      List<String> needs = [];
      
      // Extract all non-empty needs from the raw data
      // Skip the first two elements (index and team name)
      // Skip the last element (selected positions column)
      for (int i = 2; i < rawData.length - 1; i++) {
        var needValue = rawData[i];
        if (needValue != null && 
            needValue.toString().isNotEmpty && 
            needValue.toString() != '-') {
          needs.add(needValue.toString());
        }
      }
      
      _originalNeeds[need.teamName] = needs;
      debugPrint("Initialized original needs for ${need.teamName}: ${needs.join(', ')}");
    }
  }
  
  // Get original needs for a specific team
  static List<String> getOriginalNeeds(String teamName) {
    return _originalNeeds[teamName] ?? [];
  }
  
  // Check if position was an original need for the team
  static bool wasOriginalNeed(String teamName, String position) {
    List<String> needs = getOriginalNeeds(teamName);
    return needs.contains(position);
  }
  
  // Get the original need index for a position
  static int getOriginalNeedIndex(String teamName, String position) {
    List<String> needs = getOriginalNeeds(teamName);
    return needs.indexOf(position);
  }
}
