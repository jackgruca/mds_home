// lib/services/draft_grade_service.dart

import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
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
    // Force immediate debug print to ensure visibility
    debugPrint("Starting team grade calculation...");
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
    debugPrint("Calculating grade for team: $teamName with ${picks.length} picks");
  }
  
  // Store raw grades and their mapped numeric values
  List<String> pickLetterGrades = [];
  List<double> pickNumericValues = [];
  List<int> pickNumbers = [];
  double totalScore = 0.0;
  double totalWeight = 0.0;
  
  // SIMPLIFIED APPROACH: Directly convert letter grades to numeric values
  for (var pick in picks.where((p) => p.selectedPlayer != null)) {
    // Get grade info from DraftPickGradeService
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(
      pick, teamNeeds, debug: false);
    
    String letterGrade = gradeInfo['letter'];
    pickLetterGrades.add(letterGrade);
    pickNumbers.add(pick.pickNumber);
    
    // Convert letter grade to numeric value (0-10 scale)
    double numericValue = _letterToNumericValue(letterGrade);
    pickNumericValues.add(numericValue);
    
    // Calculate weight based on round
    int round = int.tryParse(pick.round) ?? DraftValueService.getRoundForPick(pick.pickNumber);
    double weight = _getPickWeight(round, pick.pickNumber);
    
    if (debug) {
      debugLog.writeln("Pick #${pick.pickNumber}: ${pick.selectedPlayer!.name}");
      debugLog.writeln("  Grade: $letterGrade (${numericValue.toStringAsFixed(2)} points)");
      debugLog.writeln("  Weight: ${weight.toStringAsFixed(2)}");
      debugLog.writeln("  Weighted Score: ${(numericValue * weight).toStringAsFixed(2)}");
    }
    
    totalScore += numericValue * weight;
    totalWeight += weight;
  }
  
  // Calculate weighted average
  double weightedAverage = totalWeight > 0 ? totalScore / totalWeight : 0.0;
  
  if (debug) {
    debugLog.writeln("\nRaw letter grades: ${pickLetterGrades.join(', ')}");
    debugLog.writeln("Raw numeric values: ${pickNumericValues.map((v) => v.toStringAsFixed(2)).join(', ')}");
    debugLog.writeln("Total weighted score: ${totalScore.toStringAsFixed(2)}");
    debugLog.writeln("Total weight: ${totalWeight.toStringAsFixed(2)}");
    debugLog.writeln("Weighted average: ${weightedAverage.toStringAsFixed(2)}");
  }
  
  // Apply trade adjustment if any trades were made
  double tradeValue = 0.0;
  if (trades.isNotEmpty) {
    for (var trade in trades) {
      if (trade.teamOffering == teamName) {
        tradeValue -= trade.valueDifferential;
      } else if (trade.teamReceiving == teamName) {
        tradeValue += trade.valueDifferential;
      }
    }
    
    // Scale trade value - use a more modest impact (50 trade points = 0.5 grade points)
    double tradeAdjustment = tradeValue / 100.0;
    // Cap the adjustment to prevent extreme swings
    tradeAdjustment = tradeAdjustment.clamp(-1.0, 1.0);
    
    if (debug) {
      debugLog.writeln("\nTrade value: ${tradeValue.toStringAsFixed(2)}");
      debugLog.writeln("Trade adjustment: ${tradeAdjustment.toStringAsFixed(2)}");
    }
    
    // Apply trade adjustment
    weightedAverage += tradeAdjustment;
  }
  
  // Convert final average to letter grade
  String finalGrade = _numericToLetterGrade(weightedAverage);
  
  if (debug) {
    debugLog.writeln("\nFinal weighted average: ${weightedAverage.toStringAsFixed(2)}");
    debugLog.writeln("Final letter grade: $finalGrade");
    // Force immediate debug print to ensure this is visible
    debugPrint("Team $teamName final grade calculation: ${weightedAverage.toStringAsFixed(2)} = $finalGrade");
    debugPrint("Individual pick grades: ${pickLetterGrades.join(', ')}");
    debugPrint("Pick numbers: ${pickNumbers.join(', ')}");
    debugPrint(debugLog.toString());
  }
  
  return {
    'grade': finalGrade,
    'value': weightedAverage,
    'description': _generateSimpleDescription(finalGrade, pickLetterGrades),
    'letterGrade': finalGrade,
    'factors': {
      'pickGrades': pickLetterGrades,
      'numericValues': pickNumericValues,
      'weightedAverage': weightedAverage,
      'tradeValue': tradeValue,
      'debugLog': debugLog.toString(),
    },
  };
}

// Simple consistent letter to numeric conversion (0-10 scale)
static double _letterToNumericValue(String letterGrade) {
  switch (letterGrade) {
    case 'A+': return 10.0;
    case 'A': return 9.5;
    case 'A-': return 9.0;
    case 'B+': return 8.5;
    case 'B': return 8.0;
    case 'B-': return 7.5;
    case 'C+': return 7.0;
    case 'C': return 6.5;
    case 'C-': return 6.0;
    case 'D+': return 5.5;
    case 'D': return 5.0;
    case 'F': return 4.0;
    default: return 6.5; // Default to C
  }
}

// Simple numeric to letter conversion using same scale
static String _numericToLetterGrade(double score) {
  if (score >= 9.75) return 'A+';
  if (score >= 9.25) return 'A';
  if (score >= 8.75) return 'A-';
  if (score >= 8.25) return 'B+';
  if (score >= 7.75) return 'B';
  if (score >= 7.25) return 'B-';
  if (score >= 6.75) return 'C+';
  if (score >= 6.25) return 'C';
  if (score >= 5.75) return 'C-';
  if (score >= 5.25) return 'D+';
  if (score >= 4.75) return 'D';
  return 'F';
}

// Get weight based on round and pick number
static double _getPickWeight(int round, int pickNumber) {
  // Higher weights for earlier picks
  if (pickNumber <= 10) return 2.0;   // Top 10 picks
  if (pickNumber <= 32) return 1.5;   // First round
  if (pickNumber <= 64) return 1.2;   // Second round
  if (pickNumber <= 96) return 1.0;   // Third round
  if (pickNumber <= 128) return 0.8;  // Fourth round
  if (pickNumber <= 160) return 0.7;  // Fifth round
  if (pickNumber <= 192) return 0.6;  // Sixth round
  return 0.5;                         // Seventh round and later
}

// Simple description generation
static String _generateSimpleDescription(String grade, List<String> pickGrades) {
  if (grade.startsWith('A')) {
    return 'Outstanding draft with excellent value selections.';
  } else if (grade.startsWith('B')) {
    return 'Strong draft that effectively balanced value and need.';
  } else if (grade.startsWith('C')) {
    return 'Average draft with some good picks but room for improvement.';
  } else if (grade.startsWith('D')) {
    return 'Below average draft that missed opportunities for better value.';
  } else {
    return 'Disappointing draft with major reaches and strategic issues.';
  }
}


// Convert letter grade to numeric GPA value

// Convert numeric GPA to letter grade

// Generate a simple description based on the final grade

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
