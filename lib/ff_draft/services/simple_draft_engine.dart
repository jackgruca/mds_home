import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_ai_personality.dart';
import 'dart:math';

/// Enhanced draft engine with sophisticated roster construction logic
/// 
/// Philosophy:
/// 1. Player talent is important (60% of decision)
/// 2. Starter slots have exponentially higher value than bench slots (30% of decision)
/// 3. Opportunity cost and positional urgency matter (10% of decision)
/// 
/// Standard PPR roster: 1 QB, 2 RB, 2 WR, 1 TE, 1 FLEX, 1 K, 1 DST
/// This means effective needs: 1 QB, 3 RB, 3 WR, 1 TE, 1 K, 1 DST
class SimpleDraftEngine {
  static final Random _random = Random();
  
  // Standard PPR roster requirements
  static const Map<String, int> _starterRequirements = {
    'QB': 1,
    'RB': 2, // 2 RB slots + FLEX eligibility = effective need of 3
    'WR': 2, // 2 WR slots + FLEX eligibility = effective need of 3  
    'TE': 1,
    'K': 1,
    'DST': 1,
  };
  
  // How much each position slot is worth (starter -> bench value degradation)
  static const Map<String, List<double>> _positionSlotValues = {
    'QB': [100, 5, 1], // 1st QB super valuable, 2nd QB almost worthless, 3rd useless
    'RB': [100, 85, 70, 25, 10], // 1st-3rd RBs are starter quality, 4th+ are bench
    'WR': [100, 85, 70, 25, 10], // Same as RB due to FLEX
    'TE': [100, 5, 1], // 1st TE valuable, 2nd TE almost worthless, 3rd useless
    'K': [100], // Only need 1
    'DST': [100], // Only need 1
  };

  /// The only method you need - picks a player for a team
  static FFPlayer pickPlayer({
    required FFTeam team,
    required List<FFPlayer> availablePlayers,
    required int currentRound,
    required int pickNumber,
    FFAIPersonality? personality,
  }) {
    
    // Step 1: Filter out obviously bad picks (disasters)
    final eligiblePlayers = availablePlayers.where((player) {
      return isEligible(player, team, currentRound);
    }).toList();
    
    if (eligiblePlayers.isEmpty) {
      return availablePlayers.first; // Emergency fallback
    }
    
    // Step 2: Score each player with sophisticated roster construction logic
    final playerScores = <FFPlayer, double>{};
    
    for (final player in eligiblePlayers.take(25)) { // Look at top 25 available
      final score = calculateEnhancedScore(player, team, currentRound, personality);
      playerScores[player] = score;
    }
    
    // Step 3: Add appropriate randomness based on personality
    final randomnessFactor = _getRandomness(personality);
    final finalScores = <FFPlayer, double>{};
    
    for (final entry in playerScores.entries) {
      final randomBonus = (_random.nextDouble() - 0.5) * randomnessFactor;
      finalScores[entry.key] = entry.value + randomBonus;
    }
    
    // Step 4: Pick the highest scorer
    final bestPlayer = finalScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return bestPlayer;
  }
  
  /// Enhanced eligibility check - prevent disasters but allow roster flexibility
  static bool isEligible(FFPlayer player, FFTeam team, int round) {
    final position = player.position;
    final currentCount = team.getPositionCount(position);
    
    // Disaster prevention - hard blocks
    if (position == 'K' && round < 12) return false; // K not before round 12
    if (position == 'DST' && round < 11) return false; // DST not before round 11
    
    // STRICT roster construction rules for premium single-need positions
    if (position == 'QB') {
      if (currentCount >= 1 && round <= 10) return false; // NO 2nd QB before round 11
      if (currentCount >= 3) return false; // Max 3 QBs total
    }
    
    if (position == 'TE') {
      if (currentCount >= 1 && round <= 8) return false; // NO 2nd TE before round 9  
      if (currentCount >= 3) return false; // Max 3 TEs total
    }
    
    if (position == 'K' && currentCount >= 1) return false; // Max 1 K
    if (position == 'DST' && currentCount >= 1) return false; // Max 1 DST
    
    // Late round urgency - must fill empty positions
    if (round >= 13) {
      final rosterGaps = getRosterGaps(team);
      if (rosterGaps.isNotEmpty && !rosterGaps.contains(position)) {
        return false; // Must fill gaps in late rounds
      }
    }
    
    return true;
  }
  
