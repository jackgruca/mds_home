import 'package:flutter/material.dart';
import '../models/ff_player.dart';

class FFDraftService {
  // Draft settings
  final int numTeams;
  final String scoringSystem;
  final String platform;
  final int rosterSize;
  
  // Draft state
  List<FFPlayer> availablePlayers = [];
  List<FFPlayer> draftedPlayers = [];
  int currentPick = 0;
  int currentRound = 1;
  int currentTeam = 0;
  
  FFDraftService({
    required this.numTeams,
    required this.scoringSystem,
    required this.platform,
    required this.rosterSize,
  });

  // Initialize draft with players
  Future<void> initializeDraft() async {
    // TODO: Load players from data source
    // For now, using dummy data
    availablePlayers = [
      FFPlayer(
        id: '1',
        name: 'Christian McCaffrey',
        position: 'RB',
        team: 'SF',
        rank: 1,
        platformRanks: {'ESPN': 1, 'Yahoo': 1, 'Sleeper': 1},
        consensusRank: 1,
        stats: {'rushingYards': 1459, 'rushingTDs': 14, 'receptions': 67},
      ),
      // Add more dummy players here
    ];
  }

  // Get next pick
  FFPlayer? getNextPick() {
    if (availablePlayers.isEmpty) return null;
    return availablePlayers.first;
  }

  // Make a pick
  void makePick(FFPlayer player) {
    if (!availablePlayers.contains(player)) {
      throw Exception('Player not available');
    }
    
    availablePlayers.remove(player);
    draftedPlayers.add(player);
    
    // Update draft state
    currentPick++;
    currentTeam = (currentTeam + 1) % numTeams;
    if (currentTeam == 0) {
      currentRound++;
    }
  }

  // Get available players by position
  List<FFPlayer> getPlayersByPosition(String position) {
    return availablePlayers.where((p) => p.position == position).toList();
  }

  // Get players with significant rank differences
  List<FFPlayer> getPlayersWithRankDifferences({int minDifference = 5}) {
    return availablePlayers.where((p) {
      final diff = p.getRankDifference(platform);
      return diff.abs() >= minDifference;
    }).toList();
  }
} 