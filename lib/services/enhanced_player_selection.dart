// lib/services/enhanced_player_selection.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';

/// Enhanced player selection logic that incorporates more realistic draft behavior
class EnhancedPlayerSelection {
  final Random _random = Random();
  
  // Position tiers based on NFL draft data
  final Map<String, double> _positionPremium = {
    'QB': 1.3,     // Premium for QBs - highest value
    'OT': 1.2,     // Premium tackles
    'EDGE': 1.2,   // Edge rushers
    'CB': 1.15,    // Cornerbacks
    'WR': 1.1,     // Wide receivers
    'S': 1.05,     // Safeties
    'IOL': 0.9,    // Interior offensive line
    'RB': 0.85,    // Running backs - typically devalued 
    'LB': 0.95,    // Linebackers
    'TE': 0.95,    // Tight ends
    'IDL': 0.95,   // Interior defensive line
    // Default value of 1.0 for any other position
  };
  
  // Team archetypes for more varied strategies
  final Map<String, String> _teamArchetypes = {
    // Example archetypes - could be expanded
    'BAL': 'balanced',
    'BUF': 'offense_focused',
    'KC': 'quarterback_driven',
    'SF': 'defense_focused',
    'NE': 'value_driven',
    'PIT': 'defense_focused',
    'DAL': 'balanced',
    // More teams could be added with different strategies
  };
  
  // Historical tendencies of teams to select certain positions
  final Map<String, Map<String, double>> _teamPositionalTendencies = {
    // Example: Baltimore Ravens tend to value LBs and DBs more
    'BAL': {'LB': 1.2, 'CB': 1.15, 'S': 1.1, 'RB': 0.9},
    // Example: Kansas City Chiefs emphasize offensive positions
    'KC': {'WR': 1.15, 'OT': 1.1, 'TE': 1.1, 'IOL': 1.05, 'IDL': 0.9},
    // Buffalo Bills tendencies
    'BUF': {'QB': 1.2, 'WR': 1.15, 'CB': 1.1, 'S': 1.05},
    // San Francisco 49ers tendencies
    'SF': {'EDGE': 1.2, 'CB': 1.15, 'OT': 1.1, 'RB': 1.05},
    // Add more teams as needed
  };
  
  // Cache for player grades to avoid recalculating
  final Map<String, Map<int, double>> _teamPlayerGradeCache = {};
  
  /// Calculate a team-specific grade for a player
  /// Returns a value where higher means the team values the player more
  double calculatePlayerGrade(Player player, String teamName, TeamNeed? teamNeed, int pickNumber) {
    // Check cache first
    if (_teamPlayerGradeCache.containsKey(teamName) && 
        _teamPlayerGradeCache[teamName]!.containsKey(player.id)) {
      return _teamPlayerGradeCache[teamName]![player.id]!;
    }
    
    // Base grade is inverse of rank (lower rank = higher grade)
    double baseGrade = 100.0 - player.rank;
    
    // Adjust for how much this player exceeds/falls below expected value at this pick
    double pickValueAdjustment = (pickNumber - player.rank) * 0.5;
    if (pickValueAdjustment > 0) {
      // Value pick - player ranked better than current pick
      baseGrade += pickValueAdjustment; 
    } else {
      // Reach pick - penalize but less severely
      baseGrade += pickValueAdjustment * 0.5;
    }
    
    // Position premium adjustment
    double positionFactor = _positionPremium[player.position] ?? 1.0;
    baseGrade *= positionFactor;
    
    // Team positional tendency adjustment
    if (_teamPositionalTendencies.containsKey(teamName) && 
        _teamPositionalTendencies[teamName]!.containsKey(player.position)) {
      baseGrade *= _teamPositionalTendencies[teamName]![player.position]!;
    }
    
    // Team need adjustment
    if (teamNeed != null) {
      int needIndex = teamNeed.needs.indexOf(player.position);
      if (needIndex != -1) {
        // Higher bonus for higher need positions
        double needBonus = (10 - min(needIndex, 9)) / 10.0;
        baseGrade *= (1 + needBonus * 0.3); // Up to 30% boost for top need
      }
    }
    
    // Team archetype adjustment
    String teamArchetype = _teamArchetypes[teamName] ?? 'balanced';
    if (teamArchetype == 'offense_focused' && 
        ['QB', 'RB', 'WR', 'TE', 'OT', 'IOL'].contains(player.position)) {
      baseGrade *= 1.1; // 10% boost for offensive positions
    } else if (teamArchetype == 'defense_focused' && 
        ['EDGE', 'IDL', 'LB', 'CB', 'S'].contains(player.position)) {
      baseGrade *= 1.1; // 10% boost for defensive positions
    } else if (teamArchetype == 'quarterback_driven' && player.position == 'QB') {
      baseGrade *= 1.3; // 30% boost for QBs
    } else if (teamArchetype == 'value_driven') {
      // Value-driven teams emphasize BPA more strongly
      if (pickValueAdjustment > 0) {
        baseGrade += pickValueAdjustment * 0.3; // Additional boost for value picks
      }
    }
    
    // Early round QB premium - teams reach for QBs early
    if (player.position == 'QB' && pickNumber <= 15 && player.rank <= 20) {
      baseGrade *= 1.2; // 20% boost for potential franchise QBs
    }
    
    // Add some controlled randomness (±10%)
    double randomFactor = 0.9 + (_random.nextDouble() * 0.2);
    baseGrade *= randomFactor;
    
    // Store in cache
    _teamPlayerGradeCache.putIfAbsent(teamName, () => {});
    _teamPlayerGradeCache[teamName]![player.id] = baseGrade;
    
    return baseGrade;
  }
  