  /// Sophisticated scoring that considers roster construction strategy
  static double calculateEnhancedScore(
    FFPlayer player, 
    FFTeam team, 
    int round, 
    FFAIPersonality? personality
  ) {
    final rank = player.consensusRank ?? 999;
    final position = player.position;
    final currentCount = team.getPositionCount(position);
    
    // 1. Base talent score (60% of decision) - diminishing returns on rank
    double talentScore = _calculateTalentScore(rank);
    
    // 2. Positional value score (30% of decision) - starter vs bench
    double positionValue = _calculatePositionValue(position, currentCount, round);
    
    // 3. Opportunity cost & urgency (10% of decision)
    double opportunityCost = _calculateOpportunityCost(player, team, round);
    
    // 4. Personality adjustment (small modifier)
    double personalityBonus = _getPersonalityBonus(player, team, round, personality);
    
    double finalScore = talentScore + positionValue + opportunityCost + personalityBonus;
    
    return finalScore;
  }
  
  /// Calculate talent score with diminishing returns
  static double _calculateTalentScore(int rank) {
    // Elite players (1-20): 350-300 points
    if (rank <= 20) return 350 - (rank * 2.5);
    
    // Good players (21-60): 300-200 points  
    if (rank <= 60) return 300 - ((rank - 20) * 2.5);
    
    // Decent players (61-120): 200-100 points
    if (rank <= 120) return 200 - ((rank - 60) * 1.67);
    
    // Late round fliers (121+): 100-0 points
    return max(0, 100 - ((rank - 120) * 0.5));
  }
  
  /// Calculate position value based on roster construction needs
  static double _calculatePositionValue(String position, int currentCount, int round) {
    final slotValues = _positionSlotValues[position] ?? [100];
    
    // If we already have enough at this position, value drops dramatically
    if (currentCount >= slotValues.length) {
      return -50; // Negative value for unnecessary depth
    }
    
    // Get the value of the next slot for this position
    double baseSlotValue = slotValues[currentCount];
    
    // Apply round-based urgency multipliers
    double urgencyMultiplier = _getUrgencyMultiplier(position, currentCount, round);
    
    return baseSlotValue * urgencyMultiplier;
  }
  
  /// Calculate urgency multiplier based on round and roster gaps
  static double _getUrgencyMultiplier(String position, int currentCount, int round) {
    final starterRequirement = _starterRequirements[position] ?? 1;
    
    // MASSIVE penalties for redundant premium positions
    if (position == 'QB' && currentCount >= 1) {
      if (round <= 10) return 0.05; // 95% penalty - almost worthless
      return 0.3; // Even late, backup QB has little value
    }
    
    if (position == 'TE' && currentCount >= 1) {
      if (round <= 8) return 0.05; // 95% penalty - almost worthless
      return 0.4; // Even late, backup TE has little value
    }
    
    // Desperate need in late rounds
    if (round >= 10 && currentCount == 0) {
      if (position == 'QB' || position == 'TE') return 3.0; // Critical positions
      return 2.0; // Important positions
    }
    
    // High urgency for missing starters
    if (currentCount < starterRequirement) {
      if (round >= 8) return 1.8; // Getting late, need starters
      if (round >= 5) return 1.3; // Moderate urgency
      return 1.1; // Slight preference early
    }
    
    // Flex positions (3rd RB/WR) have moderate value
    if ((position == 'RB' || position == 'WR') && currentCount == 2) {
      if (round >= 7) return 1.2; // Good time to grab FLEX
      return 0.9; // Early rounds, can wait
    }
    
    // Bench depth has diminishing value
    if (round <= 6) return 0.3; // Early rounds - don't hoard bench
    return 0.7; // Later rounds - depth is okay
  }
  
  /// Calculate opportunity cost of taking this player vs. addressing other needs
  static double _calculateOpportunityCost(FFPlayer player, FFTeam team, int round) {
    final rosterGaps = getRosterGaps(team);
    final position = player.position;
    final currentCount = team.getPositionCount(position);
    final starterRequirement = _starterRequirements[position] ?? 1;
    
    // Bonus for filling roster gaps
    if (rosterGaps.contains(position)) {
      return 50 + (rosterGaps.length * 15); // Bigger bonus for gap filling
    }
    
    // MASSIVE penalties for ignoring gaps to take redundant positions
    if (rosterGaps.isNotEmpty && !rosterGaps.contains(position)) {
      // If taking unnecessary depth while gaps exist
      if (currentCount >= starterRequirement) {
        double basePenalty = -40; // Base penalty
        double gapPenalty = rosterGaps.length * 20; // More penalty per gap
        
        // Extra harsh penalties for premium positions (QB/TE)
        if ((position == 'QB' || position == 'TE') && currentCount >= 1) {
          basePenalty = -100; // Massive penalty for 2nd QB/TE while gaps exist
        }
        
        return basePenalty - gapPenalty;
      }
    }
    
    // Small penalty for taking 2nd QB/TE even without gaps (they're just not valuable)
    if (position == 'QB' && currentCount >= 1) return -30;
    if (position == 'TE' && currentCount >= 1) return -25;
    
    return 0;
  }
  
