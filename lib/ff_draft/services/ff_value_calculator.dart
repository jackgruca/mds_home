import 'dart:math';
import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_ai_personality.dart';
import 'ff_positional_run_detector.dart';

class PlayerValue {
  final FFPlayer player;
  final double baseValue;
  final double positionalValue;
  final double needValue;
  final double opportunityCostValue;
  final double personalityValue;
  final double totalValue;
  final Map<String, double> valueBreakdown;

  const PlayerValue({
    required this.player,
    required this.baseValue,
    required this.positionalValue,
    required this.needValue,
    required this.opportunityCostValue,
    required this.personalityValue,
    required this.totalValue,
    required this.valueBreakdown,
  });

  double getValueComponent(String component) {
    return valueBreakdown[component] ?? 0.0;
  }

  bool isValuePick(int currentPick) {
    final expectedPick = player.consensusRank ?? 999;
    return expectedPick > currentPick + 5;
  }

  bool isReach(int currentPick) {
    final expectedPick = player.consensusRank ?? 999;
    return expectedPick < currentPick - 10;
  }
}

class FFValueCalculator {
  final FFPositionalRunDetector _runDetector = FFPositionalRunDetector();
  
  // Positional value multipliers based on roster slot importance
  static const Map<String, List<double>> _positionalValueCurves = {
    'QB': [1.0, 0.15, 0.02],  // More extreme dropoff - 2nd QB much less valuable
    'RB': [1.0, 0.85, 0.65, 0.40, 0.20],
    'WR': [1.0, 0.90, 0.70, 0.50, 0.30, 0.20],
    'TE': [1.0, 0.20, 0.05],  // More extreme dropoff - 2nd TE much less valuable
    'K': [1.0],
    'DST': [1.0],
  };

  PlayerValue calculatePlayerValue(
    FFPlayer player,
    FFTeam team,
    List<FFPlayer> availablePlayers,
    List<FFDraftPick> draftPicks,
    FFAIPersonality personality,
    int currentPick,
  ) {
    final valueBreakdown = <String, double>{};
    
    // 1. Base player value (from consensus ranking)
    final baseValue = _calculateBaseValue(player);
    valueBreakdown['base'] = baseValue;

    // 2. Positional value (diminishing returns for each position)
    final positionalValue = _calculatePositionalValue(player, team);
    valueBreakdown['positional'] = positionalValue;

    // 3. Need value (roster construction needs)
    final needValue = _calculateNeedValue(player, team);
    valueBreakdown['need'] = needValue;

    // 4. Opportunity cost (compared to best alternatives)
    final opportunityCostValue = _calculateOpportunityCost(
      player, team, availablePlayers, currentPick
    );
    valueBreakdown['opportunity_cost'] = opportunityCostValue;

    // 5. Personality adjustments (subtle modifications)
    final personalityValue = _calculatePersonalityValue(
      player, team, draftPicks, personality, currentPick
    );
    valueBreakdown['personality'] = personalityValue;

    // 6. Additional context factors
    final scarcityValue = _calculateScarcityValue(player, availablePlayers, currentPick);
    valueBreakdown['scarcity'] = scarcityValue;
    
    final runValue = _calculateRunValue(player, draftPicks);
    valueBreakdown['run'] = runValue;

    // Calculate total value with proper weighting
    final totalValue = (baseValue * positionalValue) + needValue + 
                      opportunityCostValue + personalityValue + 
                      scarcityValue + runValue;

    return PlayerValue(
      player: player,
      baseValue: baseValue,
      positionalValue: positionalValue,
      needValue: needValue,
      opportunityCostValue: opportunityCostValue,
      personalityValue: personalityValue,
      totalValue: totalValue,
      valueBreakdown: valueBreakdown,
    );
  }

  List<PlayerValue> rankPlayersByValue(
    List<FFPlayer> players,
    FFTeam team,
    List<FFPlayer> availablePlayers,
    List<FFDraftPick> draftPicks,
    FFAIPersonality personality,
    int currentPick,
  ) {
    final playerValues = players.map((player) =>
      calculatePlayerValue(
        player,
        team,
        availablePlayers,
        draftPicks,
        personality,
        currentPick,
      )
    ).toList();

    playerValues.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return playerValues;
  }

