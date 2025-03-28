// lib/services/draft_service.dart

// Update the import section at the top of DraftService file
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import 'enhanced_trade_manager.dart';
import 'position_value_tracker.dart';
import 'trade_window_detector.dart';
import 'rival_detector.dart';
import 'trade_dialog_generator.dart';
import '../models/trade_motivation.dart';

// ... Keep the rest of the imports

/// Handles the logic for the draft simulation with enhanced trade integration
class DraftService {
  // Existing properties
  final List<Player> availablePlayers;
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  
  // Draft settings
  final double randomnessFactor;
  final List<String>? userTeams;
  final int numberRounds;
  
  // Enhanced trade system
  late EnhancedTradeManager _tradeManager;
  
  // Position tracking
  late PositionValueTracker _positionTracker;
  
  // Window detection
  late TradeWindowDetector _windowDetector;
  
  // Dialogue generator
  late TradeDialogueGenerator _dialogueGenerator;
  
  // Draft state tracking
  bool _tradeUp = false;
  bool _qbTrade = false;
  String _statusMessage = "";
  int _currentPick = 0;
  final List<TradePackage> _executedTrades = [];
  final Set<String> _executedTradeIds = {};
  
  // Trade configuration
  final bool enableTrading;
  final bool enableUserTradeProposals;
  final bool enableQBPremium;
  
  // Improved trade offer tracking for user
  final Map<int, List<TradePackage>> _pendingUserOffers = {};
  
  // Track draft progress
  int _completedPicks = 0;
  
  // Random instance
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
    
    // Initialize enhanced trade system
    _tradeManager = EnhancedTradeManager(
      draftOrder: draftOrder,
      teamNeeds: teamNeeds,
      availablePlayers: availablePlayers,
      userTeams: userTeams,
      baseTradeFrequency: randomnessFactor,
      enableQBPremium: enableQBPremium,
    );
    
    // Initialize position tracking
    _positionTracker = PositionValueTracker();
    
    // Initialize window detection
    _windowDetector = TradeWindowDetector();
    
