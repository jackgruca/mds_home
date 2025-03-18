// lib/services/draft_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mds_home/screens/draft_overview_screen.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import '../models/future_pick.dart';
import 'trade_service.dart';
import 'draft_value_service.dart';

/// Handles the logic for the draft simulation with enhanced trade integration
class DraftService {
  final List<Player> availablePlayers;
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  
  // Draft settings
  final double randomnessFactor;
  final List<String>? userTeams;
  final int numberRounds;
  
  // Trade service
  late TradeService _tradeService;
  
  // Draft state tracking
  bool _tradeUp = false;
  bool _qbTrade = false;
  String _statusMessage = "";
  int _currentPick = 0;
  final List<TradePackage> _executedTrades = [];
  final Set<String> _executedTradeIds = {};
  
  // Trade frequency calibration
  final bool enableTrading;
  final bool enableUserTradeProposals;
  final bool enableQBPremium;
  
  // Improved trade offer tracking for user
  final Map<int, List<TradePackage>> _pendingUserOffers = {};
  
  // Track draft progress to adjust trade frequency
  int _completedPicks = 0;
  
  // Trade frequency settings
  final Map<int, double> _roundTradeFrequency = {
    1: 0.25,  // 25% chance of trade evaluation for round 1 picks 
    2: 0.22,  // 22% chance for round 2
    3: 0.18,  // 18% chance for round 3
    4: 0.15,  // 15% chance for round 4
    5: 0.12,  // 12% chance for round 5
    6: 0.10,  // 10% chance for round 6
    7: 0.08,  // 8% chance for round 7
  };
  
  // Random instance for introducing randomness
  final Random _random = Random();

  DraftService({
    required this.availablePlayers,
    required this.draftOrder,
    required this.teamNeeds,
    this.randomnessFactor = 0.4,
    this.userTeams,
    this.numberRounds = 1, 
    this.enableTrading = true,
    this.enableUserTradeProposals = true,
    this.enableQBPremium = true,
  }) {
    // Sort players by rank initially
    availablePlayers.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Initialize the enhanced trade service
    _tradeService = TradeService(
      draftOrder: draftOrder,
      teamNeeds: teamNeeds,
      availablePlayers: availablePlayers,
      userTeam: userTeams?.isNotEmpty == true ? userTeams!.first : null,  // Extract first team or null
      tradeRandomnessFactor: randomnessFactor,
      enableQBPremium: enableQBPremium,
    );
  }

// Also update the getOtherTeamPicks method to handle list of teams
List<DraftPick> getOtherTeamPicks(List<String>? excludeTeams) {
  if (excludeTeams == null || excludeTeams.isEmpty) {
    // If no teams to exclude, return all picks
    return draftOrder.where((pick) => 
      !pick.isSelected
    ).toList();
  }
  
  // Include ALL picks for trading, not just active ones, excluding the teams in the list
  return draftOrder.where((pick) => 
    !excludeTeams.contains(pick.teamName) && !pick.isSelected
  ).toList();
}
  
  /// Update simulation state after player selection
  void _updateAfterSelection(DraftPick pick, Player player) {
    // Update team needs by removing the position that was just filled
    TeamNeed? teamNeed = _getTeamNeeds(pick.teamName);
    if (teamNeed != null) {
      teamNeed.removeNeed(player.position);
    }
    
    // Remove player from available players
    availablePlayers.remove(player);
    
    // Update trade service with selection
    _tradeService.recordPlayerSelection(player);
    
    // Track completed picks
    _completedPicks++;
    
    // Set status message
    _statusMessage = "Pick #${pick.pickNumber}: ${pick.teamName} selects ${player.name} (${player.position})";
  }
  
  /// Generate trade offers for user team pick
  void _generateUserTradeOffers(DraftPick userPick) {
    // Generate realistic offers using trade service
    TradeOffer tradeOffers = _tradeService.generateTradeOffersForPick(userPick.pickNumber);
    
    // Store the offers for the user to consider
    if (tradeOffers.packages.isNotEmpty) {
      _pendingUserOffers[userPick.pickNumber] = tradeOffers.packages;
    } else {
      _pendingUserOffers.remove(userPick.pickNumber);
    }
  }

  /// Clean up stale trade offers for picks that have already been handled
  void cleanupTradeOffers() {
    // Get all selected picks
    final selectedPickNumbers = draftOrder
        .where((pick) => pick.isSelected || !pick.isActiveInDraft)
        .map((pick) => pick.pickNumber)
        .toSet();
    
    // Remove any pending offers for picks that have already been handled
    _pendingUserOffers.removeWhere((pickNumber, _) => 
      selectedPickNumbers.contains(pickNumber)
    );

    debugPrint('Cleaned up trade offers: ${_pendingUserOffers.length} offers remaining');
  }

