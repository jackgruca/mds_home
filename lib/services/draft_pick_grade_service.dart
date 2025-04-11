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
    'CB | WR': 1.3, // Travis Hunter 
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
  List<String> positionParts = position.split(' | ');
  int needIndex = originalNeeds.indexWhere((need) => positionParts.contains(need));
  
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
  if (['QB'].contains(position)) {
    positionValue = 1.5; // +25% for premier positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Premier position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['EDGE', 'OT', 'CB | WR'].contains(position)) {
    positionValue = 1.3; // +20% for key positions  
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Key position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['CB', 'WR'].contains(position)) {
    positionValue = 1.2; // +20% for key positions  
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Key position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['S', 'DL', 'TE'].contains(position)) {
    positionValue = 1.1; // +15% for valuable positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Valuable position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else if (['IOL', 'LB', 'RB'].contains(position)) {
    positionValue = 1.0; // +10% for solid positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Solid position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  } else {
    positionValue = 0.90; // Default +10% for unspecified positions
    if (debug) debugLog.writeln("\nPOSITION VALUE: +${positionValue.toStringAsFixed(2)} (Standard position: +${(positionValue * 10).toStringAsFixed(1)} points)");
  }
  
  // 3. VALUE DIFFERENTIAL - Scaled by round (bigger deal in early rounds)
  // Replace the VALUE DIFFERENTIAL section with this more granular approach
// 3. VALUE DIFFERENTIAL - Using percentage-based scaling for more granularity
double valueFactor = 0.0;

if (debug) debugLog.writeln("\nVALUE DIFFERENTIAL ANALYSIS:");

// Calculate value differential as a percentage of pick position
// This makes it scale appropriately for any pick number
double percentDiff = 0.0;
if (playerRank > 0) {
  percentDiff = (pickNumber - playerRank) / playerRank * 100;
} else {
  percentDiff = 0.0; // Avoid division by zero
}

