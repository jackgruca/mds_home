// lib/services/draft_service.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import 'draft_value_service.dart';
import 'trade_service.dart';

/// Configuration for draft behavior settings
class DraftConfig {
  // Core settings
  final double randomnessFactor;
  final int numberOfRounds;
  final bool enableTrading;
  final bool enableQBPremium;
  final bool enableUserTradeProposals;
  
  // Player selection behavior settings
  final double valueVsNeedBalance; // 1.0 = all value, 0.0 = all need
  final double positionTierAdjustment; // How much to adjust for position importance
  final bool enablePositionRuns; // Whether to simulate "runs" on positions
  
  // Trading frequency calibration
  final Map<int, double> roundTradeFrequency;
  
  const DraftConfig({
    this.randomnessFactor = 0.5,
    this.numberOfRounds = 7,
    this.enableTrading = true,
    this.enableQBPremium = true,
    this.enableUserTradeProposals = true,
    this.valueVsNeedBalance = 0.6, // Default to 60% value, 40% need
    this.positionTierAdjustment = 0.3,
    this.enablePositionRuns = true,
    Map<int, double>? roundTradeFrequency,
  }) : roundTradeFrequency = roundTradeFrequency ?? const {
        1: 0.25, // 25% chance of trade in round 1
        2: 0.22, // 22% chance in round 2
        3: 0.18, // 18% chance in round 3
        4: 0.15, // 15% chance in round 4
        5: 0.12, // 12% chance in round 5
        6: 0.10, // 10% chance in round 6
        7: 0.08, // 8% chance in round 7
      };
}

/// Classification of prospect tiers for consistent decision making
enum ProspectTier {
  elite,      // Top 5 talents
  premium,    // Picks 6-15
  firstRound, // Picks 16-32
  secondRound,// Picks 33-64
  midRound,   // Picks 65-150
  lateRound   // Picks 151+
}

/// Service that handles the core draft simulation logic
class DraftService {
  // Core draft data
  final List<Player> availablePlayers;
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  final String? userTeam;
  
  // Configuration
  final DraftConfig config;
  
  // Trade service integration
  late TradeService _tradeService;
  
  // Draft state tracking
  bool _isTradeActive = false;
  bool _isQBTrade = false;
  String _statusMessage = "Draft ready to begin";
  int _currentPickNumber = 0;
  int _completedPicks = 0;
  final List<TradePackage> _executedTrades = [];
  final Set<String> _executedTradeIds = {};
  
  // Better trade offer tracking for user
  final Map<int, List<TradePackage>> _pendingUserOffers = {};
  
  // Position importance mapping
  final Map<String, double> _positionImportance = {
    'QB': 1.5,  // Most important
    'OT': 1.3,
    'EDGE': 1.3,
    'CB': 1.2,
    'WR': 1.15,
    'DT': 1.05,
    'S': 1.0,   // Neutral
    'TE': 0.95,
    'IOL': 0.95,
    'LB': 0.9,
    'RB': 0.85, // Least important
  };
  
  // Premium and secondary positions for quick reference
  final Set<String> _premiumPositions = {'QB', 'OT', 'EDGE', 'CB', 'WR'};
  final Set<String> _secondaryPositions = {'DT', 'S', 'TE', 'IOL', 'LB'};
  
  // Value vs. need calculation by pick position
  final Map<int, double> _valueNeedRatio = {
    1: 0.9,   // Picks 1-10: 90% value, 10% need
    11: 0.8,  // Picks 11-20: 80% value, 20% need
    21: 0.7,  // Picks 21-32: 70% value, 30% need
    33: 0.6,  // Picks 33-64: 60% value, 40% need
    65: 0.5,  // Picks 65-100: 50% value, 50% need
    101: 0.4, // Picks 101+: 40% value, 60% need
  };
  
  // Position runs tracking
  final Map<String, int> _positionRunsCount = {};
  final List<String> _recentPositionsSelected = [];
  
