import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_ai_personality.dart';
import '../models/ff_draft_pick.dart';

enum FFDraftPhase {
  early,    // Rounds 1-4
  middle,   // Rounds 5-10
  late,     // Rounds 11+
}

class FFPositionalPriority {
  final String position;
  final int minCount;
  final int maxCount;
  final int idealCount;
  final double priority;

  const FFPositionalPriority({
    required this.position,
    required this.minCount,
    required this.maxCount,
    required this.idealCount,
    required this.priority,
  });
}

abstract class FFDraftStrategy {
  final FFAIPersonality personality;
  final FFDraftPhase currentPhase;
  
  FFDraftStrategy({
    required this.personality,
    required this.currentPhase,
  });

  List<FFPositionalPriority> getPositionalPriorities();
  double calculatePlayerScore(FFPlayer player, FFTeam team, List<FFDraftPick> recentPicks);
  bool shouldReachForPlayer(FFPlayer player, int currentPick);
  List<String> getTargetPositions(FFTeam team);
}

class EarlyRoundStrategy extends FFDraftStrategy {
  EarlyRoundStrategy({required super.personality}) : super(currentPhase: FFDraftPhase.early);

  @override
  List<FFPositionalPriority> getPositionalPriorities() {
    return const [
      FFPositionalPriority(position: 'RB', minCount: 1, maxCount: 3, idealCount: 2, priority: 1.0),
      FFPositionalPriority(position: 'WR', minCount: 1, maxCount: 3, idealCount: 2, priority: 1.0),
      FFPositionalPriority(position: 'QB', minCount: 0, maxCount: 1, idealCount: 0, priority: 0.3),
      FFPositionalPriority(position: 'TE', minCount: 0, maxCount: 1, idealCount: 0, priority: 0.2),
    ];
  }

  @override
  double calculatePlayerScore(FFPlayer player, FFTeam team, List<FFDraftPick> recentPicks) {
    double score = 0.0;
    final position = player.position;
    final rank = player.rank ?? 999;
    final consensusRank = player.consensusRank ?? rank;

    // Base value score (higher for better players)
    score += (300 - consensusRank) * personality.getTrait('valueWeight');

    // Position value in early rounds
    if (position == 'RB' || position == 'WR') {
      score += 50; // Premium positions get bonus
    } else if (position == 'QB' && personality.type == FFAIPersonalityType.needFiller) {
      score += 20; // Need fillers more likely to take early QB
    }

    // Elite player bonus
    if (consensusRank <= 12) {
      score += 30;
    }

    return score;
  }

  @override
  bool shouldReachForPlayer(FFPlayer player, int currentPick) {
    final reachAmount = (player.consensusRank ?? 999) - currentPick;
    return personality.shouldMakeReach(reachAmount.toDouble());
  }

  @override
  List<String> getTargetPositions(FFTeam team) {
    final priorities = <String>[];
    
    // Always prioritize RB/WR if needed
    if (team.getPositionCount('RB') < 2) priorities.add('RB');
    if (team.getPositionCount('WR') < 2) priorities.add('WR');
    
    // QB for certain personalities
    if (personality.type == FFAIPersonalityType.needFiller && team.getPositionCount('QB') == 0) {
      priorities.add('QB');
    }
    
    return priorities;
  }
}

class MiddleRoundStrategy extends FFDraftStrategy {
  MiddleRoundStrategy({required super.personality}) : super(currentPhase: FFDraftPhase.middle);

  @override
  List<FFPositionalPriority> getPositionalPriorities() {
    return const [
      FFPositionalPriority(position: 'RB', minCount: 2, maxCount: 4, idealCount: 3, priority: 0.8),
      FFPositionalPriority(position: 'WR', minCount: 2, maxCount: 4, idealCount: 3, priority: 0.8),
      FFPositionalPriority(position: 'QB', minCount: 1, maxCount: 1, idealCount: 1, priority: 0.7),
      FFPositionalPriority(position: 'TE', minCount: 1, maxCount: 1, idealCount: 1, priority: 0.6),
      FFPositionalPriority(position: 'FLEX', minCount: 0, maxCount: 2, idealCount: 1, priority: 0.4),
    ];
  }

  @override
  double calculatePlayerScore(FFPlayer player, FFTeam team, List<FFDraftPick> recentPicks) {
    double score = 0.0;
    final position = player.position;
    final rank = player.rank ?? 999;
    final consensusRank = player.consensusRank ?? rank;

    // Base value score
    score += (200 - consensusRank) * personality.getTrait('valueWeight');

    // Need-based scoring
    final needWeight = personality.getTrait('needWeight');
    if (_isPositionNeeded(team, position)) {
      score += 40 * needWeight;
    }

    // QB value in middle rounds
    if (position == 'QB' && team.getPositionCount('QB') == 0) {
      score += 35;
    }

    // TE value in middle rounds  
    if (position == 'TE' && team.getPositionCount('TE') == 0) {
      score += 25;
    }

    // Stacking bonuses
    final stackingBonus = _calculateStackingBonus(player, team);
    score += personality.calculateStackingBonus(stackingBonus > 0, stackingBonus < 0);

    return score;
  }

  @override
  bool shouldReachForPlayer(FFPlayer player, int currentPick) {
    final reachAmount = (player.consensusRank ?? 999) - currentPick;
    return personality.shouldMakeReach(reachAmount.toDouble());
  }

  @override
  List<String> getTargetPositions(FFTeam team) {
    final priorities = <String>[];
    
    if (team.getPositionCount('QB') == 0) priorities.add('QB');
    if (team.getPositionCount('TE') == 0) priorities.add('TE');
    if (team.getPositionCount('RB') < 3) priorities.add('RB');
    if (team.getPositionCount('WR') < 3) priorities.add('WR');
    
    return priorities;
  }

