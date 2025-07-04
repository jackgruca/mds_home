import 'package:mds_home/ff_draft/models/ff_team.dart';

import '../models/ff_draft_pick.dart';
import '../models/ff_player.dart';

class PositionalRun {
  final String position;
  final int count;
  final int picksSpan;
  final List<FFDraftPick> picks;
  final double intensity; // 0.0 to 1.0

  const PositionalRun({
    required this.position,
    required this.count,
    required this.picksSpan,
    required this.picks,
    required this.intensity,
  });

  bool get isSignificant => count >= 3 && intensity > 0.6;
  bool get isModerate => count >= 2 && intensity > 0.4;
}

class FFPositionalRunDetector {
  static const int _lookBackWindow = 8;
  static const int _significantRunThreshold = 3;
  static const int _moderateRunThreshold = 2;

  List<PositionalRun> detectRuns(List<FFDraftPick> draftPicks) {
    final recentPicks = _getRecentPicks(draftPicks);
    if (recentPicks.length < 2) return [];

    final runs = <PositionalRun>[];
    final positionCounts = <String, List<FFDraftPick>>{};

    // Group recent picks by position
    for (final pick in recentPicks) {
      if (pick.selectedPlayer != null) {
        final position = pick.selectedPlayer!.position;
        positionCounts.putIfAbsent(position, () => []);
        positionCounts[position]!.add(pick);
      }
    }

    // Analyze each position for runs
    positionCounts.forEach((position, picks) {
      if (picks.length >= _moderateRunThreshold) {
        final run = _analyzePositionalRun(position, picks, recentPicks);
        if (run != null) {
          runs.add(run);
        }
      }
    });

    // Sort by intensity (strongest runs first)
    runs.sort((a, b) => b.intensity.compareTo(a.intensity));
    return runs;
  }

  PositionalRun? getCurrentRun(List<FFDraftPick> draftPicks, String position) {
    final runs = detectRuns(draftPicks);
    return runs.firstWhere(
      (run) => run.position == position && run.isModerate,
      orElse: () => const PositionalRun(
        position: '',
        count: 0,
        picksSpan: 0,
        picks: [],
        intensity: 0.0,
      ),
    ).position.isNotEmpty ? runs.first : null;
  }

  Map<String, double> getRunPressure(List<FFDraftPick> draftPicks) {
    final runs = detectRuns(draftPicks);
    final pressure = <String, double>{};

    for (final run in runs) {
      if (run.isModerate) {
        pressure[run.position] = run.intensity;
      }
    }

    return pressure;
  }

  bool isPositionInRun(List<FFDraftPick> draftPicks, String position) {
    final run = getCurrentRun(draftPicks, position);
    return run != null && run.isModerate;
  }

  double getRunIntensity(List<FFDraftPick> draftPicks, String position) {
    final run = getCurrentRun(draftPicks, position);
    return run?.intensity ?? 0.0;
  }

  List<String> getPositionsWithRuns(List<FFDraftPick> draftPicks) {
    final runs = detectRuns(draftPicks);
    return runs
        .where((run) => run.isModerate)
        .map((run) => run.position)
        .toList();
  }

  List<FFDraftPick> _getRecentPicks(List<FFDraftPick> draftPicks) {
    final selectedPicks = draftPicks
        .where((pick) => pick.isSelected && pick.selectedPlayer != null)
        .toList();
    
    if (selectedPicks.length <= _lookBackWindow) {
      return selectedPicks;
    }
    
    return selectedPicks.sublist(selectedPicks.length - _lookBackWindow);
  }

  PositionalRun? _analyzePositionalRun(
    String position,
    List<FFDraftPick> positionPicks,
    List<FFDraftPick> allRecentPicks,
  ) {
    if (positionPicks.length < _moderateRunThreshold) return null;

    // Calculate pick numbers span
    final pickNumbers = positionPicks.map((p) => p.pickNumber).toList()..sort();
    final picksSpan = pickNumbers.last - pickNumbers.first + 1;
    
    // Calculate intensity based on:
    // 1. Frequency (picks / span)
    // 2. Recency (more recent = higher intensity)
    // 3. Concentration (picks close together = higher intensity)
    
    final frequency = positionPicks.length / picksSpan;
    final recencyWeight = _calculateRecencyWeight(positionPicks, allRecentPicks);
    final concentrationWeight = _calculateConcentrationWeight(pickNumbers);
    
    // Combine factors for overall intensity
    final intensity = (frequency * 0.4 + recencyWeight * 0.3 + concentrationWeight * 0.3)
        .clamp(0.0, 1.0);

    return PositionalRun(
      position: position,
      count: positionPicks.length,
      picksSpan: picksSpan,
      picks: List.from(positionPicks),
      intensity: intensity,
    );
  }

