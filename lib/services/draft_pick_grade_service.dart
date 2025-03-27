// lib/services/draft_pick_grade_service.dart
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
      if (needIndex >= 0 && needIndex < needImportanceFactor.length) {
        needFactor = 1.0 + needImportanceFactor[needIndex]!;
      }
    }
    
    // Draft value analysis
    double draftValueDiff = 0.0;
    double pickValue = DraftValueService.getValueForPick(pickNumber);
    double projectedPickValue = 0.0;
    
    // If player rank is within reason, get the draft value for that position
    if (playerRank > 0 && playerRank <= 262) {
      projectedPickValue = DraftValueService.getValueForPick(playerRank);
      draftValueDiff = (projectedPickValue - pickValue) / 100; // Scale appropriately
    }

    // Combine all factors with appropriate weights
    double valueDiffWeight = 0.5;     // 50% of grade is value differential
    double positionWeight = 0.25;     // 25% is position value
    double needWeight = 0.15;         // 15% is team need
    double roundExpWeight = 0.1;      // 10% is round expectation
    
    // Calculate adjusted value differential
    double adjustedValueDiff = baseValueDiff * roundFactor;
    
    // Calculate combined score 
    double combinedScore = (
      (adjustedValueDiff * valueDiffWeight) +
      (positionCoefficient * 5 * positionWeight) + // Scale position coefficient
      ((needFactor - 1.0) * 20 * needWeight) +    // Scale need factor
      (draftValueDiff * roundExpWeight)
    );
    
    // Store all the factors for analysis
    Map<String, dynamic> factors = {
      'baseValueDiff': baseValueDiff,
      'adjustedValueDiff': adjustedValueDiff,
      'positionCoefficient': positionCoefficient,
      'needFactor': needFactor,
      'needIndex': needIndex,
      'roundFactor': roundFactor,
      'draftValueDiff': draftValueDiff,
      'pickValue': pickValue,
      'projectedPickValue': projectedPickValue,
      'round': round,
    };
    
    // Convert to letter grade
    String letterGrade = getLetterGrade(combinedScore);
    
    // Calculate color gradient value (0-100 scale for UI)
    int colorScore = getColorScore(combinedScore);
    
    return {
      'grade': combinedScore,
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
  // More forgiving grading scale
  if (score >= 8) return 'A+';  // Was 16
  if (score >= 6) return 'A';    // Was 10
  if (score >= 4) return 'A-';   // Was 7
  if (score >= 2) return 'B+';   // Was 5
  if (score >= 0) return 'B';    // Was 3
  if (score >= -2) return 'B-';   // Was 1
  if (score >= -4) return 'C+';  // Was 0
  if (score >= -6) return 'C';   // Was -3
  if (score >= -8) return 'C-';  // Was -5
  if (score >= -10) return 'D+';  // Was -8
  if (score >= -12) return 'D';  // No change
  return 'F';                   // No change
}
  
  /// Get color score for gradients (0-100)
  static int getColorScore(double score) {
  // Convert score to 0-100 scale for color gradients with new thresholds
  if (score >= 8) return 100;      // A+
  if (score >= 6) return 95;        // A
  if (score >= 4) return 90;        // A-
  if (score >= 2) return 85;        // B+
  if (score >= 0) return 80;        // B
  if (score >= -2) return 75;        // B-
  if (score >= -4) return 65;       // C+
  if (score >= -6) return 60;       // C
  if (score >= -8) return 55;       // C-
  if (score >= -10) return 45;       // D+
  if (score >= -12) return 30;      // D
  return 10;                        // F
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