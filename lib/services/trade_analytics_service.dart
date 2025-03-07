// lib/services/trade_analytics_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/trade_package.dart';
import '../services/draft_value_service.dart';

/// Service that provides advanced analytics for trade proposals
class TradeAnalyticsService {
  /// Calculate a fairness score for a trade (0-100)
  static double calculateFairnessScore(TradePackage package) {
    // Calculate the value ratio (how close to a "fair" trade)
    double valueRatio = package.totalValueOffered / package.targetPickValue;
    
    // Perfect fairness would be 1.0
    // Convert to a 0-100 score where 50 is perfectly fair
    // 0 means completely unfair (80% or less value)
    // 100 means extremely generous (120% or more value)
    if (valueRatio <= 0.8) {
      return 0.0;
    } else if (valueRatio >= 1.2) {
      return 100.0;
    } else if (valueRatio < 1.0) {
      // 0.8 to 1.0 maps to 0-50
      return (valueRatio - 0.8) * 250.0;
    } else {
      // 1.0 to 1.2 maps to 50-100
      return 50.0 + (valueRatio - 1.0) * 250.0;
    }
  }
  
  /// Calculate a pick quality score (0-100) based on pick position
  static double calculatePickQualityScore(int pickNumber) {
    // Top picks are much more valuable
    if (pickNumber <= 1) return 100.0;
    if (pickNumber <= 5) return 90.0 - (pickNumber - 1) * 2.5;
    if (pickNumber <= 10) return 80.0 - (pickNumber - 5) * 2.0;
    if (pickNumber <= 32) return 70.0 - (pickNumber - 10) * 0.9;
    if (pickNumber <= 64) return 50.0 - (pickNumber - 32) * 0.5;
    if (pickNumber <= 100) return 35.0 - (pickNumber - 64) * 0.2;
    return max(0.0, 30.0 - (pickNumber - 100) * 0.1);
  }
  
  /// Get recommended action for a trade
  static String getRecommendedAction(TradePackage package) {
    double fairnessScore = calculateFairnessScore(package);
    double targetPickQuality = calculatePickQualityScore(package.targetPick.pickNumber);
    
    // If team receiving has a top pick (1-10)
    if (package.targetPick.pickNumber <= 10) {
      if (fairnessScore >= 60) {
        return "Accept - This is a very favorable deal for a premium pick";
      } else if (fairnessScore >= 50) {
        return "Consider accepting - This is a fair offer for a valuable early pick";
      } else if (fairnessScore >= 40) {
        return "Consider countering - Slightly below value for a premium pick";
      } else {
        return "Reject - This offer significantly undervalues your early-round pick";
      }
    }
    // For first round picks (11-32)
    else if (package.targetPick.pickNumber <= 32) {
      if (fairnessScore >= 65) {
        return "Accept - This is an excellent value for your first-round pick";
      } else if (fairnessScore >= 50) {
        return "Consider accepting - This is a fair offer for a first-round pick";
      } else if (fairnessScore >= 40) {
        return "Consider countering - Slightly below value for a first-round pick";
      } else {
        return "Reject - This offer undervalues your first-round pick";
      }
    }
    // For day 2 picks (33-100)
    else if (package.targetPick.pickNumber <= 100) {
      if (fairnessScore >= 55) {
        return "Accept - This is a good deal for a mid-round pick";
      } else if (fairnessScore >= 45) {
        return "Consider accepting - This is a fair offer for a mid-round pick";
      } else {
        return "Consider countering - Below market value for this pick";
      }
    }
    // For day 3 picks (101+)
    else {
      if (fairnessScore >= 50) {
        return "Accept - This is a fair or better deal for a late-round pick";
      } else if (fairnessScore >= 40) {
        return "Consider accepting - Trade value is reasonable for a late-round pick";
      } else {
        return "Consider countering - The offer is below standard value charts";
      }
    }
  }
  
  /// Calculate the average pick position acquired in a trade
  static double calculateAveragePickPosition(List<DraftPick> picks) {
    if (picks.isEmpty) return 0;
    double sum = picks.fold(0, (prev, pick) => prev + pick.pickNumber);
    return sum / picks.length;
  }
  
  /// Calculate the "pick spread" - the difference between the best and worst picks
  static int calculatePickSpread(List<DraftPick> picks) {
    if (picks.isEmpty) return 0;
    int lowest = picks.map((p) => p.pickNumber).reduce(min);
    int highest = picks.map((p) => p.pickNumber).reduce(max);
    return highest - lowest;
  }
  
  /// Calculate the future value sacrifice (how much future capital is given up)
  static double calculateFutureValueSacrifice(TradePackage package) {
    if (!package.includesFuturePick) return 0.0;
    return package.futurePickValue ?? 0.0;
  }
  