  bool _isPositionNeeded(FFTeam team, String position) {
    final priorities = getPositionalPriorities();
    final priority = priorities.firstWhere(
      (p) => p.position == position,
      orElse: () => const FFPositionalPriority(position: '', minCount: 0, maxCount: 0, idealCount: 0, priority: 0),
    );
    
    return team.getPositionCount(position) < priority.idealCount;
  }

  double _calculateStackingBonus(FFPlayer player, FFTeam team) {
    if (player.position == 'WR' || player.position == 'TE') {
      final hasQB = team.roster.any((p) => p.position == 'QB' && p.team == player.team);
      if (hasQB) return 1.0; // Positive stack
    }
    
    if (player.position == 'QB') {
      final hasWR = team.roster.any((p) => (p.position == 'WR' || p.position == 'TE') && p.team == player.team);
      if (hasWR) return 1.0; // Positive stack
    }
    
    if (player.position == 'RB') {
      final hasWR = team.roster.any((p) => p.position == 'WR' && p.team == player.team);
      if (hasWR && personality.type != FFAIPersonalityType.stackBuilder) return -1.0; // Negative stack
    }
    
    return 0.0;
  }
}

class LateRoundStrategy extends FFDraftStrategy {
  LateRoundStrategy({required super.personality}) : super(currentPhase: FFDraftPhase.late);

  @override
  List<FFPositionalPriority> getPositionalPriorities() {
    return const [
      FFPositionalPriority(position: 'RB', minCount: 3, maxCount: 6, idealCount: 4, priority: 0.7),
      FFPositionalPriority(position: 'WR', minCount: 3, maxCount: 6, idealCount: 4, priority: 0.7),
      FFPositionalPriority(position: 'QB', minCount: 1, maxCount: 2, idealCount: 1, priority: 0.3),
      FFPositionalPriority(position: 'TE', minCount: 1, maxCount: 2, idealCount: 1, priority: 0.3),
      FFPositionalPriority(position: 'K', minCount: 1, maxCount: 1, idealCount: 1, priority: 0.1),
      FFPositionalPriority(position: 'DEF', minCount: 1, maxCount: 1, idealCount: 1, priority: 0.1),
    ];
  }

  @override
  double calculatePlayerScore(FFPlayer player, FFTeam team, List<FFDraftPick> recentPicks) {
    double score = 0.0;
    final position = player.position;
    final rank = player.rank ?? 999;
    final consensusRank = player.consensusRank ?? rank;

    // Base value score (less important in late rounds)
    score += (150 - consensusRank) * personality.getTrait('valueWeight') * 0.5;

    // Upside/sleeper bonus for certain personalities
    if (personality.type == FFAIPersonalityType.sleeperHunter) {
      if (position == 'RB' || position == 'WR') {
        score += 20; // Sleeper hunters target RB/WR upside
      }
    }

    // Fill mandatory positions
    if (position == 'K' && team.getPositionCount('K') == 0) {
      score += 100; // Must fill kicker
    }
    if (position == 'DEF' && team.getPositionCount('DEF') == 0) {
      score += 100; // Must fill defense
    }

    // Handcuff bonus
    if (position == 'RB' && _isHandcuffOpportunity(player, team)) {
      score += 15;
    }

    // Bye week filler
    if (_helpsByeWeekCoverage(player, team)) {
      score += 10;
    }

    return score;
  }

  @override
  bool shouldReachForPlayer(FFPlayer player, int currentPick) {
    // Late rounds more flexible on reaches, especially for sleepers
    final reachAmount = (player.consensusRank ?? 999) - currentPick;
    final adjustedTolerance = personality.getTrait('reachTolerance') * 1.5; // 50% more tolerance
    return reachAmount <= (adjustedTolerance * 15);
  }

  @override
  List<String> getTargetPositions(FFTeam team) {
    final priorities = <String>[];
    
    // Mandatory positions first
    if (team.getPositionCount('K') == 0) priorities.add('K');
    if (team.getPositionCount('DEF') == 0) priorities.add('DEF');
    
    // Depth at skill positions
    if (team.getPositionCount('RB') < 4) priorities.add('RB');
    if (team.getPositionCount('WR') < 4) priorities.add('WR');
    
    // Backup QB for some personalities
    if (personality.type == FFAIPersonalityType.safePlayer && team.getPositionCount('QB') == 1) {
      priorities.add('QB');
    }
    
    return priorities;
  }

  bool _isHandcuffOpportunity(FFPlayer player, FFTeam team) {
    if (player.position != 'RB') return false;
    
    // Check if team has starting RB from same NFL team
    return team.roster.any((p) => 
      p.position == 'RB' && 
      p.team == player.team && 
      (p.rank ?? 999) < (player.rank ?? 999)
    );
  }

  bool _helpsByeWeekCoverage(FFPlayer player, FFTeam team) {
    if (player.byeWeek == null) return false;
    
    // Check if this player provides bye week coverage for existing players
    final samePositionPlayers = team.roster.where((p) => p.position == player.position);
    return samePositionPlayers.any((p) => p.byeWeek != player.byeWeek);
  }
}

class FFDraftStrategyFactory {
  static FFDraftStrategy createStrategy(FFAIPersonality personality, int currentRound) {
    if (currentRound <= 4) {
      return EarlyRoundStrategy(personality: personality);
    } else if (currentRound <= 10) {
      return MiddleRoundStrategy(personality: personality);
    } else {
      return LateRoundStrategy(personality: personality);
    }
  }
}