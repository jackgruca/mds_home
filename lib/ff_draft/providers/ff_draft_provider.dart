import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/ff_draft_settings.dart';
import '../models/ff_team.dart';
import '../models/ff_player.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_platform_ranks.dart';
import '../../services/fantasy/csv_rankings_service.dart';
import '../../models/fantasy/player_ranking.dart';
import 'dart:math';

class _PlayerScore {
  final FFPlayer player;
  double score;
  _PlayerScore({required this.player, required this.score});
}

class FFDraftProvider extends ChangeNotifier {
  final FFDraftSettings settings;
  final int? userPick;
  List<FFTeam> teams = [];
  List<FFPlayer> availablePlayers = [];
  List<FFDraftPick> draftPicks = [];
  List<FFPlayer> queuedPlayers = [];
  List<FFPlayer> atRiskPlayers = [];
  int currentPickIndex = 0;
  int userTeamIndex = 0;
  bool paused = true;
  List<FFDraftPick> pickHistory = [];
  List<FFDraftPick> userPickHistory = [];
  VoidCallback? onUserPick;
  final Random _rand = Random();

  FFDraftProvider({required this.settings, this.userPick});

  Future<void> initializeDraft() async {
    // Determine user team index
    if (userPick != null && userPick! > 0 && userPick! <= settings.numTeams) {
      userTeamIndex = userPick! - 1;
    } else {
      userTeamIndex = (DateTime.now().millisecondsSinceEpoch % settings.numTeams);
    }
    // Initialize teams
    teams = List.generate(
      settings.numTeams,
      (index) => FFTeam(
        id: 'team_$index',
        name: 'Team ${index + 1}',
        roster: [],
        isUserTeam: index == userTeamIndex,
      ),
    );
    await _loadPlayers();
    draftPicks = _generateDraftPicks();
    notifyListeners();
  }

  Future<void> _loadPlayers() async {
    try {
      final rankingsService = CSVRankingsService();
      final List<PlayerRanking> playerRankings = await rankingsService.fetchRankings();

      availablePlayers = playerRankings.map((ranking) {
        return FFPlayer(
          id: ranking.id,
          name: ranking.name,
          position: ranking.position,
          team: ranking.team,
          byeWeek: ranking.additionalRanks['Bye']?.toString(),
          rank: ranking.rank,
          consensusRank: ranking.rank,
          stats: {
            'rank': ranking.rank,
            'adp': ranking.additionalRanks['ADP'],
            'projectedPoints': ranking.additionalRanks['Projected Points'],
            'auctionValue': ranking.additionalRanks['Auction Value'],
            ...ranking.additionalRanks,
          },
          platformRanks: {
            'PFF': ranking.additionalRanks['PFF']?.toInt(),
            'CBS': ranking.additionalRanks['CBS']?.toInt(),
            'ESPN': ranking.additionalRanks['ESPN']?.toInt(),
            'FFToday': ranking.additionalRanks['FFToday']?.toInt(),
            'FootballGuys': ranking.additionalRanks['FootballGuys']?.toInt(),
            'Yahoo': ranking.additionalRanks['Yahoo']?.toInt(),
            'NFL': ranking.additionalRanks['NFL']?.toInt(),
          }.map((key, value) => MapEntry(key, value ?? 0)),
        );
      }).toList();

      availablePlayers.sort((a, b) {
        final rankA = a.rank ?? 9999;
        final rankB = b.rank ?? 9999;
        return rankA.compareTo(rankB);
      });

      debugPrint('Loaded ${availablePlayers.length} players');
    } catch (e) {
      debugPrint('Error loading players: $e');
      availablePlayers = [];
    }
  }

  List<FFDraftPick> _generateDraftPicks() {
    final picks = <FFDraftPick>[];
    final numRounds = settings.numRounds;
    final numTeams = settings.numTeams;
    for (var round = 1; round <= numRounds; round++) {
      final isSnakeRound = round % 2 == 0;
      final startTeam = isSnakeRound ? numTeams - 1 : 0;
      final endTeam = isSnakeRound ? 0 : numTeams - 1;
      final step = isSnakeRound ? -1 : 1;
      for (var teamIndex = startTeam;
          isSnakeRound ? teamIndex >= endTeam : teamIndex <= endTeam;
          teamIndex += step) {
        picks.add(FFDraftPick(
          pickNumber: picks.length + 1,
          round: round,
          team: teams[teamIndex],
          isUserPick: teamIndex == userTeamIndex,
        ));
      }
    }
    return picks;
  }

