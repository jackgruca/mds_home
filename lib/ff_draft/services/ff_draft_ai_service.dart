import 'dart:math';
import '../models/ff_team.dart';
import '../models/ff_player.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_ai_personality.dart';
import 'ff_draft_scorer.dart';
import 'ff_positional_run_detector.dart';

class FFDraftDecision {
  final FFPlayer selectedPlayer;
  final String reasoning;
  final double confidence;
  final String strategyUsed;
  final Map<String, double> scoreBreakdown;
  final List<FFPlayer> alternativesConsidered;

  const FFDraftDecision({
    required this.selectedPlayer,
    required this.reasoning,
    required this.confidence,
    required this.strategyUsed,
    required this.scoreBreakdown,
    required this.alternativesConsidered,
  });
}

class FFDraftAIService {
  static final _random = Random();
  static final _runDetector = FFPositionalRunDetector();
  
  /// Distribute AI personalities to draft teams
  static List<FFAIPersonality> distributePersonalities(int numAITeams) {
    final availablePersonalities = [
      FFAIPersonality.getPersonality(FFAIPersonalityType.valueHunter),
      FFAIPersonality.getPersonality(FFAIPersonalityType.needFiller),
      FFAIPersonality.getPersonality(FFAIPersonalityType.contrarian),
      FFAIPersonality.getPersonality(FFAIPersonalityType.stackBuilder),
      FFAIPersonality.getPersonality(FFAIPersonalityType.safePlayer),
      FFAIPersonality.getPersonality(FFAIPersonalityType.sleeperHunter),
    ];
    
    final personalities = <FFAIPersonality>[];
    for (int i = 0; i < numAITeams; i++) {
      personalities.add(availablePersonalities[i % availablePersonalities.length]);
    }
    
    return personalities;
  }

  /// Get recommended picks for user
  static List<FFPlayer> getRecommendedPicks({
    required FFTeam team,
    required List<FFPlayer> availablePlayers,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
    int numRecommendations = 5,
  }) {
    // Filter eligible players
    final eligiblePlayers = availablePlayers.where((player) =>
        FFAdvancedScorer.isEligiblePlayer(player, team, currentRound)).toList();
    
    if (eligiblePlayers.isEmpty) return [];
    
    // Score all eligible players
    final scoredPlayers = <({FFPlayer player, double score})>[];
    
    for (final player in eligiblePlayers) {
      final analysis = FFAdvancedScorer.analyzePickValue(
        player: player,
        team: team,
        availablePlayers: availablePlayers,
        currentPick: currentPick,
        currentRound: currentRound,
        needVsValueBalance: 0.5, // Balanced for user recommendations
        personality: FFAIPersonality.getPersonality(FFAIPersonalityType.valueHunter),
        runDetector: _runDetector,
        draftHistory: draftPicks,
      );
      
      scoredPlayers.add((player: player, score: analysis.finalScore));
    }
    
    // Sort by score and return top recommendations
    scoredPlayers.sort((a, b) => b.score.compareTo(a.score));
    
    return scoredPlayers
        .take(numRecommendations)
        .map((scored) => scored.player)
        .toList();
  }

  /// Analyze current draft state for insights
  static Map<String, dynamic> analyzeDraftState({
    required List<FFTeam> teams,
    required List<FFDraftPick> draftPicks,
    required List<FFPlayer> availablePlayers,
    required int currentRound,
  }) {
    final positionCounts = <String, int>{};
    final teamNeeds = <String, List<String>>{};
    
    // Analyze what's been drafted
    for (final pick in draftPicks.where((p) => p.selectedPlayer != null)) {
      final position = pick.selectedPlayer!.position;
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }
    
    // Analyze team needs
    for (final team in teams) {
      final needs = <String>[];
      final teamPositions = team.getPositionCounts();
      
      if ((teamPositions['RB'] ?? 0) < 2) needs.add('RB');
      if ((teamPositions['WR'] ?? 0) < 2) needs.add('WR');
      if ((teamPositions['QB'] ?? 0) < 1) needs.add('QB');
      if ((teamPositions['TE'] ?? 0) < 1) needs.add('TE');
      if (currentRound >= 12) {
        if ((teamPositions['K'] ?? 0) < 1) needs.add('K');
        if ((teamPositions['DST'] ?? 0) < 1) needs.add('DST');
      }
      
      teamNeeds[team.name] = needs;
    }
    
    return {
      'positionsDrafted': positionCounts,
      'teamNeeds': teamNeeds,
      'availableByPosition': _groupAvailableByPosition(availablePlayers),
      'roundAnalysis': 'Round $currentRound - ${_getRoundAdvice(currentRound)}',
    };
  }

  static Map<String, int> _groupAvailableByPosition(List<FFPlayer> players) {
    final counts = <String, int>{};
    for (final player in players) {
      counts[player.position] = (counts[player.position] ?? 0) + 1;
    }
    return counts;
  }

  static String _getRoundAdvice(int round) {
    if (round <= 3) return 'Focus on RB/WR starters';
    if (round <= 6) return 'Fill remaining starter spots';
    if (round <= 9) return 'Add depth and consider QB/TE';
    if (round <= 12) return 'Target sleepers and handcuffs';
    return 'Fill K/DST and final depth';
  }

