import '../models/ff_team.dart';
import '../models/ff_player.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_draft_grade.dart';
import '../models/ff_roster_construction_rules.dart';

/// Comprehensive real-time draft analytics and grading service
class FFDraftAnalyticsService {
  
  /// Grades a single draft pick in real-time
  FFPickGrade gradePickInRealTime({
    required FFPlayer player,
    required FFTeam team,
    required int pickNumber,
    required int round,
    required List<FFPlayer> remainingPlayers,
    required List<FFDraftPick> completedPicks,
  }) {
    // Calculate ADP difference
    final adpValue = player.stats?['adp'];
    final adp = (adpValue is num) ? adpValue.toDouble() : (pickNumber.toDouble() * 1.2);
    final adpDifference = pickNumber - adp;
    
    // Determine if pick fills a need
    final fillsNeed = _fillsRosterNeed(team, player.position, round);
    
    // Check if it's a positional reach
    final isReach = _isPositionalReach(player.position, round, adp.toInt());
    
    // Calculate opportunity cost
    final opportunityCost = _getOpportunityCost(player.position, round);
    
    // Calculate base value score
    double value = _calculatePickValue(
      player: player,
      team: team,
      pickNumber: pickNumber,
      round: round,
      adpDifference: adpDifference,
      fillsNeed: fillsNeed,
      isReach: isReach,
      opportunityCost: opportunityCost,
      remainingPlayers: remainingPlayers,
    );
    
    // Generate analysis
    final analysis = _analyzePickQuality(
      player: player,
      team: team,
      round: round,
      value: value,
      adpDifference: adpDifference,
      fillsNeed: fillsNeed,
      isReach: isReach,
    );
    
    return FFPickGrade(
      player: player,
      team: team,
      pickNumber: pickNumber,
      round: round,
      grade: DraftGradeUtils.valueToGrade(value),
      pickType: DraftGradeUtils.determinePickType(adpDifference, fillsNeed, value),
      value: value,
      reasoning: analysis['reasoning'] as String,
      positives: (analysis['positives'] as List<String>?) ?? [],
      negatives: (analysis['negatives'] as List<String>?) ?? [],
      adpDifference: adpDifference,
      fillsNeed: fillsNeed,
      isReach: isReach,
      opportunityCost: opportunityCost,
    );
  }
  
  /// Generates comprehensive team draft grade
  FFTeamDraftGrade gradeTeamDraft({
    required FFTeam team,
    required List<FFPickGrade> pickGrades,
    required int roundsCompleted,
  }) {
    if (pickGrades.isEmpty) {
      return FFTeamDraftGrade(
        team: team,
        overallGrade: DraftGrade.C,
        averagePickValue: 0.0,
        pickGrades: [],
        positionCounts: team.getPositionCounts(),
        strengths: [],
        weaknesses: ['No picks completed yet'],
        recommendations: ['Begin drafting players'],
        rosterBalance: 50.0,
        valueExtracted: 0.0,
        stealsCount: 0,
        reachesCount: 0,
      );
    }
    
    // Calculate overall metrics
    final averageValue = _calculateAveragePickValue(pickGrades);
    final rosterBalance = DraftGradeUtils.calculateRosterBalance(team, roundsCompleted);
    final valueExtracted = _calculateTotalValueExtracted(pickGrades);
    final stealsCount = pickGrades.where((pick) => pick.pickType == PickType.STEAL).length;
    final reachesCount = pickGrades.where((pick) => 
      pick.pickType == PickType.REACH || pick.pickType == PickType.MAJOR_REACH
    ).length;
    
    // Analyze team construction
    final teamAnalysis = _analyzeTeamConstruction(team, pickGrades, roundsCompleted);
    
    // Calculate overall grade
    final overallGrade = _calculateOverallTeamGrade(
      averageValue: averageValue,
      rosterBalance: rosterBalance,
      valueExtracted: valueExtracted,
      stealsCount: stealsCount,
      reachesCount: reachesCount,
      roundsCompleted: roundsCompleted,
    );
    
    return FFTeamDraftGrade(
      team: team,
      overallGrade: overallGrade,
      averagePickValue: averageValue,
      pickGrades: pickGrades,
      positionCounts: team.getPositionCounts(),
      strengths: teamAnalysis['strengths'] ?? [],
      weaknesses: teamAnalysis['weaknesses'] ?? [],
      recommendations: teamAnalysis['recommendations'] ?? [],
      rosterBalance: rosterBalance,
      valueExtracted: valueExtracted,
      stealsCount: stealsCount,
      reachesCount: reachesCount,
    );
  }
  