  FFDraftPick? getCurrentPick() {
    if (currentPickIndex >= draftPicks.length) return null;
    return draftPicks[currentPickIndex];
  }

  void handlePickSelection(FFDraftPick pick) {
    if (pick != getCurrentPick()) return;

    // Get best available player that fills a need
    final bestPlayer = _getBestAvailablePlayer(pick.team);
    if (bestPlayer != null) {
      _makePick(pick, bestPlayer);
    }
  }

  FFPlayer? _getBestAvailablePlayer(FFTeam team) {
    // --- 1. Dynamic reach calculation ---
    final pickNumber = getCurrentPick()?.pickNumber ?? 1;
    const randomness = 0.3; // Reduced from 0.5 to 0.3 for more consistent picks
    const baseReach = 2;
    const maxExtraReach = 10;
    final dynamicReach = baseReach + (randomness * maxExtraReach * _rand.nextDouble());
    final reachLimit = (pickNumber + dynamicReach).round();

    // --- 2. Filter candidates within reach ---
    final candidates = availablePlayers.where((p) {
      final rank = p.stats?['rank'] ?? 9999;
      return rank <= reachLimit;
    }).toList();
    if (candidates.isEmpty) return availablePlayers.isNotEmpty ? availablePlayers.first : null;

    // --- 3. Score candidates ---
    List<_PlayerScore> scored = candidates.map((p) {
      double score = 0;
      final rank = p.stats?['rank'] ?? 9999;
      final position = p.position;
      final byeWeek = p.byeWeek;
      // Position of need
      if (_isPositionNeeded(team, position)) {
        score += 10;
      }
      // Stacking bonus (QB/WR/TE)
      if (position == 'WR' || position == 'TE') {
        final hasQB = team.roster.any((rosterP) => rosterP.position == 'QB' && rosterP.team == p.team);
        if (hasQB) score += 2;
      }
      if (position == 'QB') {
        final hasWR = team.roster.any((rosterP) => (rosterP.position == 'WR' || rosterP.position == 'TE') && rosterP.team == p.team);
        if (hasWR) score += 2;
      }
      // Negative stack penalty (RB/WR on same team)
      if (position == 'RB') {
        final hasWR = team.roster.any((rosterP) => rosterP.position == 'WR' && rosterP.team == p.team);
        if (hasWR) score -= 1.5;
      }
      if (position == 'WR') {
        final hasRB = team.roster.any((rosterP) => rosterP.position == 'RB' && rosterP.team == p.team);
        if (hasRB) score -= 1.5;
      }
      // Bye week penalty
      if (byeWeek != null && byeWeek.isNotEmpty) {
        final sameBye = team.roster.where((rosterP) => rosterP.byeWeek == byeWeek).length;
        if (sameBye >= 2) score -= 0.5;
      }
      // Roster construction penalty (overfilling a position)
      final positionCount = team.roster.where((rosterP) => rosterP.position == position).length;
      // QB/TE special logic
      if (position == 'QB') {
        if (positionCount == 1) score -= 7; // much less likely to take a 2nd
        if (positionCount >= 2) score -= 1000; // never take a 3rd
      }
      if (position == 'TE') {
        if (positionCount == 1) score -= 6; // much less likely to take a 2nd
        if (positionCount >= 2) score -= 1000; // never take a 3rd
      }
      // General position limits
      final positionLimits = {
        'QB': 2,
        'RB': 8,
        'WR': 8,
        'TE': 2,
        'FLEX': 1,
        'K': 1,
        'DEF': 1,
      };
      if (positionCount >= (positionLimits[position] ?? 0)) {
        score -= 1000;
      }
      // Positional run bonus (if recent picks have targeted this position)
      final recentPicks = draftPicks.where((pick) => pick.isSelected).toList().reversed.take(5).toList();
      final runCount = recentPicks.where((pick) => pick.selectedPlayer?.position == position).length;
      if ((position == 'RB' || position == 'TE') && runCount >= 2) {
        score += 2.5;
      } else if (runCount >= 3) {
        score += 1.5;
      }
      // Slight randomness in score
      score += _rand.nextDouble() * randomness;
      // Higher score for better rank
      score += (1000 - rank) * 0.001;
      return _PlayerScore(player: p, score: score);
    }).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));

    // --- 4. With some probability, pick a player outside the top candidate ---
    if (scored.length > 1 && _rand.nextDouble() < randomness * 0.25) {
      // Pick randomly from top 3-5
      final topN = min(5, scored.length);
      return scored[_rand.nextInt(topN)].player;
    }

    // For AI bench logic: if all starting spots are filled, prefer FLEX
    final startersFilled = team.roster.length >= 9; // 9 starters (QB, RB, RB, WR, WR, WR, TE, K, DEF)
    if (startersFilled) {
      for (final s in scored) {
        if (s.player.position == 'RB' || s.player.position == 'WR' || s.player.position == 'TE') {
          s.score += 1.0;
        }
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
    }

    return scored.first.player;
  }

  bool _isPositionNeeded(FFTeam team, String position) {
    // Count current players at this position
    final positionCount = team.roster.where((p) => p.position == position).length;
    
    // Define position limits
    final positionLimits = {
      'QB': 1,
      'RB': 2,
      'WR': 3,
      'TE': 1,
      'FLEX': 1,
      'K': 1,
      'DEF': 1,
    };

    // Check if we need more players at this position
    return positionCount < (positionLimits[position] ?? 0);
  }

  void _makePick(FFDraftPick pick, FFPlayer player) {
    pickHistory.add(pick.copyWith());
    if (pick.isUserPick) {
      userPickHistory.add(pick.copyWith());
    }
    // Add player to the first available slot for their position
    final team = pick.team;
    int slotIndex = team.roster.indexWhere((p) => p.position == player.position && p.id.isEmpty);
    if (slotIndex == -1) {
      team.roster.add(player);
    } else {
      team.roster[slotIndex] = player;
    }
    // Remove player from available players
    availablePlayers.remove(player);
    // Mark pick as selected
    pick.selectedPlayer = player;
    // Move to next pick
    currentPickIndex++;
    // If next pick is user, trigger timer reset
    if (getCurrentPick()?.isUserPick == true && onUserPick != null) {
      onUserPick!();
    }
    // Update at-risk players
    _updateAtRiskPlayers();
    notifyListeners();
  }

  void _updateAtRiskPlayers() {
    // Get next 5 picks
    final nextPicks = draftPicks
        .where((pick) => !pick.isSelected && pick.pickNumber > (getCurrentPick()?.pickNumber ?? 0))
        .take(5)
        .toList();

    // Find players that might be taken in next 5 picks
    atRiskPlayers = availablePlayers
        .where((player) => player.stats?['rank'] != null)
        .toList()
      ..sort((a, b) {
        final rankA = a.stats?['rank'] ?? double.infinity;
        final rankB = b.stats?['rank'] ?? double.infinity;
        return rankA.compareTo(rankB);
      })
      ..take(5);
  }

  void handleTimeExpired() {
    final currentPick = getCurrentPick();
    if (currentPick != null) {
      handlePickSelection(currentPick);
    }
  }

  void handlePlayerSelection(FFPlayer player) {
    // Prevent drafting a player already on any roster
    if (teams.any((team) => team.roster.any((p) => p.id == player.id))) {
      return;
    }
    if (isUserTurn()) {
      userMakesPick(player);
    }
  }

  bool canDraftPlayer(FFPlayer player) {
    // Always allow user to pick any player
    final currentPick = getCurrentPick();
    if (currentPick == null) return false;
    if (currentPick.isUserPick) return true;
    // For AI, only block if all bench spots are filled
    // (AI logic for bench handled in _getBestAvailablePlayer)
    return true;
  }

  bool isUserTurn() {
    final currentPick = getCurrentPick();
    return currentPick != null && currentPick.isUserPick;
  }

  Future<void> startDraftSimulation() async {
    paused = false;
    while (!isUserTurn() && getCurrentPick() != null && !paused) {
      await Future.delayed(const Duration(milliseconds: 300));
      autoPickCurrent();
    }
    notifyListeners();
  }

  void pauseDraft() {
    paused = true;
    notifyListeners();
  }

  void autoPickCurrent() {
    if (paused) return;
    final currentPick = getCurrentPick();
    if (currentPick == null) return;
    if (!currentPick.isUserPick) {
      final bestPlayer = _getBestAvailablePlayer(currentPick.team);
      if (bestPlayer != null) {
        _makePick(currentPick, bestPlayer);
      } else {
        currentPickIndex++;
      }
    }
  }

  void userMakesPick(FFPlayer player) {
    final currentPick = getCurrentPick();
    if (currentPick == null || !currentPick.isUserPick) return;
    _makePick(currentPick, player);
    startDraftSimulation();
  }

  void undoLastPick() {
    // Ensure there's a user pick to undo
    if (userPickHistory.isEmpty) return;
    
    // Get the last user pick
    final lastUserPick = userPickHistory.last;
    
    // Find the index of the last user pick in the draft picks
    final lastUserPickIndex = draftPicks.indexWhere((pick) => 
      pick.pickNumber == lastUserPick.pickNumber);
    
    if (lastUserPickIndex == -1) return;
    
    // Undo the last user pick itself
    final userPick = draftPicks[lastUserPickIndex];
    if (userPick.selectedPlayer != null) {
      // Return the player to available players
      availablePlayers.insert(0, userPick.selectedPlayer!);
      
      // Reset the roster slot for this player
      final team = userPick.team;
      final rosterIndex = team.roster.indexWhere((p) => p.id == userPick.selectedPlayer!.id);
      if (rosterIndex != -1) {
        team.roster[rosterIndex] = FFPlayer.empty(position: userPick.selectedPlayer!.position);
      }
      
      // Clear the selected player from the draft pick
      userPick.selectedPlayer = null;
    }
    
    // Undo all picks after the last user pick
    for (int i = draftPicks.length - 1; i > lastUserPickIndex; i--) {
      final pick = draftPicks[i];
      
      // If the pick has a selected player
      if (pick.selectedPlayer != null) {
        // Return the player to available players
        availablePlayers.insert(0, pick.selectedPlayer!);
        
        // Reset the roster slot for this player
        final team = pick.team;
        final rosterIndex = team.roster.indexWhere((p) => p.id == pick.selectedPlayer!.id);
        if (rosterIndex != -1) {
          team.roster[rosterIndex] = FFPlayer.empty(position: pick.selectedPlayer!.position);
        }
        
        // Clear the selected player from the draft pick
        pick.selectedPlayer = null;
      }
    }
    
    // Reset current pick index to before the last user pick
    currentPickIndex = lastUserPickIndex;
    
    // Remove subsequent picks from history
    pickHistory.removeWhere((pick) => pick.pickNumber >= lastUserPick.pickNumber);
    userPickHistory.removeWhere((pick) => pick.pickNumber >= lastUserPick.pickNumber);
    
    // Sort available players back to original order
    availablePlayers.sort((a, b) {
      final rankA = a.stats?['rank'] ?? 9999;
      final rankB = b.stats?['rank'] ?? 9999;
      return rankA.compareTo(rankB);
    });
    
    // Update at-risk players
    _updateAtRiskPlayers();
    
    // Notify listeners of changes
    notifyListeners();
  }

  void toggleFavorite(FFPlayer player) {
    final idx = availablePlayers.indexWhere((p) => p.id == player.id);
    if (idx != -1) {
      final updated = availablePlayers[idx].copyWith(isFavorite: !availablePlayers[idx].isFavorite);
      availablePlayers[idx] = updated;
      if (updated.isFavorite) {
        if (!queuedPlayers.any((p) => p.id == player.id)) {
          queuedPlayers.add(updated);
        }
      } else {
        queuedPlayers.removeWhere((p) => p.id == player.id);
      }
      notifyListeners();
    }
  }
} 