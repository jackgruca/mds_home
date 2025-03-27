// lib/services/draft_pick_grade_service.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../services/draft_value_service.dart';

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

  /// Calculate comprehensive grade for an individual pick
static Map<String, dynamic> calculatePickGrade(
  DraftPick pick, 
  List<TeamNeed> teamNeeds,
  {bool considerTeamNeeds = true}
) {
  if (pick.selectedPlayer == null) {
    return {
      'grade': 0.0,
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
  final int round = DraftValueService.getRoundForPick(pickNumber);
  
  // Get draft pick values for comparison
  double pickValue = DraftValueService.getValueForPick(pickNumber);
  double projectedPickValue = DraftValueService.getValueForPick(playerRank);
  
  // ---- VALUE SCORE CALCULATION ----
  // Base value differential (traditional calculation)
  int baseValueDiff = pickNumber - playerRank;
  
  // Value ratio (key factor in real draft analysis)
  double valueRatio = playerRank <= 0 ? 1.0 : pickNumber / playerRank;
  
  // Create a value score with more nuanced thresholds
  double valueScore;
  
  // First round has highest standards
  if (round == 1) {
    if (baseValueDiff >= 20) valueScore = 98;       // Exceptional value (e.g. #10 pick getting #30 talent)
    else if (baseValueDiff >= 15) valueScore = 95;  // Excellent value 
    else if (baseValueDiff >= 10) valueScore = 90;  // Great value
    else if (baseValueDiff >= 5) valueScore = 85;   // Very good value
    else if (baseValueDiff >= 0) valueScore = 80;   // Good value
    else if (baseValueDiff >= -5) valueScore = 75;  // Fair value
    else if (baseValueDiff >= -10) valueScore = 65; // Slight reach
    else if (baseValueDiff >= -15) valueScore = 55; // Moderate reach
    else if (baseValueDiff >= -20) valueScore = 45; // Significant reach
    else valueScore = 35;                          // Major reach
  } 
  // Expectations decrease with each round
  else if (round == 2) {
    if (baseValueDiff >= 20) valueScore = 98;
    else if (baseValueDiff >= 15) valueScore = 95;
    else if (baseValueDiff >= 10) valueScore = 90;
    else if (baseValueDiff >= 5) valueScore = 85;
    else if (baseValueDiff >= 0) valueScore = 80;
    else if (baseValueDiff >= -10) valueScore = 70;
    else if (baseValueDiff >= -20) valueScore = 60;
    else if (baseValueDiff >= -30) valueScore = 50;
    else valueScore = 40;
  }
  else if (round == 3) {
    if (baseValueDiff >= 25) valueScore = 98;
    else if (baseValueDiff >= 15) valueScore = 95;
    else if (baseValueDiff >= 10) valueScore = 90;
    else if (baseValueDiff >= 0) valueScore = 85;
    else if (baseValueDiff >= -15) valueScore = 75;
    else if (baseValueDiff >= -30) valueScore = 65;
    else valueScore = 55;
  }
  else {
    // Later rounds (4-7) are more forgiving but still have standards
    if (baseValueDiff >= 30) valueScore = 98;
    else if (baseValueDiff >= 20) valueScore = 95;
    else if (baseValueDiff >= 10) valueScore = 90;
    else if (baseValueDiff >= 0) valueScore = 85;
    else if (baseValueDiff >= -20) valueScore = 75;
    else if (baseValueDiff >= -40) valueScore = 65;
    else valueScore = 55;
  }
  
  // ---- TEAM NEED SCORE CALCULATION ----
  double needScore = 65; // Default when not a team need
  int needIndex = -1;
  double needFactor = 1.0;
  
  if (considerTeamNeeds) {
    // Find team needs
    TeamNeed? teamNeed = teamNeeds.firstWhere(
      (need) => need.teamName == pick.teamName,
      orElse: () => TeamNeed(teamName: pick.teamName, needs: []),
    );
    
    if (teamNeed.needs.isNotEmpty) {
      // Check position in needs list
      needIndex = teamNeed.needs.indexOf(position);
      
      if (needIndex == 0) {
        needScore = 100; // Top need
        needFactor = 1.25; // 25% boost
      } else if (needIndex == 1) {
        needScore = 95; // Second need
        needFactor = 1.20; // 20% boost
      } else if (needIndex == 2) {
        needScore = 90; // Third need
        needFactor = 1.15; // 15% boost
      } else if (needIndex == 3) {
        needScore = 85; // Fourth need
        needFactor = 1.10; // 10% boost
      } else if (needIndex == 4) {
        needScore = 80; // Fifth need
        needFactor = 1.05; // 5% boost
      } else if (needIndex > 4) {
        needScore = 75; // Lower priority need
        needFactor = 1.0; // No boost
      }
    }
  }
  
  // ---- POSITIONAL VALUE CALCULATION ----
  double positionScore;
  double positionCoefficient = positionValueCoefficients[position] ?? 1.0;
  
  // Convert coefficient to score
  if (positionCoefficient >= 1.4) {
    positionScore = 98; // QB premium
  } else if (positionCoefficient >= 1.3) {
    positionScore = 95; // Elite position (EDGE, OT)
  } else if (positionCoefficient >= 1.15) {
    positionScore = 90; // Premium position (CB, WR)
  } else if (positionCoefficient >= 1.0) {
    positionScore = 85; // Standard value position
  } else if (positionCoefficient >= 0.9) {
    positionScore = 75; // Below average value position
  } else {
    positionScore = 70; // Devalued position (RB, etc.)
  }
  
  // ---- ROUND-BASED ADJUSTMENTS ----
  double roundFactor = getRoundExpectationFactor(round);
  
  // ---- FINAL GRADE CALCULATION ----
  // Weighted components (60% value, 30% need, 10% position)
  Map<String, double> weights = getWeightsByPickContext(pickNumber);
  
  // Calculate weighted component scores
  double weightedValueScore = valueScore * weights['value']!;
  double weightedNeedScore = needScore * weights['need']!;
  double weightedPositionScore = positionScore * weights['position']!;
  
  // Calculate preliminary numeric grade
  double numericGrade = weightedValueScore + weightedNeedScore + weightedPositionScore;
  
  // Apply need boost for top needs to offset modest reaches
  if (needIndex >= 0 && needIndex <= 2 && baseValueDiff < 0 && baseValueDiff > -20) {
    // Apply boost only for top 3 needs when there was a modest reach
    numericGrade = min(100, numericGrade + (5 - needIndex));
  }
  
  // Apply reach penalty for significant reaches that aren't for top needs
  if (baseValueDiff < -20 && (needIndex < 0 || needIndex > 2)) {
    numericGrade = max(40, numericGrade - 10);
  }
  
  // Apply early round premium positions bonus
  if (round <= 2 && positionCoefficient >= 1.3) {
    numericGrade = min(100, numericGrade + 2);
  }
  
  // Apply premium for truly exceptional value
  if (baseValueDiff > 20) {
    numericGrade = min(100, numericGrade + 3);
  }
  
  // Final round-appropriate floor (worse grades in early rounds, more forgiving later)
  double roundFloor;
  if (round == 1) roundFloor = 35; // First round can get D/F for terrible value
  else if (round == 2) roundFloor = 40;
  else if (round == 3) roundFloor = 45;
  else roundFloor = 50; // Later rounds don't go below F
  
  numericGrade = max(numericGrade, roundFloor);
  
  // Convert to letter grade with NFL draft analyst style distribution
  String letterGrade = getLetterGrade(numericGrade);
  
  // Color score for visualizations (0-100)
  int colorScore = numericGrade.round();
  
  // Store all calculation factors for transparency
  Map<String, dynamic> factors = {
    'baseValueDiff': baseValueDiff,
    'valueRatio': valueRatio,
    'valueScore': valueScore,
    'needScore': needScore,
    'needFactor': needFactor,
    'needIndex': needIndex,
    'positionScore': positionScore,
    'positionCoefficient': positionCoefficient,
    'draftValueDiff': (projectedPickValue / pickValue) - 1.0,
    'pickValue': pickValue,
    'projectedPickValue': projectedPickValue,
    'roundFactor': roundFactor,
    'round': round,
    'weightedValueScore': weightedValueScore,
    'weightedNeedScore': weightedNeedScore,
    'weightedPositionScore': weightedPositionScore,
    'roundFloor': roundFloor
  };
  
  return {
    'grade': numericGrade,
    'letter': letterGrade,
    'value': baseValueDiff,
    'colorScore': colorScore,
    'factors': factors,
  };
}

/// Convert score to letter grade
static String getLetterGrade(double score) {
  if (score >= 97) return 'A+';
  if (score >= 93) return 'A';
  if (score >= 90) return 'A-';
  if (score >= 87) return 'B+';
  if (score >= 83) return 'B';
  if (score >= 80) return 'B-';
  if (score >= 77) return 'C+';
  if (score >= 73) return 'C';
  if (score >= 70) return 'C-';
  if (score >= 67) return 'D+';
  if (score >= 63) return 'D';
  if (score >= 60) return 'D-';
  return 'F';
}

/// Get color score for gradients (0-100)
static int getColorScore(double score) {
  // Already in 0-100 range
  return score.round().clamp(0, 100);
}

/// Convert percentage score to letter grade
static String getLetterGradeFromPercentage(double score) {
  if (score >= 97) return 'A+';
  if (score >= 93) return 'A';
  if (score >= 90) return 'A-';
  if (score >= 87) return 'B+';
  if (score >= 83) return 'B';
  if (score >= 80) return 'B-';
  if (score >= 77) return 'C+';
  if (score >= 73) return 'C';
  if (score >= 70) return 'C-';
  if (score >= 67) return 'D+';
  if (score >= 63) return 'D';
  if (score >= 60) return 'D-';
  return 'F';
}

// Need a random instance for small variations within ranges
static final Random _random = Random();

/// Get appropriate weights by pick context - adjusted to emphasize need more
static Map<String, double> getWeightsByPickContext(int pickNumber) {
  if (pickNumber <= 10) {
    // Top 10 picks: balanced approach with strong need component
    return {'value': 0.5, 'need': 0.4, 'position': 0.1};
  } else if (pickNumber <= 32) {
    // Rest of 1st round: balanced approach
    return {'value': 0.4, 'need': 0.5, 'position': 0.1};
  } else if (pickNumber <= 105) {
    // Day 2 (Rounds 2-3): needs matter most
    return {'value': 0.4, 'need': 0.5, 'position': 0.1};
  } else {
    // Day 3 (Rounds 4-7): value hunting more important
    return {'value': 0.5, 'need': 0.4, 'position': 0.1};
  }
}

/// Get expected range for picks at different draft positions
static int getExpectedRange(int pickNumber) {
  if (pickNumber <= 5) return 10;       // Top 5: within 10 spots
  if (pickNumber <= 15) return 15;      // Early 1st: within 15 spots
  if (pickNumber <= 32) return 20;      // 1st round: within 20 spots
  if (pickNumber <= 64) return 30;      // 2nd round: within 30 spots
  if (pickNumber <= 105) return 40;     // 3rd round: within 40 spots
  return 50;                            // Later rounds: within 50 spots
}

/// Get the expected range for a pick
/// Early picks should have tighter expectations
static int _getExpectedRangeForPick(int pickNumber) {
  if (pickNumber <= 5) return 5;      // Top 5 picks: expected within 5 spots
  if (pickNumber <= 10) return 7;     // Top 10: within 7 spots
  if (pickNumber <= 15) return 10;    // Top 15: within 10 spots
  if (pickNumber <= 32) return 15;    // 1st round: within 15 spots
  if (pickNumber <= 64) return 20;    // 2nd round: within 20 spots
  if (pickNumber <= 100) return 25;   // 3rd round: within 25 spots
  return 30;                          // Later rounds: within 30 spots
}

/// Get appropriate weights based on pick context
static Map<String, double> _getWeightsByPickContext(int pickNumber) {
  if (pickNumber <= 10) {
    // Top 10 picks: value matters most, needs matter less
    return {'value': 0.7, 'need': 0.2, 'position': 0.1};
  } else if (pickNumber <= 32) {
    // 1st round: balanced approach
    return {'value': 0.6, 'need': 0.3, 'position': 0.1};
  } else if (pickNumber <= 100) {
    // 2nd-3rd rounds: needs matter more
    return {'value': 0.5, 'need': 0.4, 'position': 0.1};
  } else {
    // Later rounds: value hunting matters most
    return {'value': 0.6, 'need': 0.3, 'position': 0.1};
  }
}

/// Premium positions with higher draft value
static const Set<String> _premiumPositions = {
  'QB', 'EDGE', 'OT', 'CB', 'WR'
};

/// Secondary value positions
static const Set<String> _secondaryPositions = {
  'DT', 'S', 'TE', 'IOL', 'LB'
};

/// Convert score to letter grade
static String getLetterGradeFromScore(double score) {
  if (score >= 8) return 'A+';
  if (score >= 6) return 'A';
  if (score >= 4) return 'A-';
  if (score >= 2) return 'B+';
  if (score >= 0) return 'B';
  if (score >= -2) return 'B-';
  if (score >= -4) return 'C+';
  if (score >= -6) return 'C';
  if (score >= -8) return 'C-';
  if (score >= -10) return 'D+';
  if (score >= -12) return 'D';
  return 'F';
}

/// Convert score to color score (0-100)
static int _getColorScoreFromScore(double score) {
  // Map the -12 to +10 range to 0-100
  double normalizedScore = (score + 12) / 22.0; // Map to 0-1 range
  return (normalizedScore * 100).round(); // Convert to 0-100
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

  /// Generate pick grade description
  static String getGradeDescription(Map<String, dynamic> gradeInfo) {
    final double baseValueDiff = gradeInfo['factors']['baseValueDiff'];
    final double positionCoefficient = gradeInfo['factors']['positionCoefficient'];
    final int needIndex = gradeInfo['factors']['needIndex'];
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
    if (positionCoefficient >= 1.3) {
      description += 'Premium position. ';
    } else if (positionCoefficient >= 1.1) {
      description += 'Valuable position. ';
    } else if (positionCoefficient <= 0.9) {
      description += 'Devalued position. ';
    }
    
    // Need component
    if (needIndex >= 0 && needIndex <= 1) {
      description += 'Fills top team need.';
    } else if (needIndex >= 2 && needIndex <= 3) {
      description += 'Addresses secondary team need.';
    } else if (needIndex >= 0) { // Any other positive need index
      description += 'Addresses team need.';
    } else {
      description += 'Does not address immediate team needs.';
    }
    
    return description;
  }
  
  /// Get color for grade display
  static Color getGradeColor(String grade, [double opacity = 1.0]) {
    if (grade.startsWith('A+')) return Colors.blue.shade900.withOpacity(opacity);
    if (grade.startsWith('A-')) return Colors.blue.shade600.withOpacity(opacity);
    if (grade.startsWith('A')) return Colors.blue.shade700.withOpacity(opacity);
    if (grade.startsWith('B+')) return Colors.green.shade800.withOpacity(opacity);
    if (grade.startsWith('B-')) return Colors.green.shade600.withOpacity(opacity);
    if (grade.startsWith('B')) return Colors.green.shade700.withOpacity(opacity);
    if (grade.startsWith('C+')) return Colors.yellow.shade700.withOpacity(opacity);
    if (grade.startsWith('C-')) return Colors.amber.shade800.withOpacity(opacity);
    if (grade.startsWith('C')) return Colors.amber.shade600.withOpacity(opacity);
    if (grade.startsWith('D+')) return Colors.deepOrange.shade700.withOpacity(opacity);
    if (grade.startsWith('D')) return Colors.deepOrange.shade900.withOpacity(opacity);
    return Colors.red.shade700.withOpacity(opacity); // F
  }
}