// Apply round-based scaling to the percentage
// Scale is more stringent in early rounds
if (round == 1) {
  // First round: Very fine-grained value assessment
  if (percentDiff >= 40) {
    valueFactor = 0.45;      // Exceptional value (>30% value)
    if (debug) debugLog.writeln("Round 1 with exceptional value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 26) {
    valueFactor = 0.40;      // Outstanding value (20-30% value)
    if (debug) debugLog.writeln("Round 1 with outstanding value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 20) {
    valueFactor = 0.35;      // Excellent value (15-20% value)
    if (debug) debugLog.writeln("Round 1 with excellent value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 14) {
    valueFactor = 0.30;      // Great value (10-15% value)
    if (debug) debugLog.writeln("Round 1 with great value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 7) {
    valueFactor = 0.20;      // Good value (5-10% value)
    if (debug) debugLog.writeln("Round 1 with good value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 0) {
    valueFactor = 0.10;      // Fair value (0-5% value)
    if (debug) debugLog.writeln("Round 1 with fair value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -7) {
    valueFactor = 0.0;       // Slight reach (-5-0% value)
    if (debug) debugLog.writeln("Round 1 with slight reach (${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -14) {
    valueFactor = -0.15;     // Moderate reach (-10 to -5% value)
    if (debug) debugLog.writeln("Round 1 with moderate reach (${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -20) {
    valueFactor = -0.25;     // Significant reach (-15 to -10% value)
    if (debug) debugLog.writeln("Round 1 with significant reach (${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -26) {
    valueFactor = -0.35;     // Major reach (-20 to -15% value)
    if (debug) debugLog.writeln("Round 1 with major reach (${percentDiff.toStringAsFixed(1)}%)");
  } else {
    valueFactor = -0.45;     // Extreme reach (< -20% value)
    if (debug) debugLog.writeln("Round 1 with extreme reach (${percentDiff.toStringAsFixed(1)}%)");
  }
} 
else if (round == 2) {
  // Round 2: Still important but slightly more forgiving
  if (percentDiff >= 40) {
    valueFactor = 0.40;      // Exceptional value
    if (debug) debugLog.writeln("Round 2 with exceptional value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 26) {
    valueFactor = 0.35;      // Great value
    if (debug) debugLog.writeln("Round 2 with great value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 14) {
    valueFactor = 0.25;      // Good value
    if (debug) debugLog.writeln("Round 2 with good value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 0) {
    valueFactor = 0.10;      // Fair value
    if (debug) debugLog.writeln("Round 2 with fair value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -14) {
    valueFactor = -0.10;     // Slight reach
    if (debug) debugLog.writeln("Round 2 with slight reach (${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -26) {
    valueFactor = -0.20;     // Moderate reach
    if (debug) debugLog.writeln("Round 2 with moderate reach (${percentDiff.toStringAsFixed(1)}%)");
  } else {
    valueFactor = -0.30;     // Major reach
    if (debug) debugLog.writeln("Round 2 with major reach (${percentDiff.toStringAsFixed(1)}%)");
  }
}
else if (round == 3) {
  // Round 3: Moderately important
  if (percentDiff >= 40) {
    valueFactor = 0.35;      // Exceptional value
    if (debug) debugLog.writeln("Round 3 with exceptional value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 26) {
    valueFactor = 0.25;      // Great value
    if (debug) debugLog.writeln("Round 3 with great value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 14) {
    valueFactor = 0.15;      // Good value
    if (debug) debugLog.writeln("Round 3 with good value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 0) {
    valueFactor = 0.05;      // Fair value
    if (debug) debugLog.writeln("Round 3 with fair value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -20) {
    valueFactor = -0.05;     // Slight reach
    if (debug) debugLog.writeln("Round 3 with slight reach (${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -33) {
    valueFactor = -0.15;     // Moderate reach
    if (debug) debugLog.writeln("Round 3 with moderate reach (${percentDiff.toStringAsFixed(1)}%)");
  } else {
    valueFactor = -0.25;     // Major reach
    if (debug) debugLog.writeln("Round 3 with major reach (${percentDiff.toStringAsFixed(1)}%)");
  }
}
else {
  // Rounds 4+: Less important, more forgiving
  if (percentDiff >= 50) {
    valueFactor = 0.30;      // Exceptional value
    if (debug) debugLog.writeln("Late round with exceptional value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 30) {
    valueFactor = 0.20;      // Great value
    if (debug) debugLog.writeln("Late round with great value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= 15) {
    valueFactor = 0.10;      // Good value
    if (debug) debugLog.writeln("Late round with good value (+${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -14) {
    valueFactor = 0.0;       // Fair value/Neutral
    if (debug) debugLog.writeln("Late round with fair value (${percentDiff.toStringAsFixed(1)}%)");
  } else if (percentDiff >= -33) {
    valueFactor = -0.10;     // Reach
    if (debug) debugLog.writeln("Late round with reach (${percentDiff.toStringAsFixed(1)}%)");
  } else {
    valueFactor = -0.20;     // Major reach
    if (debug) debugLog.writeln("Late round with major reach (${percentDiff.toStringAsFixed(1)}%)");
  }
}

if (debug) {
  debugLog.writeln("Value differential as percentage: ${percentDiff.toStringAsFixed(1)}%");
  debugLog.writeln("Value Factor: ${valueFactor >= 0 ? '+' : ''}${valueFactor.toStringAsFixed(2)} (${(valueFactor * 10).toStringAsFixed(1)} points)");
}
  
  // 4. COMBINE FACTORS - Base score is 5 (C grade), adjust up or down
  double baseScore = 4.0;  // Changed from 5.0 to 4.0

// Build up score with our factors
double needPoints = needFactor * 10;
double positionPoints = positionValue;
double valuePoints = valueFactor * 10;
double finalScore = baseScore + (needPoints*positionPoints) + valuePoints;

if (debug) {
  debugLog.writeln("\nSCORE CALCULATION:");
  debugLog.writeln("Base Score: ${baseScore.toStringAsFixed(1)}");
  debugLog.writeln("Need Points: ${needPoints >= 0 ? '+' : ''}${needPoints.toStringAsFixed(1)}");
  debugLog.writeln("Position Points: ${positionPoints.toStringAsFixed(1)}x");
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
  
  /// Get color score for gradients (0-100)
  static int getColorScore(double score) {
  // Convert score to 0-100 scale for color gradients
  if (score >= 9.0) return 100;      // A+
  if (score >= 8.0) return 95;       // A
  if (score >= 7.0) return 90;       // A-
  if (score >= 6.0) return 85;       // B+
  if (score >= 5.0) return 80;       // B
  if (score >= 4.0) return 75;       // B-
  if (score >= 3.0) return 65;       // C+
  if (score >= 2.0) return 60;       // C
  if (score >= 1.0) return 55;       // C-
  if (score >= 0.0) return 45;       // D+
  if (score >= -1.0) return 30;      // D
  return 10;                         // F
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