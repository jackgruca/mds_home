import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_ai_personality.dart';
import 'simple_draft_engine.dart';
import 'dart:math';

/// Simplified AI service that uses the clean SimpleDraftEngine
/// 
/// This replaces all the complex analytics, value calculations, and strategy classes
/// with one simple method: Pick good players when you need them.
class FFDraftAIService {
  static final Random _random = Random();

  /// Main method: AI makes a draft pick using simple logic
  static FFPlayer makeAIPick({
    required FFTeam team,
    required List<FFPlayer> availablePlayers,
    required List<FFDraftPick> draftHistory,
    required int currentRound,
    required int pickNumber,
    FFAIPersonality? personality,
  }) {
    // Use the simple draft engine - no complex calculations needed
    return SimpleDraftEngine.pickPlayer(
      team: team,
      availablePlayers: availablePlayers,
      currentRound: currentRound,
      pickNumber: pickNumber,
      personality: personality,
    );
  }

  /// Simple pick analysis for the UI (replaces complex FFPickAnalysis)
  static Map<String, dynamic> analyzeLastPick({
    required FFPlayer player,
    required FFTeam team,
    required int round,
    FFAIPersonality? personality,
  }) {
    return SimpleDraftEngine.analyzePickSimple(
      player: player,
      team: team,
      round: round,
      personality: personality,
    );
  }

  /// Basic draft context for UI - much simpler than before
  static Map<String, dynamic> getDraftContext({
    required List<FFTeam> teams,
    required List<FFPlayer> availablePlayers,
    required List<FFDraftPick> draftPicks,
    required int currentRound,
  }) {
    // Count what's been drafted by position
    final positionCounts = <String, int>{};
    for (final pick in draftPicks.where((p) => p.selectedPlayer != null)) {
      final position = pick.selectedPlayer!.position;
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }

    // Available players by position
    final availableByPosition = <String, int>{};
    for (final player in availablePlayers) {
      availableByPosition[player.position] = (availableByPosition[player.position] ?? 0) + 1;
    }

    // Simple round advice
    String roundAdvice;
    if (currentRound <= 3) {
      roundAdvice = 'Early rounds - prioritize RB/WR studs';
    } else if (currentRound <= 6) {
      roundAdvice = 'Fill remaining starter spots';
    } else if (currentRound <= 9) {
      roundAdvice = 'Add depth and consider QB/TE';
    } else if (currentRound <= 12) {
      roundAdvice = 'Target sleepers and handcuffs';
    } else {
      roundAdvice = 'Fill K/DST and final roster spots';
    }

    return {
      'positionsDrafted': positionCounts,
      'availableByPosition': availableByPosition,
      'roundAdvice': roundAdvice,
      'totalPicksMade': draftPicks.where((p) => p.selectedPlayer != null).length,
    };
  }

  /// Check if a player is eligible (basic version)
  static bool isPlayerEligible({
    required FFPlayer player,
    required FFTeam team,
    required int currentRound,
  }) {
    final position = player.position;
    final currentCount = team.getPositionCount(position);
    
    // Just the basic disaster prevention
    if (position == 'K' && currentRound < 14) return false;
    if (position == 'DST' && currentRound < 13) return false;
    if (position == 'QB' && currentCount >= 2) return false;
    if (position == 'TE' && currentCount >= 2) return false;
    if (position == 'K' && currentCount >= 1) return false;
    if (position == 'DST' && currentCount >= 1) return false;
    if (team.roster.length >= 16) return false; // Roster full
    
    return true;
  }

  /// Get top recommended players for user (simple version)
  static List<FFPlayer> getRecommendedPlayers({
    required FFTeam team,
    required List<FFPlayer> availablePlayers,
    required int currentRound,
    int count = 5,
  }) {
    // Filter eligible players
    final eligible = availablePlayers.where((player) {
      return isPlayerEligible(
        player: player,
        team: team,
        currentRound: currentRound,
      );
    }).toList();

    // Score each player using the simple engine
    final playerScores = <FFPlayer, double>{};
    for (final player in eligible.take(20)) {
      final score = SimpleDraftEngine.calculateSimpleScore(player, team, currentRound, null);
      playerScores[player] = score;
    }

    // Return top scorers
    final sortedPlayers = playerScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedPlayers.take(count).map((e) => e.key).toList();
  }

  /// Simple team needs assessment
  static List<String> getTeamNeeds(FFTeam team, int currentRound) {
    final needs = <String>[];
    final positionCounts = team.getPositionCounts();

    // Check basic starter needs
    if ((positionCounts['QB'] ?? 0) == 0) needs.add('QB');
    if ((positionCounts['RB'] ?? 0) < 2) needs.add('RB');
    if ((positionCounts['WR'] ?? 0) < 2) needs.add('WR');
    if ((positionCounts['TE'] ?? 0) == 0) needs.add('TE');

    // Late round needs
    if (currentRound >= 13) {
      if ((positionCounts['K'] ?? 0) == 0) needs.add('K');
      if ((positionCounts['DST'] ?? 0) == 0) needs.add('DST');
    }

    return needs;
  }
}