  /// Add this helper to check for offers for the current pick
  bool hasOffersForCurrentPick() {
    DraftPick? nextPick = getNextPick();
    if (nextPick == null) {
      return false;
    }
    
    return hasOffersForPick(nextPick.pickNumber);
  }

  // Modify the getTradeOffersForCurrentPick method to filter out invalid offers
  TradeOffer getTradeOffersForCurrentPick() {
    DraftPick? nextPick = _getNextPick();
    if (nextPick == null) {
      return const TradeOffer(packages: [], pickNumber: 0);
    }
    
    // First clean up any stale offers
    cleanupTradeOffers();
    
    // Then generate new trade offers
    return _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
  }

  // Modify the processDraftPick method to clean up offers after a pick
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
    if (userTeams != null && userTeams!.contains(nextPick.teamName)) {
      // Generate trade offers for the user to consider
      _generateUserTradeOffers(nextPick);
      
      // Return without making a selection - user will choose
      _statusMessage = "Your turn to pick or trade for pick #${nextPick.pickNumber}";
      return nextPick;
    }
    
    // If trading is disabled, skip trade evaluation
    if (!enableTrading) {
      // Select player using algorithm
      Player selectedPlayer = _selectBestPlayerForTeam(nextPick);
      nextPick.selectedPlayer = selectedPlayer;
      
      // Update simulation state
      _updateAfterSelection(nextPick, selectedPlayer);
      
      // Clean up any stale trade offers
      cleanupTradeOffers();
      
      return nextPick;
    }
    
    // Evaluate potential trades with calibrated frequency
    TradePackage? executedTrade = _evaluateTrades(nextPick);
    
    // If a trade was executed, return the updated pick
    if (executedTrade != null) {
      _tradeUp = true;
      _statusMessage = "Trade executed: ${executedTrade.tradeDescription}";
      
      // Clean up any stale trade offers
      cleanupTradeOffers();
      
      return nextPick;
    }
    
    // No trade - select a player
    Player selectedPlayer = _selectBestPlayerForTeam(nextPick);
    nextPick.selectedPlayer = selectedPlayer;
    
    // Update simulation state
    _updateAfterSelection(nextPick, selectedPlayer);
    
    // Clean up any stale trade offers
    cleanupTradeOffers();
    
    return nextPick;
  }
  
  /// Evaluate potential trades for the current pick with realistic behavior
TradePackage? _evaluateTrades(DraftPick nextPick) {
  // Skip if already has trade info or is a user team pick
  if (nextPick.tradeInfo != null && nextPick.tradeInfo!.isNotEmpty) {
    return null;
  }

  // Get team needs
  TeamNeed? teamNeeds = _getTeamNeeds(nextPick.teamName);
  
  // Check for QB needs within relevant threshold (round+3)
  int round = DraftValueService.getRoundForPick(nextPick.pickNumber);
  int needsToConsider = min(round + 3, teamNeeds?.needs.length ?? 0);
  
  // Check if QB is within the needs to consider
  bool teamNeedsQB = false;
  for (int i = 0; i < needsToConsider; i++) {
    if (teamNeeds != null && i < teamNeeds.needs.length && teamNeeds.needs[i] == "QB") {
      teamNeedsQB = true;
      break;
    }
  }
  
  if (teamNeedsQB) {
    // Check for valuable QBs available
    bool valuableQBAvailable = availablePlayers
        .any((p) => p.position == "QB" && p.rank <= nextPick.pickNumber + 15);
    
    if (valuableQBAvailable) {
      // 98% chance to stay and draft the QB
      if (_random.nextDouble() < 0.98) {
        return null;
      }
    }
  }

    double tradeChance = _roundTradeFrequency[round] ?? 0.10;
    
    // Calibrated randomness to determine if we evaluate trades
    bool evaluateTrades = _random.nextDouble() < tradeChance;
    
    // If we decide not to evaluate trades, skip
    if (!evaluateTrades && !_qbTrade) {
      return null;
    }
    
    // Enhanced QB trade logic - more aggressive for top QB prospects
    bool tryQBTrade = _evaluateQBTradeScenario(nextPick);
    if (tryQBTrade) {
      final qbTradeOffer = _tradeService.generateTradeOffersForPick(
        nextPick.pickNumber, 
        qbSpecific: true
      );
      
      if (qbTradeOffer.packages.isNotEmpty) {
        final bestPackage = qbTradeOffer.bestPackage;
        if (bestPackage != null) {
          _qbTrade = true;
          _executeTrade(bestPackage);
          return bestPackage;
        }
      }
    }
    
    // Regular trade evaluation
    final tradeOffer = _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
    
    // Don't automatically execute user-involved trades
    if (tradeOffer.isUserInvolved) {
      return null;
    }
    
    // If we have offers, find the best one that meets criteria
    if (tradeOffer.packages.isNotEmpty) {
      // Sort packages by value differential
      List<TradePackage> viablePackages = List.from(tradeOffer.packages);
      
      for (var package in viablePackages) {
        _executeTrade(package);
        return package;  // Execute first viable trade
      }
    }
    
    return null;
  }
  
  /// Evaluate if we should try a QB-specific trade scenario
