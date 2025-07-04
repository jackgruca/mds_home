import '../models/ff_team.dart';

/// Traditional fantasy football roster construction rules and logic
class FFRosterConstructionRules {
  // Starting lineup requirements - MUST fill these first
  static const Map<String, int> startingLineupRequirements = {
    'QB': 1,
    'RB': 2, 
    'WR': 2,
    'TE': 1,
    'FLEX': 1, // RB/WR/TE
    'K': 1,
    'DEF': 1,
  };

  // Maximum reasonable roster counts
  static const Map<String, int> absoluteMaxByPosition = {
    'QB': 2, // Never more than 2 QBs
    'RB': 6, // Max 6 RBs total
    'WR': 6, // Max 6 WRs total  
    'TE': 2, // Never more than 2 TEs
    'K': 1,  // Only 1 kicker
    'DEF': 1, // Only 1 defense
  };

  // Ideal roster construction by round ranges
  static const Map<String, Map<String, int>> idealRosterByRound = {
    'early': { // Rounds 1-6
      'RB': 3,
      'WR': 3, 
      'QB': 1,
      'TE': 1,
    },
    'mid': { // Rounds 7-12
      'RB': 4,
      'WR': 5,
      'QB': 1,
      'TE': 1,
      'K': 1,
      'DEF': 1,
    },
    'late': { // Rounds 13+
      'QB': 2,
      'TE': 2,
    }
  };

  // Anti-hoarding thresholds - discourage taking too many of one position
  static const Map<String, int> hoardingThresholds = {
    'QB': 1, // Discourage 2nd QB until late
    'TE': 1, // Discourage 2nd TE until late  
    'K': 1,  // Never take 2nd K
    'DEF': 1, // Never take 2nd DEF
  };

  // Check if team needs to fill starting lineup positions first
  static bool hasUnfilledStarterNeeds(FFTeam team) {
    // Check core starting positions
    if (team.getPositionCount('QB') == 0) return true;
    if (team.getPositionCount('RB') < 2) return true;
    if (team.getPositionCount('WR') < 2) return true;
    if (team.getPositionCount('TE') == 0) return true;
    
    // Check if FLEX need is filled (need at least 3 RB+WR+TE combined for flex)
    final flexEligible = team.getPositionCount('RB') + 
                        team.getPositionCount('WR') + 
                        team.getPositionCount('TE');
    if (flexEligible < 5) return true; // 2 RB + 2 WR + 1 TE = 5 minimum
    
    return false;
  }

  // Get the most critical position need for this team
  static String? getMostCriticalNeed(FFTeam team, int currentRound) {
    // Always prioritize filling starting lineup first
    if (team.getPositionCount('QB') == 0) return 'QB';
    if (team.getPositionCount('RB') == 0) return 'RB'; 
    if (team.getPositionCount('WR') == 0) return 'WR';
    if (team.getPositionCount('TE') == 0) return 'TE';
    
    // Then fill out core positions
    if (team.getPositionCount('RB') == 1) return 'RB';
    if (team.getPositionCount('WR') == 1) return 'WR';
    
    // Mid-draft needs (rounds 7-12)
    if (currentRound >= 7 && currentRound <= 12) {
      if (team.getPositionCount('K') == 0 && currentRound >= 10) return 'K';
      if (team.getPositionCount('DEF') == 0 && currentRound >= 11) return 'DEF';
    }
    
    return null; // No critical needs
  }

  // Check if team should avoid this position completely
  static bool shouldAvoidPosition(FFTeam team, String position, int currentRound) {
    final currentCount = team.getPositionCount(position);
    final absoluteMax = absoluteMaxByPosition[position] ?? 6;
    
    // Hard stop only at absolute maximum
    if (currentCount >= absoluteMax) return true;
    
    // K/DEF restrictions remain reasonable
    if ((position == 'K' || position == 'DEF') && currentRound < 12) return true;
    
    // No other hard blocks - let value drive decisions
    return false;
  }

  // Check if taking this position would be hoarding
  static bool isHoarding(FFTeam team, String position, int currentRound) {
    final currentCount = team.getPositionCount(position);
    
    // Only prevent excessive hoarding, not reasonable depth
    if (position == 'QB' && currentCount >= 2) return true;
    if (position == 'TE' && currentCount >= 2) return true;
    if ((position == 'K' || position == 'DEF') && currentCount >= 1) return true;
    
    return false;
  }

