// lib/services/draft_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mds_home/screens/draft_overview_screen.dart';

import '../models/draft_pick.dart';
import '../models/future_pick_record.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import '../models/future_pick.dart';
import 'data_service.dart';
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
  // Position market volatility - tracks "runs" on positions
  final Map<String, double> _positionMarketVolatility = {};
  final double tradeFrequency;
  final double needVsValueBalance;

  final List<PlayerSelectionRecord> _userSelectionHistory = [];
  bool _canUndo = false;

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

  /// Get all future picks for a team
  List<FutureDraftPick> getFuturePicks(String teamName) {
    return _teamFuturePicks[teamName] ?? [];
  }
  
  /// Get available (untraded) future pick rounds for a team
  List<int> getAvailableFuturePickRounds(String teamName) {
    final futurePicks = _teamFuturePicks[teamName] ?? [];
    return futurePicks
        .where((pick) => !pick.isTraded && pick.teamOwning == teamName)
        .map((pick) => pick.round)
        .toList();
  }
  
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
  this.tradeFrequency = 0.5,
  this.needVsValueBalance = 0.4,
}) {
  // Store available players in the static DataService cache for lookup
  DataService._availablePlayers = List.from(availablePlayers);
  
  // Sort players by rank initially
  availablePlayers.sort((a, b) => a.rank.compareTo(b.rank));
  
  // Initialize the enhanced trade service
  _tradeService = TradeService(
    draftOrder: draftOrder,
    teamNeeds: teamNeeds,
    availablePlayers: availablePlayers,
    userTeam: userTeams?.isNotEmpty == true ? userTeams!.first : null,
    tradeRandomnessFactor: randomnessFactor,
    enableQBPremium: enableQBPremium,
    tradeFrequency: tradeFrequency,
  );
  
  // Apply actual picks if available
  _applyActualPicks();
  
  _initializeFuturePicks();
}

