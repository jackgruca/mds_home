import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_draft_pick.dart';
import 'ff_draft_ai_service.dart';
// import 'ff_value_calculator.dart'; // TODO: Use for enhanced valuation
import 'ff_positional_run_detector.dart';

class DraftRecommendation {
  final FFPlayer player;
  final String reason;
  final String category;
  final double confidence;
  final Map<String, dynamic> metadata;

  const DraftRecommendation({
    required this.player,
    required this.reason,
    required this.category,
    required this.confidence,
    this.metadata = const {},
  });
}

class FFRecommendationEngine {
  final FFDraftAIService _aiService = FFDraftAIService();
  // final FFValueCalculator _valueCalculator = FFValueCalculator(); // TODO: Use for enhanced valuation
  final FFPositionalRunDetector _runDetector = FFPositionalRunDetector();

  List<DraftRecommendation> getRecommendations({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
    int count = 5,
  }) {
    final recommendations = <DraftRecommendation>[];
    
    // Get AI-powered top recommendations
    final aiRecommendations = FFDraftAIService.getRecommendedPicks(
      team: userTeam,
      availablePlayers: availablePlayers,
      draftPicks: draftPicks,
      currentPick: currentPick,
      currentRound: currentRound,
      numRecommendations: count * 2, // Get extra to diversify reasons
    );

    // Analyze each recommendation and categorize it
    for (final player in aiRecommendations.take(count)) {
      final recommendation = _analyzeRecommendation(
        player,
        userTeam,
        availablePlayers,
        draftPicks,
        currentPick,
        currentRound,
      );
      recommendations.add(recommendation);
    }

    return recommendations;
  }