  double _calculateBaseValue(FFPlayer player) {
    final rank = player.consensusRank ?? player.rank ?? 999;
    
    // Exponential decay for player value based on consensus ranking
    if (rank <= 12) {
      return 300 - (rank * 15); // 285-120 range for elite players
    } else if (rank <= 36) {
      return 120 - ((rank - 12) * 3); // 120-48 range for good players
    } else if (rank <= 100) {
      return 48 - ((rank - 36) * 0.5); // 48-16 range for depth
    } else if (rank <= 200) {
      return 16 - ((rank - 100) * 0.1); // 16-6 range for late picks
    } else {
      return max(0, 6 - ((rank - 200) * 0.03)); // 6-0 range for waiver wire
    }
  }

  double _calculatePositionalValue(FFPlayer player, FFTeam team) {
    final position = player.position;
    final positionCount = team.getPositionCount(position);
    final valueCurve = _positionalValueCurves[position] ?? [1.0, 0.5, 0.25];
    
    // Get the positional multiplier based on how many we already have
    final multiplierIndex = min(positionCount, valueCurve.length - 1);
    final positionalMultiplier = valueCurve[multiplierIndex];
    
    return positionalMultiplier;
  }

  double _calculateNeedValue(FFPlayer player, FFTeam team) {
    final position = player.position;
    final positionCount = team.getPositionCount(position);
    
    // Define critical needs
    final criticalNeeds = {
      'QB': positionCount == 0,
      'RB': positionCount < 2,
      'WR': positionCount < 2, 
      'TE': positionCount == 0,
      'K': positionCount == 0,
      'DEF': positionCount == 0,
    };
    
    // Define moderate needs  
    final moderateNeeds = {
      'QB': positionCount == 1, // backup QB
      'RB': positionCount >= 2 && positionCount < 4, // depth
      'WR': positionCount >= 2 && positionCount < 4, // depth
      'TE': positionCount == 1, // backup TE
      'K': false, // never need multiple
      'DEF': false, // never need multiple
    };

    if (criticalNeeds[position] == true) {
      return 50.0; // High need bonus
    } else if (moderateNeeds[position] == true) {
      return 20.0; // Moderate need bonus
    } else {
      // Penalty for positions we already have enough of
      final excessPenalty = {
        'QB': positionCount >= 2 ? -30.0 : 0.0,
        'TE': positionCount >= 2 ? -25.0 : 0.0,
        'RB': positionCount >= 6 ? -10.0 : 0.0,
        'WR': positionCount >= 6 ? -10.0 : 0.0,
        'K': positionCount >= 1 ? -100.0 : 0.0,
        'DEF': positionCount >= 1 ? -100.0 : 0.0,
      };
      return excessPenalty[position] ?? 0.0;
    }
  }

  double _calculateOpportunityCost(
    FFPlayer player, 
    FFTeam team, 
    List<FFPlayer> availablePlayers,
    int currentPick
  ) {
    // Find best alternatives at other positions
    final otherPositions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']
        .where((pos) => pos != player.position)
        .toList();
    
    double bestAlternativeValue = 0.0;
    
    for (final position in otherPositions) {
      final positionPlayers = availablePlayers
          .where((p) => p.position == position)
          .take(3) // Top 3 at each position
          .toList();
      
      for (final alternative in positionPlayers) {
        final altBaseValue = _calculateBaseValue(alternative);
        final altPositionalValue = _calculatePositionalValue(alternative, team);
        final altNeedValue = _calculateNeedValue(alternative, team);
        
        final alternativeTotal = (altBaseValue * altPositionalValue) + altNeedValue;
        bestAlternativeValue = max(bestAlternativeValue, alternativeTotal);
      }
    }
    
    // Current player's total value
    final currentBaseValue = _calculateBaseValue(player);
    final currentPositionalValue = _calculatePositionalValue(player, team);
    final currentNeedValue = _calculateNeedValue(player, team);
    final currentTotal = (currentBaseValue * currentPositionalValue) + currentNeedValue;
    
    // Opportunity cost is the difference (can be negative if alternatives are better)
    return currentTotal - bestAlternativeValue;
  }