  /// Analyzes current draft state and generates insights
  List<FFDraftInsight> generateRealTimeInsights({
    required List<FFTeam> teams,
    required List<FFPlayer> remainingPlayers,
    required List<FFDraftPick> completedPicks,
    required int currentRound,
    String? userTeamId,
  }) {
    List<FFDraftInsight> insights = [];
    final now = DateTime.now();
    
    // Detect positional runs
    final positionalRuns = _detectPositionalRuns(completedPicks.take(15).toList());
    for (final run in positionalRuns) {
      insights.add(FFDraftInsight(
        title: '${run['position']} Run Detected',
        message: '${run['count']} ${run['position']}s taken in last ${run['picks']} picks',
        type: InsightType.POSITIONAL_RUN,
        priority: InsightPriority.HIGH,
        timestamp: now,
        metadata: run,
      ));
    }
    
    // Find value opportunities
    final valueOpportunities = _findValueOpportunities(remainingPlayers, currentRound);
    for (final opportunity in valueOpportunities.take(3)) {
      insights.add(FFDraftInsight(
        title: 'Value Opportunity',
        message: '${opportunity.name} (${opportunity.position}) available at great value',
        type: InsightType.VALUE_OPPORTUNITY,
        priority: InsightPriority.MEDIUM,
        relatedPlayer: opportunity,
        timestamp: now,
      ));
    }
    
    // Analyze user team (if specified)
    if (userTeamId != null) {
      final userTeam = teams.firstWhere((t) => t.id == userTeamId);
      final userInsights = _analyzeUserTeamNeeds(userTeam, currentRound, remainingPlayers);
      insights.addAll(userInsights);
    }
    
    // Position scarcity alerts
    final scarcityAlerts = _analyzePositionScarcity(remainingPlayers, currentRound);
    insights.addAll(scarcityAlerts);
    
    return insights..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }
  
  /// Calculates the value of a draft pick
  double _calculatePickValue({
    required FFPlayer player,
    required FFTeam team,
    required int pickNumber,
    required int round,
    required double adpDifference,
    required bool fillsNeed,
    required bool isReach,
    required double opportunityCost,
    required List<FFPlayer> remainingPlayers,
  }) {
    double value = 0.0;
    
    // Base value from ADP difference
    value += (adpDifference * -0.2); // Negative ADP diff is good
    
    // Position-specific value adjustments
    final positionMultiplier = FFRosterConstructionRules.getPositionPriorityMultiplier(
      team, player.position, round
    );
    value += (positionMultiplier - 1.0) * 2.0;
    
    // Need-based bonus
    if (fillsNeed) value += 1.5;
    
    // Reach penalty
    if (isReach) value -= 2.0;
    
    // Opportunity cost penalty
    value -= opportunityCost * 0.5;
    
    // Player rank bonus (higher ranked = better value)
    if (player.rank != null && player.rank! <= 50) {
      value += (51 - player.rank!) * 0.05;
    }
    
    // Round-specific adjustments
    if (round <= 3) {
      // Early rounds - prioritize elite players
      if (player.rank != null && player.rank! <= 24) value += 1.0;
    } else if (round >= 12) {
      // Late rounds - any starter is valuable
      if (['K', 'DEF'].contains(player.position)) value += 0.5;
    }
    
    // Consensus vs ADP value
    if (player.consensusRank != null && player.stats?['adp'] != null) {
      final consensusVsAdp = player.stats!['adp']! - player.consensusRank!;
      value += consensusVsAdp * 0.1;
    }
    
    return value.clamp(-10.0, 10.0);
  }
  
