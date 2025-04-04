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
  List<TeamNeed> teamNeeds
) {
  if (picks.isEmpty) {
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
  
  // Simply get the letter grades for all picks
  List<String> letterGrades = [];
  List<double> weights = [];
  
  for (var pick in picks) {
    if (pick.selectedPlayer == null) continue;
    
    // Calculate the pick grade
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
    String letter = gradeInfo['letter'];
    letterGrades.add(letter);
    
    // Add weight based on round
    int round = DraftValueService.getRoundForPick(pick.pickNumber);
    if (round == 1) weights.add(3.0);         // 1st round counts 3x
    else if (round == 2) weights.add(2.0);    // 2nd round counts 2x
    else if (round == 3) weights.add(1.5);    // 3rd round counts 1.5x
    else weights.add(1.0);                    // Later rounds count 1x
  }
  
  // Convert letter grades to numeric values (simple 4.0 scale)
  List<double> numericGrades = [];
  for (var letter in letterGrades) {
    double value;
    if (letter == 'A+') value = 4.3;
    else if (letter == 'A') value = 4.0;
    else if (letter == 'A-') value = 3.7;
    else if (letter == 'B+') value = 3.3;
    else if (letter == 'B') value = 3.0;
    else if (letter == 'B-') value = 2.7;
    else if (letter == 'C+') value = 2.3;
    else if (letter == 'C') value = 2.0;
    else if (letter == 'C-') value = 1.7;
    else if (letter == 'D+') value = 1.3;
    else if (letter == 'D') value = 1.0;
    else value = 0.0; // F
    
    numericGrades.add(value);
  }
  
  // Simple weighted average
  double totalValue = 0;
  double totalWeight = 0;
  
  for (int i = 0; i < numericGrades.length; i++) {
    totalValue += numericGrades[i] * weights[i];
    totalWeight += weights[i];
  }
  
  double avgGrade = totalValue / totalWeight;
  
  // Minimal trade adjustment (optional)
  double tradeImpact = 0.0;
  if (trades.isNotEmpty) {
    for (var trade in trades) {
      if (trade.teamOffering == teamName) {
        tradeImpact -= trade.valueDifferential < 0 ? 0.1 : 0.0;
      } else if (trade.teamReceiving == teamName) {
        tradeImpact += trade.valueDifferential > 0 ? 0.1 : 0.0;
      }
    }
  }
  
  // Apply minimal trade impact
  tradeImpact = tradeImpact.clamp(-0.2, 0.2);
  avgGrade += tradeImpact;
  
  // Convert back to letter grade
  String finalGrade;
  if (avgGrade >= 4.2) finalGrade = 'A+';
  else if (avgGrade >= 3.85) finalGrade = 'A';
  else if (avgGrade >= 3.5) finalGrade = 'A-';
  else if (avgGrade >= 3.15) finalGrade = 'B+';
  else if (avgGrade >= 2.85) finalGrade = 'B';
  else if (avgGrade >= 2.5) finalGrade = 'B-';
  else if (avgGrade >= 2.15) finalGrade = 'C+';
  else if (avgGrade >= 1.85) finalGrade = 'C';
  else if (avgGrade >= 1.5) finalGrade = 'C-';
  else if (avgGrade >= 1.15) finalGrade = 'D+';
  else if (avgGrade >= 0.85) finalGrade = 'D';
  else finalGrade = 'F';
  
  // Generate a description
  String description = _generateTeamGradeDescription(finalGrade, {
    'avgGrade': avgGrade,
    'letterGrades': letterGrades,
  });
  
  return {
    'grade': finalGrade,
    'value': avgGrade,
    'description': description,
    'letterGrade': finalGrade,
    'factors': {
      'letterGrades': letterGrades,
      'numericGrades': numericGrades,
      'weights': weights,
      'avgGrade': avgGrade,
      'tradeImpact': tradeImpact,
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
  static String getTeamLetterGrade(double value) {
    if (value >= 15) return 'A+';
    if (value >= 10) return 'A';
    if (value >= 5) return 'B+';
    if (value >= 0) return 'B';
    if (value >= -5) return 'C+';
    if (value >= -10) return 'C';
    if (value >= -15) return 'D';
    return 'F';
  }

  /// Generate description based on team grade
  static String generateTeamGradeDescription(
    String grade, 
    Map<String, dynamic> factors
  ) {
    if (grade.startsWith('A+')) {
      return 'Outstanding draft with exceptional value and need fulfillment';
    } else if (grade.startsWith('A')) {
      return 'Excellent draft with great value picks and strategic trades';
    } else if (grade.startsWith('B+')) {
      return 'Very good draft with solid value and good need fulfillment';
    } else if (grade.startsWith('B')) {
      return 'Solid draft with good value picks addressing team needs';
    } else if (grade.startsWith('C+')) {
      return 'Average draft with some good picks but missed opportunities';
    } else if (grade.startsWith('C')) {
      return 'Below average draft with several reaches or missed needs';
    } else if (grade.startsWith('D')) {
      return 'Poor draft with significant reaches and unfilled needs';
    } else {
      return 'Very poor draft with major reaches and strategic errors';
    }
  }
}