  double _calculatePersonalityValue(
    FFPlayer player,
    FFTeam team,
    List<FFDraftPick> draftPicks,
    FFAIPersonality personality,
    int currentPick,
  ) {
    double personalityBonus = 0.0;
    
    switch (personality.type) {
      case FFAIPersonalityType.valueHunter:
        // Bonus for players falling beyond ADP
        final adp = player.adp > 0 ? player.adp.toInt() : (player.consensusRank ?? 999);
        if (currentPick > adp + 5) {
          personalityBonus += 15.0; // Value pick bonus
        }
        break;
        
      case FFAIPersonalityType.needFiller:
        // Extra bonus for critical needs
        final positionCount = team.getPositionCount(player.position);
        if ((player.position == 'RB' && positionCount < 2) ||
            (player.position == 'WR' && positionCount < 2) ||
            (player.position == 'QB' && positionCount == 0) ||
            (player.position == 'TE' && positionCount == 0)) {
          personalityBonus += 10.0;
        }
        break;
        
      case FFAIPersonalityType.contrarian:
        // Slight bonus for avoiding runs, penalty for following them
        final runIntensity = _runDetector.getRunIntensity(draftPicks, player.position);
        if (runIntensity > 0.5) {
          personalityBonus -= 8.0; // Avoid the run
        } else if (runIntensity < 0.2) {
          personalityBonus += 5.0; // Go against the grain
        }
        break;
        
      case FFAIPersonalityType.stackBuilder:
        // Bonus for stacking with existing players
        final stackBonus = _calculateStackingValue(player, team);
        personalityBonus += stackBonus * 1.5; // Enhanced stacking
        break;
        
      default:
        break;
    }
    
    // Keep personality adjustments reasonable (max ±20 points)
    return personalityBonus.clamp(-20.0, 20.0);
  }

  double _calculateScarcityValue(
    FFPlayer player, 
    List<FFPlayer> availablePlayers,
    int currentPick,
  ) {
    final position = player.position;
    final samePositionPlayers = availablePlayers
        .where((p) => p.position == position)
        .toList();
    
    if (samePositionPlayers.isEmpty) return 0.0;
    
    // Sort by consensus rank to find tier breaks
    samePositionPlayers.sort((a, b) => 
        (a.consensusRank ?? 999).compareTo(b.consensusRank ?? 999));
    
    final playerIndex = samePositionPlayers.indexOf(player);
    if (playerIndex == -1) return 0.0;
    
    // Bonus for being last in a tier (next player is significantly worse)
    if (playerIndex < samePositionPlayers.length - 1) {
      final nextPlayer = samePositionPlayers[playerIndex + 1];
      final currentRank = player.consensusRank ?? 999;
      final nextRank = nextPlayer.consensusRank ?? 999;
      
      // If there's a big gap to the next player, this is a tier break
      if (nextRank - currentRank > 20) {
        return 12.0; // Tier break bonus
      } else if (nextRank - currentRank > 10) {
        return 6.0; // Minor tier break
      }
    }
    
    return 0.0;
  }

  double _calculateRunValue(FFPlayer player, List<FFDraftPick> draftPicks) {
    final position = player.position;
    final runIntensity = _runDetector.getRunIntensity(draftPicks, position);
    
    if (runIntensity > 0.4) {
      // Moderate run pressure - slight urgency bonus
      return runIntensity * 8.0; // Up to 8 points
    }
    
    return 0.0;
  }

  double _calculateStackingValue(FFPlayer player, FFTeam team) {
    double stackValue = 0.0;
    final position = player.position;
    final playerTeam = player.team;

    // QB-pass catcher stacks
    if (position == 'WR' || position == 'TE') {
      final hasQB = team.roster.any((p) => p.position == 'QB' && p.team == playerTeam);
      if (hasQB) {
        stackValue += 8.0; // Positive stack bonus
      }
    } else if (position == 'QB') {
      final hasPassCatcher = team.roster.any((p) => 
          (p.position == 'WR' || p.position == 'TE') && p.team == playerTeam);
      if (hasPassCatcher) {
        stackValue += 8.0; // Positive stack bonus
      }
    }
         
     return stackValue;
   }
}