    // Initialize dialogue generator
    _dialogueGenerator = TradeDialogueGenerator();
  }

  /// Update the processDraftPick method to use the enhanced trade system
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
    
    // Evaluate potential trades with enhanced system
    TradePackage? executedTrade = _evaluateTradesEnhanced(nextPick);
    
    // If a trade was executed, return the updated pick
    if (executedTrade != null) {
      _tradeUp = true;
      
      // Generate narrative for the trade
      String tradeNarrative = _dialogueGenerator.generateAITradeDialogue(
        executedTrade, 
        null // We don't have the motivation here, but could pass it in future
      );
      
      _statusMessage = tradeNarrative;
      
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
  
  /// Enhanced trade evaluation using the new system
  TradePackage? _evaluateTradesEnhanced(DraftPick nextPick) {
    // Skip if the pick already has trade info
    if (nextPick.tradeInfo != null && nextPick.tradeInfo!.isNotEmpty) {
      return null;
    }

    // Get trade offers using the enhanced trade manager
    TradeOffer tradeOffers = _tradeManager.generateTradeOffersForPick(nextPick.pickNumber);
    
    // If no offers, nothing to evaluate
    if (tradeOffers.packages.isEmpty) {
      return null;
    }
    
    // Don't automatically execute user-involved trades
    if (tradeOffers.isUserInvolved) {
      return null;
    }
    
    // Sort packages by value differential
    List<TradePackage> packages = List.from(tradeOffers.packages);
    packages.sort((a, b) => b.valueDifferential.compareTo(a.valueDifferential));
    
    // We'll take the best package (highest value differential)
    if (packages.isNotEmpty) {
      TradePackage bestPackage = packages.first;
      _executeTrade(bestPackage);
      
      // Record in the trade manager
      _tradeManager.recordCompletedTrade(bestPackage);
      
      return bestPackage;
    }
    
    return null;
  }
  
  /// Generate trade offers for user team pick
  void _generateUserTradeOffers(DraftPick userPick) {
    // Generate trade offers using the enhanced trade manager
    TradeOffer tradeOffers = _tradeManager.generateTradeOffersForPick(userPick.pickNumber);
    
    // Store the offers for the user to consider
    if (tradeOffers.packages.isNotEmpty) {
      _pendingUserOffers[userPick.pickNumber] = tradeOffers.packages;
    } else {
      _pendingUserOffers.remove(userPick.pickNumber);
    }
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
  
  /// Update simulation state after player selection
  void _updateAfterSelection(DraftPick pick, Player player) {
    // Update team needs by removing the position that was just filled
    TeamNeed? teamNeed = _getTeamNeeds(pick.teamName);
    if (teamNeed != null) {
      teamNeed.removeNeed(player.position);
    }
    
    // Update position tracker
    _positionTracker.recordSelection(player);
    
    // Update window detector
    _windowDetector.recordSelection(player);
    
    // Remove player from available players
    availablePlayers.remove(player);
    
    // Update trade manager with selection
    // (This is handled internally by sharing the availablePlayers reference)
    
    // Track completed picks
    _completedPicks++;
    
    // Set status message
    _statusMessage = "Pick #${pick.pickNumber}: ${pick.teamName} selects ${player.name} (${player.position})";
  }
  
  /// Process a user trade proposal with enhanced system
  bool processUserTradeProposal(TradePackage proposal) {
    // Determine if the AI team should accept
    final shouldAccept = _tradeManager.evaluateTradeProposal(proposal);
    
    // Execute the trade if accepted
    if (shouldAccept) {
      _executeTrade(proposal);
      _statusMessage = "Trade accepted: ${proposal.tradeDescription}";
      _tradeManager.recordCompletedTrade(proposal);
    }
    
    return shouldAccept;
  }
  
  /// Get a realistic rejection reason if trade is declined
  String getTradeRejectionReason(TradePackage proposal) {
    // Use the dialogue generator to create a narrative
    return _dialogueGenerator.generateRejectionDialogue(proposal, null);
  }
  
  /// Generate a narrative for an executed trade
  String getTradeNarrative(TradePackage package) {
    return _dialogueGenerator.generateAITradeDialogue(package, null);
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
      
      // Generate using enhanced system
      TradeOffer offers = _tradeManager.generateTradeOffersForPick(pickNum);
      if (offers.packages.isNotEmpty) {
        _pendingUserOffers[pickNum] = offers.packages;
      }
    }
  }
  
  /// Select the best player for a team
  Player _selectBestPlayerForTeam(DraftPick pick) {
    // Get team needs
    TeamNeed? teamNeed = _getTeamNeeds(pick.teamName);
    
    // Use the core selection logic, but with position tracking
    return selectPlayerRStyle(teamNeed, pick);
  }
   /// Check if there are trade offers for a specific user pick
  bool hasOffersForPick(int pickNumber) {
    return _pendingUserOffers.containsKey(pickNumber) && 
           _pendingUserOffers[pickNumber]!.isNotEmpty;
  }
  
  /// Get all pending offers for user team
  Map<int, List<TradePackage>> get pendingUserOffers => _pendingUserOffers;
  
  /// Evaluate a user counter offer with enhanced system
  bool evaluateCounterOffer(TradePackage originalOffer, TradePackage counterOffer) {
    // Counter offers have leverage, so they have higher acceptance chance
    return _tradeManager.evaluateTradeProposal(counterOffer);
  }

  /// Select player with enhanced position value tracking
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
      
      // Get position value weight from enhanced tracker
      double posWeight = _positionTracker.getPositionValueMultiplier(needPosition);
      
      // Check for position runs and tier dropoffs
      double contextAdjustment = _positionTracker.getContextAdjustedPremium(
        needPosition, 
        availablePlayers
      );

      if (debugMode) {
        debugLog.writeln("  Position weight: $posWeight | Context adjustment: $contextAdjustment");
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
        
        // Apply position run / tier dropoff adjustment
        double marketContextFactor = contextAdjustment - 1.0; // Extract just the adjustment portion
        
        // Store all scoring components for debugging
        Map<String, double> scoreComponents = {
          'needFactor': needFactor * 0.35,
          'valueScore': valueScore * 0.25,
          'positionWeight': posWeight * 0.2,
          'marketContext': marketContextFactor * 0.15,
          'pickFactor': pickFactor
        };

        // Calculate player score - adjusting weights to include market context
        double score = scoreComponents.values.reduce((a, b) => a + b);
                      
        // Store score
        playerScores[player] = score;
        playerScoreDetails[player] = scoreComponents;
      
        if (debugMode) {
          debugLog.writeln("  - ${player.name} (${player.position}) - Rank #${player.rank}:");
          debugLog.writeln("    Need Factor: ${(needFactor * 0.35).toStringAsFixed(3)} | Value Score: ${(valueScore * 0.25).toStringAsFixed(3)}");
          debugLog.writeln("    Position Weight: ${(posWeight * 0.2).toStringAsFixed(3)} | Market Context: ${(marketContextFactor * 0.15).toStringAsFixed(3)}");
          debugLog.writeln("    Pick Factor: ${pickFactor.toStringAsFixed(3)} | Value Gap: $valueGap");
          debugLog.writeln("    Score before randomness: ${score.toStringAsFixed(3)}");
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
    
    // Get position value weight
    double posWeight = _positionTracker.getPositionValueMultiplier(player.position);
    
    // Get context adjustment
    double contextAdjustment = _positionTracker.getContextAdjustedPremium(
      player.position, 
      availablePlayers
    );
    
    // Value calculation
    int valueGap = nextPick.pickNumber - player.rank;
    double valueScore = valueGap >= 0 
        ? min(1.0, valueGap / 10) 
        : max(-0.5, valueGap / 20);
    
    // BPA gets a boost but need factor is low
    double needFactor = 0.4; // Low since not in needs list
    
    // Apply position run / tier dropoff adjustment
    double marketContextFactor = contextAdjustment - 1.0; // Extract just the adjustment portion
    
    // Store all scoring components for debugging
    Map<String, double> scoreComponents = {
      'needFactor': needFactor * 0.2,
      'valueScore': valueScore * 0.45,
      'positionWeight': posWeight * 0.2,
      'marketContext': marketContextFactor * 0.15
    };
    
    // Calculate score with higher value emphasis for BPA
    double score = scoreComponents.values.reduce((a, b) => a + b);
    
    // Store score
    playerScores[player] = score;
    playerScoreDetails[player] = scoreComponents;
  
    if (debugMode) {
      debugLog.writeln("  - ${player.name} (${player.position}) - Rank #${player.rank}:");
      debugLog.writeln("    Need Factor: ${(needFactor * 0.2).toStringAsFixed(3)} | Value Score: ${(valueScore * 0.45).toStringAsFixed(3)}");
      debugLog.writeln("    Position Weight: ${(posWeight * 0.2).toStringAsFixed(3)} | Market Context: ${(marketContextFactor * 0.15).toStringAsFixed(3)}");
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
  
  
  /// Execute a specific trade (for use with UI)
  void executeUserSelectedTrade(TradePackage package) {
    _executeTrade(package);
    
    // Generate narrative for the trade
    String tradeNarrative = _dialogueGenerator.generateAITradeDialogue(
      package, 
      null
    );
    
    _statusMessage = tradeNarrative;
    _tradeUp = true;
    
    // Record in trade manager
    _tradeManager.recordCompletedTrade(package);
  }
  
  /// Clean up stale trade offers
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
  }
  
  /// Check if there are offers for the current pick
  bool hasOffersForCurrentPick() {
    DraftPick? nextPick = _getNextPick();
    if (nextPick == null) {
      return false;
    }
    
    // Check if this pick belongs to any user team and has offers
    return userTeams != null && 
           userTeams!.contains(nextPick.teamName) &&
           hasOffersForPick(nextPick.pickNumber);
  }
  
  /// Check if any user team has offers
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
  
  /// Get trade offers for the current pick
  TradeOffer getTradeOffersForCurrentPick() {
    DraftPick? nextPick = _getNextPick();
    if (nextPick == null) {
      return const TradeOffer(packages: [], pickNumber: 0);
    }
    
    // First clean up any stale offers
    cleanupTradeOffers();
    
    // Use enhanced trade manager to generate offers
    return _tradeManager.generateTradeOffersForPick(nextPick.pickNumber);
  }
  
  /// Get all available picks for a specific team
  List<DraftPick> getTeamPicks(String teamName) {
    return draftOrder.where((pick) => 
      pick.teamName == teamName && !pick.isSelected
    ).toList();
  }
  
  /// Get other team picks (all picks except for specified teams)
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
  
  /// Get team needs for a specific team
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
  
  /// Select the best player available with appropriate randomness
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
  
  /// Select the best player available from the list
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
  
  // Getters for state information
  String get statusMessage => _statusMessage;
  int get currentPick => _currentPick;
  int get completedPicksCount => draftOrder.where((pick) => pick.isSelected).length;
  int get totalPicksCount => draftOrder.length;
  List<TradePackage> get executedTrades => _executedTrades;
  bool get isDraftComplete => draftOrder.where((pick) => pick.isActiveInDraft).every((pick) => pick.isSelected);
}


