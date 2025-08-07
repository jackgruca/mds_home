// lib/models/nfl_trade/nfl_player.dart

class NFLPlayer {
  final String playerId;
  final String name;
  final String position;
  final String team;
  final int age;
  final int experience; // years in NFL
  final double marketValue; // in millions
  final String contractStatus; // 'rookie', 'extension', 'franchise', 'free agent'
  final int contractYearsRemaining;
  final double annualSalary; // in millions
  final String? imageUrl;
  
  // Performance metrics (0-100 scale)
  final double overallRating;
  final double positionRank; // 1-100 percentile at position
  final double ageAdjustedValue; // market value adjusted for age curve
  
  // Position-specific importance weights
  final double positionImportance; // QB=1.0, EDGE=0.9, OT=0.85, etc.
  
  // Injury/availability concerns
  final double durabilityScore; // 0-100, based on games played
  final bool hasInjuryConcerns;

  const NFLPlayer({
    required this.playerId,
    required this.name,
    required this.position,
    required this.team,
    required this.age,
    required this.experience,
    required this.marketValue,
    required this.contractStatus,
    required this.contractYearsRemaining,
    required this.annualSalary,
    required this.overallRating,
    required this.positionRank,
    required this.ageAdjustedValue,
    required this.positionImportance,
    required this.durabilityScore,
    this.hasInjuryConcerns = false,
    this.imageUrl,
  });

  // Calculate position-adjusted value
  double get positionAdjustedValue => ageAdjustedValue * positionImportance;

  // Calculate contract efficiency (value per dollar)
  double get contractEfficiency => 
      annualSalary > 0 ? (overallRating / (annualSalary * 10)) : 0;

  // Get age tier for trade logic
  String get ageTier {
    if (age <= 25) return 'young';
    if (age <= 28) return 'prime';
    if (age <= 31) return 'veteran';
    return 'aging';
  }

  // Get position group for trade analysis
  String get positionGroup {
    switch (position) {
      case 'QB':
        return 'QB';
      case 'RB':
      case 'FB':
        return 'RB';
      case 'WR':
      case 'WR/PR':
        return 'WR';
      case 'TE':
        return 'TE';
      case 'LT':
      case 'LG':
      case 'C':
      case 'RG':
      case 'RT':
      case 'OT':
      case 'OG':
        return 'OL';
      case 'DE':
      case 'EDGE':
      case 'OLB':
        return 'EDGE';
      case 'DT':
      case 'NT':
        return 'DL';
      case 'MLB':
      case 'ILB':
        return 'LB';
      case 'CB':
        return 'CB';
      case 'S':
      case 'SS':
      case 'FS':
        return 'S';
      case 'K':
        return 'K';
      case 'P':
        return 'P';
      default:
        return 'OTHER';
    }
  }

  // Check if player is a premium position
  bool get isPremiumPosition {
    const premiumPositions = {'QB', 'EDGE', 'OL', 'CB', 'WR'};
    return premiumPositions.contains(positionGroup);
  }

  @override
  String toString() => '$name ($position) - $team - Age $age - \$${marketValue.toStringAsFixed(1)}M';
}