  // Random instance for introducing randomness
  final Random _random;
  
  DraftService({
    required this.availablePlayers,
    required this.draftOrder,
    required this.teamNeeds,
    this.userTeam,
    double randomnessFactor = 0.5,
    int numberRounds = 7,
    bool enableTrading = true,
    bool enableUserTradeProposals = true,
    bool enableQBPremium = true,
    DraftConfig? config,
    TradeService? tradeService,
    Random? random,
  }) : 
    config = config ?? DraftConfig(
      randomnessFactor: randomnessFactor,
      numberOfRounds: numberRounds,
      enableTrading: enableTrading,
      enableUserTradeProposals: enableUserTradeProposals,
      enableQBPremium: enableQBPremium
    ),
    _random = random ?? Random() {
    // Sort players by rank initially
    availablePlayers.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Initialize the trading service
    _tradeService = tradeService ?? TradeService(
      draftOrder: draftOrder,
      teamNeeds: teamNeeds,
      availablePlayers: availablePlayers,
      userTeam: userTeam,
      randomnessFactor: this.config.randomnessFactor,
      enableQBPremium: this.config.enableQBPremium,
    );
  }
  
  /// Process the next draft pick
  DraftPick processDraftPick() {
    // Find the next pick in the draft order
    DraftPick? nextPick = getNextPick();
    
    if (nextPick == null) {
      throw Exception('No more picks available in the draft');
    }
    
    _currentPickNumber = nextPick.pickNumber;
    _isTradeActive = false;
    _isQBTrade = false;
    
    // Check if this is a user team pick
    if (userTeam != null && nextPick.teamName == userTeam) {
      // Generate trade offers for user-controlled team
      generateUserTradeOffers();
      
      // Return without making a selection - user will choose
      _statusMessage = "Your turn to pick or trade for pick #${nextPick.pickNumber}";
      return nextPick;
    }
    
    // Handle CPU team selection
    
    // If trading is disabled, skip trade evaluation
    if (!config.enableTrading) {
      _makePlayerSelection(nextPick);
      return nextPick;
    }
    
    // Evaluate potential trades
    TradePackage? executedTrade = _evaluateTrades(nextPick);
    
    // If a trade was executed, return the updated pick
    if (executedTrade != null) {
      _isTradeActive = true;
      _statusMessage = "Trade executed: ${executedTrade.tradeDescription}";
      
      // Clean up any stale trade offers
      cleanupTradeOffers();
      
      return nextPick;
    }
    
    // No trade - select a player
    _makePlayerSelection(nextPick);
    
    return nextPick;
  }
  
  /// Make a player selection for a pick and update state
  void _makePlayerSelection(DraftPick pick) {
    // Select best player for this team
    Player selectedPlayer = selectBestPlayerForTeam(pick.teamName);
    pick.selectedPlayer = selectedPlayer;
    
    // Update team needs
    _updateTeamNeeds(pick.teamName, selectedPlayer.position);
    
    // Remove player from available pool
    availablePlayers.remove(selectedPlayer);
    
    // Track position runs
    _trackPositionSelection(selectedPlayer.position);
    
    // Update trade service
    _tradeService.recordSelection(selectedPlayer);
    
    // Track completed picks
    _completedPicks++;
    
    // Set status message
    _statusMessage = "Pick #${pick.pickNumber}: ${pick.teamName} selects ${selectedPlayer.name} (${selectedPlayer.position})";
    
    // Clean up trade offers
    cleanupTradeOffers();
  }
  
  /// Track position selections to detect position runs
  void _trackPositionSelection(String position) {
    // Add to recent positions list
    _recentPositionsSelected.add(position);
    
    // Keep only most recent 10 selections
    if (_recentPositionsSelected.length > 10) {
      _recentPositionsSelected.removeAt(0);
    }
    
    // Count consecutive selections of the same position
    _positionRunsCount[position] = (_positionRunsCount[position] ?? 0) + 1;
    
    // Decay other position counts
    for (final pos in _positionRunsCount.keys.toList()) {
      if (pos != position) {
        _positionRunsCount[pos] = max(0, (_positionRunsCount[pos] ?? 0) - 1);
      }
    }
  }
  
