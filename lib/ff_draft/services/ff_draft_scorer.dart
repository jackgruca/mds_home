import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_ai_personality.dart';
import '../models/ff_draft_pick.dart';
import 'ff_positional_run_detector.dart';
import 'dart:math';

class FFPickAnalysis {
  final String reasoning;
  final Map<String, double> scoreBreakdown;
  final double finalScore;
  final List<FFPlayer> alternativesConsidered;
  final String pickType; // "Need", "Value", "BPA", "Positional Run"
  
  const FFPickAnalysis({
    required this.reasoning,
    required this.scoreBreakdown,
    required this.finalScore,
    required this.alternativesConsidered,
    required this.pickType,
  });
}

class FFAdvancedScorer {
  // Equal position weights - let need and value drive decisions
  static final Map<String, double> _positionWeights = {
    'RB': 1.0,   // Equal starting point
    'WR': 1.0,   // Equal starting point
    'QB': 1.0,   // Equal starting point
    'TE': 1.0,   // Equal starting point
    'K': 0.8,    // Kickers and DEF still lower
    'DST': 0.8,
  };

  // Realistic dropoffs based on roster construction needs
  static final Map<String, List<double>> _needFactorsByPosition = {
    'RB': [1.0, 0.95, 0.8, 0.5, 0.3],    // Gradual - need depth for injuries/matchups
    'WR': [1.0, 0.95, 0.8, 0.5, 0.3, 0.2], // Gradual - flex spots and depth needed
    'QB': [1.0, 0.15, 0.05],             // STEEP - only need 1, maybe backup
    'TE': [1.0, 0.15, 0.05],             // Elite TEs deserve full value, steep dropoff after
    'K': [0.6, 0.05],                    // Only need one
    'DST': [0.6, 0.05],                  // Only need one
  };

  static FFPickAnalysis scorePlayer({
    required FFPlayer player,
    required FFTeam team,
    required FFDraftPick currentPick,
    required List<FFPlayer> availablePlayers,
    required List<FFDraftPick> draftHistory,
    required FFPositionalRunDetector runDetector,
    FFAIPersonality? personality,
  }) {
    // 1. BASE PLAYER VALUE - Start with player's rank (higher rank = higher score)
    final baseValue = max(0.0, 250.0 - (player.consensusRank?.toDouble() ?? 999.0));
    
    // 2. POSITION WEIGHT - Much more balanced now
    final positionWeight = _positionWeights[player.position] ?? 1.0;
    final weightedBaseValue = baseValue * positionWeight;
    
    // 3. VALUE DIFFERENTIAL - Bonus for getting value, penalty for reaching
    final valueDifferential = _calculateValueDifferential(player, currentPick.pickNumber);
    
    // 4. NEED FACTOR - Steep dropoffs for secondary players
    final needFactor = _calculateNeedFactor(team, player.position);
    
    // 5. SCARCITY BONUS - Position getting thin?
    final scarcityBonus = _calculateScarcityBonus(player, availablePlayers);
    
    // 6. POSITIONAL RUN ADJUSTMENT
    final runAdjustment = _calculateRunAdjustment(player, draftHistory, runDetector);
    
    // 7. PERSONALITY ADJUSTMENT - Small tweaks based on team style
    final personalityAdjustment = _calculatePersonalityAdjustment(
      player, currentPick, personality
    );
    
    // FINAL SCORE CALCULATION
    final coreScore = weightedBaseValue + valueDifferential;
    final finalScore = (coreScore * needFactor) + scarcityBonus + runAdjustment + personalityAdjustment;
    
    // Generate reasoning and analysis
    final reasoning = _generateReasoning(
      player, team, currentPick, baseValue, weightedBaseValue, 
      valueDifferential, needFactor, scarcityBonus, runAdjustment, 
      personalityAdjustment, finalScore
    );
    
    final scoreBreakdown = {
      'baseValue': baseValue,
      'weightedBase': weightedBaseValue,
      'valueDifferential': valueDifferential,
      'needFactor': needFactor,
      'scarcityBonus': scarcityBonus,
      'runAdjustment': runAdjustment,
      'personalityAdjustment': personalityAdjustment,
      'finalScore': finalScore,
    };
    
    final pickType = _determinePickType(scoreBreakdown);
    
    final alternatives = availablePlayers
        .where((p) => p.id != player.id)
        .take(3)
        .toList();
    
    return FFPickAnalysis(
      reasoning: reasoning,
      scoreBreakdown: scoreBreakdown,
      finalScore: finalScore,
      alternativesConsidered: alternatives,
      pickType: pickType,
    );
  }

  /// Calculate value differential (positive = good value, negative = reach)
  static double _calculateValueDifferential(FFPlayer player, int currentPick) {
    final playerRank = player.consensusRank ?? 999;
    final differential = currentPick - playerRank;
    
    if (differential > 0) {
      // Getting value - player ranked higher than pick
      return min(50.0, differential * 2.0); // Max 50 point bonus
    } else {
      // Reaching for player
      return max(-25.0, differential * 1.0); // Max 25 point penalty
    }
  }

