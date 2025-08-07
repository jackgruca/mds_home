// lib/models/nfl_trade/nfl_team_info.dart

class NFLTeamInfo {
  final String teamName;
  final String abbreviation;
  final String? logoUrl;
  
  // Financial information
  final double availableCapSpace; // in millions
  final double totalCapSpace; // in millions
  final double projectedCapSpace2025; // future year projection
  
  // Team building philosophy
  final TeamPhilosophy philosophy;
  
  // Current competitive status
  final TeamStatus status;
  
  // Position needs (weighted by importance)
  final Map<String, double> positionNeeds; // position -> need level (0-1)
  
  // Draft capital available
  final List<int> availableDraftPicks; // pick numbers they own
  final int futureFirstRounders; // number of future 1st round picks
  
  // Trading tendencies
  final double tradeAggressiveness; // 0-1, how likely to make trades
  final double valueSeeker; // 0-1, how much they care about fair value
  final bool willingToOverpay; // for key positions

  const NFLTeamInfo({
    required this.teamName,
    required this.abbreviation,
    required this.availableCapSpace,
    required this.totalCapSpace,
    required this.projectedCapSpace2025,
    required this.philosophy,
    required this.status,
    required this.positionNeeds,
    required this.availableDraftPicks,
    required this.futureFirstRounders,
    this.logoUrl,
    this.tradeAggressiveness = 0.5,
    this.valueSeeker = 0.7,
    this.willingToOverpay = false,
  });

  // Calculate cap space utilization percentage
  double get capUtilization => (totalCapSpace - availableCapSpace) / totalCapSpace;
  
  // Check if team has significant cap space
  bool get hasCapSpace => availableCapSpace > 20.0; // $20M+ available
  
  // Check if team is in cap hell
  bool get isCapStrapped => availableCapSpace < 5.0; // Less than $5M
  
  // Get top 3 position needs
  List<String> get topPositionNeeds {
    var sortedNeeds = positionNeeds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedNeeds.take(3).map((e) => e.key).toList();
  }
  
  // Calculate need level for specific position (0-1)
  double getNeedLevel(String position) => positionNeeds[position] ?? 0.0;
  
  // Check if position is a significant need
  bool hasSignificantNeed(String position) => getNeedLevel(position) >= 0.7;
  
  // Get draft capital strength
  DraftCapitalStrength get draftCapitalStrength {
    int earlyPicks = availableDraftPicks.where((pick) => pick <= 64).length;
    
    if (futureFirstRounders >= 2 || earlyPicks >= 3) return DraftCapitalStrength.strong;
    if (futureFirstRounders >= 1 || earlyPicks >= 2) return DraftCapitalStrength.average;
    return DraftCapitalStrength.weak;
  }
  
  // Calculate trade likelihood for a specific player
  double calculateTradeLikelihood(String position, double playerValue) {
    double baseLikelihood = tradeAggressiveness;
    
    // Increase likelihood for position of need
    double needBonus = getNeedLevel(position) * 0.3;
    
    // Adjust for team status
    double statusAdjustment = switch (status) {
      TeamStatus.rebuilding => 0.2, // more likely to trade for future
      TeamStatus.contending => willWillingness(playerValue), // depends on player value
      TeamStatus.winNow => 0.3, // aggressive for missing pieces
      TeamStatus.competitive => 0.0, // neutral
    };
    
    return (baseLikelihood + needBonus + statusAdjustment).clamp(0.0, 1.0);
  }
  
  // Calculate willingness to pay premium based on team status and player value
  double willWillingness(double playerValue) {
    bool isHighValuePlayer = playerValue > 30.0; // $30M+ value
    return switch (status) {
      TeamStatus.winNow => isHighValuePlayer ? 0.4 : 0.1,
      TeamStatus.contending => isHighValuePlayer ? 0.2 : 0.0,
      _ => 0.0,
    };
  }
  
  @override
  String toString() => '$teamName ($abbreviation) - Cap: \$${availableCapSpace.toStringAsFixed(1)}M';
}

enum TeamPhilosophy {
  buildThroughDraft, // prefer draft picks and young players
  winNow, // prefer proven veterans
  balanced, // mix of both approaches
  analytics, // strictly value-based decisions
  aggressive, // willing to overpay for talent
}

enum TeamStatus {
  rebuilding, // 3+ years from contention
  competitive, // 1-2 years from contention
  contending, // playoff contender
  winNow, // super bowl window is open
}

enum DraftCapitalStrength {
  weak,
  average,
  strong,
}