  /// Get current position run multiplier for a position
  double getPositionRunMultiplier(String position) {
    if (!config.enablePositionRuns) return 1.0;
    
    // Count recent occurrences
    int recentCount = _recentPositionsSelected
        .where((pos) => pos == position)
        .length;
    
    // Return multiplier based on recent count
    if (recentCount >= 3) return 1.4;      // Strong run
    else if (recentCount >= 2) return 1.2; // Moderate run
    else return 1.0;                      // No run
  }
  
  /// Update a team's needs after a selection
  void _updateTeamNeeds(String teamName, String position) {
    TeamNeed? teamNeed = _getTeamNeeds(teamName);
    if (teamNeed != null) {
      teamNeed.removeNeed(position);
    }
  }
  
  /// Generate trade offers for user team pick
  void generateUserTradeOffers() {
    if (userTeam == null || !config.enableUserTradeProposals) {
      _pendingUserOffers.clear();
      return;
    }
    
    // Find the next user pick that's active in the draft
    DraftPick? nextUserPick;
    
    // Find the next pick in the draft order
    DraftPick? nextPick = getNextPick();
    if (nextPick == null) return;
    
    // Only generate offers if it's the user's current pick
    if (nextPick.teamName == userTeam) {
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
  
  /// Legacy method alias for backward compatibility
  void generateUserPickOffers() {
    generateUserTradeOffers();
  }
  
  /// Clean up stale trade offers for picks that have been handled
  void cleanupTradeOffers() {
    // Get all selected picks
    final selectedPickNumbers = draftOrder
        .where((pick) => pick.isSelected || !pick.isActiveInDraft)
        .map((pick) => pick.pickNumber)
        .toSet();
    
    // Remove offers for picks that have already been processed
    _pendingUserOffers.removeWhere((pickNumber, _) => 
      selectedPickNumbers.contains(pickNumber)
    );
  }
  
  /// Evaluate potential trades for a pick with realistic constraints
  TradePackage? _evaluateTrades(DraftPick currentPick) {
    // Skip if already has trade info
    if (currentPick.tradeInfo != null && currentPick.tradeInfo!.isNotEmpty) {
      return null;
    }
    
    // Check for QB needs to prevent certain trades
    if (_teamNeedsQB(currentPick.teamName)) {
      // Check for valuable QBs available
      bool valuableQBAvailable = availablePlayers
          .any((p) => p.position == "QB" && p.rank <= currentPick.pickNumber + 10);
      
      if (valuableQBAvailable && currentPick.pickNumber <= 15) {
        // Teams with QB needs rarely trade out of top picks
        if (_random.nextDouble() < 0.95) {
          return null;
        }
      }
    }
    
    // Determine current round for trade frequency
    int round = _getRoundForPick(currentPick.pickNumber);
    double tradeChance = config.roundTradeFrequency[round] ?? 0.10;
    
    // Determine if we evaluate trades based on calibrated frequency
    if (_random.nextDouble() >= tradeChance && !_isQBTrade) {
      return null;
    }
    
    // Special QB trade logic - more likely with top QBs available
    bool tryQBTrade = _shouldTryQBTradeScenario(currentPick);
    if (tryQBTrade) {
      final qbTradeOffer = _tradeService.generateTradeOffersForPick(
        currentPick.pickNumber, 
        qbSpecific: true
      );
      
      if (qbTradeOffer.packages.isNotEmpty) {
        final bestPackage = qbTradeOffer.bestPackage;
        if (bestPackage != null) {
          _isQBTrade = true;
          _executeTrade(bestPackage);
          return bestPackage;
        }
      }
    }
    
    // Regular trade evaluation
    final tradeOffer = _tradeService.generateTradeOffersForPick(currentPick.pickNumber);
    
    // Don't execute user-involved trades automatically
    if (tradeOffer.isUserInvolved) {
      return null;
    }
    
    // If we have offers, find the best one
    if (tradeOffer.packages.isNotEmpty) {
      // Take the best package (the service already sorted them)
      final bestPackage = tradeOffer.bestPackage;
      if (bestPackage != null) {
        _executeTrade(bestPackage);
        return bestPackage;
      }
    }
    
    return null;
  }
  
  /// Evaluate if a QB-specific trade scenario should be attempted
  bool _shouldTryQBTradeScenario(DraftPick currentPick) {
    // Skip QB trade logic for user team picks
    if (currentPick.teamName == userTeam) return false;
    
    // Check if current team needs QB
    if (_teamNeedsQB(currentPick.teamName) && currentPick.pickNumber <= 15) {
      return false; // Team with a top pick and QB need would rarely trade out
    }
    
    // Check for available QB prospects
    final availableQBs = availablePlayers
        .where((p) => p.position == "QB" && p.rank <= 32)
        .toList();
    
    if (availableQBs.isEmpty) return false;
    
    // Count how many teams need a QB
    int qbNeedyTeams = 0;
    for (var team in teamNeeds) {
      if (team.needs.take(3).contains("QB")) {
        qbNeedyTeams++;
      }
    }
    
    // Scale factor based on QB market demand
    double qbMarketFactor = min(1.0, qbNeedyTeams / 5.0);
    
    // Probability depends on pick position and QB availability
    if (currentPick.pickNumber <= 10) {
      // Very high chance in top 10 with top QB
      bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 10);
      double qbTradeProb = (topQBAvailable ? 0.9 : 0.7) * qbMarketFactor;
      return _random.nextDouble() < qbTradeProb;
    } 
    else if (currentPick.pickNumber <= 32) {
      // Moderate chance in first round
      bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 20);
      double qbTradeProb = (topQBAvailable ? 0.7 : 0.4) * qbMarketFactor;
      return _random.nextDouble() < qbTradeProb;
    }
    else if (currentPick.pickNumber <= 50) {
      // Lower chance early in second round
      double qbTradeProb = 0.3 * qbMarketFactor;
      return _random.nextDouble() < qbTradeProb;
    }
    
    // Very low chance in later rounds
    return _random.nextDouble() < (0.1 * qbMarketFactor);
  }
  