  /// Make a draft pick decision using math equation approach
  static FFDraftDecision makePickDecision({
    required FFTeam team,
    required List<FFPlayer> availablePlayers,
    required List<FFDraftPick> draftPicks,
    required int currentPick,
    required int currentRound,
  }) {
    // Get team personality and calculate need vs value balance  
    final personality = team.aiPersonality;
    if (personality == null) {
      // Fallback for human teams or teams without personality
      final fallbackPlayer = availablePlayers.first;
      return FFDraftDecision(
        selectedPlayer: fallbackPlayer,
        reasoning: 'Human player or no AI personality assigned',
        confidence: 0.5,
        strategyUsed: 'Human',
        scoreBreakdown: {'human': 1.0},
        alternativesConsidered: [],
      );
    }
    
    final needVsValueBalance = _calculateNeedVsValueBalance(personality);
    
    // Filter eligible players
    final eligiblePlayers = availablePlayers
        .where((player) => FFAdvancedScorer.isEligiblePlayer(player, team, currentRound))
        .toList();
    
    if (eligiblePlayers.isEmpty) {
      // Fallback - just take best available
      final fallbackPlayer = availablePlayers.first;
      return FFDraftDecision(
        selectedPlayer: fallbackPlayer,
        reasoning: 'No eligible players found, selected best available',
        confidence: 0.5,
        strategyUsed: 'Fallback',
        scoreBreakdown: {'fallback': 1.0},
        alternativesConsidered: [],
      );
    }

    // Score all eligible players
    final playerAnalyses = <FFPlayer, FFPickAnalysis>{};
    
    for (final player in eligiblePlayers.take(15)) { // Only evaluate top 15 to avoid performance issues
      final analysis = FFAdvancedScorer.analyzePickValue(
        player: player,
        team: team,
        availablePlayers: availablePlayers,
        currentPick: currentPick,
        currentRound: currentRound,
        needVsValueBalance: needVsValueBalance,
        personality: personality,
        runDetector: _runDetector,
        draftHistory: draftPicks,
      );
      
      playerAnalyses[player] = analysis;
    }
    
    // Add randomness based on personality
    final finalScores = <FFPlayer, double>{};
    final randomnessFactor = _getRandomnessFactor(personality, currentRound);
    
    for (final entry in playerAnalyses.entries) {
      final baseScore = entry.value.finalScore;
      final randomnessRange = 0.3 * randomnessFactor;
      final randomAdjustment = (_random.nextDouble() * randomnessRange) - (randomnessRange / 2);
      finalScores[entry.key] = baseScore + randomAdjustment;
    }
    
    // Select player with highest final score
    final bestEntry = finalScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    final selectedPlayer = bestEntry.key;
    final bestAnalysis = playerAnalyses[selectedPlayer]!;
    
    // Update position scarcity
    FFAdvancedScorer.updatePositionScarcity(selectedPlayer.position);
    
    // Calculate confidence
    final confidence = _calculateConfidence(finalScores, selectedPlayer);
    
    return FFDraftDecision(
      selectedPlayer: selectedPlayer,
      reasoning: bestAnalysis.reasoning,
      confidence: confidence,
      strategyUsed: bestAnalysis.pickType,
      scoreBreakdown: bestAnalysis.scoreBreakdown,
      alternativesConsidered: bestAnalysis.alternativesConsidered,
    );
  }

  /// Calculate need vs value balance based on personality (0.0 = pure BPA, 1.0 = pure need)
  static double _calculateNeedVsValueBalance(FFAIPersonality personality) {
    switch (personality.name) {
      case 'Value Hunter': return 0.2; // Heavy value focus
      case 'Contrarian': return 0.3; // Value with some contrarian picks
      case 'Need Filler': return 0.7; // Need focused
      case 'Stack Builder': return 0.4; // Moderate need focus for stacking
      case 'Safe Player': return 0.5; // Even balance
      case 'Sleeper Hunter': return 0.3; // Value focus but willing to reach
      default: return 0.5; // Default balanced
    }
  }
  
  /// Calculate randomness factor based on personality and round
  static double _getRandomnessFactor(FFAIPersonality personality, int currentRound) {
    double baseRandomness = 0.5; // Base randomness
    
    // Personality adjustments
    switch (personality.name) {
      case 'Value Hunter': baseRandomness = 0.3; // Fairly consistent
      case 'Contrarian': baseRandomness = 0.8; // More unpredictable
      case 'Safe Player': baseRandomness = 0.2; // Very consistent
      case 'Need Filler': baseRandomness = 0.4; // Somewhat predictable
      case 'Stack Builder': baseRandomness = 0.6; // Moderate unpredictability
      case 'Sleeper Hunter': baseRandomness = 0.7; // Unpredictable for upside
      default: baseRandomness = 0.5; // Moderate randomness
    }
    
    // Reduce randomness in early rounds (more important picks)
    if (currentRound <= 3) {
      baseRandomness *= 0.5;
    } else if (currentRound <= 6) {
      baseRandomness *= 0.7;
    } else if (currentRound <= 10) {
      baseRandomness *= 0.9;
    }
    
    return baseRandomness;
  }
  
  /// Calculate confidence in the pick decision
  static double _calculateConfidence(Map<FFPlayer, double> finalScores, FFPlayer selectedPlayer) {
    if (finalScores.length <= 1) return 1.0;
    
    final sortedScores = finalScores.values.toList()..sort((a, b) => b.compareTo(a));
    final bestScore = sortedScores[0];
    final secondBestScore = sortedScores[1];
    
    final scoreGap = bestScore - secondBestScore;
    
    // Convert score gap to confidence (0.5 to 1.0 range)
    return (0.5 + (scoreGap * 2)).clamp(0.5, 1.0);
  }
}