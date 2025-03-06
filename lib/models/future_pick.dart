// lib/models/future_pick.dart
import 'dart:math';
import '../services/draft_value_service.dart';

/// Represents a future draft pick (for next year)
class FuturePick {
  final String team;
  final int estimatedPickNumber;
  final double value;
  final int estimatedRound;
  final String year;

  const FuturePick({
    required this.team,
    required this.estimatedPickNumber,
    required this.value,
    required this.estimatedRound,
    this.year = '2026', // Default to next year
  });

  /// Create a future pick with estimated position based on team strength
  factory FuturePick.estimate(String team, int teamStrength) {
    // TeamStrength is 1-32 scale where 1 = strongest team, 32 = weakest
    
    // Calculate a realistic pick range based on team strength
    // Strong teams (1-8) typically pick 24-32
    // Average teams (9-24) typically pick 9-23
    // Weak teams (25-32) typically pick 1-8
    
    int basePick;
    if (teamStrength <= 8) {
      // Strong team: Likely to pick late
      basePick = 33 - teamStrength; // 25-32
    } else if (teamStrength <= 24) {
      // Average team: Mid-round pick with some variation
      basePick = 33 - teamStrength; // 9-24
    } else {
      // Weak team: Likely early pick
      basePick = 33 - teamStrength; // 1-8
    }
    
    // Add some randomness (±3 spots)
    final random = Random();
    final variation = random.nextInt(7) - 3; // -3 to +3
    
    // Ensure pick stays in 1-32 range
    final estimatedPick = max(1, min(32, basePick + variation));
    
    // Calculate round (always 1 for picks 1-32)
    const round = 1;
    
    // Calculate the base value of this pick
    final baseValue = DraftValueService.getValueForPick(estimatedPick);
    
    // Future picks are typically discounted 
    // 1st round: ~70% of current value
    // 2nd round: ~60% of current value
    // 3rd+ round: ~50% of current value
    double discountFactor;
    if (round == 1) {
      discountFactor = 0.7;
    } else if (round == 2) {
      discountFactor = 0.6;
    } else {
      discountFactor = 0.5;
    }
    
    // Apply discount
    final discountedValue = baseValue * discountFactor;
    
    return FuturePick(
      team: team,
      estimatedPickNumber: estimatedPick,
      value: discountedValue,
      estimatedRound: round,
    );
  }

  /// Create a future pick for a specific round (when exact pick is unknown)
  factory FuturePick.forRound(String team, int round, {String year = '2026'}) {
    // Estimate the middle pick of the specified round
    final estimatedPick = (round - 1) * 32 + 16;
    
    // Get base value for this pick
    double baseValue;
    if (round == 1) {
      // Average of all 1st round picks
      baseValue = 1000; // Approximate average 1st round value
    } else if (round == 2) {
      baseValue = 450; // Approximate average 2nd round value
    } else if (round == 3) {
      baseValue = 250; // Approximate average 3rd round value
    } else if (round == 4) {
      baseValue = 120; // Approximate average 4th round value
    } else {
      baseValue = 50; // Approximate average late round value
    }
    
    // Apply future discount based on round
    double discountFactor;
    if (round == 1) {
      discountFactor = 0.7;
    } else if (round == 2) {
      discountFactor = 0.6;
    } else {
      discountFactor = 0.5;
    }
    
    return FuturePick(
      team: team,
      estimatedPickNumber: estimatedPick,
      value: baseValue * discountFactor,
      estimatedRound: round,
      year: year,
    );
  }

  /// Get a readable description of this future pick
  String get description {
    if (estimatedRound == 1) {
      // For 1st round picks, estimate early/mid/late
      String pickRange;
      if (estimatedPickNumber <= 10) {
        pickRange = "early";
      } else if (estimatedPickNumber <= 20) {
        pickRange = "mid";
      } else {
        pickRange = "late";
      }
      return "$year $pickRange 1st Round";
    } else {
      // For other rounds, just specify the round
      return "$year ${_getRoundText(estimatedRound)} Round";
    }
  }

  /// Convert round number to text with suffix
  String _getRoundText(int round) {
    if (round == 1) return "1st";
    if (round == 2) return "2nd";
    if (round == 3) return "3rd";
    return "${round}th";
  }
}