  /// Select the best player for a team at this pick
  Player selectBestPlayer(
    List<Player> availablePlayers, 
    String teamName, 
    TeamNeed? teamNeed, 
    int pickNumber,
    {double randomnessFactor = 0.5}
  ) {
    if (availablePlayers.isEmpty) {
      throw Exception('No players available for selection');
    }
    
    // Calculate grades for all available players
    Map<Player, double> playerGrades = {};
    for (var player in availablePlayers) {
      playerGrades[player] = calculatePlayerGrade(
        player, 
        teamName, 
        teamNeed, 
        pickNumber
      );
    }
    
    // Sort players by grade (highest first)
    List<Player> gradedPlayers = playerGrades.keys.toList()
      ..sort((a, b) => playerGrades[b]!.compareTo(playerGrades[a]!));
    
    // Adjust randomness factor based on pick position
    double effectiveRandomness = randomnessFactor;
    if (pickNumber <= 3) {
      // First 3 picks are highly predictable
      effectiveRandomness *= 0.2;
    } else if (pickNumber <= 10) {
      // Top 10 picks are somewhat predictable
      effectiveRandomness *= 0.5;
    } else if (pickNumber <= 32) {
      // First round has reduced randomness
      effectiveRandomness *= 0.75;
    }
    
    // Calculate the pool size of players to consider
    int poolSize = max(1, (gradedPlayers.length * effectiveRandomness).round());
    poolSize = min(poolSize, gradedPlayers.length);
    
    // For top picks, further restrict the pool
    if (pickNumber <= 5) {
      poolSize = min(3, poolSize);
    }
    
    // Log the top candidates for debugging
    debugPrint('Pick #$pickNumber - $teamName considering:');
    for (int i = 0; i < min(poolSize, 5); i++) {
      Player candidate = gradedPlayers[i];
      debugPrint('  [${i+1}] ${candidate.name} (${candidate.position}) - '
                 'Rank: ${candidate.rank}, Grade: ${playerGrades[candidate]!.toStringAsFixed(1)}');
    }
    
    // Select a player from the top candidates with weighted probability
    if (poolSize == 1 || pickNumber <= 3) {
      // For very top picks, just take the top graded player
      return gradedPlayers.first;
    } else {
      // Create a weighted random selection that favors higher-graded players
      List<Player> pool = gradedPlayers.sublist(0, poolSize);
      List<double> weights = [];
      
      for (int i = 0; i < pool.length; i++) {
        // Weight decreases exponentially as we go down the list
        weights.add(pow(0.7, i).toDouble());
      }
      
      // Normalize weights to sum to 1.0
      double sumWeights = weights.fold(0.0, (sum, weight) => sum + weight);
      for (int i = 0; i < weights.length; i++) {
        weights[i] /= sumWeights;
      }
      
      // Cumulative distribution function for selection
      List<double> cdf = [];
      double cumSum = 0.0;
      for (double weight in weights) {
        cumSum += weight;
        cdf.add(cumSum);
      }
      
      // Random selection using CDF
      double rand = _random.nextDouble();
      for (int i = 0; i < cdf.length; i++) {
        if (rand <= cdf[i]) {
          return pool[i];
        }
      }
      
      // Fallback to top player (should rarely happen)
      return pool.first;
    }
  }
  
  /// Check if a player is a significant value at this pick
  bool isSignificantValue(Player player, int pickNumber) {
    // A player is a significant value if they're ranked much higher than the current pick
    return player.rank <= pickNumber - 10;
  }
  
  /// Analyze the selection of a player
  Map<String, dynamic> analyzeSelection(Player player, String teamName, int pickNumber, TeamNeed? teamNeed) {
    bool isNeed = teamNeed != null && teamNeed.isPositionANeed(player.position);
    bool isValue = player.rank < pickNumber;
    bool isSignificantValuePick = isSignificantValue(player, pickNumber);
    bool isReach = player.rank > pickNumber + 10;
    
    int valueGap = pickNumber - player.rank;
    String analysisText;
    
    if (isSignificantValuePick && isNeed) {
      analysisText = 'Excellent value pick that fills a team need';
    } else if (isSignificantValuePick) {
      analysisText = 'Great value selection - player ranked much higher than this pick';
    } else if (isValue && isNeed) {
      analysisText = 'Solid pick - good value that addresses a team need';
    } else if (isValue) {
      analysisText = 'Good value selection at this pick';
    } else if (isNeed && isReach) {
      analysisText = 'Reach for a needed position - selected much earlier than rank suggests';
    } else if (isNeed) {
      analysisText = 'Addresses a team need, though not a great value';
    } else if (isReach) {
      analysisText = 'Significant reach - selected much earlier than rank suggests';
    } else {
      analysisText = 'Standard pick - reasonable selection at this position';
    }
    
    return {
      'isNeed': isNeed,
      'isValue': isValue,
      'isSignificantValue': isSignificantValuePick,
      'isReach': isReach,
      'valueGap': valueGap,
      'analysis': analysisText,
    };
  }
}