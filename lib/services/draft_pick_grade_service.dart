// lib/services/draft_pick_grade_service.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../services/draft_value_service.dart';
import 'draft_grade_service.dart';

/// Service for grading individual draft picks with sophisticated methodology
class DraftPickGradeService {
  // Position value coefficients - how valuable each position is in the NFL draft
  static const Map<String, double> positionValueCoefficients = {
    'QB': 1.5,   // Premium for franchise QBs
    'EDGE': 1.3, // Elite pass rushers
    'OT': 1.3,   // Elite offensive tackles
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

/// Calculate comprehensive grade for an individual pick with improved factors
static Map<String, dynamic> calculatePickGrade(
  DraftPick pick, 
  List<TeamNeed> teamNeeds,
  {bool considerTeamNeeds = true, bool debug = true}
) {
  final StringBuffer debugLog = StringBuffer();
  
  if (debug) {
    debugLog.writeln("\n===== PICK GRADE CALCULATION DEBUG =====");
    debugLog.writeln("Team: ${pick.teamName} | Pick #${pick.pickNumber}");
  }
  
  if (pick.selectedPlayer == null) {
    if (debug) debugLog.writeln("No player selected, returning N/A");
    if (debug) debugPrint(debugLog.toString());
    
    return {
      'grade': 'N/A',
      'letter': 'N/A',
      'value': 0.0,
      'colorScore': 50,
      'factors': {},
    };
  }

  final player = pick.selectedPlayer!;
  final int pickNumber = pick.pickNumber;
  final int playerRank = player.rank;
  final String position = player.position;
  
  if (debug) {
    debugLog.writeln("Player: ${player.name} (${player.position})");
    debugLog.writeln("Pick Number: $pickNumber | Player Rank: $playerRank");
  }
  
  // Base value differential (traditional calculation)
  int baseValueDiff = pickNumber - playerRank;
  
  // Calculate pick round for expectation & weighting
  int round = DraftValueService.getRoundForPick(pickNumber);
  
  if (debug) {
    debugLog.writeln("Round: $round | Base Value Differential: $baseValueDiff");
  }
  
  // 1. NEED FACTOR - Now with both positive and negative impact
  double needFactor = 0.0;
int needIndex = -1;
bool isInNeedRange = false;

if (considerTeamNeeds) {
  // Get original needs from the snapshot
  List<String> originalNeeds = TeamNeedsSnapshot.getOriginalNeeds(pick.teamName);
  
  // Find the matching team need for current state
  TeamNeed? teamNeed;
  try {
    teamNeed = teamNeeds.firstWhere(
      (need) => need.teamName == pick.teamName,
    );
  } catch (e) {
    // If no team found, create an empty one
    teamNeed = TeamNeed(teamName: pick.teamName, needs: []);
    if (debug) {
      debugLog.writeln("WARNING: No team needs found for ${pick.teamName}, using empty needs list");
    }
  }
  
  if (debug) {
    debugLog.writeln("\nNEEDS ANALYSIS:");
    debugLog.writeln("Original Team Needs (from snapshot): ${originalNeeds.join(', ')}");
    debugLog.writeln("Current Team Needs: ${teamNeed.needs.join(', ')}");
    debugLog.writeln("Selected Positions: ${teamNeed.selectedPositions.join(', ')}");
  }
  
  // Calculate eligible need range (round + 3)
  int eligibleNeedRange = round + 3;
  eligibleNeedRange = min(eligibleNeedRange, originalNeeds.length);
  
  // Check if position is in original needs list
  needIndex = originalNeeds.indexOf(position);
  
  // Determine if position is within the eligible range
  isInNeedRange = needIndex >= 0 && needIndex < eligibleNeedRange;

    
    // Calculate need factor based on need priority and eligibility
    if (isInNeedRange) {
      // Position is in eligible need range - positive boost
      if (needIndex == 0) needFactor = 0.35;      // Top need: +35%
      else if (needIndex == 1) needFactor = 0.30; // Second need: +30%
      else if (needIndex == 2) needFactor = 0.25; // Third need: +25%
      else if (needIndex == 3) needFactor = 0.20; // Fourth need: +20%
      else if (needIndex == 4) needFactor = 0.15; // Fifth need: +15%
      else needFactor = 0.10;                     // Other eligible needs: +10%
      
      if (debug) {
        debugLog.writeln("✓ Position is need #${needIndex+1} - within eligible range (0-$eligibleNeedRange)");
        debugLog.writeln("✓ Need Factor: +${needFactor.toStringAsFixed(2)} (+${(needFactor * 10).toStringAsFixed(1)} points)");
      }
    } else if (needIndex >= eligibleNeedRange) {
      // Position is a need but outside eligible range - neutral
      needFactor = 0.0;
      
      if (debug) {
        debugLog.writeln("⚠ Position is need #${needIndex+1} - outside eligible range (0-$eligibleNeedRange)");
        debugLog.writeln("⚠ Need Factor: ${needFactor.toStringAsFixed(2)} (0 points)");
      }
    } else {
      // Position not in needs list at all - penalty
      // Penalty is stronger in early rounds, milder in later rounds
      if (round == 1) needFactor = -0.30;      // 1st round: -30%
      else if (round == 2) needFactor = -0.25; // 2nd round: -25%
      else if (round == 3) needFactor = -0.20; // 3rd round: -20%
      else if (round == 4) needFactor = -0.15; // 4th round: -15%
      else needFactor = -0.10;                 // 5th+ round: -10%
      
      if (debug) {
        debugLog.writeln("✗ Position is not in team needs list");
        debugLog.writeln("✗ Need Factor: ${needFactor.toStringAsFixed(2)} (${(needFactor * 10).toStringAsFixed(1)} points)");
      }
    }
  } else {
    if (debug) {
      debugLog.writeln("Team needs consideration disabled");
      debugLog.writeln("Need Factor: ${needFactor.toStringAsFixed(2)} (0 points)");
    }
  }
  
  // 2. POSITION VALUE - Premium for valuable positions
  double positionValue = 0.0;
  
  // Premium positions get additional value
  if (['QB', 'EDGE', 'OT'].contains(position)) {
    positionValue = 0.25; // +25% for premier positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Premier position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['CB', 'WR'].contains(position)) {
    positionValue = 0.20; // +20% for key positions  
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Key position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['S', 'DT', 'TE'].contains(position)) {
    positionValue = 0.15; // +15% for valuable positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Valuable position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['IOL', 'LB'].contains(position)) {
    positionValue = 0.10; // +10% for solid positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Solid position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['RB'].contains(position)) {
    positionValue = 0.05; // Small bonus for devalued positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Devalued position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else {
    positionValue = 0.10; // Default +10% for unspecified positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Standard position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  }
  
  // 3. VALUE DIFFERENTIAL - Scaled by round (bigger deal in early rounds)
  double valueFactor = 0.0;
  
  if (debug) debugLog.writeln("\nVALUE DIFFERENTIAL ANALYSIS:");
  
  // Scale based on round - value is more critical in early rounds
  if (round == 1) {
    // Round 1: Value matters a lot
    if (baseValueDiff >= 15) {
      valueFactor = 0.40;      // Exceptional value
      if (debug) debugLog.writeln("Round 1 with exceptional value (+$baseValueDiff)");
    } else if (baseValueDiff >= 10) {
      valueFactor = 0.35;      // Great value
      if (debug) debugLog.writeln("Round 1 with great value (+$baseValueDiff)");
    } else if (baseValueDiff >= 5) {
      valueFactor = 0.25;      // Good value
      if (debug) debugLog.writeln("Round 1 with good value (+$baseValueDiff)");
    } else if (baseValueDiff >= 0) {
      valueFactor = 0.15;      // Fair value
      if (debug) debugLog.writeln("Round 1 with fair value (+$baseValueDiff)");
    } else if (baseValueDiff >= -5) {
      valueFactor = 0.0;       // Slight reach
      if (debug) debugLog.writeln("Round 1 with slight reach ($baseValueDiff)");
    } else if (baseValueDiff >= -10) {
      valueFactor = -0.20;     // Moderate reach
      if (debug) debugLog.writeln("Round 1 with moderate reach ($baseValueDiff)");
    } else {
      valueFactor = -0.35;     // Major reach
      if (debug) debugLog.writeln("Round 1 with major reach ($baseValueDiff)");
    }
  } 
  else if (round == 2) {
    // Round 2: Value still important
    if (baseValueDiff >= 15) {
      valueFactor = 0.35;      // Exceptional value
      if (debug) debugLog.writeln("Round 2 with exceptional value (+$baseValueDiff)");
    } else if (baseValueDiff >= 10) {
      valueFactor = 0.30;      // Great value
      if (debug) debugLog.writeln("Round 2 with great value (+$baseValueDiff)");
    } else if (baseValueDiff >= 5) {
      valueFactor = 0.20;      // Good value
      if (debug) debugLog.writeln("Round 2 with good value (+$baseValueDiff)");
    } else if (baseValueDiff >= 0) {
      valueFactor = 0.10;      // Fair value
      if (debug) debugLog.writeln("Round 2 with fair value (+$baseValueDiff)");
    } else if (baseValueDiff >= -10) {
      valueFactor = -0.15;     // Reach
      if (debug) debugLog.writeln("Round 2 with reach ($baseValueDiff)");
    } else {
      valueFactor = -0.25;     // Major reach
      if (debug) debugLog.writeln("Round 2 with major reach ($baseValueDiff)");
    }
  }
  else if (round == 3) {
    // Round 3: Value moderately important
    if (baseValueDiff >= 15) {
      valueFactor = 0.30;      // Exceptional value
      if (debug) debugLog.writeln("Round 3 with exceptional value (+$baseValueDiff)");
    } else if (baseValueDiff >= 10) {
      valueFactor = 0.25;      // Great value
      if (debug) debugLog.writeln("Round 3 with great value (+$baseValueDiff)");
    } else if (baseValueDiff >= 5) {
      valueFactor = 0.15;      // Good value
      if (debug) debugLog.writeln("Round 3 with good value (+$baseValueDiff)");
    } else if (baseValueDiff >= 0) {
      valueFactor = 0.05;      // Fair value
      if (debug) debugLog.writeln("Round 3 with fair value (+$baseValueDiff)");
    } else if (baseValueDiff >= -10) {
      valueFactor = -0.10;     // Reach
      if (debug) debugLog.writeln("Round 3 with reach ($baseValueDiff)");
    } else {
      valueFactor = -0.20;     // Major reach
      if (debug) debugLog.writeln("Round 3 with major reach ($baseValueDiff)");
    }
  }
  else {
    // Rounds 4+: Value less important
    if (baseValueDiff >= 15) {
      valueFactor = 0.25;      // Exceptional value
      if (debug) debugLog.writeln("Late round with exceptional value (+$baseValueDiff)");
    } else if (baseValueDiff >= 10) {
      valueFactor = 0.20;      // Great value
      if (debug) debugLog.writeln("Late round with great value (+$baseValueDiff)");
    } else if (baseValueDiff >= 5) {
      valueFactor = 0.10;      // Good value
      if (debug) debugLog.writeln("Late round with good value (+$baseValueDiff)");
    } else if (baseValueDiff >= 0) {
      valueFactor = 0.05;      // Fair value
      if (debug) debugLog.writeln("Late round with fair value (+$baseValueDiff)");
    } else if (baseValueDiff >= -10) {
      valueFactor = -0.05;     // Reach
      if (debug) debugLog.writeln("Late round with reach ($baseValueDiff)");
    } else {
      valueFactor = -0.15;     // Major reach
      if (debug) debugLog.writeln("Late round with major reach ($baseValueDiff)");
    }
  }
  
  if (debug) {
    debugLog.writeln("Value Factor: ${valueFactor >= 0 ? '+' : ''}${valueFactor.toStringAsFixed(2)} (${(valueFactor * 10).toStringAsFixed(1)} points)");
  }
  
  // 4. COMBINE FACTORS - Base score is 5 (C grade), adjust up or down
  // Base of 5 allows more room for both positive and negative adjustments
  double baseScore = 5.0;
  
  // Build up score with our factors
  double needPoints = needFactor * 10;
  double positionPoints = positionValue * 10;
  double valuePoints = valueFactor * 10;
  double finalScore = baseScore + needPoints + positionPoints + valuePoints;
  
  if (debug) {
    debugLog.writeln("\nSCORE CALCULATION:");
    debugLog.writeln("Base Score: ${baseScore.toStringAsFixed(1)}");
    debugLog.writeln("Need Points: ${needPoints >= 0 ? '+' : ''}${needPoints.toStringAsFixed(1)}");
    debugLog.writeln("Position Points: +${positionPoints.toStringAsFixed(1)}");
    debugLog.writeln("Value Points: ${valuePoints >= 0 ? '+' : ''}${valuePoints.toStringAsFixed(1)}");
    debugLog.writeln("FINAL SCORE: ${finalScore.toStringAsFixed(1)}");
  }
  
  // Convert to letter grade using new scale
  String letterGrade = getLetterGrade(finalScore);
  
  // Calculate color gradient value (0-100 scale for UI)
  int colorScore = getColorScore(finalScore);
  
  if (debug) {
    debugLog.writeln("LETTER GRADE: $letterGrade");
    debugLog.writeln("===== END PICK GRADE CALCULATION =====\n");
    debugPrint(debugLog.toString());
  }
  
  // Store all factors for analysis
  Map<String, dynamic> factors = {
    'baseValueDiff': baseValueDiff,
    'needFactor': needFactor,
    'needIndex': needIndex,
    'isInNeedRange': isInNeedRange,
    'eligibleNeedRange': round + 3,
    'positionValue': positionValue,
    'valueFactor': valueFactor,
    'round': round,
    'baseScore': baseScore,
    'needPoints': needPoints,
    'positionPoints': positionPoints,
    'valuePoints': valuePoints,
    'debugLog': debugLog.toString(), // Store the debug log for later analysis
  };
  
  return {
    'grade': finalScore,
    'letter': letterGrade,
    'value': baseValueDiff,
    'colorScore': colorScore,
    'factors': factors,
  };
}

  /// Get round expectation factor - similar adjustment to your team grade system
  static double getRoundExpectationFactor(int round) {
    switch(round) {
      case 1: return 1.0;     // Full expectations for 1st round
      case 2: return 0.9;     // 90% expectations for 2nd round
      case 3: return 0.8;     // 80% expectations for 3rd round
      case 4: return 0.7;     // 70% expectations for 4th round
      case 5: return 0.6;     // 60% expectations for 5th round
      case 6: return 0.5;     // 50% expectations for 6th round
      case 7: return 0.4;     // 40% expectations for 7th round
      default: return 0.3;    // 30% expectations for late rounds
    }
  }

  /// Convert numeric grade to letter grade
  static String getLetterGrade(double score) {
  if (score >= 10.0) return 'A+';  // Outstanding pick
  if (score >= 9.0) return 'A';    // Excellent pick
  if (score >= 8.0) return 'A-';   // Very good pick
  if (score >= 7.0) return 'B+';   // Good pick
  if (score >= 6.0) return 'B';    // Solid pick
  if (score >= 5.0) return 'B-';   // Decent pick
  if (score >= 4.0) return 'C+';   // Average pick
  if (score >= 3.0) return 'C';    // Mediocre pick
  if (score >= 2.0) return 'C-';   // Below average pick
  if (score >= 1.0) return 'D+';   // Poor pick
  if (score >= 0.0) return 'D';    // Very poor pick
  return 'F';                      // Terrible pick
}
  
  /// Get color score for gradients (0-100)
  static int getColorScore(double score) {
  // Convert score to 0-100 scale for color gradients
  if (score >= 10.0) return 100;      // A+
  if (score >= 9.0) return 95;        // A
  if (score >= 8.0) return 90;        // A-
  if (score >= 7.0) return 85;        // B+
  if (score >= 6.0) return 80;        // B
  if (score >= 5.0) return 75;        // B-
  if (score >= 4.0) return 65;        // C+
  if (score >= 3.0) return 60;        // C
  if (score >= 2.0) return 55;        // C-
  if (score >= 1.0) return 45;        // D+
  if (score >= 0.0) return 30;        // D
  return 10;                          // F
}

  /// Generate pick grade description
  static String getGradeDescription(Map<String, dynamic> gradeInfo) {
  final factors = gradeInfo['factors'];
  final double baseValueDiff = factors['baseValueDiff'];
  final double positionValue = factors['positionValue'];
  final int needIndex = factors['needIndex'];
  final bool isInNeedRange = factors['isInNeedRange'];
  final String letterGrade = gradeInfo['letter'];
  
  String description = '';
  
  // Value component
  if (baseValueDiff >= 15) {
    description += 'Exceptional value. ';
  } else if (baseValueDiff >= 10) {
    description += 'Great value. ';
  } else if (baseValueDiff >= 5) {
    description += 'Good value. ';
  } else if (baseValueDiff >= 0) {
    description += 'Fair value. ';
  } else if (baseValueDiff >= -10) {
    description += 'Slight reach. ';
  } else {
    description += 'Significant reach. ';
  }
  
  // Position component
  if (positionValue >= 0.25) {
    description += 'Premium position. ';
  } else if (positionValue >= 0.15) {
    description += 'Valuable position. ';
  } else if (positionValue <= 0.05) {
    description += 'Devalued position. ';
  }
  
  // Need component - now with negative assessments
  if (needIndex >= 0 && needIndex <= 1 && isInNeedRange) {
    description += 'Fills top team need.';
  } else if (needIndex >= 2 && needIndex <= 3 && isInNeedRange) {
    description += 'Addresses secondary team need.';
  } else if (needIndex >= 0 && isInNeedRange) {
    description += 'Addresses team need.';
  } else if (needIndex >= 0 && !isInNeedRange) {
    description += 'Addresses lower priority need.';
  } else {
    description += 'Does not address team needs.';
  }
  
  return description;
}
  
  /// Get color for grade display
  static Color getGradeColor(String grade, [double opacity = 1.0]) {
    if (grade.startsWith('A+')) return Colors.green.shade700.withOpacity(opacity);
    if (grade.startsWith('A')) return Colors.green.shade600.withOpacity(opacity);
    if (grade.startsWith('B+')) return Colors.blue.shade700.withOpacity(opacity);
    if (grade.startsWith('B')) return Colors.blue.shade600.withOpacity(opacity);
    if (grade.startsWith('C+')) return Colors.orange.shade700.withOpacity(opacity);
    if (grade.startsWith('C')) return Colors.orange.shade600.withOpacity(opacity);
    if (grade.startsWith('D+')) return Colors.deepOrange.shade700.withOpacity(opacity);
    if (grade.startsWith('D')) return Colors.deepOrange.shade600.withOpacity(opacity);
    return Colors.red.shade700.withOpacity(opacity); // F
  }
}