  /// Calculate need factor based on roster construction and position
  static double _calculateNeedFactor(FFTeam team, String position) {
    final currentCount = team.getPositionCount(position);
    final needFactors = _needFactorsByPosition[position] ?? [1.0];
    
    if (currentCount >= needFactors.length) return needFactors.last;
    return needFactors[currentCount];
  }

  /// Calculate scarcity bonus based on available players
  static double _calculateScarcityBonus(FFPlayer player, List<FFPlayer> availablePlayers) {
    final positionCount = availablePlayers.where((p) => p.position == player.position).length;
    
    if (positionCount > 10) return 0.0; // No scarcity bonus if many players available
    if (positionCount > 5) return 5.0; // Small bonus for moderate scarcity
    return 10.0; // Large bonus for severe scarcity
  }

  /// Calculate positional run adjustment
  static double _calculateRunAdjustment(FFPlayer player, List<FFDraftPick> draftHistory, FFPositionalRunDetector runDetector) {
    double runBonus = 0.0;
    if (runDetector.isPositionInRun(draftHistory, player.position)) {
      runBonus = 10.0; // Up to 10 point bonus for running
    }
    return runBonus;
  }

  /// Small personality-based adjustments
  static double _calculatePersonalityAdjustment(FFPlayer player, FFDraftPick currentPick, FFAIPersonality? personality) {
    double adjustment = 0.0;
    
    if (personality == null) return adjustment;

    switch (personality.type) {
      case FFAIPersonalityType.valueHunter:
        // Bonus for good value picks
        adjustment += 5.0;
        break;
        
      case FFAIPersonalityType.needFiller:
        // Bonus when focusing on needs
        adjustment += 3.0;
        break;
        
      case FFAIPersonalityType.contrarian:
        // Small random adjustment
        adjustment += Random().nextDouble() * 4 - 2; // -2 to +2
        break;
        
      default:
        break;
    }

    return adjustment;
  }

  /// Generate human-readable reasoning
  static String _generateReasoning(FFPlayer player, FFTeam team, FFDraftPick currentPick, double baseValue, double weightedBaseValue, 
      double valueDifferential, double needFactor, double scarcityBonus, double runAdjustment, 
      double personalityAdjustment, double finalScore) {
    
    final positionCount = team.getPositionCount(player.position);
    final currentPickNumber = currentPick.pickNumber;
    final playerRank = player.consensusRank ?? 999;

    if (needFactor > 0.8 && positionCount == 0) {
      return 'Filling critical starter need at ${player.position}';
    } else if (needFactor > 0.6 && positionCount == 1) {
      return 'Securing second starter at ${player.position}';
    } else if (valueDifferential > 15) {
      return 'Excellent value - ${player.name} ranked $playerRank at pick $currentPickNumber';
    } else if (runAdjustment > 5) {
      return 'Following positional run at ${player.position}';
    } else {
      return 'Best available player considering needs and value';
    }
  }

  /// Determine pick type
  static String _determinePickType(Map<String, double> scoreBreakdown) {
    final needFactor = scoreBreakdown['needFactor'] ?? 1.0;
    final valueDifferential = scoreBreakdown['valueDifferential'] ?? 0.0;
    final runAdjustment = scoreBreakdown['runAdjustment'] ?? 0.0;
    
    if (runAdjustment > 5) return 'Positional Run';
    if (needFactor > 0.8 && valueDifferential > 10) return 'Need';
    if (valueDifferential > 10) return 'Value';
    return 'BPA';
  }

  /// Analyze pick value with advanced scoring
  static FFPickAnalysis analyzePickValue({
    required FFPlayer player,
    required FFTeam team,
    required List<FFPlayer> availablePlayers,
    required int currentPick,
    required int currentRound,
    required double needVsValueBalance,
    required FFAIPersonality personality,
    required FFPositionalRunDetector runDetector,
    required List<FFDraftPick> draftHistory,
  }) {
    return scorePlayer(
      player: player,
      team: team,
      currentPick: FFDraftPick(
        pickNumber: currentPick,
        round: currentRound,
        team: team,
        isUserPick: false,
      ),
      availablePlayers: availablePlayers,
      draftHistory: draftHistory,
      runDetector: runDetector,
      personality: personality,
    );
  }

  /// Update position scarcity tracking
  static void updatePositionScarcity(String position) {
    // This method is no longer needed as scarcity is calculated dynamically
  }

  /// Reset scarcity for new draft
  static void resetPositionScarcity() {
    // This method is no longer needed as scarcity is calculated dynamically
  }

  /// Eligibility check with minimal restrictions
  static bool isEligiblePlayer(FFPlayer player, FFTeam team, int currentRound) {
    final currentCount = team.getPositionCount(player.position);
    
    // Hard limits - maximum 2 QB, 2 TE per team
    if (player.position == 'QB' && currentCount >= 2) {
      return false;
    }
    
    if (player.position == 'TE' && currentCount >= 2) {
      return false;
    }
    
    // Don't draft K/DST before round 12
    if ((player.position == 'K' || player.position == 'DST') && currentRound < 12) {
      return false;
    }
    
    return true;
  }

  /// Get position scarcity values
  static Map<String, double> getPositionScarcity() {
    return {}; // No longer tracking scarcity
  }
} 