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
  // Optional roster bio
  final int? jerseyNumber;
  final String? height; // Preserve raw string like 6'1"
  final int? weight; // pounds
  final String? college;
  
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
    this.jerseyNumber,
    this.height,
    this.weight,
    this.college,
  });

  // Calculate position-adjusted value (for compatibility - uses trade value score)
  double get positionAdjustedValue => marketValue; // marketValue is now the trade value score (0-100)

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
    String group;
    switch (position) {
      case 'QB':
        group = 'QB';
        break;
      case 'RB':
      case 'FB':
        group = 'RB';
        break;
      case 'WR':
      case 'WR/PR':
        group = 'WR';
        break;
      case 'TE':
        group = 'TE';
        break;
      case 'LT':
      case 'LG':
      case 'C':
      case 'RG':
      case 'RT':
      case 'OT':
      case 'OG':
        group = 'OL';
        break;
      case 'DE':
      case 'EDGE':
      case 'OLB':
        group = 'EDGE';
        break;
      case 'DT':
      case 'NT':
        group = 'DL';
        break;
      case 'MLB':
      case 'ILB':
        group = 'LB';
        break;
      case 'CB':
        group = 'CB';
        break;
      case 'S':
      case 'SS':
      case 'FS':
        group = 'S';
        break;
      case 'K':
        group = 'K';
        break;
      case 'P':
        group = 'P';
        break;
      default:
        group = 'OTHER';
        break;
    }
    
    // DEBUG: Print position group mapping for Micah Parsons
    if (name.contains('Parsons')) {
      print('🔍 DEBUG: Position group mapping for $name');
      print('  - Position: $position -> Group: $group');
    }
    
    return group;
  }

  // Check if player is a premium position
  bool get isPremiumPosition {
    const premiumPositions = {'QB', 'EDGE', 'OL', 'CB', 'WR'};
    return premiumPositions.contains(positionGroup);
  }

  @override
  String toString() => '$name ($position) - $team - Age $age - \$${marketValue.toStringAsFixed(1)}M';
}