  double _calculateRecencyWeight(
    List<FFDraftPick> positionPicks,
    List<FFDraftPick> allRecentPicks,
  ) {
    if (allRecentPicks.isEmpty) return 0.0;

    final mostRecentPickIndex = allRecentPicks.length - 1;
    double recencyScore = 0.0;

    for (final pick in positionPicks) {
      final pickIndex = allRecentPicks.indexOf(pick);
      if (pickIndex != -1) {
        // More recent picks get higher scores (exponential decay)
        final normalizedIndex = pickIndex / mostRecentPickIndex;
        recencyScore += normalizedIndex * normalizedIndex;
      }
    }

    return (recencyScore / positionPicks.length).clamp(0.0, 1.0);
  }

  double _calculateConcentrationWeight(List<int> pickNumbers) {
    if (pickNumbers.length < 2) return 1.0;

    final gaps = <int>[];
    for (int i = 1; i < pickNumbers.length; i++) {
      gaps.add(pickNumbers[i] - pickNumbers[i - 1]);
    }

    // Lower average gap = higher concentration
    final averageGap = gaps.reduce((a, b) => a + b) / gaps.length;
    const maxGap = _lookBackWindow / 2; // Reasonable max gap
    
    return (1.0 - (averageGap / maxGap)).clamp(0.0, 1.0);
  }

  // Predict likelihood of run continuing
  double predictRunContinuation(List<FFDraftPick> draftPicks, String position) {
    final run = getCurrentRun(draftPicks, position);
    if (run == null || !run.isModerate) return 0.0;

    // Factors that increase continuation likelihood:
    // 1. Run intensity
    // 2. Position scarcity (fewer good players left)
    // 3. Recent momentum
    
    double continuationScore = run.intensity * 0.6;
    
    // Add momentum bonus if the last pick was this position
    final lastPick = draftPicks.where((pick) => pick.isSelected).lastOrNull;
    
    if (lastPick?.selectedPlayer?.position == position) {
      continuationScore += 0.3;
    }
    
    // Add intensity bonus for significant runs
    if (run.isSignificant) {
      continuationScore += 0.1;
    }
    
    return continuationScore.clamp(0.0, 1.0);
  }

  // Get positions that might start a run based on scarcity
  List<String> getPotentialRunStarters(
    List<FFPlayer> availablePlayers,
    List<FFDraftPick> draftPicks,
  ) {
    final positionCounts = <String, int>{};
    final positionTopTierCounts = <String, int>{};
    
    // Analyze available players by position
    for (final player in availablePlayers) {
      final position = player.position;
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
      
      // Count top-tier players (roughly top 30% of their position)
      if (_isTopTierPlayer(player, availablePlayers, position)) {
        positionTopTierCounts[position] = (positionTopTierCounts[position] ?? 0) + 1;
      }
    }
    
    final potentialRunStarters = <String>[];
    
    // Positions with limited top-tier talent are run candidates
    positionTopTierCounts.forEach((position, topTierCount) {
      final totalCount = positionCounts[position] ?? 0;
      if (totalCount > 0) {
        final topTierRatio = topTierCount / totalCount;
        if (topTierRatio < 0.3 && topTierCount > 0) { // Limited top talent available
          potentialRunStarters.add(position);
        }
      }
    });
    
    return potentialRunStarters;
  }

  bool _isTopTierPlayer(FFPlayer player, List<FFPlayer> allPlayers, String position) {
    final samePositionPlayers = allPlayers
        .where((p) => p.position == position)
        .toList()
      ..sort((a, b) => (a.consensusRank ?? 999).compareTo(b.consensusRank ?? 999));
    
    if (samePositionPlayers.isEmpty) return false;
    
    final playerIndex = samePositionPlayers.indexOf(player);
    if (playerIndex == -1) return false;
    
    final threshold = (samePositionPlayers.length * 0.3).ceil();
    return playerIndex < threshold;
  }
}