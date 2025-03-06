// lib/models/future_pick.dart
/// Represents a future draft pick (for next year)
class FuturePick {
  final String team;
  final int estimatedPickNumber;
  final double value;
  final int estimatedRound;

  const FuturePick({
    required this.team,
    required this.estimatedPickNumber,
    required this.value,
    required this.estimatedRound,
  });

  /// Create a future pick with estimated position based on team strength
  factory FuturePick.estimate(String team, int teamStrength) {
    // Estimate pick position based on team strength (1-32)
    // 1 = strongest team, 32 = weakest team
    final estimatedPick = teamStrength + ((32 - teamStrength) ~/ 3);
    final round = (estimatedPick / 32).ceil();
    
    // Value is typically discounted for future picks (60% of current value)
    const discountFactor = 0.6;
    double baseValue = 0;
    
    // Rough estimation of pick value
    if (estimatedPick <= 32) {
      baseValue = 3000 * pow(0.9, estimatedPick - 1);
    } else if (estimatedPick <= 64) {
      baseValue = 580 * pow(0.98, estimatedPick - 33);
    } else {
      baseValue = 300 * pow(0.95, estimatedPick - 65);
    }
    
    return FuturePick(
      team: team,
      estimatedPickNumber: estimatedPick,
      value: baseValue * discountFactor,
      estimatedRound: round,
    );
  }

  /// Helper to calculate powers for value estimation
  static double pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }

  /// Get a readable description of this future pick
  String get description {
    return "2026 ${_getRoundText(estimatedRound)} Round Pick (est. #$estimatedPickNumber)";
  }

  /// Convert round number to text with suffix
  String _getRoundText(int round) {
    if (round == 1) return "1st";
    if (round == 2) return "2nd";
    if (round == 3) return "3rd";
    return "${round}th";
  }
}