bool _evaluateQBTradeScenario(DraftPick nextPick) {
  // Skip QB trade logic for user team picks
  if (userTeams != null && userTeams!.contains(nextPick.teamName)) return false;
  
  // Get team needs for the team with the current pick
  TeamNeed? teamNeeds = _getTeamNeeds(nextPick.teamName);
  
  // Check if QB is a need within the relevant threshold (round+3)
  int round = DraftValueService.getRoundForPick(nextPick.pickNumber);
  int needsToConsider = min(round + 3, teamNeeds?.needs.length ?? 0);
  
  bool currentTeamNeedsQB = false;
  for (int i = 0; i < needsToConsider; i++) {
    if (teamNeeds != null && i < teamNeeds.needs.length && teamNeeds.needs[i] == "QB") {
      currentTeamNeedsQB = true;
      break;
    }
  }
  
  // If team with the pick needs a QB, they likely won't trade out
  // for a QB-motivated trade (but might trade for other reasons)
  if (currentTeamNeedsQB && nextPick.pickNumber <= 20) {
    return false;
  }
  
  // Check for available QB prospects in the top 32
  final availableQBs = availablePlayers
      .where((p) => p.position == "QB" && p.rank <= 32)
      .toList();
  
  if (availableQBs.isEmpty) return false;
  
  // For other teams, we need to check if there are QB-needy teams that might trade up
  // We'll use a simpler approach here since we don't have direct access to _teamCurrentPickPosition
  
  // Count how many teams need a QB as one of their top needs
  int qbNeedyTeamsCount = 0;
  
  for (var team in this.teamNeeds) {
    // Only consider where QB is in their top needs 
    int qbIndex = team.needs.indexOf("QB");
    if (qbIndex >= 0 && qbIndex < 3) { // QB is in top 3 needs
      qbNeedyTeamsCount++;
    }
  }
  
  // If multiple teams need a QB, trade ups become more likely
  double qbMarketFactor = min(1.0, qbNeedyTeamsCount / 5.0); // Scale factor based on QB demand
  
  // High probabilities for QB trades when top QBs are available
  if (nextPick.pickNumber <= 10) {
    // Very high chance in top 10 with top QB
    bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 10);
    double qbTradeProb = (topQBAvailable ? 0.9 : 0.7) * qbMarketFactor;
    return _random.nextDouble() < qbTradeProb;
  } 
  else if (nextPick.pickNumber <= 32) {
    // Moderate chance in first round
    bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 20);
    double qbTradeProb = (topQBAvailable ? 0.8 : 0.5) * qbMarketFactor;
    return _random.nextDouble() < qbTradeProb;
  }
  else if (nextPick.pickNumber <= 45) {
    // Lower chance early in second round
    double qbTradeProb = 0.4 * qbMarketFactor;
    return _random.nextDouble() < qbTradeProb;
  }
  
  // Very low chance in later rounds
  return _random.nextDouble() < (0.15 * qbMarketFactor);
}
  
  /// Execute a trade by swapping teams for picks
  void _executeTrade(TradePackage package) {
    // Create unique ID to prevent duplicate processing
    String tradeId = "${package.teamOffering}_${package.teamReceiving}_${package.targetPick.pickNumber}";
    if (_executedTradeIds.contains(tradeId)) {
      return; // Skip if already processed
    }
    _executedTradeIds.add(tradeId);
    
    final teamReceiving = package.teamReceiving;
    final teamOffering = package.teamOffering;
    
    // Update the target pick to belong to the offering team
    for (var pick in draftOrder) {
      if (pick.pickNumber == package.targetPick.pickNumber) {
        pick.teamName = teamOffering;
        pick.tradeInfo = "From $teamReceiving";
        break;
      }
    }
    
    // Update any additional target picks
    for (var additionalPick in package.additionalTargetPicks) {
      for (var pick in draftOrder) {
        if (pick.pickNumber == additionalPick.pickNumber) {
          pick.teamName = teamOffering;
          pick.tradeInfo = "From $teamReceiving";
          break;
        }
      }
    }
    
    // Update the offered picks to belong to the receiving team
    for (var offeredPick in package.picksOffered) {
      for (var pick in draftOrder) {
        if (pick.pickNumber == offeredPick.pickNumber) {
          pick.teamName = teamReceiving;
          pick.tradeInfo = "From $teamOffering";
          break;
        }
      }
    }
    
    _executedTrades.add(package);
  }
  
  /// Select the best player for a team
  Player _selectBestPlayerForTeam(DraftPick pick) {
    // Get team needs
    TeamNeed? teamNeed = _getTeamNeeds(pick.teamName);
    
    // Use enhanced player selection logic
    return selectPlayerRStyle(teamNeed, pick);
  }
  
  // Add this to the DraftService class - position value tiers
  final Map<String, double> _positionValueWeights = {
    'QB': 1.5,   // Premium for franchise QBs
    'EDGE': 1.25, // Elite pass rushers
    'OT': 1.20,   // Offensive tackles highly valued
    'CB | WR': 1.2, // Travis Hunter
    'CB': 1.15,   // Cornerbacks
    'WR': 1.12,   // Wide receivers
    'DT': 1.05,   // Interior defensive line
    'S': 1.0,     // Safeties
    'TE': 0.95,   // Tight ends
    'IOL': 0.90,  // Interior offensive line
    'LB': 0.90,   // Linebackers
    'RB': 0.85,   // Running backs typically devalued
  };

  // Position scarcity tracker - will change during draft
  final Map<String, double> _positionScarcity = {
    'QB': 1.0,
    'OT': 1.0,
    'EDGE': 1.0,
    'CB': 1.0,
    'WR': 1.0,
    'DT': 1.0,
    'S': 1.0,
    'TE': 1.0,
    'IOL': 1.0,
    'LB': 1.0,
    'RB': 1.0,
  };

  // Method to update position scarcity after each selection
  void _updatePositionScarcity(String position) {
    const debugMode = true; // Keep consistent with other debug flags
    double oldScarcity = _positionScarcity[position] ?? 1.0;
    
    // Increase scarcity for the selected position
    _positionScarcity[position] = (_positionScarcity[position] ?? 1.0) * 1.03;
    
    // Cap at a maximum value
    _positionScarcity[position] = min(_positionScarcity[position]!, 1.3);
    
    // Slightly decrease scarcity for other positions
    for (var pos in _positionScarcity.keys) {
      if (pos != position) {
        double oldPosScarcity = _positionScarcity[pos] ?? 1.0;
        _positionScarcity[pos] = max(1.0, (_positionScarcity[pos] ?? 1.0) * 0.99);
        
        if (debugMode && (_positionScarcity[pos]! - oldPosScarcity).abs() > 0.001) {
          debugPrint("Scarcity adjustment for $pos: ${oldPosScarcity.toStringAsFixed(3)} → ${_positionScarcity[pos]!.toStringAsFixed(3)}");
        }
      }
    }
    
    if (debugMode) {
      debugPrint("Position scarcity updated for $position: ${oldScarcity.toStringAsFixed(3)} → ${_positionScarcity[position]!.toStringAsFixed(3)}");
    }
  }

  // Then, modifying the selectPlayerRStyle method:
  Player selectPlayerRStyle(TeamNeed? teamNeed, DraftPick nextPick) {
      const debugMode = true; // Toggle this to enable/disable debugging
      final StringBuffer debugLog = StringBuffer();
      if (debugMode) {
        debugLog.writeln("\n----------- PLAYER SELECTION DEBUG -----------");
        debugLog.writeln("Team: ${teamNeed?.teamName ?? 'Unknown'} | Pick #${nextPick.pickNumber}");
        if (teamNeed != null) {
          debugLog.writeln("Team Needs: ${teamNeed.needs.join(', ')}");
        }
  }

    // If team has no needs defined, use best player available
    if (teamNeed == null || teamNeed.needs.isEmpty) {
      if (debugMode) debugLog.writeln("No team needs defined, selecting best player available");
      Player selected = _selectBestPlayerWithRandomness(availablePlayers, nextPick.pickNumber);
      if (debugMode) debugLog.writeln("Selected: ${selected.name} (${selected.position}) - Rank #${selected.rank}");
      if (debugMode) debugPrint(debugLog.toString());
      return selected;
    }
    
    // Calculate round based on pick number (1-indexed)
    int round = (nextPick.pickNumber / 32).ceil();
    
    // Get needs based on round (only consider round+3 needs)
    int needsToConsider = min(round + 3, teamNeed.needs.length);

    if (debugMode) {
      debugLog.writeln("Round: $round | Considering top $needsToConsider needs");
      debugLog.writeln("Relevant needs: ${teamNeed.needs.take(needsToConsider).toList()}");
    }
    
    // Generate selections for each need, but with positional weighting
    Map<Player, double> playerScores = {};
    Map<Player, Map<String, double>> playerScoreDetails = {}; // Store detailed scoring for debugging

    // First, evaluate available players against team needs
    for (int i = 0; i < needsToConsider; i++) {
      if (i < teamNeed.needs.length) {
        String needPosition = teamNeed.needs[i];
        
        // Skip empty needs
        if (needPosition == "-" || needPosition.isEmpty) continue;
        
        if (debugMode) debugLog.writeln("\nEvaluating need: $needPosition (Priority: ${i+1})");

        // Find candidates for this position
        final positionCandidates = availablePlayers
          .where((p) => p.position.contains(needPosition) || 
                      (p.position.contains('|') && 
                        needPosition.contains(p.position.split('|')[0].trim())))
          .where((p) => p.rank <= nextPick.pickNumber + 25)
          .toList();
        
        if (positionCandidates.isEmpty) {
          if (debugMode) debugLog.writeln("  No candidates found for position: $needPosition");
          continue;
        }
        
        // Sort by rank
        positionCandidates.sort((a, b) => a.rank.compareTo(b.rank));
        
        // Get position value weight
        double posWeight = _positionValueWeights[needPosition] ?? 1.0;
        
        // Get current scarcity factor
        double scarcityFactor = _positionScarcity[needPosition] ?? 1.0;

        if (debugMode) {
          debugLog.writeln("  Position weight: $posWeight | Scarcity factor: $scarcityFactor");
          debugLog.writeln("  Top candidates for $needPosition:");
        }
        
        // Process top 3 candidates for this position
        for (var player in positionCandidates.take(3)) {
          // Need factor - higher for top needs
          double needFactor = 1.0 - (i * 0.15); // 1.0 for top need, decreasing
          
          // Value calculation - how good is player relative to pick?
          int valueGap = nextPick.pickNumber - player.rank;
          double valueScore = valueGap >= 0 
              ? min(1.0, valueGap / 10) // Good value (up to +1.0)
              : max(-0.5, valueGap / 20); // Negative for reaching (-0.5 max penalty)
          
          // Early pick factor - higher standards for top picks
          double pickFactor = 0;
          if (nextPick.pickNumber <= 5) pickFactor = 0.15;
          else if (nextPick.pickNumber <= 15) pickFactor = 0.1;
          else if (nextPick.pickNumber <= 32) pickFactor = 0.05;
          
          // Store all scoring components for debugging
          Map<String, double> scoreComponents = {
            'needFactor': needFactor * 0.4,
            'valueScore': valueScore * 0.3,
            'positionWeight': posWeight * 0.2,
            'scarcityFactor': scarcityFactor * 0.1,
            'pickFactor': pickFactor
          };

          // Calculate player score
          double score = scoreComponents.values.reduce((a, b) => a + b);
                        
          // Store score
          playerScores[player] = score;
          playerScoreDetails[player] = scoreComponents;
        
          if (debugMode) {
            debugLog.writeln("  - ${player.name} (${player.position}) - Rank #${player.rank}:");
            debugLog.writeln("    Need Factor: ${(needFactor * 0.4).toStringAsFixed(3)} | Value Score: ${(valueScore * 0.3).toStringAsFixed(3)} | Position Weight: ${(posWeight * 0.2).toStringAsFixed(3)} | Scarcity: ${(scarcityFactor * 0.1).toStringAsFixed(3)} | Pick Factor: ${pickFactor.toStringAsFixed(3)}");
            debugLog.writeln("    Value Gap: $valueGap | Score before randomness: ${score.toStringAsFixed(3)}");
          }
        }
      }
    }
    
    // Also evaluate top 5 overall players (BPA consideration)
    final topPlayers = availablePlayers
        .where((p) => p.rank <= min(50, nextPick.pickNumber + 15))
        .take(5)
        .toList();

    if (debugMode) debugLog.writeln("\nEvaluating Top 5 BPA candidates:");
        
    for (var player in topPlayers) {
      // Skip if already evaluated through needs
      if (playerScores.containsKey(player)) continue;
      
      // Get position weight
      double posWeight = _positionValueWeights[player.position] ?? 1.0;
      
      // Get scarcity factor
      double scarcityFactor = _positionScarcity[player.position] ?? 1.0;
      
      // Value calculation
      int valueGap = nextPick.pickNumber - player.rank;
      double valueScore = valueGap >= 0 
          ? min(1.0, valueGap / 10) 
          : max(-0.5, valueGap / 20);
      
      // BPA gets a boost but need factor is low
      double needFactor = 0.4; // Low since not in needs list
      
      // Store all scoring components for debugging
      Map<String, double> scoreComponents = {
        'needFactor': needFactor * 0.3,
        'valueScore': valueScore * 0.5,
        'positionWeight': posWeight * 0.15,
        'scarcityFactor': scarcityFactor * 0.05
      };
      
      // Calculate score with higher value emphasis
      double score = scoreComponents.values.reduce((a, b) => a + b);
      
      // Store score
      playerScores[player] = score;
      playerScoreDetails[player] = scoreComponents;
    
      if (debugMode) {
        debugLog.writeln("  - ${player.name} (${player.position}) - Rank #${player.rank}:");
        debugLog.writeln("    Need Factor: ${(needFactor * 0.3).toStringAsFixed(3)} | Value Score: ${(valueScore * 0.5).toStringAsFixed(3)} | Position Weight: ${(posWeight * 0.15).toStringAsFixed(3)} | Scarcity: ${(scarcityFactor * 0.05).toStringAsFixed(3)}");
        debugLog.writeln("    Value Gap: $valueGap | Score before randomness: ${score.toStringAsFixed(3)}");
      }
    }
    
    // If no players evaluated, fall back to best available
    if (playerScores.isEmpty) {
      if (debugMode) debugLog.writeln("\nNo players evaluated, falling back to best available");
      Player selected = _selectBestPlayerAvailable(nextPick.pickNumber);
      if (debugMode) {
        debugLog.writeln("Selected: ${selected.name} (${selected.position}) - Rank #${selected.rank}");
        debugPrint(debugLog.toString());
      }
      return selected;
    }

    
    // Add randomness to each score
    Map<Player, double> finalScores = {};

    if (debugMode) debugLog.writeln("\nAdding randomness to scores:");

    for (var entry in playerScores.entries) {
      //double randomFactor = _random.nextDouble() * 0.3 - 0.15; // -0.15 to +0.15
      //finalScores[entry.key] = entry.value + randomFactor;
      double randomnessRange = 0.3 * randomnessFactor; // 0.3 is the maximum range
      double randomFactor = (_random.nextDouble() * randomnessRange) - (randomnessRange / 2);
      finalScores[entry.key] = entry.value + randomFactor;
    
      if (debugMode) {
        debugLog.writeln("  ${entry.key.name}: Base score ${entry.value.toStringAsFixed(3)} + Random ${randomFactor.toStringAsFixed(3)} = Final ${finalScores[entry.key]!.toStringAsFixed(3)}");
      }
    }
    
    // Find player with highest score
    Player bestPlayer = finalScores.entries.reduce((a, b) => 
        a.value > b.value ? a : b).key;
    
    // Update position scarcity after selection
    _updatePositionScarcity(bestPlayer.position);

    if (debugMode) {
      // Print all player scores in order for comparison
      debugLog.writeln("\nFinal player rankings:");
      List<MapEntry<Player, double>> sortedEntries = finalScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
        
      for (int i = 0; i < min(sortedEntries.length, 5); i++) {
        var entry = sortedEntries[i];
        String indicator = entry.key == bestPlayer ? " ★ SELECTED" : "";
        debugLog.writeln("  ${i+1}. ${entry.key.name} (${entry.key.position}) - Score: ${entry.value.toStringAsFixed(3)}$indicator");
      }
      
      debugLog.writeln("\nSELECTION RESULT: ${bestPlayer.name} (${bestPlayer.position}) - Rank #${bestPlayer.rank}");
      debugLog.writeln("----------- END DEBUG -----------\n");
      debugPrint(debugLog.toString());
    }
    
    return bestPlayer;
  }
  
  // Modify _makeSelection method to use pick number for determining randomness
  Player? _makeSelection(String needPosition) {
    // Filter players by position using contains
    List<Player> candidatesForPosition = availablePlayers
        .where((player) => player.position.contains(needPosition))
        .toList();
    
    if (candidatesForPosition.isEmpty) {
      return null;
    }
    
    // Sort by rank
    candidatesForPosition.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Use current pick number for randomness calculation
    int pickNumber = _currentPick;
    double randSelect = _random.nextDouble();
    int selectIndex;
    
    // Differentiate selection probabilities by pick range
    if (pickNumber <= 5) {
      // Top 5 picks - almost always take the best player (95%)
      if (randSelect <= 0.95) {
        selectIndex = 0;
      } else {
        selectIndex = min(1, candidatesForPosition.length - 1);
      }
    } 
    else if (pickNumber <= 15) {
      // Picks 6-15 - still heavily favor best player (90%)
      if (randSelect <= 0.90) {
        selectIndex = 0;
      } else if (randSelect <= 0.98) {
        selectIndex = min(1, candidatesForPosition.length - 1);
      } else {
        selectIndex = min(2, candidatesForPosition.length - 1);
      }
    }
    else if (pickNumber <= 32) {
      // Rest of first round - moderately favor best player (85%)
      if (randSelect <= 0.85) {
        selectIndex = 0;
      } else if (randSelect <= 0.97) {
        selectIndex = min(1, candidatesForPosition.length - 1);
      } else {
        selectIndex = min(2, candidatesForPosition.length - 1);
      }
    }
    else if (pickNumber <= 64) {
      // Second round - slightly favor best player (80%)
      if (randSelect <= 0.80) {
        selectIndex = 0;
      } else if (randSelect <= 0.95) {
        selectIndex = min(1, candidatesForPosition.length - 1);
      } else {
        selectIndex = min(2, candidatesForPosition.length - 1);
      }
    }
    else {
      // Later rounds - standard randomness
      if (randSelect <= 0.75) {
        selectIndex = 0;
      } else if (randSelect <= 0.90) {
        selectIndex = min(1, candidatesForPosition.length - 1);
      } else {
        selectIndex = min(2, candidatesForPosition.length - 1);
      }
    }
    
    return candidatesForPosition[selectIndex];
  }
  
  /// Select the best player available with consideration for pick position
  Player _selectBestPlayerAvailable(int pickNumber) {
    // For top picks, be more consistent
    if (pickNumber <= 5) {
      double randSelect = _random.nextDouble();
      
      // For picks 1-3, almost always pick the top player (90%)
      if (pickNumber <= 3) {
        if (randSelect <= 0.95) {
          return availablePlayers.first;
        } else if (randSelect <= 0.99) {
          return availablePlayers.length > 1 ? availablePlayers[1] : availablePlayers.first;
        } else {
          return availablePlayers.length > 2 ? availablePlayers[2] : availablePlayers.first;
        }
      }
      // For picks 4-5, usually pick top 2 players (80%)
      else {
        if (randSelect <= 0.9) {
          return availablePlayers.first;
        } else if (randSelect <= 0.97) {
          return availablePlayers.length > 1 ? availablePlayers[1] : availablePlayers.first;
        } else {
          return availablePlayers.length > 2 ? availablePlayers[2] : availablePlayers.first;
        }
      }
    }
    
    // Regular random selection with bias toward top players for picks 6+
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
  Player _selectBestPlayerForPosition(List<String> positions, int pickNumber) {
    // Filter players by any matching position
    List<Player> candidatesForPositions = availablePlayers
      .where((player) => positions.contains(player.position))
      .toList();
  
    // If no matches, fall back to best overall
    if (candidatesForPositions.isEmpty) {
      return _selectBestPlayerAvailable(pickNumber);
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
  
  /// Select the best player with appropriate randomness factor for draft position
  Player _selectBestPlayerWithRandomness(List<Player> players, int pickNumber) {
    const debugMode = true; // Keep consistent with the main function
    final StringBuffer debugLog = StringBuffer();
    
    if (debugMode) {
      debugLog.writeln("\n----------- RANDOMNESS SELECTION DEBUG -----------");
      debugLog.writeln("Pick #$pickNumber | Using Best Player Available with Randomness");
    }
    
    if (players.isEmpty) {
      throw Exception('No players available for selection');
    }
    
    // Sort players by rank
    players.sort((a, b) => a.rank.compareTo(b.rank));
    
    // With no randomness, just return the top player
    if (randomnessFactor <= 0.0) {
      if (debugMode) {
        debugLog.writeln("Randomness is disabled, selecting top player");
        debugLog.writeln("Selected: ${players.first.name} (${players.first.position}) - Rank #${players.first.rank}");
        debugPrint(debugLog.toString());
      }
      return players.first;
    }
    
    // Adjust randomness based on pick position
    // Top 5 picks should be much more predictable
    double effectiveRandomness = randomnessFactor;
    if (pickNumber <= 3) {
      // First 3 picks are highly predictable
      effectiveRandomness = randomnessFactor * 0.2;
    } else if (pickNumber <= 5) {
      // Picks 4-5 are very predictable
      effectiveRandomness = randomnessFactor * 0.3;
    } else if (pickNumber <= 10) {
      // Picks 6-10 are fairly predictable
      effectiveRandomness = randomnessFactor * 0.5;
    } else if (pickNumber <= 32) {
      // First round has slightly reduced randomness
      effectiveRandomness = randomnessFactor * 0.75;
    }
    
    if (debugMode) {
      debugLog.writeln("Base randomness factor: $randomnessFactor");
      debugLog.writeln("Effective randomness for pick #$pickNumber: $effectiveRandomness");
    }

    // Calculate how many players to consider in the pool
    int poolSize = max(1, (players.length * effectiveRandomness).round());
    poolSize = min(poolSize, players.length); // Don't exceed list length
    
    // For top 3 picks, further restrict the pool size
    if (pickNumber <= 3) {
      poolSize = min(2, poolSize); // At most consider top 2 players
    }

    if (debugMode) {
      debugLog.writeln("Pool size: $poolSize players");
      debugLog.writeln("Available players in pool:");
      for (int i = 0; i < poolSize; i++) {
        debugLog.writeln("  ${i+1}. ${players[i].name} (${players[i].position}) - Rank #${players[i].rank}");
      }
    }
    
    // Select a random player from the top poolSize players
    int randomIndex = _random.nextInt(poolSize);
    Player selectedPlayer = players[randomIndex];
    
    if (debugMode) {
      debugLog.writeln("Random selection index: $randomIndex");
      debugLog.writeln("Selected: ${selectedPlayer.name} (${selectedPlayer.position}) - Rank #${selectedPlayer.rank}");
      debugLog.writeln("----------- END RANDOMNESS DEBUG -----------\n");
      debugPrint(debugLog.toString());
    }
    
    return selectedPlayer;
  }
    
  // Randomization helper functions (from R code)
  double _getRandomAddValue() {
    return _random.nextDouble() * 10 - 4; // Range from -4 to 6
  }
    
  double _getRandomMultValue() {
    return _random.nextDouble() * 0.3 + 0.01; // Range from 0.01 to 0.3
  }
  
  /// Get the team needs for a specific team
  TeamNeed? _getTeamNeeds(String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      debugPrint('No team needs found for $teamName');
      return null;
    }
  }
  
  /// Get the next pick in the draft order
  DraftPick? _getNextPick() {
    for (var pick in draftOrder) {
      if (!pick.isSelected && pick.isActiveInDraft) {
        return pick;
      }
    }
    return null;
  }
  
  /// Generate user-initiated trade offers to AI teams
  void generateUserTradeOffers() {
    if (userTeams == null || userTeams!.isEmpty || !enableUserTradeProposals) {
      _pendingUserOffers.clear();
      return;
    }
    
    // Find only the current active user pick that's next in the draft
    DraftPick? nextUserPick;
    
    // First find the next pick in the draft order
    DraftPick? nextPick = _getNextPick();
    if (nextPick == null) return;
    
    // Only generate offers if it's the user's current pick
    if (userTeams != null && userTeams!.contains(nextPick.teamName)) {
      nextUserPick = nextPick;
    } else {
      // Clear any existing offers since it's not the user's turn
      _pendingUserOffers.clear();
      return;
    }
    
    // Generate offers only for the current pick
    final pickNum = nextUserPick.pickNumber;
    
    // If there are already offers for this pick, don't regenerate
    if (_pendingUserOffers.containsKey(pickNum)) return;
    
    // Generate trade offers for this pick
    TradeOffer offers = _tradeService.generateTradeOffersForPick(pickNum);
    if (offers.packages.isNotEmpty) {
      _pendingUserOffers[pickNum] = offers.packages;
    }
  }

/// Method alias for backward compatibility
void generateUserPickOffers() {
  generateUserTradeOffers();
}
  
  /// Check if there are trade offers for a specific user pick
  bool hasOffersForPick(int pickNumber) {
    return _pendingUserOffers.containsKey(pickNumber) && 
           _pendingUserOffers[pickNumber]!.isNotEmpty;
  }
  
  /// Get all pending offers for user team
  Map<int, List<TradePackage>> get pendingUserOffers => _pendingUserOffers;
  
  /// Process a user trade proposal with realistic acceptance criteria
  bool processUserTradeProposal(TradePackage proposal) {
    // Determine if the AI team should accept
    final shouldAccept = _tradeService.evaluateTradeProposal(proposal);
    
    // Execute the trade if accepted
    if (shouldAccept) {
      _executeTrade(proposal);
      _statusMessage = "Trade accepted: ${proposal.tradeDescription}";
    }
    
    return shouldAccept;
  }
  
  /// Get a realistic rejection reason if trade is declined
  String getTradeRejectionReason(TradePackage proposal) {
    return _tradeService.getTradeRejectionReason(proposal);
  }
  
  /// Execute a specific trade (for use with UI)
  void executeUserSelectedTrade(TradePackage package) {
    _executeTrade(package);
    _statusMessage = "Trade executed: ${package.tradeDescription}";
    _tradeUp = true;
  }
  
  /// Get all available picks for a specific team
  List<DraftPick> getTeamPicks(String teamName) {
    // Include ALL picks for trading, not just active ones
    return draftOrder.where((pick) => 
      pick.teamName == teamName && !pick.isSelected
    ).toList();
  }
  
  // Getters for state information
  String get statusMessage => _statusMessage;
  int get currentPick => _currentPick;
  int get completedPicksCount => draftOrder.where((pick) => pick.isSelected).length;
  int get totalPicksCount => draftOrder.length;
  List<TradePackage> get executedTrades => _executedTrades;
  
  // Check if draft is complete
  bool isDraftComplete() {
    return draftOrder.where((pick) => pick.isActiveInDraft).every((pick) => pick.isSelected);
  }
}