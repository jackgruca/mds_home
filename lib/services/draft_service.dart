// lib/services/draft_service.dart - Updated with trade integration
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import 'trade_service.dart';
import 'draft_value_service.dart';

/// Handles the logic for the draft simulation with trade integration
class DraftService {
  final List<Player> availablePlayers;
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  
  // Draft settings
  final double randomnessFactor;
  final String? userTeam;
  final int numberRounds;
  
  // Trade service
  late TradeService _tradeService;
  
  // Draft state tracking
  bool _tradeUp = false;
  bool _qbTrade = false;
  String _statusMessage = "";
  int _currentPick = 0;
  final List<TradePackage> _executedTrades = [];
  
  // Random instance for introducing randomness
  final Random _random = Random();
  
  DraftService({
    required this.availablePlayers,
    required this.draftOrder,
    required this.teamNeeds,
    this.randomnessFactor = 0.5,
    this.userTeam,
    this.numberRounds = 1,
  }) {
    // Sort players by rank initially
    availablePlayers.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Initialize the trade service
    _tradeService = TradeService(
      draftOrder: draftOrder,
      teamNeeds: teamNeeds,
      availablePlayers: availablePlayers,
      userTeam: userTeam,
      tradeRandomnessFactor: randomnessFactor,
    );
  }
  
  /// Process a single draft pick with possible trade evaluations
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
      _statusMessage = "User's turn to pick";
      return nextPick; // Return without making a selection
    }
    
    // Evaluate potential trades
    TradePackage? executedTrade = _evaluateTrades(nextPick);
    
    // If a trade was executed, return the updated pick
    if (executedTrade != null) {
      _tradeUp = true;
      _executedTrades.add(executedTrade);
      _statusMessage = "Trade executed: ${executedTrade.tradeDescription}";
      return nextPick;
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
  
  /// Evaluate potential trades for the current pick
  TradePackage? _evaluateTrades(DraftPick nextPick) {
    // Skip trade evaluation if user team (will handle separately)
    if (nextPick.teamName == userTeam) {
      return null;
    }
    
    // First round QB-specific trade evaluation
    if (nextPick.pickNumber <= 32) {
      final qbTradeOffer = _tradeService.generateTradeOffersForPick(
        nextPick.pickNumber, 
        qbSpecific: true
      );
      
      if (qbTradeOffer.hasFairTrades) {
        final bestPackage = qbTradeOffer.bestPackage;
        if (bestPackage != null && _shouldAcceptTrade(bestPackage, isQBTrade: true)) {
          _qbTrade = true;
          _executeTrade(bestPackage);
          return bestPackage;
        }
      }
    }
    
    // General trade evaluations - evaluate up to 3 times with different thresholds
    for (int attempt = 1; attempt <= 3; attempt++) {
      // Each attempt has stricter value requirements
      final valueMultiplier = attempt > 1 ? 1.0 + (attempt - 1) * 0.5 : 1.0;
      
      // Generate trade offers
      final tradeOffer = _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
      
      if (tradeOffer.hasFairTrades) {
        final bestPackage = tradeOffer.bestPackage;
        if (bestPackage != null && 
            bestPackage.totalValueOffered >= bestPackage.targetPickValue * valueMultiplier &&
            _shouldAcceptTrade(bestPackage)) {
          _executeTrade(bestPackage);
          return bestPackage;
        }
      }
    }
    
    return null;
  }
  
  /// Execute a trade by swapping teams for picks
  void _executeTrade(TradePackage package) {
  final targetPickNumber = package.targetPick.pickNumber;
  final teamReceiving = package.teamReceiving;
  final teamOffering = package.teamOffering;
  
  // Update the target pick to belong to the offering team
  for (var pick in draftOrder) {
    if (pick.pickNumber == targetPickNumber) {
      pick.teamName = teamOffering; // Now works with updated model
      pick.tradeInfo = "From $teamReceiving";
      break;
    }
  }
  
  // Update the offered picks to belong to the receiving team
  for (var offeredPick in package.picksOffered) {
    for (var pick in draftOrder) {
      if (pick.pickNumber == offeredPick.pickNumber) {
        pick.teamName = teamReceiving; // Now works with updated model
        pick.tradeInfo = "From $teamOffering";
        break;
      }
    }
  }
}
  
  /// Determine if a trade should be accepted
  bool _shouldAcceptTrade(TradePackage package, {bool isQBTrade = false}) {
    // Random factor for variability
    final randomTradeChance = _random.nextDouble(); 
    
    // QBs get higher acceptance rate
    if (isQBTrade && randomTradeChance > 0.5) {
      return true;
    }
    
    // General trade acceptance
    return _tradeService.shouldAcceptTrade(package) && randomTradeChance > 0.5;
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
  
  Player selectPlayerRStyle(TeamNeed? teamNeed, DraftPick nextPick) {
    return _selectPlayerRStyle(teamNeed, nextPick);
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
  List<TradePackage> get executedTrades => _executedTrades;
  
  bool isDraftComplete() {
    return draftOrder.every((pick) => pick.isSelected);
  }
  
  /// Get trade offers for the current pick (mainly for UI purposes)
  TradeOffer getTradeOffersForCurrentPick() {
    DraftPick? nextPick = _getNextPick();
    if (nextPick == null) {
      return const TradeOffer(packages: [], pickNumber: 0);
    }
    
    return _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
  }
  
  /// Execute a specific trade (for use with UI)
  void executeUserSelectedTrade(TradePackage package) {
    _executeTrade(package);
    _executedTrades.add(package);
    _statusMessage = "Trade executed: ${package.tradeDescription}";
    _tradeUp = true;
  }

  /// Get all available picks for a specific team
  List<DraftPick> getTeamPicks(String teamName) {
    return draftOrder.where((pick) => 
      pick.teamName == teamName && !pick.isSelected
    ).toList();
  }

  /// Get picks from all other teams
  List<DraftPick> getOtherTeamPicks(String excludeTeam) {
    return draftOrder.where((pick) => 
      pick.teamName != excludeTeam && !pick.isSelected
    ).toList();
  }

  /// Process a user-proposed trade
  bool processUserTradeProposal(TradePackage proposal) {
    // Calculate probability of accepting based on value
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    
    // Random factor for team preferences
    double randomFactor = _random.nextDouble() * 0.2;
    
    // Base probability on value and random factor
    bool shouldAccept = valueRatio >= 0.95 - randomFactor;
    
    // Execute the trade if accepted
    if (shouldAccept) {
      _executeTrade(proposal);
      _executedTrades.add(proposal);
      _statusMessage = "Trade accepted: ${proposal.tradeDescription}";
    }
    
    return shouldAccept;
  }

  /// Get a rejection reason if trade is declined
  String? getTradeRejectionReason(TradePackage proposal) {
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    
    if (valueRatio < 0.8) {
      return "The offer doesn't provide enough value.";
    } else if (valueRatio < 0.95) {
      return "The offer is close, but not quite enough value.";
    } else {
      return "Team has other plans for this pick.";
    }
  }
}