  /// Analyzes pick quality and generates reasoning
  Map<String, dynamic> _analyzePickQuality({
    required FFPlayer player,
    required FFTeam team,
    required int round,
    required double value,
    required double adpDifference,
    required bool fillsNeed,
    required bool isReach,
  }) {
    List<String> positives = [];
    List<String> negatives = [];
    String reasoning = '';
    
    // Analyze ADP value
    if (adpDifference <= -10) {
      positives.add('Great value - ${adpDifference.abs().toInt()} picks after ADP');
    } else if (adpDifference >= 15) {
      negatives.add('Reach - ${adpDifference.toInt()} picks before ADP');
    }
    
    // Analyze roster fit
    if (fillsNeed) {
      positives.add('Fills roster need at ${player.position}');
    } else {
      final positionCount = team.getPositionCount(player.position);
      if (positionCount >= 2) {
        negatives.add('Already have $positionCount ${player.position}s');
      }
    }
    
    // Analyze round appropriateness
    if (isReach) {
      negatives.add('${player.position} typically drafted later');
    }
    
    // Player-specific analysis
    if (player.rank != null && player.rank! <= 12) {
      positives.add('Elite tier player (Top 12 overall)');
    }
    
    if (player.position == 'QB' && round <= 3) {
      negatives.add('Very early QB pick - could wait');
    }
    
    if (player.position == 'K' && round <= 13) {
      negatives.add('Kicker drafted too early');
    }
    
    // Generate reasoning based on value
    if (value >= 3.0) {
      reasoning = 'Excellent pick - great value with strong roster fit';
    } else if (value >= 1.0) {
      reasoning = 'Solid pick - good value and fits team needs';
    } else if (value >= -1.0) {
      reasoning = 'Decent pick - reasonable selection for the round';
    } else if (value >= -3.0) {
      reasoning = 'Questionable pick - better options likely available';
    } else {
      reasoning = 'Poor pick - significant reach or bad roster fit';
    }
    
    return {
      'reasoning': reasoning,
      'positives': positives,
      'negatives': negatives,
    };
  }
  
  /// Determines if pick fills a roster need
  bool _fillsRosterNeed(FFTeam team, String position, int round) {
    final positionCount = team.getPositionCount(position);
    final shouldPrioritizeStarters = FFRosterConstructionRules.hasUnfilledStarterNeeds(team);
    
    // Check standard positional needs
    if (position == 'QB' && positionCount == 0) return true;
    if (position == 'RB' && positionCount < 2) return true;
    if (position == 'WR' && positionCount < 2) return true;
    if (position == 'TE' && positionCount == 0) return true;
    
    // Late round needs
    if (round >= 13) {
      if (position == 'K' && positionCount == 0) return true;
      if (position == 'DEF' && positionCount == 0) return true;
    }
    
    // Depth needs if starters filled
    if (!shouldPrioritizeStarters) {
      if (['RB', 'WR'].contains(position) && positionCount < 4) return true;
      if (position == 'QB' && positionCount < 2) return true;
    }
    
    return false;
  }
  
  /// Calculates average pick value for a team
  double _calculateAveragePickValue(List<FFPickGrade> pickGrades) {
    if (pickGrades.isEmpty) return 0.0;
    return pickGrades.map((pick) => pick.value).reduce((a, b) => a + b) / pickGrades.length;
  }
  
  /// Calculates total value extracted above expectation
  double _calculateTotalValueExtracted(List<FFPickGrade> pickGrades) {
    return pickGrades.map((pick) => pick.value).where((value) => value > 0).fold(0.0, (a, b) => a + b);
  }
  
