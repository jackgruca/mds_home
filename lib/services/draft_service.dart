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

  
  // Add to DraftService class
  enum ProspectTier {
    elite,      // Top 5 talents
    premium,    // Picks 6-15
    firstRound, // Picks 16-32
    secondRound,// Picks 33-64
    midRound,   // Picks 65-150
    lateRound   // Picks 151+
  }

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

  // Add need / value ratio
  final Map<int, double> _pickPositionValueFactor = {
    1: 0.9,   // Picks 1-10: 90% value, 10% need
    11: 0.8,  // Picks 11-20: 80% value, 20% need
    21: 0.7,  // Picks 21-32: 70% value, 30% need
    33: 0.6,  // Picks 33-64: 60% value, 40% need
    65: 0.5,  // Picks 65-100: 50% value, 50% need
    101: 0.4, // Picks 101+: 40% value, 60% need
  };

  // Method to get value/need ratio based on pick number
  double _getValueNeedRatio(int pickNumber) {
    // Find the appropriate tier
    int tier = _pickPositionValueFactor.keys
        .where((key) => key <= pickNumber)
        .reduce(max);
    
    return _pickPositionValueFactor[tier] ?? 0.5;
  }

  // Get prospect tier based on rank
  ProspectTier _getProspectTier(int rank) {
    if (rank <= 5) return ProspectTier.elite;
    if (rank <= 15) return ProspectTier.premium;
    if (rank <= 32) return ProspectTier.firstRound;
    if (rank <= 64) return ProspectTier.secondRound;
    if (rank <= 150) return ProspectTier.midRound;
    return ProspectTier.lateRound;
  }

  // Get tier-based selection threshold
  double _getTierSelectionThreshold(ProspectTier tier, bool isPremiumPosition) {
    switch (tier) {
      case ProspectTier.elite:
        return isPremiumPosition ? 0.98 : 0.95;  // 98% chance to take elite premium position
      case ProspectTier.premium:
        return isPremiumPosition ? 0.92 : 0.88;  // 92% chance to take premium position
      case ProspectTier.firstRound:
        return isPremiumPosition ? 0.85 : 0.8;   // 85% chance to take first round premium
      case ProspectTier.secondRound:
        return isPremiumPosition ? 0.75 : 0.7;   // Lower percentage for second round
      case ProspectTier.midRound:
        return isPremiumPosition ? 0.6 : 0.55;
      case ProspectTier.lateRound:
        return isPremiumPosition ? 0.45 : 0.4;
    }
  }

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
  
  // Update the _premiumPositions and add position weights
  final Map<String, double> _positionWeights = {
    'QB': 1.5,     // Extremely high premium
    'OT': 1.3,     // High premium
    'EDGE': 1.25,  // High premium 
    'CB': 1.2,     // Significant premium
    'CB | WR': 1.2,
    'WR': 1.15,    // Moderate premium
    'IDL': 1.05,   // Slight premium
    'S': 1.0,      // Neutral
    'TE': 0.95,    // Slightly devalued
    'IOL': 0.95,   // Slightly devalued
    'LB': 0.9,     // Moderately devalued
    'RB': 0.9,    // Significantly devalued
  };

  // Method to get position weight with pick position adjustment
  double _getPositionWeight(String position, int pickNumber) {
    // Base weight from the map, defaulting to 1.0 for unlisted positions
    double baseWeight = _positionWeights[position] ?? 1.0;
    
    // Position-specific adjustments based on draft position
    if (position == 'QB') {
      // QBs are extremely valuable early, less so later
      if (pickNumber <= 10) return baseWeight * 1.2;
      if (pickNumber <= 32) return baseWeight * 1.1;
      if (pickNumber <= 75) return baseWeight * 0.9;
      return baseWeight * 0.8;
    }
    
    if (position == 'RB') {
      // RBs are devalued early, but can be value picks later
      if (pickNumber <= 32) return baseWeight * 0.8;
      if (pickNumber >= 100) return baseWeight * 1.2;
    }
    
    if (position == 'OT') {
      // Tackles maintain high value throughout first two rounds
      if (pickNumber <= 64) return baseWeight * 1.1;
    }
    
    if (position == 'LB') {
      // LBs are increasingly valued in later rounds
      if (pickNumber >= 100) return baseWeight * 1.15;
    }
    
    return baseWeight;
  }

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
    if (nextPick.teamName == userTeam) return false;
    
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
  
  // Position specific value weighting
  double _evaluatePlayerForTeam(Player player, String teamName, TeamNeed? teamNeed, int pickNumber) {
    double score = 100.0 - player.rank; // Base score is inverse of rank
    
    // Apply position weight
    double positionWeight = _getPositionWeight(player.position, pickNumber);
    score *= positionWeight;
    
    // Apply need-based adjustment if needs exist
    if (teamNeed != null && teamNeed.needs.isNotEmpty) {
      int needIndex = teamNeed.needs.indexOf(player.position);
      if (needIndex != -1) {
        // Higher bonus for higher need positions
        double needBonus = (10.0 - min(needIndex, 9.0)) / 10.0;
        
        // Scale need bonus based on pick position (needs matter more later)
        double needScale = pickNumber <= 10 ? 0.1 : 
                          pickNumber <= 32 ? 0.2 :
                          pickNumber <= 100 ? 0.3 : 0.4;
        
        score *= (1.0 + (needBonus * needScale));
      }
    }
    
    // Special handling for elite prospects
    if (player.rank <= 5) {
      // Elite prospects get additional premium
      score *= 1.5;
    } else if (player.rank <= 15) {
      // Premium prospects get moderate boost
      score *= 1.25;
    } else if (player.rank <= 32) {
      // First round talents get small boost
      score *= 1.1;
    }
    
    // Random factor for less predictable behavior
    double randomFactor = 0.9 + (_random.nextDouble() * 0.2);
    score *= randomFactor;
    
    return score;
  }

  /// Select the best player for a team
  Player _selectBestPlayerForTeam(DraftPick pick) {
    // Get team needs
    TeamNeed? teamNeed = _getTeamNeeds(pick.teamName);
    
    // Use enhanced player selection logic
    return selectPlayerRStyle(teamNeed, pick);
  }

  // Modified player selection implementation
  List<Player> _evaluateProspectsByTier(List<Player> availablePlayers, int pickNumber) {
    List<Player> evaluatedPlayers = [];
    
    for (var player in availablePlayers.take(20)) {
      ProspectTier tier = _getProspectTier(player.rank);
      bool isPremiumPosition = _premiumPositions.contains(player.position);
      
      // Calculate selection probability
      double selectionThreshold = _getTierSelectionThreshold(tier, isPremiumPosition);
      
      // Adjust threshold by draft position
      int pickGap = pickNumber - player.rank;
      
      // Higher gap means higher chance to select
      if (pickGap > 0) {
        // Apply increasingly aggressive selection for higher gaps
        selectionThreshold += min(0.3, (pickGap / 30) * 0.3);
      } else if (pickGap < 0) {
        // Reduce likelihood of reaching for players
        selectionThreshold -= min(0.4, (pickGap.abs() / 20) * 0.4);
      }
      
      // Add the evaluated player with its selection probability
      evaluatedPlayers.add(player);
    }
    
    return evaluatedPlayers;
  }
  
  /// Select a player based on the R algorithm - enhanced with better need/position weighting
  Player selectPlayerRStyle(TeamNeed? teamNeed, DraftPick nextPick) {
    // Build a list of evaluated players with both tier and team-specific scoring
    List<Map<String, dynamic>> evaluatedPlayers = [];
    
    for (var player in availablePlayers) {
      // Get tier-based evaluation
      ProspectTier tier = _getProspectTier(player.rank);
      bool isPremiumPosition = _premiumPositions.contains(player.position);
      double tierThreshold = _getTierSelectionThreshold(tier, isPremiumPosition);
      
      // Get team-specific evaluation
      double teamScore = _evaluatePlayerForTeam(
        player, 
        nextPick.teamName, 
        teamNeed, 
        nextPick.pickNumber
      );
      
      // Combine into a single composite score
      double compositeScore = teamScore * tierThreshold;
      
      evaluatedPlayers.add({
        'player': player,
        'score': compositeScore,
        'tier': tier,
        'isPremiumPosition': isPremiumPosition
      });
    }
    
    // Sort by score
    evaluatedPlayers.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    // Get top candidates
    List<Map<String, dynamic>> topCandidates = evaluatedPlayers.take(5).toList();
    
    // Selection strategy varies by pick position
    int pickNumber = nextPick.pickNumber;
    
    if (pickNumber <= 10) {
      // Top 10 picks - most aggressive on pure talent/value
      for (var candidate in topCandidates) {
        // Check if it's an elite prospect
        if (candidate['tier'] == ProspectTier.elite) {
          // 95% chance to take
          if (_random.nextDouble() < 0.95) {
            return candidate['player'];
          }
        }
        
        // Check if it's a premium prospect at premium position
        if (candidate['tier'] == ProspectTier.premium && candidate['isPremiumPosition']) {
          // 90% chance to take
          if (_random.nextDouble() < 0.9) {
            return candidate['player'];
          }
        }
      }
    }
    
    // For any pick, select based on score with some randomness
    double randomThreshold = 0.75;  // Base 75% chance to take top player
    
    // Adjust threshold based on pick number
    if (pickNumber <= 32) {
      randomThreshold = 0.85;  // Higher chance for 1st round
    } else if (pickNumber >= 100) {
      randomThreshold = 0.65;  // Lower chance for later rounds
    }
    
    // Make selection based on threshold
    for (var candidate in topCandidates) {
      if (_random.nextDouble() < randomThreshold) {
        return candidate['player'];
      }
      // Decrease threshold for next candidate
      randomThreshold *= 0.7;
    }
    
    // Default to top scored player if no selection made
    return topCandidates.first['player'];
  }

// Define premium positions set (add this to DraftService class)
final Set<String> _premiumPositions = {
  'QB', 'OT', 'EDGE', 'CB', 'WR', 'CB | WR'
};

// Secondary value positions
final Set<String> _secondaryPositions = {
  'DT', 'S', 'TE', 'IOL', 'LB'
};
  
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
    
    // Find only the current active user pick that's next in the draft
    DraftPick? nextUserPick;
    
    // First find the next pick in the draft order
    DraftPick? nextPick = _getNextPick();
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