// Add this new method to the DraftService class
Future<List> _applyActualPicks() async {
  try {
    // Load actual picks
    final actualPicks = await DataService.loadActualPicks(year: 2025);
    
    if (actualPicks.isEmpty) return;
    
    // Log the actual picks we're incorporating
    debugPrint("Incorporating ${actualPicks.length} actual picks into simulation");
    
    // Track actual pick numbers
    List<int> actualPickNumbers = [];
    
    // Process each actual pick
    for (var actualPick in actualPicks) {
      try {
        // Find corresponding pick in draft order
        var draftPickIndex = draftOrder.indexWhere(
          (pick) => pick.pickNumber == actualPick.pickNumber
        );
        
        if (draftPickIndex == -1) {
          debugPrint("Warning: Pick #${actualPick.pickNumber} not found in draft order. Skipping.");
          continue;
        }
        
        // Add to actual pick numbers list if it has a player selected
        if (actualPick.selectedPlayer != null) {
          actualPickNumbers.add(actualPick.pickNumber);
        }
        
        // Rest of the existing code...
      } catch (e) {
        debugPrint("Error applying actual pick #${actualPick.pickNumber}: $e");
      }
    }
    
    // Return the actual pick numbers
    return actualPickNumbers;
    
  } catch (e) {
    debugPrint("Error applying actual picks: $e");
    return [];
  }
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

// Future picks tracking
  final Map<String, List<FutureDraftPick>> _teamFuturePicks = {};

  // Initialize future picks for all teams
  void _initializeFuturePicks() {
    for (var teamNeed in teamNeeds) {
      final teamName = teamNeed.teamName;
      _teamFuturePicks[teamName] = [];
      
      // Add default future picks for each team (2026 draft)
      for (int round = 1; round <= 7; round++) {
        _teamFuturePicks[teamName]!.add(
          FutureDraftPick(
            teamOwning: teamName,
            teamOriginal: teamName,
            round: round,
            year: "2026",
            value: FuturePick.forRound(teamName, round).value,
          )
        );
      }
    }
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
  
  // Check if this pick belongs to any user team and has offers
  return userTeams != null && 
         userTeams!.contains(nextPick.teamName) &&
         hasOffersForPick(nextPick.pickNumber);
}

// Add a method to check if any user team has offers
bool anyUserTeamHasOffers() {
  if (userTeams == null || userTeams!.isEmpty) return false;
  
  // Check if any user team has pending offers
  for (var pickNumber in _pendingUserOffers.keys) {
    // Find the team for this pick
    var pickTeam = draftOrder.firstWhere(
      (pick) => pick.pickNumber == pickNumber, 
      orElse: () => DraftPick(pickNumber: 0, teamName: "", round: "")
    ).teamName;
    
    if (userTeams!.contains(pickTeam)) {
      return true;
    }
  }
  
  return false;
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
  
TradePackage? _evaluateTrades(DraftPick nextPick) {
  // Skip if already has trade info or is a user team pick
  if (nextPick.tradeInfo != null && nextPick.tradeInfo!.isNotEmpty) {
    return null;
  }

  // Enhanced QB need check
  TeamNeed? teamNeeds = _getTeamNeeds(nextPick.teamName);
  int round = DraftValueService.getRoundForPick(nextPick.pickNumber);
  int needsToConsider = min(round + 3, teamNeeds?.needs.length ?? 0);
  
  bool teamNeedsQB = false;
  int qbNeedIndex = -1;
  for (int i = 0; i < needsToConsider; i++) {
    if (teamNeeds != null && teamNeeds.needs[i] == "QB") {
      teamNeedsQB = true;
      qbNeedIndex = i;
      break;
    }
  }
  
  debugPrint("\n==== TRADE EVALUATION DEBUG ====");
  debugPrint("Team: ${nextPick.teamName}");
  debugPrint("Needs QB: $teamNeedsQB");
  if (teamNeedsQB) {
    debugPrint("QB Need Index: $qbNeedIndex");
  }
  
  // More verbose QB prospect check
  bool valuableQBAvailable = availablePlayers
      .where((p) => p.position == "QB" && p.rank <= nextPick.pickNumber + 15)
      .toList()
      .isNotEmpty;
  
  debugPrint("Valuable QB Prospects Available: $valuableQBAvailable");
  
  if (teamNeedsQB && valuableQBAvailable) {
    // 98% chance to stay and draft the QB
    if (_random.nextDouble() < 0.98) {
      debugPrint("Highly likely to draft QB - skipping trade");
      return null;
    }
  }

  // Adjust the base trade chance using the tradeFrequency parameter
  double baseTradeChance = _roundTradeFrequency[round] ?? 0.10;
  // Scale the actual chance by the tradeFrequency (0-1)
  double scaledTradeChance = baseTradeChance * (tradeFrequency * 2);
    
  // Calibrated randomness to determine if we evaluate trades
  bool evaluateTrades = _random.nextDouble() < scaledTradeChance;
    
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
    debugPrint("Skipping already processed trade: $tradeId");
    return; 
  }
  _executedTradeIds.add(tradeId);
  
  debugPrint("\n==== EXECUTING TRADE ====");
  debugPrint("${package.teamOffering} receives: pick #${package.targetPick.pickNumber}");
  debugPrint("${package.teamReceiving} receives: ${package.picksOffered.map((p) => '#${p.pickNumber}').join(', ')}");
  
  final teamReceiving = package.teamReceiving;
  final teamOffering = package.teamOffering;
  
  // Update the target pick to belong to the offering team
  for (var pick in draftOrder) {
    if (pick.pickNumber == package.targetPick.pickNumber) {
      pick.teamName = teamOffering;
      pick.tradeInfo = "From $teamReceiving";
      debugPrint("Updated pick #${pick.pickNumber} to belong to $teamOffering");
      break;
    }
  }
  
  // Update any additional target picks
  for (var additionalPick in package.additionalTargetPicks) {
    for (var pick in draftOrder) {
      if (pick.pickNumber == additionalPick.pickNumber) {
        pick.teamName = teamOffering;
        pick.tradeInfo = "From $teamReceiving";
        debugPrint("Updated additional pick #${pick.pickNumber} to belong to $teamOffering");
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
        debugPrint("Updated offered pick #${pick.pickNumber} to belong to $teamReceiving");
        break;
      }
    }
  }
  
  // Handle future picks
  debugPrint("Future picks in trade:");
  debugPrint("- From offering team (${package.teamOffering}): ${package.futureDraftRounds?.join(', ') ?? 'None'}");
  debugPrint("- From receiving team (${package.teamReceiving}): ${package.targetFutureDraftRounds?.join(', ') ?? 'None'}");
  
  // Handle future picks if included from offering team
  if (package.futureDraftRounds != null && package.futureDraftRounds!.isNotEmpty) {
    debugPrint("Processing ${package.futureDraftRounds!.length} future picks from ${package.teamOffering} to ${package.teamReceiving}");
    // Move future picks from offering team to receiving team
    for (var round in package.futureDraftRounds!) {
      _transferFuturePick(package.teamOffering, package.teamReceiving, round);
    }
  } 
  // Legacy handling for backwards compatibility
  else if (package.includesFuturePick && package.futurePickDescription != null) {
    debugPrint("Using legacy future pick description: ${package.futurePickDescription}");
    // Parse future picks from description and process them
    _processFuturePickFromDescription(package.futurePickDescription!, package.teamOffering, package.teamReceiving);
  }
  
  // Handle target future picks if included
  if (package.targetFutureDraftRounds != null && package.targetFutureDraftRounds!.isNotEmpty) {
    debugPrint("Processing ${package.targetFutureDraftRounds!.length} future picks from ${package.teamReceiving} to ${package.teamOffering}");
    // Move future picks from receiving team to offering team
    for (var round in package.targetFutureDraftRounds!) {
      _transferFuturePick(package.teamReceiving, package.teamOffering, round);
    }
  }
  
  _executedTrades.add(package);
  debugPrint("Trade execution complete\n");
  
  // Print future picks status
  printFuturePicksStatus(package.teamOffering);
  printFuturePicksStatus(package.teamReceiving);
}

// Add this helper method to parse future pick descriptions
void _processFuturePickFromDescription(String description, String fromTeam, String toTeam) {
  String desc = description.toLowerCase();
  if (desc.contains("1st")) _transferFuturePick(fromTeam, toTeam, 1);
  if (desc.contains("2nd")) _transferFuturePick(fromTeam, toTeam, 2);
  if (desc.contains("3rd")) _transferFuturePick(fromTeam, toTeam, 3);
  if (desc.contains("4th")) _transferFuturePick(fromTeam, toTeam, 4);
  if (desc.contains("5th")) _transferFuturePick(fromTeam, toTeam, 5);
  if (desc.contains("6th")) _transferFuturePick(fromTeam, toTeam, 6);
  if (desc.contains("7th")) _transferFuturePick(fromTeam, toTeam, 7);
}
  
  /// Transfer a future pick from one team to another
void _transferFuturePick(String fromTeam, String toTeam, int round) {
  // Find the future pick for the team and round
  if (!_teamFuturePicks.containsKey(fromTeam)) return;
  
  int pickIndex = _teamFuturePicks[fromTeam]!.indexWhere(
    (pick) => pick.round == round && !pick.isTraded
  );
  
  if (pickIndex == -1) {
    // Improved error logging if pick not found
    debugPrint("ERROR: Cannot find available future pick for round $round from team $fromTeam");
    // Check if they have any picks of this round (traded or not)
    int anyPickIndex = _teamFuturePicks[fromTeam]!.indexWhere(
      (pick) => pick.round == round
    );
    if (anyPickIndex != -1) {
      debugPrint("Note: Found a pick but it's already traded");
    }
    return;
  }
  
  // Mark the pick as traded
  final originalPick = _teamFuturePicks[fromTeam]![pickIndex];
  _teamFuturePicks[fromTeam]![pickIndex] = originalPick.copyWith(isTraded: true);
  
  // Add the pick to the receiving team
  if (!_teamFuturePicks.containsKey(toTeam)) {
    _teamFuturePicks[toTeam] = [];
  }
  
  _teamFuturePicks[toTeam]!.add(
    FutureDraftPick(
      teamOwning: toTeam,
      teamOriginal: originalPick.teamOriginal,
      round: round,
      year: originalPick.year,
      value: originalPick.value,
      tradeInfo: "From $fromTeam",
    )
  );
  
  debugPrint("Transferred future $round${_getRoundSuffix(round)} round pick from $fromTeam to $toTeam");
}

  /// Get ordinal suffix for a number
  String _getRoundSuffix(int round) {
    if (round == 1) return "st";
    if (round == 2) return "nd";
    if (round == 3) return "rd";
    return "th";
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
    'QB': 2.0,   // Premium for franchise QBs
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
  
/// Process a user counter offer with leverage premium applied
bool evaluateCounterOffer(TradePackage originalOffer, TradePackage counterOffer) {
  // Use the trade service to evaluate the counter offer with leverage premium
  return _tradeService.evaluateCounterOffer(originalOffer, counterOffer);
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
  int round = DraftValueService.getRoundForPick(nextPick.pickNumber);
  
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
        // Need factor - higher for top needs (ADJUSTED BY needVsValueBalance)
        // Adjust the need weight based on the needVsValueBalance setting (0-1)
        // 0 = BPA focused, 1 = Need focused
        double needWeight = 0.2 + (needVsValueBalance * 0.3); // Range from 0.3 to 0.7
        double needFactor = 1.0 - (i * 0.15); // 1.0 for top need, decreasing
        
        // Value calculation - how good is player relative to pick?
        // (ADJUSTED BY inverse of needVsValueBalance)
        double valueWeight = 0.8 - (needVsValueBalance * 0.3); // Range from 0.7 to 0.3
        int valueGap = nextPick.pickNumber - player.rank;
        double valueScore = valueGap >= 0 
            ? min(1.0, valueGap / 10) // Good value (up to +1.0)
            : max(-0.5, valueGap / 20); // Negative for reaching (-0.5 max penalty)
        
        // Early pick factor - higher standards for top picks
        double pickFactor = 0;
        if (nextPick.pickNumber <= 5) pickFactor = 0.15;
        else if (nextPick.pickNumber <= 15) pickFactor = 0.1;
        else if (nextPick.pickNumber <= 32) pickFactor = 0.05;
        
        // Get position volatility factor
        double volatilityFactor = _positionMarketVolatility[player.position] ?? 0.0;

        // Store all scoring components for debugging
        Map<String, double> scoreComponents = {
          'needFactor': needFactor * needWeight,
          'valueScore': valueScore * valueWeight,
          'positionWeight': posWeight * 0.2,
          'scarcityFactor': scarcityFactor * 0.1,
          'pickFactor': pickFactor,
          'volatilityFactor': volatilityFactor * 0.15 // Add volatility to scoring
        };

        // Calculate player score including position run effect
        double score = scoreComponents.values.reduce((a, b) => a + b);

        // Position runs create urgency for teams
        if (volatilityFactor > 0.3) {
          // The position is getting scarce - teams with this need will prioritize it
          int positionNeedIndex = teamNeed != null ? teamNeed.needs.indexOf(player.position) : -1;
          
          if (positionNeedIndex >= 0 && positionNeedIndex < 3) {
            score += volatilityFactor * 0.2; // Additional boost for positions in active runs
            if (debugMode) {
              debugLog.writeln("    Position Run Boost: +${(volatilityFactor * 0.2).toStringAsFixed(3)} (Volatility: ${volatilityFactor.toStringAsFixed(2)})");
            }
          }
        }
                        
        // Store score
        playerScores[player] = score;
        playerScoreDetails[player] = scoreComponents;
      
        if (debugMode) {
          debugLog.writeln("  - ${player.name} (${player.position}) - Rank #${player.rank}:");
          debugLog.writeln("    Need Factor: ${(needFactor * needWeight).toStringAsFixed(3)} | Value Score: ${(valueScore * valueWeight).toStringAsFixed(3)} | Position Weight: ${(posWeight * 0.2).toStringAsFixed(3)} | Scarcity: ${(scarcityFactor * 0.1).toStringAsFixed(3)} | Pick Factor: ${pickFactor.toStringAsFixed(3)}");
          debugLog.writeln("    Value Gap: $valueGap | Score before randomness: ${score.toStringAsFixed(3)}");
        }
      }
    }
  }
  
  // Also evaluate top 5 overall players (BPA consideration)
  // ADJUSTED BY inverse of needVsValueBalance (stronger BPA with lower value)
  // More weight to BPA approach when needVsValueBalance is low
  double bpaWeight = 1.0 - (needVsValueBalance * 0.5); // 1.0 to 0.5
  final topPlayers = availablePlayers
      .where((p) => p.rank <= min(50, nextPick.pickNumber + 15))
      .take(5)
      .toList();

  if (debugMode) debugLog.writeln("\nEvaluating Top 5 BPA candidates (Weight: ${bpaWeight.toStringAsFixed(2)}):");
      
  for (var player in topPlayers) {
    // Skip if already evaluated through needs
    if (playerScores.containsKey(player)) continue;
    
    // Get position weight
    double posWeight = _positionValueWeights[player.position] ?? 1.0;

    if (player.position == 'QB') {
      posWeight = .5;
    }
    
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
      'needFactor': needFactor * (0.3 + (needVsValueBalance * 0.4)), // Same formula as for needs
      'valueScore': valueScore * (0.7 - (needVsValueBalance * 0.4)) * bpaWeight, // Same formula multiplied by bpaWeight
      'positionWeight': posWeight * 0.2, // Same as need evaluation (currently 0.15)
      'scarcityFactor': scarcityFactor * 0.1 // Same as need evaluation (currently 0.05)
    };
    
    // Calculate score with higher value emphasis
    double score = scoreComponents.values.reduce((a, b) => a + b);
    
    // Store score
    playerScores[player] = score;
    playerScoreDetails[player] = scoreComponents;
  
    if (debugMode) {
      debugLog.writeln("  - ${player.name} (${player.position}) - Rank #${player.rank}:");
      debugLog.writeln("    Need Factor: ${(needFactor * 0.3).toStringAsFixed(3)} | Value Score: ${(valueScore * 0.5 * bpaWeight).toStringAsFixed(3)} | Position Weight: ${(posWeight * 0.15).toStringAsFixed(3)} | Scarcity: ${(scarcityFactor * 0.05).toStringAsFixed(3)}");
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
  
  // Find the next pick in the draft order
  DraftPick? nextPick = _getNextPick();
  if (nextPick == null) return;
  
  // Check if this is a user team pick
  bool isUserTeamPick = userTeams!.contains(nextPick.teamName);
  
  // Generate offers only for the current team's pick
  if (isUserTeamPick) {
    final pickNum = nextPick.pickNumber;
    
    // If there are already offers for this pick, don't regenerate
    if (_pendingUserOffers.containsKey(pickNum)) return;
    
    // Generate trade offers for this pick
    TradeOffer offers = _tradeService.generateTradeOffersForPick(pickNum);
    if (offers.packages.isNotEmpty) {
      _pendingUserOffers[pickNum] = offers.packages;
    }
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
  
  // Clean up any stale trade offers
  cleanupTradeOffers();
  
  // Debug output to verify future picks state
  printFuturePicksStatus(package.teamOffering);
  printFuturePicksStatus(package.teamReceiving);
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

  /// Debug method to print the status of future picks
void printFuturePicksStatus(String teamName) {
  debugPrint("\n==== FUTURE PICKS STATUS FOR $teamName ====");
  final futurePicks = _teamFuturePicks[teamName] ?? [];
  
  if (futurePicks.isEmpty) {
    debugPrint("No future picks registered for $teamName");
    return;
  }
  
  for (var pick in futurePicks) {
    debugPrint("${pick.year} Round ${pick.round}: Owner: ${pick.teamOwning}${pick.teamOriginal != pick.teamOwning ? " (Original: ${pick.teamOriginal})" : ""}${pick.isTraded ? " [TRADED]" : " [AVAILABLE]"} Value: ${pick.value.toStringAsFixed(1)}");
  }
  debugPrint("==========================================\n");
}

/// Record a user selection for undo functionality
void recordUserSelection(DraftPick pick, Player player, List<Player> currentAvailablePlayers) {
  // Create deep copies of all needed state
  List<Player> availablePlayersSnapshot = List.from(currentAvailablePlayers);
  
  // Create deep copies of draft picks with their current state
  List<DraftPick> draftPicksSnapshot = draftOrder.map((dp) {
    return DraftPick(
      pickNumber: dp.pickNumber,
      teamName: dp.teamName,
      selectedPlayer: dp.selectedPlayer,
      round: dp.round,
      originalPickNumber: dp.originalPickNumber,
      tradeInfo: dp.tradeInfo,
      isActiveInDraft: dp.isActiveInDraft,
    );
  }).toList();
  
  // Create deep copies of team needs
  List<TeamNeed> teamNeedsSnapshot = teamNeeds.map((tn) {
    TeamNeed newNeed = TeamNeed(
      teamName: tn.teamName,
      needs: List.from(tn.needs),
    );
    
    // Copy selected positions
    for (var pos in tn.selectedPositions) {
      newNeed.selectedPositions.add(pos);
    }
    
    return newNeed;
  }).toList();
  
  // Record the complete state
  _userSelectionHistory.add(PlayerSelectionRecord(
    pick: pick,
    player: player,
    availablePlayersSnapshot: availablePlayersSnapshot,
    draftPicksSnapshot: draftPicksSnapshot,
    teamNeedsSnapshot: teamNeedsSnapshot,
    pickNumber: pick.pickNumber,
  ));
  
  _canUndo = true;
}

/// Check if there's an action that can be undone
bool canUndo() {
  return _canUndo && _userSelectionHistory.isNotEmpty;
}

/// Undo the last user selection
/// Undo the last user selection and all subsequent picks
bool undoLastUserSelection() {
  if (!canUndo() || _userSelectionHistory.isEmpty) {
    return false;
  }
  
  // Get the last selection record
  final lastSelection = _userSelectionHistory.removeLast();
  
  // The pick number where we want to revert to
  final revertToPick = lastSelection.pickNumber;
  
  // 1. Restore all draft picks to their previous state
  // First identify all picks after the user's pick that need to be completely cleared
  for (var pick in draftOrder) {
    // If this pick comes after the user's pick, clear its selected player
    if (pick.pickNumber >= revertToPick) {
      pick.selectedPlayer = null;
    } else {
      // For picks before or at the user's pick, restore from snapshot
      final snapshotPick = lastSelection.draftPicksSnapshot.firstWhere(
        (sp) => sp.pickNumber == pick.pickNumber,
        orElse: () => pick
      );
      pick.selectedPlayer = snapshotPick.selectedPlayer;
      pick.teamName = snapshotPick.teamName;
      pick.tradeInfo = snapshotPick.tradeInfo;
    }
  }
  
  // 2. Completely restore available players from snapshot
  availablePlayers.clear();
  availablePlayers.addAll(lastSelection.availablePlayersSnapshot);
  
  // 3. Completely restore team needs from snapshot
  for (var teamNeed in teamNeeds) {
    // Find matching team need in snapshot
    final snapshotNeed = lastSelection.teamNeedsSnapshot.firstWhere(
      (tn) => tn.teamName == teamNeed.teamName,
      orElse: () => teamNeed
    );
    
    // Restore needs and selected positions
    teamNeed.needs.clear();
    teamNeed.needs.addAll(snapshotNeed.needs);
    
    teamNeed.selectedPositions.clear();
    teamNeed.selectedPositions.addAll(snapshotNeed.selectedPositions);
  }
  
  // Update the canUndo flag
  _canUndo = _userSelectionHistory.isNotEmpty;
  
  // Return success
  return true;
}

}
class PlayerSelectionRecord {
  final DraftPick pick;
  final Player player;
  final List<Player> availablePlayersSnapshot;
  final List<DraftPick> draftPicksSnapshot;
  final List<TeamNeed> teamNeedsSnapshot;
  final int pickNumber;  // The pick number where we want to revert to
  
  PlayerSelectionRecord({
    required this.pick,
    required this.player,
    required this.availablePlayersSnapshot,
    required this.draftPicksSnapshot,
    required this.teamNeedsSnapshot,
    required this.pickNumber,
  });
}