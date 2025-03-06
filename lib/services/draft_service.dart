// lib/services/draft_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';

/// Handles the logic for the draft simulation
class DraftService {
  final List<Player> availablePlayers;
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  
  // Draft settings
  final double randomnessFactor;
  final String? userTeam;
  final int numberRounds;
  
  // Internal state tracking
  bool _tradeUp = false;
  bool _qbTrade = false;
  String _statusMessage = "";
  int _currentPick = 0;
  
  // Random instance for introducing randomness
  final Random _random = Random();
  
  DraftService({
    required this.availablePlayers,
    required this.draftOrder,
    required this.teamNeeds,
    this.randomnessFactor = 0.5, // Default value
    this.userTeam,
    this.numberRounds = 1,
  }) {
    // Sort players by rank initially
    availablePlayers.sort((a, b) => a.rank.compareTo(b.rank));
  }
  
  /// Process a single draft pick using the specified strategy
  DraftPick processDraftPick() {
    // Find the next pick in the draft order
    DraftPick? nextPick = _getNextPick();
    
    if (nextPick == null) {
      throw Exception('No more picks available in the draft');
    }
    
    _currentPick = nextPick.pickNumber;
    _tradeUp = false;
    _qbTrade = false;
    
    // Check if this is a user team pick
    if (userTeam != null && nextPick.teamName == userTeam) {
      // User interaction would be handled by the UI, not directly in the service
      // For now, just make a selection based on the algorithm
      _statusMessage = "User's turn to pick";
    }
    
    // Find team needs for the team making the pick
    TeamNeed? teamNeed = _getTeamNeed(nextPick.teamName);
    
    // Select a player based on R algorithm
    Player selectedPlayer = _selectPlayerRStyle(teamNeed, nextPick);
    
    // Update the draft pick with the selected player
    nextPick.selectedPlayer = selectedPlayer;
    
    // Update team needs by removing the position that was just filled
    if (teamNeed != null) {
      teamNeed.removeNeed(selectedPlayer.position);
    }
    
    // Remove the player from available players
    availablePlayers.remove(selectedPlayer);
    
    // Set selection message
    _statusMessage = "Pick #${nextPick.pickNumber}: ${nextPick.teamName} selects ${selectedPlayer.name} (${selectedPlayer.position})";
    
    return nextPick;
  }
  
  /// Get the next available pick in the draft order
  DraftPick? _getNextPick() {
    for (var pick in draftOrder) {
      if (!pick.isSelected) {
        return pick;
      }
    }
    return null;
  }
  