  DraftRecommendation? getBestAvailableRecommendation({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    // Check if there are available players
    if (availablePlayers.isEmpty) return null;
    
    // Get the highest ranked available player
    final bestPlayer = availablePlayers.first;
    
    return DraftRecommendation(
      player: bestPlayer,
      reason: 'Highest ranked player available',
      category: 'Best Available',
      confidence: 0.9,
      metadata: {
        'rank': bestPlayer.consensusRank ?? bestPlayer.rank,
        'isElite': bestPlayer.isEliteTier(),
      },
    );
  }

  DraftRecommendation? getFillNeedRecommendation({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    final neededPositions = _getNeededPositions(userTeam, currentRound);
    
    for (final position in neededPositions) {
      final positionPlayers = availablePlayers
          .where((p) => p.position == position)
          .toList();
      
      if (positionPlayers.isNotEmpty) {
        final bestAtPosition = positionPlayers.first;
        return DraftRecommendation(
          player: bestAtPosition,
          reason: 'Best $position to fill roster need',
          category: 'Fill Need',
          confidence: 0.8,
          metadata: {
            'position': position,
            'positionCount': userTeam.getPositionCount(position),
          },
        );
      }
    }
    
    return null;
  }

  DraftRecommendation? getValueRecommendation({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    // Find players who are falling significantly
    for (final player in availablePlayers.take(10)) {
      if (player.isValuePick(currentPick)) {
        final expectedPick = player.consensusRank ?? player.rank ?? currentPick;
        final dropAmount = currentPick - expectedPick;
        
        return DraftRecommendation(
          player: player,
          reason: 'Excellent value - fell $dropAmount spots',
          category: 'Value Pick',
          confidence: 0.85,
          metadata: {
            'expectedPick': expectedPick,
            'actualPick': currentPick,
            'dropAmount': dropAmount,
          },
        );
      }
    }
    
    return null;
  }

  DraftRecommendation? getRookieUpsideRecommendation({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    // Find highest upside rookie
    final rookies = availablePlayers
        .where((p) => p.isRookie || p.hasTag('high_upside'))
        .take(5);
    
    if (rookies.isNotEmpty) {
      final bestRookie = rookies.first;
      return DraftRecommendation(
        player: bestRookie,
        reason: 'High upside rookie with breakout potential',
        category: 'Rookie Upside',
        confidence: 0.7,
        metadata: {
          'isRookie': bestRookie.isRookie,
          'hasUpsideTag': bestRookie.hasTag('high_upside'),
        },
      );
    }
    
    return null;
  }

  DraftRecommendation? getStackingRecommendation({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    // Check for QB-WR/TE stacking opportunities
    final userQBs = userTeam.getPlayersByPosition('QB');
    
    for (final qb in userQBs) {
      final teammates = availablePlayers
          .where((p) => 
            p.team == qb.team && 
            (p.position == 'WR' || p.position == 'TE'))
          .take(3);
      
      if (teammates.isNotEmpty) {
        final bestTeammate = teammates.first;
        return DraftRecommendation(
          player: bestTeammate,
          reason: 'Creates stack with ${qb.name}',
          category: 'Stacking',
          confidence: 0.75,
          metadata: {
            'qbName': qb.name,
            'team': qb.team,
            'stackType': 'QB-${bestTeammate.position}',
          },
        );
      }
    }
    
    return null;
  }

  DraftRecommendation? getRunReactionRecommendation({
    required List<FFPlayer> availablePlayers,
    required FFTeam userTeam,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    final runs = _runDetector.detectRuns(draftPicks);
    final activeRuns = runs.where((run) => run.isModerate).toList();
    
    for (final run in activeRuns) {
      final bestAtPosition = availablePlayers
          .where((p) => p.position == run.position)
          .take(3);
      
      if (bestAtPosition.isNotEmpty) {
        final player = bestAtPosition.first;
        return DraftRecommendation(
          player: player,
          reason: '${run.position} run happening - grab one now',
          category: 'Run Reaction',
          confidence: 0.8,
          metadata: {
            'position': run.position,
            'runIntensity': run.intensity,
            'runCount': run.count,
          },
        );
      }
    }
    
    return null;
  }

  DraftRecommendation _analyzeRecommendation(
    FFPlayer player,
    FFTeam userTeam,
    List<FFPlayer> availablePlayers,
    List<FFDraftPick> draftPicks,
    int currentPick,
    int currentRound,
  ) {
    // Determine the primary reason for this recommendation
    String reason = 'AI recommended pick';
    String category = 'AI Suggestion';
    double confidence = 0.7;
    final metadata = <String, dynamic>{};

    // Check for value
    if (player.isValuePick(currentPick)) {
      final expectedPick = player.consensusRank ?? player.rank ?? currentPick;
      final dropAmount = currentPick - expectedPick;
      reason = 'Great value - fell $dropAmount spots';
      category = 'Value Pick';
      confidence = 0.85;
      metadata['dropAmount'] = dropAmount;
    }
    // Check for positional need
    else if (_isPositionNeeded(userTeam, player.position, currentRound)) {
      reason = 'Fills ${player.position} need';
      category = 'Fill Need';
      confidence = 0.8;
      metadata['positionCount'] = userTeam.getPositionCount(player.position);
    }
    // Check for elite talent
    else if (player.isEliteTier()) {
      reason = 'Elite talent available';
      category = 'Best Available';
      confidence = 0.9;
      metadata['tier'] = 'elite';
    }
    // Check for stacking
    else if (_isStackingOpportunity(player, userTeam)) {
      final qbs = userTeam.getPlayersByPosition('QB');
      final qb = qbs.isNotEmpty 
          ? qbs.firstWhere((p) => p.team == player.team, orElse: () => qbs.first)
          : userTeam.roster.isNotEmpty 
              ? userTeam.roster.first 
              : null;
      reason = 'Creates stack with ${qb?.name ?? 'QB'}';
      category = 'Stacking';
      confidence = 0.75;
      metadata['stackType'] = 'QB-${player.position}';
    }
    // Check for rookie upside
    else if (player.isRookie || player.hasTag('high_upside')) {
      reason = 'High upside breakout candidate';
      category = 'Rookie Upside';
      confidence = 0.7;
      metadata['isRookie'] = player.isRookie;
    }
    // Check for positional run
    else if (_isInPositionalRun(player.position, draftPicks)) {
      reason = '${player.position} run - grab one now';
      category = 'Run Reaction';
      confidence = 0.8;
      metadata['position'] = player.position;
    }

    return DraftRecommendation(
      player: player,
      reason: reason,
      category: category,
      confidence: confidence,
      metadata: metadata,
    );
  }

  List<String> _getNeededPositions(FFTeam team, int currentRound) {
    final needs = <String>[];
    
    // Early round needs (1-6)
    if (currentRound <= 6) {
      if (team.getPositionCount('QB') == 0) needs.add('QB');
      if (team.getPositionCount('RB') < 2) needs.add('RB');
      if (team.getPositionCount('WR') < 2) needs.add('WR');
      if (team.getPositionCount('TE') == 0) needs.add('TE');
    }
    // Middle round needs (7-12)
    else if (currentRound <= 12) {
      if (team.getPositionCount('QB') == 0) needs.add('QB');
      if (team.getPositionCount('RB') < 3) needs.add('RB');
      if (team.getPositionCount('WR') < 4) needs.add('WR');
      if (team.getPositionCount('TE') == 0) needs.add('TE');
    }
    // Late round needs (13+)
    else {
      if (team.getPositionCount('K') == 0) needs.add('K');
      if (team.getPositionCount('DEF') == 0) needs.add('DEF');
      if (team.getPositionCount('QB') == 0) needs.add('QB');
      if (team.getPositionCount('TE') == 0) needs.add('TE');
    }
    
    return needs;
  }

  bool _isPositionNeeded(FFTeam team, String position, int currentRound) {
    final neededPositions = _getNeededPositions(team, currentRound);
    return neededPositions.contains(position);
  }

  bool _isStackingOpportunity(FFPlayer player, FFTeam team) {
    if (player.position != 'WR' && player.position != 'TE') return false;
    
    return team.getPlayersByPosition('QB')
        .any((qb) => qb.team == player.team);
  }

  bool _isInPositionalRun(String position, List<FFDraftPick> draftPicks) {
    final run = _runDetector.getCurrentRun(draftPicks, position);
    return run != null && run.isModerate;
  }
}