  /// Analyzes team construction strengths and weaknesses
  Map<String, List<String>> _analyzeTeamConstruction(
    FFTeam team,
    List<FFPickGrade> pickGrades,
    int roundsCompleted,
  ) {
    List<String> strengths = [];
    List<String> weaknesses = [];
    List<String> recommendations = [];
    
    final counts = team.getPositionCounts();
    final steals = pickGrades.where((p) => p.pickType == PickType.STEAL).length;
    final reaches = pickGrades.where((p) => p.pickType == PickType.REACH).length;
    
    // Analyze positional balance
    if (counts['RB']! >= 3 && counts['WR']! >= 3) {
      strengths.add('Strong skill position depth');
    }
    
    if (counts['QB']! == 0 && roundsCompleted >= 8) {
      weaknesses.add('No quarterback drafted yet');
      recommendations.add('Draft QB soon');
    }
    
    if (counts['TE']! == 0 && roundsCompleted >= 10) {
      weaknesses.add('No tight end drafted');
      recommendations.add('Address TE position');
    }
    
    // Analyze draft execution
    if (steals >= 2) {
      strengths.add('Found multiple steals');
    }
    
    if (reaches >= 3) {
      weaknesses.add('Too many reaches');
    }
    
    // Late round analysis
    if (roundsCompleted >= 13) {
      if (counts['K']! == 0) recommendations.add('Draft kicker');
      if (counts['DEF']! == 0) recommendations.add('Draft defense');
    }
    
    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
    };
  }
  
  /// Calculates overall team grade
  DraftGrade _calculateOverallTeamGrade({
    required double averageValue,
    required double rosterBalance,
    required double valueExtracted,
    required int stealsCount,
    required int reachesCount,
    required int roundsCompleted,
  }) {
    double score = 50.0; // Base C grade
    
    // Average pick value contribution (40% weight)
    score += averageValue * 8.0;
    
    // Roster balance contribution (30% weight)
    score += (rosterBalance - 50.0) * 0.6;
    
    // Value extraction contribution (20% weight)
    score += valueExtracted * 2.0;
    
    // Steals and reaches contribution (10% weight)
    score += stealsCount * 3.0;
    score -= reachesCount * 2.0;
    
    return DraftGradeUtils.valueToGrade(score / 10.0);
  }
  
  /// Detects positional runs in recent picks
  List<Map<String, dynamic>> _detectPositionalRuns(List<FFDraftPick> recentPicks) {
    List<Map<String, dynamic>> runs = [];
    Map<String, int> positionCounts = {};
    
    for (final pick in recentPicks.reversed) {
      if (pick.selectedPlayer != null) {
        final position = pick.selectedPlayer!.position;
        positionCounts[position] = (positionCounts[position] ?? 0) + 1;
      }
    }
    
    positionCounts.forEach((position, count) {
      if (count >= 3) {
        runs.add({
          'position': position,
          'count': count,
          'picks': recentPicks.length,
        });
      }
    });
    
    return runs;
  }
  
  /// Finds value opportunities in remaining players
  List<FFPlayer> _findValueOpportunities(List<FFPlayer> remainingPlayers, int currentRound) {
    return remainingPlayers.where((player) {
      final adp = player.stats?['adp']?.toDouble() ?? (currentRound * 12.0);
      final currentPick = currentRound * 12; // Approximate
      return currentPick > adp + 10; // Available 10+ picks after ADP
    }).take(5).toList();
  }
  
  /// Analyzes user team needs and generates insights
  List<FFDraftInsight> _analyzeUserTeamNeeds(
    FFTeam userTeam,
    int currentRound,
    List<FFPlayer> remainingPlayers,
  ) {
    List<FFDraftInsight> insights = [];
    final now = DateTime.now();
    final counts = userTeam.getPositionCounts();
    
    // Check for roster imbalances
    if (counts['QB']! == 0 && currentRound >= 6) {
      insights.add(FFDraftInsight(
        title: 'QB Need',
        message: 'Consider drafting QB soon - waiting much longer is risky',
        type: InsightType.ROSTER_IMBALANCE,
        priority: InsightPriority.HIGH,
        relatedTeam: userTeam,
        timestamp: now,
      ));
    }
    
    if (counts['RB']! < 2 && currentRound >= 6) {
      insights.add(FFDraftInsight(
        title: 'RB Need',
        message: 'Need more running backs for lineup flexibility',
        type: InsightType.ROSTER_IMBALANCE,
        priority: InsightPriority.HIGH,
        relatedTeam: userTeam,
        timestamp: now,
      ));
    }
    
    return insights;
  }
  
  /// Analyzes position scarcity and generates alerts
  List<FFDraftInsight> _analyzePositionScarcity(
    List<FFPlayer> remainingPlayers,
    int currentRound,
  ) {
    List<FFDraftInsight> insights = [];
    final now = DateTime.now();
    
    // Count remaining players by position
    Map<String, int> remainingCounts = {};
    for (final player in remainingPlayers) {
      remainingCounts[player.position] = (remainingCounts[player.position] ?? 0) + 1;
    }
    
    // Check for scarcity
    remainingCounts.forEach((position, count) {
      if (position == 'QB' && count <= 8 && currentRound <= 10) {
        insights.add(FFDraftInsight(
          title: 'QB Scarcity',
          message: 'Only $count starting QBs remain - consider drafting soon',
          type: InsightType.POSITION_SCARCITY,
          priority: InsightPriority.MEDIUM,
          timestamp: now,
          metadata: {'position': position, 'remaining': count},
        ));
      }
    });
    
    return insights;
  }
  
  /// Helper method to determine if a position pick is a reach
  bool _isPositionalReach(String position, int round, int adp) {
    // K and DEF are reaches if drafted early
    if (position == 'K' && round <= 13) return true;
    if (position == 'DEF' && round <= 13) return true;
    
    // QB in first 3 rounds is often a reach
    if (position == 'QB' && round <= 3) return true;
    
    // Check if ADP is significantly higher than current pick
    final approximatePickNumber = round * 12;
    return adp > approximatePickNumber + 20;
  }
  
  /// Helper method to calculate opportunity cost
  double _getOpportunityCost(String position, int round) {
    // Higher opportunity cost for drafting certain positions early
    if (position == 'K' && round <= 13) return 3.0;
    if (position == 'DEF' && round <= 13) return 2.5;
    if (position == 'QB' && round <= 3) return 1.5;
    if (position == 'TE' && round <= 5) return 1.0;
    
    return 0.0;
  }
}