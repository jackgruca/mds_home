// lib/services/draft_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

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
    this.randomnessFactor = 0.5,
    this.userTeam,
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
      userTeam: userTeam,
      tradeRandomnessFactor: randomnessFactor,
      enableQBPremium: enableQBPremium,
    );
  }
  
  /// Process a single draft pick with improved trade evaluation
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
      return nextPick;
    }
    
    // Evaluate potential trades with calibrated frequency
    TradePackage? executedTrade = _evaluateTrades(nextPick);
    
    // If a trade was executed, return the updated pick
    if (executedTrade != null) {
      _tradeUp = true;
      _statusMessage = "Trade executed: ${executedTrade.tradeDescription}";
      return nextPick;
    }
    
    // No trade - select a player
    Player selectedPlayer = _selectBestPlayerForTeam(nextPick);
    nextPick.selectedPlayer = selectedPlayer;
    
    // Update simulation state
    _updateAfterSelection(nextPick, selectedPlayer);
    
    return nextPick;
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
  
  /// Evaluate potential trades for the current pick with realistic behavior
  TradePackage? _evaluateTrades(DraftPick nextPick) {
    // Skip if already has trade info or is a user team pick
    if (nextPick.tradeInfo != null && nextPick.tradeInfo!.isNotEmpty) {
      return null;
    }

    // Get team needs
    TeamNeed? teamNeeds = _getTeamNeeds(nextPick.teamName);
    
    // Check for QB needs specifically - teams with a QB need should almost never
    // trade out of a pick where they could select a valuable QB
    bool teamNeedsQB = teamNeeds != null && teamNeeds.needs.take(3).contains("QB");
    
    if (teamNeedsQB && nextPick.pickNumber <= 32) {
      // Check for valuable QBs available
      bool valuableQBAvailable = availablePlayers
          .any((p) => p.position == "QB" && p.rank <= nextPick.pickNumber + 10);
      
      if (valuableQBAvailable) {
        // 98% chance to stay and draft the QB
        if (_random.nextDouble() < 0.98) {
          return null;
        }
      }
    }

    // Determine the chance of trade evaluation based on round
    int round = DraftValueService.getRoundForPick(nextPick.pickNumber);
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
  if (nextPick.teamName == userTeam) return false;
  
  // Get team needs for the team with the current pick
  TeamNeed? teamNeeds = _getTeamNeeds(nextPick.teamName);
  bool currentTeamNeedsQB = teamNeeds != null && 
                           teamNeeds.needs.take(3).contains("QB");
  
  // If team with the pick needs a QB, they likely won't trade out
  // for a QB-motivated trade (but might trade for other reasons)
  if (currentTeamNeedsQB && nextPick.pickNumber <= 15) {
    return false;
  }
  
  // Check for available QB prospects in the top 20
  final availableQBs = availablePlayers
      .where((p) => p.position == "QB" && p.rank <= 20)
      .toList();
  
  if (availableQBs.isEmpty) return false;
  
  // High probabilities for QB trades when top QBs are available
  if (nextPick.pickNumber <= 10) {
    // Very high chance in top 10 with top QB
    bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 10);
    double qbTradeProb = topQBAvailable ? 0.9 : 0.7;
    return _random.nextDouble() < qbTradeProb;
  } 
  else if (nextPick.pickNumber <= 32) {
    // Moderate chance in first round
    bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 15);
    double qbTradeProb = topQBAvailable ? 0.8 : 0.5;
    return _random.nextDouble() < qbTradeProb;
  }
  else if (nextPick.pickNumber <= 45) {
    // Lower chance early in second round
    double qbTradeProb = 0.4;
    return _random.nextDouble() < qbTradeProb;
  }
  
  // Very low chance in later rounds
  return _random.nextDouble() < 0.15;
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
  
  /// Select a player based on the R algorithm - enhanced with better need/position weighting
  Player selectPlayerRStyle(TeamNeed? teamNeed, DraftPick nextPick) {
  // If team has no needs defined, use best player available
  if (teamNeed == null || teamNeed.needs.isEmpty) {
    return _selectBestPlayerWithRandomness(availablePlayers, nextPick.pickNumber);
  }
  
  // Calculate round based on pick number (1-indexed)
  int round = (nextPick.pickNumber / 32).ceil();
  
  // Get needs based on round (only consider round+3 needs as you specified)
  int needsToConsider = min(round + 3, teamNeed.needs.length);
  
  // Generate selections for each need, but strictly prioritize earlier needs
  List<Player?> candidates = [];
  for (int i = 0; i < needsToConsider; i++) {
    if (i < teamNeed.needs.length) {
      String needPosition = teamNeed.needs[i];
      if (needPosition != "-") {
        candidates.add(_makeSelection(needPosition));
      }
    }
  }
  
  // Remove null entries
  candidates.removeWhere((player) => player == null);
  
  // If no candidates found through needs, use best player available
  if (candidates.isEmpty) {
    return _selectBestPlayerAvailable(nextPick.pickNumber);
  }
  
  // Special case for QB-needy teams 
  if (_qbTrade && candidates.any((p) => p!.position == "QB")) {
    return candidates.firstWhere((p) => p!.position == "QB")!;
  }
  
  // Calculate value thresholds with less randomness for early picks
  double factor = min(0.2, ((round * 0.05) + 0.05));
  
  // Evaluate each need/player in order of priority
  for (int i = 0; i < candidates.length; i++) {
    Player candidate = candidates[i]!;
    // Check if this player's rank is close enough to pick value
    if (candidate.rank <= nextPick.pickNumber * (1 + factor) + round) {
      return candidate; // Pick player at this need position
    }
  }
  
  // If no good value at needs, select best player available that matches any team need
  if (candidates.isNotEmpty) {
    candidates.sort((a, b) => a!.rank.compareTo(b!.rank));
    return candidates.first!;
  }
  
  // Fallback to best overall player
  return _selectBestPlayerAvailable(nextPick.pickNumber);
}
  
  /// Make a selection for a specific need position
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
    
    // Random selection logic
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
  
  /// Select the best player available with consideration for pick position
  Player _selectBestPlayerAvailable(int pickNumber) {
    // For top picks, be more consistent
    if (pickNumber <= 5) {
      double randSelect = _random.nextDouble();
      
      // For picks 1-3, almost always pick the top player (90%)
      if (pickNumber <= 3) {
        if (randSelect <= 0.9) {
          return availablePlayers.first;
        } else if (randSelect <= 0.98) {
          return availablePlayers.length > 1 ? availablePlayers[1] : availablePlayers.first;
        } else {
          return availablePlayers.length > 2 ? availablePlayers[2] : availablePlayers.first;
        }
      }
      // For picks 4-5, usually pick top 2 players (80%)
      else {
        if (randSelect <= 0.8) {
          return availablePlayers.first;
        } else if (randSelect <= 0.95) {
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
    if (players.isEmpty) {
      throw Exception('No players available for selection');
    }
    
    // Sort players by rank
    players.sort((a, b) => a.rank.compareTo(b.rank));
    
    // With no randomness, just return the top player
    if (randomnessFactor <= 0.0) {
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
    
    // Calculate how many players to consider in the pool
    int poolSize = max(1, (players.length * effectiveRandomness).round());
    poolSize = min(poolSize, players.length); // Don't exceed list length
    
    // For top 3 picks, further restrict the pool size
    if (pickNumber <= 3) {
      poolSize = min(2, poolSize); // At most consider top 2 players
    }
    
    // Select a random player from the top poolSize players
    int randomIndex = _random.nextInt(poolSize);
    return players[randomIndex];
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
    if (userTeam == null || !enableUserTradeProposals) {
      _pendingUserOffers.clear();
      return;
    }
    
    // Find all user picks
    final userPicks = draftOrder
        .where((pick) => pick.teamName == userTeam && !pick.isSelected && pick.isActiveInDraft)
        .toList();
    
    // Generate offers for each pick
    for (var pick in userPicks) {
      final pickNum = pick.pickNumber;
      // If there are already offers for this pick, skip
      if (_pendingUserOffers.containsKey(pickNum)) continue;
      
      // Generate trade offers for this pick
      TradeOffer offers = _tradeService.generateTradeOffersForPick(pickNum);
      if (offers.packages.isNotEmpty) {
        _pendingUserOffers[pickNum] = offers.packages;
      }
    }
  }

  TradeOffer getTradeOffersForCurrentPick() {
  DraftPick? nextPick = _getNextPick();
  if (nextPick == null) {
    return const TradeOffer(packages: [], pickNumber: 0);
  }
  
  return _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
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
  
  /// Get picks from all other teams
  List<DraftPick> getOtherTeamPicks(String excludeTeam) {
    // Include ALL picks for trading, not just active ones
    return draftOrder.where((pick) => 
      pick.teamName != excludeTeam && !pick.isSelected
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