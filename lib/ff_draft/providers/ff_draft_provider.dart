import 'package:flutter/foundation.dart';
import '../models/ff_draft_settings.dart';
import '../models/ff_team.dart';
import '../models/ff_player.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_ai_personality.dart';
import '../services/ff_draft_ai_service.dart';
// import '../services/ff_value_alert_service.dart'; // REMOVED - deleted service
import '../../services/fantasy/csv_rankings_service.dart';
import '../../models/fantasy/player_ranking.dart';

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
  final FFDraftAIService _aiService = FFDraftAIService();
  // final FFValueAlertService _alertService = FFValueAlertService(); // REMOVED

  FFDraftProvider({required this.settings, this.userPick});

  /// Get access to the value alert stream - SIMPLIFIED
  // Stream<ValueAlert> get alertStream => _alertService.alertStream; // REMOVED

  Future<void> initializeDraft() async {
    debugPrint('=== Starting FF Draft Initialization ===');
    
    // Determine user team index
    if (userPick != null && userPick! > 0 && userPick! <= settings.numTeams) {
      userTeamIndex = userPick! - 1;
    } else {
      userTeamIndex = (DateTime.now().millisecondsSinceEpoch % settings.numTeams);
    }
    debugPrint('User team index set to: $userTeamIndex');
    
    // Initialize teams with AI personalities - SIMPLIFIED
    const personalityTypes = FFAIPersonalityType.values;
    int aiPersonalityIndex = 0;
    
    teams = List.generate(
      settings.numTeams,
      (index) {
        if (index == userTeamIndex) {
          return FFTeam(
            id: 'team_$index',
            name: 'Your Team',
            roster: [],
            draftPosition: index + 1,
            isUserTeam: true,
          );
        } else {
          final personalityType = personalityTypes[aiPersonalityIndex % personalityTypes.length];
          final personality = FFAIPersonality.getPersonality(personalityType);
          aiPersonalityIndex++;
          return FFTeam.createAITeam(
            id: 'team_$index',
            name: '${personality.name} (Team ${index + 1})',
            draftPosition: index + 1,
            personality: personality,
          );
        }
      },
    );
    debugPrint('Created ${teams.length} teams');

    await _loadPlayers();
    debugPrint('Players loaded: ${availablePlayers.length}');
    
    draftPicks = _generateDraftPicks();
    debugPrint('Generated ${draftPicks.length} draft picks');
    
    final currentPick = getCurrentPick();
    debugPrint('Current pick: ${currentPick?.pickNumber} (Round ${currentPick?.round})');
    debugPrint('Is user turn: ${isUserTurn()}');
    
    debugPrint('=== FF Draft Initialization Complete ===');
    notifyListeners();
  }

  Future<void> _loadPlayers() async {
    debugPrint('Starting to load players...');
    try {
      final rankingsService = CSVRankingsService();
      debugPrint('Created CSV rankings service');
      
      final List<PlayerRanking> playerRankings = await rankingsService.fetchRankings();
      debugPrint('Fetched ${playerRankings.length} player rankings from CSV');

      if (playerRankings.isEmpty) {
        debugPrint('WARNING: No player rankings loaded from CSV!');
        // Create mock players if CSV loading fails
        availablePlayers = _createMockPlayers();
        debugPrint('Created ${availablePlayers.length} mock players as fallback');
        return;
      }

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

      debugPrint('Successfully loaded and sorted ${availablePlayers.length} players');
      
      // Debug: Print first few players
      if (availablePlayers.isNotEmpty) {
        debugPrint('Top 3 players: ${availablePlayers.take(3).map((p) => '${p.name} (${p.position})').join(', ')}');
      }
    } catch (e) {
      debugPrint('Error loading players: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Create mock players as fallback
      availablePlayers = _createMockPlayers();
      debugPrint('Created ${availablePlayers.length} mock players as fallback');
    }
  }

  List<FFPlayer> _createMockPlayers() {
    // Create a basic set of mock players for testing if CSV fails
    return [
      FFPlayer(
        id: '1',
        name: 'Christian McCaffrey',
        position: 'RB',
        team: 'SF',
        rank: 1,
        consensusRank: 1,
        byeWeek: '9',
        stats: {'rank': 1, 'adp': 1.2, 'projectedPoints': 280},
      ),
      FFPlayer(
        id: '2',
        name: 'Tyreek Hill',
        position: 'WR',
        team: 'MIA',
        rank: 2,
        consensusRank: 2,
        byeWeek: '6',
        stats: {'rank': 2, 'adp': 2.1, 'projectedPoints': 275},
      ),
      FFPlayer(
        id: '3',
        name: 'Josh Allen',
        position: 'QB',
        team: 'BUF',
        rank: 3,
        consensusRank: 3,
        byeWeek: '12',
        stats: {'rank': 3, 'adp': 3.5, 'projectedPoints': 270},
      ),
      FFPlayer(
        id: '4',
        name: 'Austin Ekeler',
        position: 'RB',
        team: 'WSH',
        rank: 4,
        consensusRank: 4,
        byeWeek: '14',
        stats: {'rank': 4, 'adp': 4.2, 'projectedPoints': 265},
      ),
      FFPlayer(
        id: '5',
        name: 'Stefon Diggs',
        position: 'WR',
        team: 'HOU',
        rank: 5,
        consensusRank: 5,
        byeWeek: '7',
        stats: {'rank': 5, 'adp': 5.1, 'projectedPoints': 260},
      ),
      // Add more positions for a complete draft
      ...List.generate(50, (index) {
        final positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'];
        final teams = ['KC', 'BUF', 'DAL', 'SF', 'PHI', 'MIA', 'CIN', 'BAL'];
        final pos = positions[index % positions.length];
        final team = teams[index % teams.length];
        
        return FFPlayer(
          id: '${index + 6}',
          name: 'Player ${index + 6}',
          position: pos,
          team: team,
          rank: index + 6,
          consensusRank: index + 6,
          byeWeek: '${(index % 14) + 1}',
          stats: {'rank': index + 6, 'adp': index + 6.0, 'projectedPoints': 255 - index},
        );
      }),
    ];
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

    // Use AI service for better decision making - SIMPLIFIED
    final selectedPlayer = FFDraftAIService.makeAIPick(
      team: pick.team,
      availablePlayers: availablePlayers,
      draftHistory: draftPicks,
      currentRound: pick.round,
      pickNumber: pick.pickNumber,
      personality: pick.team.aiPersonality,
    );

    _makePick(pick, selectedPlayer);
    
    // Log AI reasoning for debugging
    debugPrint('${pick.team.name} selected ${selectedPlayer.name}');
  }

  // Legacy method kept for compatibility - now delegates to AI service
  FFPlayer? _getBestAvailablePlayer(FFTeam team) {
    final currentPick = getCurrentPick();
    if (currentPick == null) return availablePlayers.isNotEmpty ? availablePlayers.first : null;

    return FFDraftAIService.makeAIPick(
      team: team,
      availablePlayers: availablePlayers,
      draftHistory: draftPicks,
      currentRound: currentPick.round,
      pickNumber: currentPick.pickNumber,
      personality: team.aiPersonality,
    );
  }


  void _makePick(FFDraftPick pick, FFPlayer player) {
    pickHistory.add(pick.copyWith());
    if (pick.isUserPick) {
      userPickHistory.add(pick.copyWith());
    }
    
    // Generate value alerts for this pick
    // _alertService.analyzePick( // REMOVED
    //   player: player, // REMOVED
    //   team: pick.team, // REMOVED
    //   pickNumber: pick.pickNumber, // REMOVED
    //   round: pick.round, // REMOVED
    //   remainingPlayers: availablePlayers, // REMOVED
    //   isUserTeam: pick.isUserPick, // REMOVED
    // ); // REMOVED
    
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
    
    // Generate opportunity alerts for next pick
    final nextPick = getCurrentPick();
    if (nextPick != null) {
      // _alertService.analyzeOpportunities( // REMOVED
      //   remainingPlayers: availablePlayers, // REMOVED
      //   currentRound: nextPick.round, // REMOVED
      //   currentPick: nextPick.pickNumber, // REMOVED
      //   userTeam: nextPick.isUserPick ? nextPick.team : null, // REMOVED
      // ); // REMOVED
    }
    
    // If next pick is user, trigger timer reset
    if (getCurrentPick()?.isUserPick == true && onUserPick != null) {
      onUserPick!();
    }
    // Update at-risk players
    _updateAtRiskPlayers();
    notifyListeners();
  }

  void _updateAtRiskPlayers() {
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

  // Get AI-powered recommendations for the user
  List<FFPlayer> getRecommendations({int count = 5}) {
    final currentPick = getCurrentPick();
    if (currentPick == null || !currentPick.isUserPick) return [];

    final userTeam = teams[userTeamIndex];
    
    return FFDraftAIService.getRecommendedPlayers(
      team: userTeam,
      availablePlayers: availablePlayers,
      currentRound: currentPick.round,
      count: count,
    );
  }

  // Get draft analysis for insights
  Map<String, dynamic> getDraftAnalysis() {
    final currentPick = getCurrentPick();
    if (currentPick == null) return {};

    return FFDraftAIService.getDraftContext(
      teams: teams,
      availablePlayers: availablePlayers,
      draftPicks: draftPicks,
      currentRound: currentPick.round,
    );
  }
} 