  /// Check if a team needs a QB in their top priorities
  bool _teamNeedsQB(String teamName) {
    TeamNeed? needs = _getTeamNeeds(teamName);
    if (needs == null) return false;
    
    // Consider QB a priority if in top 3 needs
    return needs.needs.take(3).contains("QB");
  }
  
  /// Execute a trade by swapping team ownership of picks
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
    
    // Track the executed trade
    _executedTrades.add(package);
    
    // Update trade service's market state
    _tradeService.recordTradeExecution(package);
  }
  
  /// Select the best player for a team at a pick position
  Player selectBestPlayerForTeam(String teamName) {
  // Get team needs
  TeamNeed? teamNeed = teamNeeds.firstWhere(
    (need) => need.teamName == teamName,
    orElse: () => TeamNeed(teamName: teamName, needs: []),
  );
  
  // Get next pick
  DraftPick? nextPick = getNextPick();
  if (nextPick == null) {
    // Fallback to best overall player if no pick found
    return availablePlayers.first;
  }
  
  // Use the existing selection algorithm
  return selectPlayerRStyle(teamNeed, nextPick.pickNumber);
}
  
  /// Player selection with realistic balance of BPA and need
Player selectPlayerRStyle(TeamNeed? teamNeed, int pickNumber) {
  // Map of players to their scores
  final Map<Player, double> playerScores = {};
  
  // Get value/need balance for this pick position
  double valueWeight = _getValueNeedRatio(pickNumber);
  double needWeight = 1.0 - valueWeight;
  
  // Calculate scores for top available players (limit to 20 for performance)
  for (var player in availablePlayers.take(min(20, availablePlayers.length))) {
    // Calculate value component (based on rank differential)
    double rankScore = 100.0 - player.rank;
    if (rankScore < 0) rankScore = 0; // Ensure non-negative
    
    // Apply position importance
    double positionFactor = _positionImportance[player.position] ?? 1.0;
    
    // Apply position adjustment based on pick position
    positionFactor = _adjustPositionValueForPickNumber(positionFactor, player.position, pickNumber);
    
    // Calculate position run adjustment
    double runMultiplier = getPositionRunMultiplier(player.position);
    
    // Calculate need component
    double needScore = 0.0;
    if (teamNeed != null) {
      int needIndex = teamNeed.needs.indexOf(player.position);
      if (needIndex != -1) {
        // Higher score for higher need positions
        needScore = 100.0 * (1.0 - (min(needIndex, 9) / 10.0));
      }
    }
    
    // Elite prospect bonus
    double eliteBonus = 0.0;
    if (player.rank <= 5) {
      eliteBonus = 50.0; // Major boost for top-5 players
    } else if (player.rank <= 15) {
      eliteBonus = 30.0; // Good boost for premium players
    } else if (player.rank <= 32) {
      eliteBonus = 15.0; // Moderate boost for 1st rounders
    }
    
    // Combine components with appropriate weights
    double totalScore = (rankScore * valueWeight * positionFactor * runMultiplier) + 
                        (needScore * needWeight) + 
                        (eliteBonus * valueWeight);
    
    // Store the score
    playerScores[player] = totalScore;
  }
  
  // Sort players by score
  final List<MapEntry<Player, double>> sortedPlayers = playerScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  // Get top candidates
  final List<Player> topCandidates = sortedPlayers
      .take(min(5, sortedPlayers.length))
      .map((entry) => entry.key)
      .toList();
  
  // Apply randomness appropriate to the pick position
  double randomnessAdjusted = _getRandomnessByPickPosition(pickNumber);
  
  // With no randomness, just return the top player
  if (randomnessAdjusted <= 0.0) {
    return topCandidates.first;
  }
  
  // Weighted random selection with exponentially decreasing probabilities
  double totalWeight = 0.0;
  final List<double> weights = [];
  
  for (int i = 0; i < topCandidates.length; i++) {
    // Weight decreases exponentially as we go down the list
    double weight = pow(0.5, i * randomnessAdjusted).toDouble();
    weights.add(weight);
    totalWeight += weight;
  }
  
  // Normalize weights to sum to 1.0
  for (int i = 0; i < weights.length; i++) {
    weights[i] /= totalWeight;
  }
  
  // Cumulative distribution function for weighted random selection
  double randomValue = _random.nextDouble();
  double cumulativeProbability = 0.0;
  
  for (int i = 0; i < topCandidates.length; i++) {
    cumulativeProbability += weights[i];
    if (randomValue <= cumulativeProbability) {
      return topCandidates[i];
    }
  }
  
  // Default to top player if something goes wrong
  return topCandidates.first;
}
  
  /// Adjust position value based on pick number
  double _adjustPositionValueForPickNumber(double baseFactor, String position, int pickNumber) {
    if (position == 'QB') {
      // QBs are extremely valuable early, less so later
      if (pickNumber <= 10) return baseFactor * 1.2;
      if (pickNumber <= 32) return baseFactor * 1.1;
      if (pickNumber >= 75) return baseFactor * 0.8;
    }
    
    if (position == 'RB') {
      // RBs are devalued early, more valued in middle rounds
      if (pickNumber <= 32) return baseFactor * 0.8;
      if (pickNumber >= 75 && pickNumber <= 150) return baseFactor * 1.2;
    }
    
    if (position == 'OT') {
      // Tackles maintain high value throughout first two rounds
      if (pickNumber <= 64) return baseFactor * 1.1;
    }
    
    if (position == 'EDGE') {
      // Edge rushers highly valued in first round
      if (pickNumber <= 32) return baseFactor * 1.1;
    }
    
    return baseFactor;
  }
  
  /// Get the value vs. need ratio based on pick position
  double _getValueNeedRatio(int pickNumber) {
    // Find the right tier for this pick
    int tier = _valueNeedRatio.keys
        .where((key) => key <= pickNumber)
        .reduce(max);
    
    // Return the value ratio for this tier
    return _valueNeedRatio[tier] ?? 0.5;
  }
  
  /// Adjust randomness based on pick position
  double _getRandomnessByPickPosition(int pickNumber) {
    double adjustedRandomness = config.randomnessFactor;
    
    // Top picks should be more predictable
    if (pickNumber <= 3) {
      adjustedRandomness *= 0.2; // 80% reduction for top 3
    } else if (pickNumber <= 5) {
      adjustedRandomness *= 0.3; // 70% reduction for picks 4-5
    } else if (pickNumber <= 10) {
      adjustedRandomness *= 0.5; // 50% reduction for picks 6-10
    } else if (pickNumber <= 32) {
      adjustedRandomness *= 0.7; // 30% reduction for first round
    } else if (pickNumber >= 150) {
      adjustedRandomness *= 1.2; // 20% increase for late rounds
    }
    
    return adjustedRandomness;
  }
  
  /// Get the team needs for a specific team
  TeamNeed? _getTeamNeeds(String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      debugPrint('No team needs found for $teamName');
      // Instead of returning null, create a default instance
      return TeamNeed(teamName: teamName, needs: []);
    }
  }
  
  /// Get the round for a specific pick number
  int _getRoundForPick(int pickNumber) {
    return ((pickNumber - 1) / 32).floor() + 1;
  }
  
  /// Get the next pick in the draft order
  DraftPick? getNextPick() {
    for (var pick in draftOrder) {
      if (!pick.isSelected && pick.isActiveInDraft) {
        return pick;
      }
    }
    return null;
  }
  
  /// Get prospect tier based on rank
  ProspectTier _getProspectTier(int rank) {
    if (rank <= 5) return ProspectTier.elite;
    if (rank <= 15) return ProspectTier.premium;
    if (rank <= 32) return ProspectTier.firstRound;
    if (rank <= 64) return ProspectTier.secondRound;
    if (rank <= 150) return ProspectTier.midRound;
    return ProspectTier.lateRound;
  }
  
  /// Check if there are trade offers for a specific pick
  bool hasOffersForPick(int pickNumber) {
    return _pendingUserOffers.containsKey(pickNumber) && 
           _pendingUserOffers[pickNumber]!.isNotEmpty;
  }
  
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
    _isTradeActive = true;
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
  
  /// Get trade offers for current pick
  TradeOffer getTradeOffersForCurrentPick() {
    DraftPick? nextPick = getNextPick();
    if (nextPick == null) {
      return const TradeOffer(
        packages: [],
        pickNumber: 0,
        isUserInvolved: false
      );
    }
    
    return _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
  }
  
  // Public getters for state information
  String get statusMessage => _statusMessage;
  int get currentPick => _currentPickNumber;
  int get completedPicksCount => _completedPicks;
  int get totalPicksCount => draftOrder.where((pick) => pick.isActiveInDraft).length;
  List<TradePackage> get executedTrades => _executedTrades;
  Map<int, List<TradePackage>> get pendingUserOffers => _pendingUserOffers;
  
  /// Check if draft is complete
  bool isDraftComplete() {
    return draftOrder.where((pick) => pick.isActiveInDraft).every((pick) => pick.isSelected);
  }
}