  /// Identify critical roster gaps that need to be filled
  static List<String> getRosterGaps(FFTeam team) {
    final gaps = <String>[];
    
    for (final entry in _starterRequirements.entries) {
      final position = entry.key;
      final required = entry.value;
      final current = team.getPositionCount(position);
      
      if (current < required) {
        // Add position to gaps list multiple times based on how many needed
        for (int i = current; i < required; i++) {
          gaps.add(position);
        }
      }
    }
    
    return gaps;
  }
  
  /// Enhanced personality bonuses that work with new scoring system
  static double _getPersonalityBonus(
    FFPlayer player, 
    FFTeam team, 
    int round, 
    FFAIPersonality? personality
  ) {
    if (personality == null) return 0;
    
    final rank = player.consensusRank ?? 999;
    final currentCount = team.getPositionCount(player.position);
    final expectedPick = round * 12;
    
    switch (personality.type) {
      case FFAIPersonalityType.valueHunter:
        // Loves players falling past their rank
        if (rank < expectedPick - 15) return 25;
        if (rank < expectedPick - 8) return 15;
        break;
        
      case FFAIPersonalityType.needFiller:
        // Extra bonus for addressing roster gaps
        final gaps = getRosterGaps(team);
        if (gaps.contains(player.position)) return 20;
        break;
        
      case FFAIPersonalityType.safePlayer:
        // Strongly prefers highly ranked, safe picks
        if (rank <= 30) return 15;
        if (rank <= 60) return 8;
        break;
        
      case FFAIPersonalityType.sleeperHunter:
        // Bonus for later round upside picks
        if (round >= 9 && rank >= 100) return 18;
        if (round >= 6 && rank >= 80) return 10;
        break;
        
      case FFAIPersonalityType.contrarian:
        // Random bonus/penalty to create unpredictability
        return (_random.nextDouble() - 0.5) * 20;
        
      default:
        return 0;
    }
    
    return 0;
  }
  
  /// Personality-based randomness levels
  static double _getRandomness(FFAIPersonality? personality) {
    if (personality == null) return 8.0;
    
    switch (personality.type) {
      case FFAIPersonalityType.contrarian:
        return 25.0; // Very unpredictable
      case FFAIPersonalityType.sleeperHunter:
        return 15.0; // Pretty unpredictable
      case FFAIPersonalityType.valueHunter:
        return 12.0; // Moderately unpredictable
      case FFAIPersonalityType.needFiller:
        return 8.0;  // Fairly predictable
      case FFAIPersonalityType.safePlayer:
        return 5.0;  // Very predictable
      default:
        return 8.0;
    }
  }
  
  /// Generate detailed analysis for UI debugging
  static Map<String, dynamic> analyzePickSimple({
    required FFPlayer player,
    required FFTeam team,
    required int round,
    FFAIPersonality? personality,
  }) {
    final rank = player.consensusRank ?? 999;
    final position = player.position;
    final currentCount = team.getPositionCount(position);
    final gaps = getRosterGaps(team);
    
    final talentScore = _calculateTalentScore(rank);
    final positionValue = _calculatePositionValue(position, currentCount, round);
    final opportunityCost = _calculateOpportunityCost(player, team, round);
    final personalityBonus = _getPersonalityBonus(player, team, round, personality);
    
    String reasoning;
    String pickType;
    
    if (gaps.contains(position) && gaps.length >= 3) {
      reasoning = 'CRITICAL: Filling major roster gap at $position (${gaps.length} gaps remaining)';
      pickType = 'Gap Fill';
    } else if (currentCount == 0 && round >= 8) {
      reasoning = 'URGENT: First $position with draft getting late';
      pickType = 'Urgent Need';
    } else if (positionValue >= 80 && talentScore >= 250) {
      reasoning = 'PREMIUM: Elite $position for starting lineup';
      pickType = 'Premium Pick';
    } else if (gaps.contains(position)) {
      reasoning = 'Addressing $position need in roster construction';
      pickType = 'Need Pick';
    } else if (talentScore >= 300) {
      reasoning = 'TALENT: ${player.name} too good to pass up (rank #$rank)';
      pickType = 'Best Available';
    } else if (opportunityCost < -15) {
      reasoning = 'DEPTH: Adding $position depth while gaps exist elsewhere';
      pickType = 'Questionable Depth';
    } else {
      reasoning = 'Solid $position depth for later rounds';
      pickType = 'Depth Pick';
    }
    
    return {
      'reasoning': reasoning,
      'pickType': pickType,
      'playerRank': rank,
      'talentScore': talentScore.round(),
      'positionValue': positionValue.round(),
      'opportunityCost': opportunityCost.round(),
      'personalityBonus': personalityBonus.round(),
      'rosterGaps': gaps,
      'positionCount': currentCount,
    };
  }

  // Backward compatibility - keep old method name
  static double calculateSimpleScore(
    FFPlayer player, 
    FFTeam team, 
    int round, 
    FFAIPersonality? personality
  ) {
    return calculateEnhancedScore(player, team, round, personality);
  }
} 