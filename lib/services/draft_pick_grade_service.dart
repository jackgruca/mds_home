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
  
  // STEP 1: Calculate BPA Delta Score - ADJUSTED FOR INVERTED METHOD
  int bpaDelta = pickNumber - playerRank; // Now negative is good, positive is a reach
  double bpaScore;
  
  // REVISED: BPA score calculation for inverted delta
  if (bpaDelta <= -10) {
    bpaScore = 100.0; // Excellent value
  } else if (bpaDelta <= 0) {
    bpaScore = 80.0 + (bpaDelta * -2.0); // Good value (80-100)
  } else if (bpaDelta <= 10) {
    bpaScore = 60.0 + (bpaDelta * -2.0); // Fair value (40-60)
  } else if (bpaDelta <= 20) {
    bpaScore = 30.0 + ((bpaDelta - 20) * -1.0); // Reach (30-40)
  } else {
    bpaScore = max(20.0, 30.0 + ((bpaDelta - 20) * -0.5)); // Major reach (20-30)
  }
  
  // Add a flat boost to all grades to raise the overall grade distribution
  bpaScore = min(100.0, bpaScore + 10.0);
  
  // Add pick context adjustment: early picks get a boost
  if (pickNumber <= 5) {
    // Top 5 picks are often "best player available" rather than pure value plays
    bpaScore = max(bpaScore, 75.0); // Ensure at least 75 for top 5 picks
  } else if (pickNumber <= 15) {
    // Early 1st rounders also get a boost
    bpaScore = max(bpaScore, 70.0); // Ensure at least 70 for top 15 picks
  } else if (pickNumber <= 32) {
    // 1st rounders get a small boost
    bpaScore = max(bpaScore, 65.0); // Ensure at least 65 for 1st round
  }
  
  // STEP 2: Calculate Team Need Level (0-100) - ENHANCED
  double teamNeedLevel = 60.0; // Higher neutral default
  int needIndex = -1;
  
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
        teamNeedLevel = 100.0; // Top need
      } else if (needIndex == 1) {
        teamNeedLevel = 95.0; // Second need
      } else if (needIndex == 2) {
        teamNeedLevel = 90.0; // Third need
      } else if (needIndex >= 3 && needIndex <= 5) {
        teamNeedLevel = 80.0; // Secondary need
      } else if (needIndex > 5) {
        teamNeedLevel = 70.0; // Lower priority need
      } else {
        teamNeedLevel = 50.0; // Not in needs list
      }
    }
  }
  
  // STEP 3: Calculate Positional Value (0-100) - ENHANCED
  double positionalValue;
  
  // Premium positions
  if (position == 'QB') {
    positionalValue = 125.0; // Quarterback premium
  } else if (['EDGE', 'OT', 'CB | WR'].contains(position)) {
    positionalValue = 115.0; // Top tier
  } else if (['CB', 'WR'].contains(position)) {
    positionalValue = 110.0; // High value
  } else if (['DT', 'S', 'TE'].contains(position)) {
    positionalValue = 100.0; // Good value
  } else if (['LB', 'IOL', 'G', 'C'].contains(position)) {
    positionalValue = 100.0; // Solid value
  } else if (position == 'RB') {
    positionalValue = 100.0; // Lower value
  } else {
    positionalValue = 80.0; // Specialists
  }
  
  // STEP 4: Calculate Weighted Pick Grade Score
  double pickGradeScore = (bpaScore * 0.5) + (teamNeedLevel * 0.3) + (positionalValue * 0.2);
  
  // Store all factors for transparency
  Map<String, dynamic> factors = {
    'bpaDelta': bpaDelta,
    'bpaScore': bpaScore,
    'needIndex': needIndex,
    'teamNeedLevel': teamNeedLevel,
    'positionalValue': positionalValue,
    'pickGradeScore': pickGradeScore
  };
  
  // Convert to letter grade and color score
  String letterGrade = getLetterGrade(pickGradeScore);
  
  return {
    'grade': pickGradeScore,
    'letter': letterGrade,
    'value': bpaDelta,
    'colorScore': pickGradeScore.round(),
    'factors': factors,
  };
}

/// Convert score to letter grade
static String getLetterGrade(double score) {
  if (score >= 95) return 'A+';
  if (score >= 90) return 'A';
  if (score >= 85) return 'A-';
  if (score >= 80) return 'B+';
  if (score >= 75) return 'B';
  if (score >= 70) return 'B-';
  if (score >= 65) return 'C+';
  if (score >= 60) return 'C';
  if (score >= 50) return 'D';
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