enum FFAIPersonalityType {
  valueHunter,
  needFiller,
  contrarian,
  stackBuilder,
  safePlayer,
  sleeperHunter,
}

class FFAIPersonality {
  final FFAIPersonalityType type;
  final String name;
  final String description;
  final Map<String, double> traits;
  
  const FFAIPersonality({
    required this.type,
    required this.name,
    required this.description,
    required this.traits,
  });

  static const Map<FFAIPersonalityType, FFAIPersonality> personalities = {
    FFAIPersonalityType.valueHunter: FFAIPersonality(
      type: FFAIPersonalityType.valueHunter,
      name: "The Value Hunter",
      description: "Always seeks best available player, ignores positional runs",
      traits: {
        'valueWeight': 0.7,           // Moderately weights player value over need
        'positionRunResistance': 0.3, // Light resistance to positional runs
        'reachTolerance': 0.4,        // Moderate tolerance for reaches
        'byeWeekConcern': 0.3,        // Low concern for bye week conflicts
        'stackingPreference': 0.2,    // Low preference for stacking
        'riskTolerance': 0.6,         // Moderate risk tolerance
        'needWeight': 0.4,            // Moderate weight on positional needs
      },
    ),
    
    FFAIPersonalityType.needFiller: FFAIPersonality(
      type: FFAIPersonalityType.needFiller,
      name: "The Need Filler",
      description: "Prioritizes roster construction, fills positions methodically",
      traits: {
        'valueWeight': 0.4,           // Moderate weight on player value
        'positionRunResistance': 0.2, // Low resistance to positional runs
        'reachTolerance': 0.7,        // High tolerance for reaches to fill needs
        'byeWeekConcern': 0.8,        // High concern for bye week management
        'stackingPreference': 0.3,    // Low stacking preference
        'riskTolerance': 0.3,         // Low risk tolerance
        'needWeight': 0.9,            // High weight on positional needs
      },
    ),
    
    FFAIPersonalityType.contrarian: FFAIPersonality(
      type: FFAIPersonalityType.contrarian,
      name: "The Contrarian",
      description: "Zigs when others zag, avoids popular picks",
      traits: {
        'valueWeight': 0.5,           // Moderate weight on player value
        'positionRunResistance': 0.3, // Light resistance to runs
        'reachTolerance': 0.6,        // Moderate tolerance for unconventional picks
        'byeWeekConcern': 0.4,        // Moderate bye week concern
        'stackingPreference': 0.4,    // Moderate stacking tendency
        'riskTolerance': 0.7,         // Moderate-high risk tolerance
        'needWeight': 0.5,            // Moderate weight on needs
      },
    ),
    
    FFAIPersonalityType.stackBuilder: FFAIPersonality(
      type: FFAIPersonalityType.stackBuilder,
      name: "The Stack Builder",
      description: "Seeks QB/WR combinations, avoids RB/WR from same team",
      traits: {
        'valueWeight': 0.6,           // Moderate-high weight on value
        'positionRunResistance': 0.5, // Moderate resistance to runs
        'reachTolerance': 0.6,        // Moderate-high reach tolerance for stacks
        'byeWeekConcern': 0.6,        // Moderate bye week concern
        'stackingPreference': 0.9,    // Very high stacking preference
        'riskTolerance': 0.7,         // High risk tolerance
        'needWeight': 0.4,            // Lower weight on basic needs
      },
    ),
    
    FFAIPersonalityType.safePlayer: FFAIPersonality(
      type: FFAIPersonalityType.safePlayer,
      name: "The Safe Player",
      description: "Conservative picks, avoids risky/injury-prone players",
      traits: {
        'valueWeight': 0.7,           // High weight on proven value
        'positionRunResistance': 0.3, // Low resistance, follows the crowd
        'reachTolerance': 0.3,        // Low reach tolerance
        'byeWeekConcern': 0.7,        // High bye week concern
        'stackingPreference': 0.2,    // Low stacking preference
        'riskTolerance': 0.2,         // Low risk tolerance
        'needWeight': 0.7,            // High weight on filling needs safely
      },
    ),
    
    FFAIPersonalityType.sleeperHunter: FFAIPersonality(
      type: FFAIPersonalityType.sleeperHunter,
      name: "The Sleeper Hunter",
      description: "Reaches for late-round breakout candidates",
      traits: {
        'valueWeight': 0.4,           // Lower weight on current value
        'positionRunResistance': 0.4, // Moderate resistance to runs
        'reachTolerance': 0.7,        // High tolerance for reaches
        'byeWeekConcern': 0.2,        // Low bye week concern
        'stackingPreference': 0.5,    // Moderate stacking preference
        'riskTolerance': 0.8,         // High risk tolerance
        'needWeight': 0.4,            // Moderate weight on needs
      },
    ),
  };

  static FFAIPersonality getPersonality(FFAIPersonalityType type) {
    return personalities[type]!;
  }

  static List<FFAIPersonality> getAllPersonalities() {
    return personalities.values.toList();
  }

  double getTrait(String traitName) {
    return traits[traitName] ?? 0.5;
  }

  bool shouldFollowPositionalRun(int runCount) {
    final resistance = getTrait('positionRunResistance');
    final threshold = 0.3 + (resistance * 0.4); // 0.3 to 0.7 threshold
    final runPressure = (runCount - 1) * 0.25; // Increases with run length
    
    // Floor: Never completely ignore runs of 4+ players
    if (runCount >= 4) return true;
    
    return runPressure > threshold;
  }

  bool shouldMakeReach(double reachAmount) {
    final tolerance = getTrait('reachTolerance');
    final maxReach = tolerance * 8; // Up to 8 spots for high tolerance (reduced from 15)
    return reachAmount <= maxReach && reachAmount <= 5; // Hard cap at 5 spots
  }

  double calculateByeWeekPenalty(int sameByeCount) {
    final concern = getTrait('byeWeekConcern');
    final penalty = sameByeCount * concern * 2.0; // Up to 2.0 penalty per player
    return penalty.clamp(0.0, 1.0); // Cap at 1.0 to prevent excessive influence
  }

  double calculateStackingBonus(bool isPositiveStack, bool isNegativeStack) {
    final preference = getTrait('stackingPreference');
    if (isPositiveStack) return (preference * 3.0).clamp(0.0, 1.0); // Cap at 1.0 bonus
    if (isNegativeStack) return -(preference * 1.5).clamp(0.0, 0.5); // Cap at -0.5 penalty
    return 0.0;
  }

  double calculateRiskPenalty(double riskFactor) {
    final tolerance = getTrait('riskTolerance');
    final penalty = (1.0 - tolerance) * riskFactor;
    return (penalty * 2.0).clamp(0.0, 1.0); // Cap at 1.0 penalty for high-risk players
  }
}