  // Get position priority multiplier based on VALUE-DRIVEN fantasy football strategy
  static double getPositionPriorityMultiplier(FFTeam team, String position, int currentRound) {
    final currentCount = team.getPositionCount(position);
    
    // Base multiplier - all positions start equal, then adjust based on positional value and needs
    double multiplier = 1.0;
    
    switch (position) {
      case 'RB':
      case 'WR':
        // Natural preference for skill positions due to their importance and scarcity
        if (currentCount < 2) {
          multiplier = 1.3; // Need starters - good bonus
        } else if (currentCount < 4) {
          multiplier = 1.1; // Good depth value
        } else {
          multiplier = 0.8; // Getting crowded, but not blocked
        }
        break;
        
      case 'QB':
      case 'TE':
        // Natural disincentive for low-volume positions, but don't block elite players
        if (currentCount == 0) {
          multiplier = 1.0; // Need one - neutral value
        } else if (currentCount == 1) {
          multiplier = 0.4; // Depth less valuable due to positional scarcity
        } else {
          multiplier = 0.1; // Really don't need 3rd, but don't hard block
        }
        break;
        
      case 'K':
      case 'DEF':
        // Late draft priorities - these restrictions make sense
        if (currentCount == 0 && currentRound >= 12) {
          multiplier = 1.0; // Appropriate time to draft
        } else if (currentRound < 12) {
          multiplier = 0.1; // Too early - heavy penalty but not hard block
        } else {
          multiplier = 0.0; // Don't need multiples
        }
        break;
    }
    
    return multiplier;
  }

  // Check if this pick makes roster construction sense
  static bool isReasonableRosterMove(FFTeam team, String position, int currentRound) {
    // Never violate absolute maximums
    if (team.getPositionCount(position) >= (absoluteMaxByPosition[position] ?? 6)) {
      return false;
    }
    
    // Always allow filling critical starter needs
    if (getMostCriticalNeed(team, currentRound) == position) {
      return true;
    }
    
    // Don't allow hoarding
    if (isHoarding(team, position, currentRound)) {
      return false;
    }
    
    // In early rounds (1-6), focus on RB/WR/QB/TE
    if (currentRound <= 6) {
      return ['RB', 'WR', 'QB', 'TE'].contains(position);
    }
    
    // In mid rounds (7-12), allow K/DEF but discourage excessive depth
    if (currentRound <= 12) {
      if (position == 'K' && currentRound < 10) return false;
      if (position == 'DEF' && currentRound < 11) return false;
      return true;
    }
    
    // Late rounds (13+) - only depth or 2nd QB/TE
    return true;
  }

  // Get roster construction advice for debugging
  static Map<String, dynamic> getRosterAnalysis(FFTeam team, int currentRound) {
    return {
      'hasUnfilledStarters': hasUnfilledStarterNeeds(team),
      'criticalNeed': getMostCriticalNeed(team, currentRound),
      'positionCounts': {
        'QB': team.getPositionCount('QB'),
        'RB': team.getPositionCount('RB'),
        'WR': team.getPositionCount('WR'),
        'TE': team.getPositionCount('TE'),
        'K': team.getPositionCount('K'),
        'DEF': team.getPositionCount('DEF'),
      },
      'recommendations': _getRecommendations(team, currentRound),
    };
  }

  static List<String> _getRecommendations(FFTeam team, int currentRound) {
    final recommendations = <String>[];
    
    if (hasUnfilledStarterNeeds(team)) {
      recommendations.add('PRIORITY: Fill starting lineup first');
    }
    
    final criticalNeed = getMostCriticalNeed(team, currentRound);
    if (criticalNeed != null) {
      recommendations.add('CRITICAL: Need $criticalNeed');
    }
    
    // Position-specific advice
    if (team.getPositionCount('QB') == 0) {
      recommendations.add('Must draft QB immediately');
    } else if (team.getPositionCount('QB') >= 2) {
      recommendations.add('Too many QBs - avoid position');
    }
    
    if (team.getPositionCount('TE') >= 2) {
      recommendations.add('Too many TEs - avoid position');
    }
    
    return recommendations;
  }
}