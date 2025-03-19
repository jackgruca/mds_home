// lib/services/draft_grade_service.dart

import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../services/draft_value_service.dart';

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
    
    // 1. Calculate grades for each pick
    double totalPickValue = 0;
    double weightedTotal = 0;
    double weightSum = 0;
    List<Map<String, dynamic>> pickGrades = [];
    
    for (var pick in picks) {
      if (pick.selectedPlayer == null) continue;
      
      // Get the grade for this pick
      Map<String, dynamic> gradeInfo = calculatePickGrade(pick, teamNeeds);
      pickGrades.add(gradeInfo);
      
      // Calculate the weight based on pick position (earlier picks matter more)
      double pickWeight = getPickWeight(pick.pickNumber);
      weightSum += pickWeight;
      
      // Add to weighted total
      weightedTotal += gradeInfo['grade'] * pickWeight;
      totalPickValue += gradeInfo['grade'];
    }
    
    // Calculate weighted average of pick grades
    double avgPickValue = weightSum > 0 ? weightedTotal / weightSum : 0;
    
    // 2. Calculate trade value
    double tradeValue = 0;
    double tradeWeight = 0.3; // How much to weight trades vs. picks
    
    for (var trade in trades) {
      if (trade.teamOffering == teamName) {
        tradeValue -= trade.valueDifferential / 100; // Scale trade value
      } else if (trade.teamReceiving == teamName) {
        tradeValue += trade.valueDifferential / 100;
      }
    }
    
    // 3. Calculate needs satisfaction score
    double needsSatisfactionScore = calculateNeedsSatisfactionScore(picks, teamNeeds);
    double needsWeight = 0.2; // How much to weight needs satisfaction
    
    // 4. Combine all factors for final grade
    double finalGrade = (avgPickValue * (1 - tradeWeight - needsWeight)) + 
                       (tradeValue * tradeWeight) + 
                       (needsSatisfactionScore * needsWeight);
    
    // Store factors for transparency
    Map<String, dynamic> factors = {
      'avgPickValue': avgPickValue,
      'totalPickValue': totalPickValue,
      'tradeValue': tradeValue,
      'tradeWeight': tradeWeight,
      'needsSatisfactionScore': needsSatisfactionScore,
      'needsWeight': needsWeight,
      'pickCount': picks.length,
      'tradeCount': trades.length,
    };
    
    // Convert to letter grade
    String letterGrade = getTeamLetterGrade(finalGrade);
    
    // Generate description
    String description = generateTeamGradeDescription(letterGrade, factors);
    
    return {
      'grade': letterGrade,
      'value': finalGrade,
      'description': description,
      'letterGrade': letterGrade,
      'pickCount': picks.length,
      'factors': factors,
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