  /// Get pros and cons analysis for a trade
  static Map<String, List<String>> getTradeProsCons(TradePackage package) {
    List<String> pros = [];
    List<String> cons = [];
    double fairnessScore = calculateFairnessScore(package);
    double valueRatio = package.totalValueOffered / package.targetPickValue;
    
    // Analysis based on value
    if (valueRatio >= 1.15) {
      pros.add("Receiving ${((valueRatio - 1.0) * 100).toInt()}% more draft value than giving up");
    } else if (valueRatio >= 1.0) {
      pros.add("Receiving fair value according to standard draft charts");
    } else if (valueRatio >= 0.9) {
      cons.add("Giving up ${((1.0 - valueRatio) * 100).toInt()}% more draft value than receiving");
    } else {
      cons.add("Significant value loss of ${((1.0 - valueRatio) * 100).toInt()}% according to standard draft charts");
    }
    
    // Analysis based on pick quality
    if (package.targetPick.pickNumber <= 10) {
      pros.add("Acquiring a premium top-10 pick with blue-chip potential");
    } else if (package.targetPick.pickNumber <= 32) {
      pros.add("Acquiring a first-round pick with potential starter value");
    }
    
    if (package.picksOffered.any((pick) => pick.pickNumber <= 15)) {
      cons.add("Trading away a valuable early pick (#${package.picksOffered.firstWhere((pick) => pick.pickNumber <= 15).pickNumber})");
    }
    
    // Analysis based on pick quantity
    if (package.picksOffered.length > 1) {
      if (package.picksOffered.length > package.additionalTargetPicks.length + 1) {
        cons.add("Giving up ${package.picksOffered.length} picks to receive ${package.additionalTargetPicks.length + 1} picks");
      } else if (package.additionalTargetPicks.isNotEmpty) {
        pros.add("Receiving multiple picks (${package.additionalTargetPicks.length + 1}) in the trade");
      }
    }
    
    // Future pick analysis
    if (package.includesFuturePick) {
      cons.add("Sacrificing future draft capital (${package.futurePickDescription})");
    }
    
    // Add at least one pro and con if lists are empty
    if (pros.isEmpty) {
      if (package.targetPick.pickNumber < calculateAveragePickPosition(package.picksOffered)) {
        pros.add("Moving up in the draft to target a specific player");
      } else {
        pros.add("Acquiring additional draft assets to address multiple needs");
      }
    }
    
    if (cons.isEmpty) {
      if (package.picksOffered.length > 1) {
        cons.add("Using multiple draft picks that could address different needs");
      } else {
        cons.add("Standard opportunity cost of the traded assets");
      }
    }
    
    return {
      'pros': pros,
      'cons': cons,
    };
  }
  
  /// Get a visualization color based on fairness score
  static Color getVisualizationColor(double fairnessScore) {
    if (fairnessScore >= 70) return Colors.green;
    if (fairnessScore >= 50) return Colors.blue;
    if (fairnessScore >= 30) return Colors.orange;
    return Colors.red;
  }
  
  /// Calculate the total number of picks given up vs. received
  static Map<String, int> calculatePickCounts(TradePackage package) {
    int picksGiven = package.picksOffered.length;
    int picksReceived = 1 + package.additionalTargetPicks.length; // Target pick + additional
    
    // Account for future picks
    if (package.includesFuturePick) {
      // Estimate the number of future picks from the description
      if (package.futurePickDescription != null) {
        // Simple estimation - count commas + 1 for rough number of picks
        picksGiven += package.futurePickDescription!.split(',').length;
      } else {
        picksGiven += 1; // Assume at least one
      }
    }
    
    return {
      'given': picksGiven,
      'received': picksReceived,
    };
  }
  
  /// Generate a detailed report of the trade
  static Map<String, dynamic> generateTradeReport(TradePackage package) {
    double fairnessScore = calculateFairnessScore(package);
    double targetPickQuality = calculatePickQualityScore(package.targetPick.pickNumber);
    Map<String, List<String>> prosCons = getTradeProsCons(package);
    Map<String, int> pickCounts = calculatePickCounts(package);
    
    return {
      'fairnessScore': fairnessScore,
      'targetPickQuality': targetPickQuality,
      'recommendedAction': getRecommendedAction(package),
      'pros': prosCons['pros'],
      'cons': prosCons['cons'],
      'pickCountsGiven': pickCounts['given'],
      'pickCountsReceived': pickCounts['received'],
      'valueRatio': package.totalValueOffered / package.targetPickValue,
      'totalValueOffered': package.totalValueOffered,
      'targetPickValue': package.targetPickValue,
      'valueDifferential': package.valueDifferential,
    };
  }
}