  /// Get the team needs for a specific team
  TeamNeed? _getTeamNeed(String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      debugPrint('No team needs found for $teamName');
      return null;
    }
  }
  
  /// Select a player based on the R algorithm
  Player _selectPlayerRStyle(TeamNeed? teamNeed, DraftPick nextPick) {
    // If team has no needs defined, use best player available
    if (teamNeed == null || teamNeed.needs.isEmpty) {
      return _selectBestPlayerWithRandomness(availablePlayers);
    }
    
    // Following your R code pattern for selections
    List<Player?> selectionCandidates = [];
    
    // Calculate round based on pick number
    int round = (nextPick.pickNumber / 32).ceil();
    
    // Get needs based on round (more needs considered in later rounds)
    int needsToConsider = min(3 + round, teamNeed.needs.length);
    
    // Generate selections for each need
    for (int i = 0; i < needsToConsider; i++) {
      String? needPosition = i < teamNeed.needs.length ? teamNeed.needs[i] : null;
      
      if (needPosition != null && needPosition != "-") {
        selectionCandidates.add(_makeSelection(needPosition));
      } else {
        selectionCandidates.add(null);
      }
    }
    
    // Remove null entries
    selectionCandidates.removeWhere((player) => player == null);
    
    // If no candidates found through needs, use best player available
    if (selectionCandidates.isEmpty) {
      return _selectBestPlayerAvailable();
    }
    
    // Initialize with the first selection (need1)
    Player bestSelection = selectionCandidates[0]!;
    int selectedIndex = 0;
    
    // QB preference logic (from your R code)
    if (_qbTrade && bestSelection.position == "QB") {
      return bestSelection;
    }
    
    // Need 1 QB auto pick (high priority for QBs in first need)
    if (selectedIndex == 0 && 
        bestSelection.position == "QB" && 
        bestSelection.rank <= 2 * _getRandomAddValue() + 7 + nextPick.pickNumber) {
      return bestSelection;
    }
    
    // Variables for selection logic
    double randMult = _getRandomMultValue();
    double randAdd = _getRandomAddValue();
    int pickNum = nextPick.pickNumber;
    
    // Previous condition
    bool prevCondition = true;
    
    // Loop through candidates to find best selection
    for (int i = 0; i < selectionCandidates.length; i++) {
      Player candidate = selectionCandidates[i]!;
      
      // Calculate conditions similar to R code
      double factor = ((21 - i) / 20) * randMult;
      bool rankCondition = candidate.rank < pickNum + factor * pickNum + randAdd;
      
      if (i > 0 && rankCondition && prevCondition) {
        bestSelection = candidate;
        selectedIndex = i;
        prevCondition = false;
      } else if (i == 0) {
        prevCondition = bestSelection.rank > pickNum + factor * pickNum + randAdd;
      }
    }
    
    // If no selection made, use best player available that matches any team need
    if (prevCondition && selectionCandidates.length == needsToConsider) {
      return _selectBestPlayerForPosition(teamNeed.needs);
    }
    
    return bestSelection;
  }
  
  /// Make a selection for a specific need position (similar to make_selection in R)
  Player? _makeSelection(String needPosition) {
    // Filter players by position
    List<Player> candidatesForPosition = availablePlayers
        .where((player) => player.position.contains(needPosition))
        .toList();
    
    if (candidatesForPosition.isEmpty) {
      return null;
    }
    
    // Sort by rank
    candidatesForPosition.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Random selection logic from R code
    double randSelect = _tradeUp ? 0.1 : _random.nextDouble();
    int selectIndex;
    
    if (randSelect <= 0.8) {
      selectIndex = 0; // 80% chance for top player
    } else if (randSelect > 0.8 && randSelect <= 0.95) {
      selectIndex = min(1, candidatesForPosition.length - 1); // 15% for second
    } else {
      selectIndex = min(2, candidatesForPosition.length - 1); // 5% for third
    }
    
    return candidatesForPosition[selectIndex];
  }
  
  /// Select the best player available from all available players
  Player _selectBestPlayerAvailable() {
    // Random selection with bias toward top players
    double randSelect = _random.nextDouble();
    int selectIndex;
    
    if (randSelect <= 0.75) {
      selectIndex = 0; // 75% chance for top player
    } else if (randSelect > 0.75 && randSelect <= 0.95) {
      selectIndex = min(1, availablePlayers.length - 1); // 20% for second
    } else {
      selectIndex = min(2, availablePlayers.length - 1); // 5% for third
    }
    
    return availablePlayers[selectIndex];
  }
  
  /// Select best player that matches any of the given positions
  Player _selectBestPlayerForPosition(List<String> positions) {
    // Filter players by any matching position
    List<Player> candidatesForPositions = availablePlayers
        .where((player) => positions.contains(player.position))
        .toList();
    
    // If no matches, fall back to best overall
    if (candidatesForPositions.isEmpty) {
      return _selectBestPlayerAvailable();
    }
    
    // Sort by rank
    candidatesForPositions.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Random selection logic
    double randSelect = _random.nextDouble();
    int selectIndex;
    
    if (randSelect <= 0.75) {
      selectIndex = 0; // 75% chance for top player
    } else if (randSelect > 0.75 && randSelect <= 0.95) {
      selectIndex = min(1, candidatesForPositions.length - 1); // 20% for second
    } else {
      selectIndex = min(2, candidatesForPositions.length - 1); // 5% for third
    }
    
    return candidatesForPositions[selectIndex];
  }
  
  /// Select the best player with some randomness factor applied
  Player _selectBestPlayerWithRandomness(List<Player> players) {
    if (players.isEmpty) {
      throw Exception('No players available for selection');
    }
    
    // Sort players by rank (assuming lower rank number is better)
    players.sort((a, b) => a.rank.compareTo(b.rank));
    
    // With no randomness, just return the top player
    if (randomnessFactor <= 0.0) {
      return players.first;
    }
    
    // Calculate how many players to consider in the pool
    // More randomness = larger pool of players that could be selected
    int poolSize = max(1, (players.length * randomnessFactor).round());
    poolSize = min(poolSize, players.length); // Don't exceed list length
    
    // Select a random player from the top poolSize players
    int randomIndex = _random.nextInt(poolSize);
    return players[randomIndex];
  }
  
  // Randomization helper functions from your R code
  double _getRandomAddValue() {
    return _random.nextDouble() * 10 - 4; // Range from -4 to 6
  }
  
  double _getRandomMultValue() {
    return _random.nextDouble() * 0.3 + 0.01; // Range from 0.01 to 0.3
  }
  
  double _getRandomTradeValue() {
    return _random.nextDouble(); // Range from 0 to 1
  }
  
  // Getters for state information
  String get statusMessage => _statusMessage;
  int get currentPick => _currentPick;
  int get completedPicksCount => draftOrder.where((pick) => pick.isSelected).length;
  int get totalPicksCount => draftOrder.length;
  bool isDraftComplete() {
    return draftOrder.every((pick) => pick.isSelected);
  }

  // Future enhancement: Implement trade logic modeled after the R code
  // This would include:
  // - QBTradeLogic
  // - GeneralTradeLogic
  // - UserTradeInteraction
}