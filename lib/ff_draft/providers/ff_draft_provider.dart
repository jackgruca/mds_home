import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/ff_draft_settings.dart';
import '../models/ff_team.dart';
import '../models/ff_player.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_platform_ranks.dart';

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
    await _loadPlayersFromCSV();
    draftPicks = _generateDraftPicks();
    notifyListeners();
  }

  Future<void> _loadPlayersFromCSV() async {
    try {
      final rawData = await rootBundle.loadString('assets/2025/FF_ranks.csv');
      final List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      if (listData.isEmpty) return;
      final header = listData.first;
      final nameIdx = header.indexOf('Name');
      final posIdx = header.indexOf('Position');
      final espnIdx = header.indexOf('ESPN Rank');
      final fpIdx = header.indexOf('FantasyPro Rank');
      final cbsIdx = header.indexOf('CBS Rank');
      final consensusIdx = header.indexOf('Consensus');
      final consensusRankIdx = header.indexOf('Consensus Rank');

      availablePlayers = listData.skip(1).where((row) => row.length > consensusRankIdx).map((row) {
        final name = row[nameIdx].toString();
        final position = row[posIdx].toString();
        final espnRank = int.tryParse(row[espnIdx].toString()) ?? 0;
        final fpRank = int.tryParse(row[fpIdx].toString()) ?? 0;
        final cbsRank = int.tryParse(row[cbsIdx].toString()) ?? 0;
        final consensus = double.tryParse(row[consensusIdx].toString()) ?? 0.0;
        final consensusRank = int.tryParse(row[consensusRankIdx].toString()) ?? 0;
        return FFPlayer(
          id: name,
          name: name,
          position: position,
          team: '',
          stats: {
            'espnRank': espnRank,
            'fpRank': fpRank,
            'cbsRank': cbsRank,
            'consensus': consensus,
            'rank': consensusRank,
          },
          rank: consensusRank,
          platformRanks: {
            'ESPN': espnRank,
            'FantasyPro': fpRank,
            'CBS': cbsRank,
          },
          consensusRank: consensusRank,
        );
      }).toList();

      availablePlayers.sort((a, b) {
        final rankA = a.rank ?? 9999;
        final rankB = b.rank ?? 9999;
        return rankA.compareTo(rankB);
      });
      debugPrint('Loaded [32m${availablePlayers.length}[0m players from CSV');
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
    // Sort available players by rank
    availablePlayers.sort((a, b) {
      final rankA = a.stats?['rank'] ?? double.infinity;
      final rankB = b.stats?['rank'] ?? double.infinity;
      return rankA.compareTo(rankB);
    });

    // Find first player that fills a need
    for (final player in availablePlayers) {
      if (_isPositionNeeded(team, player.position)) {
        return player;
      }
    }

    // If no position is needed, take best available
    return availablePlayers.isNotEmpty ? availablePlayers.first : null;
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
    if (isUserTurn()) {
      userMakesPick(player);
    }
  }

  bool canDraftPlayer(FFPlayer player) {
    final currentPick = getCurrentPick();
    if (currentPick == null || !currentPick.isUserPick) return false;

    // Check if we need this position
    return _isPositionNeeded(currentPick.team, player.position);
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
    if (pickHistory.isEmpty) return;
    final lastPick = pickHistory.removeLast();
    // Remove player from team roster
    if (lastPick.selectedPlayer != null) {
      lastPick.team.roster.removeWhere((p) => p.id == lastPick.selectedPlayer!.id);
      availablePlayers.insert(0, lastPick.selectedPlayer!);
    }
    // Move back pick index
    currentPickIndex = lastPick.pickNumber - 1;
    draftPicks[currentPickIndex].selectedPlayer = null;
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