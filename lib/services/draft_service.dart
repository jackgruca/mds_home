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
  
  // Random instance for introducing randomness
  final Random _random = Random();
  
  DraftService({
    required this.availablePlayers,
    required this.draftOrder,
    required this.teamNeeds,
    this.randomnessFactor = 0.5, // Default value
  });
  
  /// Process a single draft pick using the specified strategy
  DraftPick processDraftPick() {
    // Find the next pick in the draft order
    DraftPick? nextPick = _getNextPick();
    
    if (nextPick == null) {
      throw Exception('No more picks available in the draft');
    }
    
    // Find team needs for the team making the pick
    TeamNeed? teamNeed = _getTeamNeed(nextPick.teamName);
    
    // Select a player based on team needs and strategy
    Player selectedPlayer = _selectPlayer(teamNeed);
    
    // Update the draft pick with the selected player
    nextPick.selectedPlayer = selectedPlayer;
    
    // Update team needs by removing the position that was just filled
    if (teamNeed != null) {
      teamNeed.removeNeed(selectedPlayer.position);
    }
    
    // Remove the player from available players
    availablePlayers.remove(selectedPlayer);
    
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
  
  /// Select a player based on team needs and strategy
  Player _selectPlayer(TeamNeed? teamNeed) {
    // Strategy 1: Draft for primary need if available
    if (teamNeed != null && teamNeed.needs.isNotEmpty) {
      String primaryNeed = teamNeed.needs.first;
      
      // Find players at the primary need position
      List<Player> candidatePlayers = availablePlayers
          .where((player) => player.position == primaryNeed)
          .toList();
      
      // If we found players with the primary need position, select the best one
      if (candidatePlayers.isNotEmpty) {
        return _selectBestPlayerWithRandomness(candidatePlayers);
      }
    }
    
    // Strategy 2: Draft best player available
    return _selectBestPlayerWithRandomness(availablePlayers);
  }
  
  /// Select the best player with some randomness factor applied
  Player _selectBestPlayerWithRandomness(List<Player> players) {
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
  
  /// Check if the draft is complete
  bool isDraftComplete() {
    return draftOrder.every((pick) => pick.isSelected);
  }
  
  /// Calculate the number of picks completed
  int completedPicksCount() {
    return draftOrder.where((pick) => pick.isSelected).length;
  }
  
  /// Get the total number of picks in the draft
  int totalPicksCount() {
    return draftOrder.length;
  }
}