// lib/services/draft_service.dart
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
  final Set<String> _executedTradeIds = {}; 
  
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
    
    // Evaluate potential trades using realistic behavior
    TradePackage? executedTrade = _evaluateTrades(nextPick);
    
    // If a trade was executed, return the updated pick
    if (executedTrade != null) {
      _tradeUp = true;
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
  
  /// Evaluate potential trades for the current pick with realistic behavior
  TradePackage? _evaluateTrades(DraftPick nextPick) {
    // Skip trade evaluation if user team or if the pick already has trade info
    if (nextPick.teamName == userTeam || (nextPick.tradeInfo != null && nextPick.tradeInfo!.isNotEmpty)) {
      return null;
    }
    
    // Generate trade offers for this pick
    // For QB-specific trades, check available QBs first
    final availableQBs = availablePlayers
        .where((p) => p.position == "QB" && p.rank <= 20)
        .toList();
    
    // Higher probability for QB trades when top QBs are available early
    bool tryQBTrade = false;
    if (nextPick.pickNumber <= 15 && availableQBs.isNotEmpty) {
      // Check if any team has QB as a top need
      bool topQBAvailable = availableQBs.any((qb) => qb.rank <= 10);
      double qbTradeProb = topQBAvailable ? 0.7 : 0.4;
      tryQBTrade = _random.nextDouble() < qbTradeProb;
    }
    
    if (tryQBTrade) {
      final qbTradeOffer = _tradeService.generateTradeOffersForPick(
        nextPick.pickNumber, 
        qbSpecific: true
      );
      
      if (qbTradeOffer.hasFairTrades) {
        final bestPackage = qbTradeOffer.bestPackage;
        if (bestPackage != null && _shouldAcceptTradeRealistic(bestPackage, isQBTrade: true)) {
          _qbTrade = true;
          _executeTrade(bestPackage);
          return bestPackage;
        }
      }
    }
    
    // Regular trade evaluations
    final tradeOffer = _tradeService.generateTradeOffersForPick(nextPick.pickNumber);
    
    if (tradeOffer.hasFairTrades) {
      // Sort packages by value differential
      List<TradePackage> sortedPackages = List.from(tradeOffer.packages);
      sortedPackages.sort((a, b) => 
        b.valueDifferential.compareTo(a.valueDifferential)
      );
      
      // Try best package first
      if (sortedPackages.isNotEmpty) {
        final bestPackage = sortedPackages.first;
        if (_shouldAcceptTradeRealistic(bestPackage)) {
          _executeTrade(bestPackage);
          return bestPackage;
        }
        
        // Try second package if available
        if (sortedPackages.length > 1) {
          final secondPackage = sortedPackages[1];
          if (_shouldAcceptTradeRealistic(secondPackage, secondChoice: true)) {
            _executeTrade(secondPackage);
            return secondPackage;
          }
        }
      }
    }
    
    return null;
  }
  
  /// Determine if a trade should be accepted using realistic criteria
  bool _shouldAcceptTradeRealistic(TradePackage package, {bool isQBTrade = false, bool secondChoice = false}) {
    // Core decision factors
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    final pickNumber = package.targetPick.pickNumber;
    
    // 1. Consider value - foundation of any trade decision
    double acceptanceProbability;
    
    if (valueRatio >= 1.2) {
      // Excellent value (20%+ surplus)
      acceptanceProbability = 0.85;
    } else if (valueRatio >= 1.1) {
      // Good value (10-20% surplus)
      acceptanceProbability = 0.7;
    } else if (valueRatio >= 1.0) {
      // Fair value (0-10% surplus)
      acceptanceProbability = 0.55;
    } else if (valueRatio >= 0.9) {
      // Slightly below value (0-10% below)
      acceptanceProbability = 0.3;
    } else {
      // Poor value (>10% below)
      acceptanceProbability = 0.1;
    }
    
    // 2. Consider pick position - early picks carry premium
    if (pickNumber <= 5) {
      acceptanceProbability -= 0.2; // Top 5 picks have premium value
    } else if (pickNumber <= 10) {
      acceptanceProbability -= 0.15; // Top 10 picks have significant premium
    } else if (pickNumber <= 32) {
      acceptanceProbability -= 0.1; // 1st round picks have moderate premium
    } else if (pickNumber <= 64) {
      acceptanceProbability -= 0.05; // 2nd round picks have slight premium
    }
    
    // 3. Consider player availability - don't trade if great player available
    final teamNeed = _getTeamNeed(package.teamReceiving);
    if (teamNeed != null) {
      // Check top 3 available players to see if they match team needs
      final topPlayers = availablePlayers.take(3).toList();
      
      bool topNeedPlayerAvailable = false;
      for (var player in topPlayers) {
        if (teamNeed.needs.take(2).contains(player.position)) {
          topNeedPlayerAvailable = true;
          break;
        }
      }
      
      if (topNeedPlayerAvailable) {
        acceptanceProbability -= 0.2; // Less likely to trade with top need player available
      }
    }
    
    // 4. Consider package composition
    // Teams often prefer specific package types
    
    // Prefer packages with future picks in early rounds
    if (package.includesFuturePick && pickNumber <= 32) {
      acceptanceProbability += 0.1;
    }
    
    // Prefer packages with multiple picks for rebuilding teams
    bool isRebuildingTeam = false;
    if (teamNeed != null) {
      // Rough proxy for rebuilding - multiple high needs
      isRebuildingTeam = teamNeed.needs.length >= 5;
    }
    
    if (isRebuildingTeam && package.picksOffered.length > 1) {
      acceptanceProbability += 0.15;
    }
    
    // 5. QB-specific adjustments
    if (isQBTrade) {
      acceptanceProbability += 0.15; // Teams more willing to trade when QBs involved
    }
    
    // 6. Adjust for second-choice packages
    if (secondChoice) {
      acceptanceProbability -= 0.1;
    }
    
    // 7. Add randomness for team-specific preferences
    final randomFactor = _random.nextDouble() * randomnessFactor - (randomnessFactor / 2);
    acceptanceProbability += randomFactor;
    
    // Ensure probability is within 0-1 range
    acceptanceProbability = min(0.95, max(0.05, acceptanceProbability));
    
    // Make final decision
    return _random.nextDouble() < acceptanceProbability;
  }
  
  /// Execute a trade by swapping teams for picks
  void _executeTrade(TradePackage package) {
    // Add these lines:
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
        pick.teamName = teamOffering; // Now works with updated model
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
          pick.teamName = teamReceiving; // Now works with updated model
          pick.tradeInfo = "From $teamOffering";
          break;
        }
      }
    }
    
    _executedTrades.add(package);
  }
  
  /// Get a realistic rejection reason if trade is declined
  String? getTradeRejectionReason(TradePackage proposal) {
    final valueRatio = proposal.totalValueOffered / proposal.targetPickValue;
    final teamNeed = teamNeeds.firstWhere(
      (need) => need.teamName == proposal.teamReceiving,
      orElse: () => TeamNeed(teamName: proposal.teamReceiving, needs: []),
    );
    
    // 1. Value-based rejections
    if (valueRatio < 0.85) {
      final options = [
        "The offer doesn't provide sufficient draft value.",
        "We need more compensation to move down from this position.",
        "That offer falls well short of our valuation of this pick.",
        "We're looking for significantly more value to make this move.",
        "Our draft models show this proposal undervalues our pick considerably."
      ];
      return options[_random.nextInt(options.length)];
    }
    
    // 2. Slightly below market value
    else if (valueRatio < 0.95) {
      final options = [
        "We're close, but we need a bit more value to make this deal work.",
        "The offer is slightly below what we're looking for.",
        "We'd need a little more compensation to justify moving back.",
        "Interesting offer, but not quite enough value for us.",
        "Our analytics team is looking for a slightly better return."
      ];
      return options[_random.nextInt(options.length)];
    }
    
    // 3. Need-based rejections (when value is fair but team has needs)
    else if (teamNeed.needs.isNotEmpty) {
      // Check if there are players available that match team needs
      final topPlayers = availablePlayers.take(5).toList();
      bool hasNeedMatch = false;
      
      for (var player in topPlayers) {
        if (teamNeed.needs.take(3).contains(player.position)) {
          hasNeedMatch = true;
          break;
        }
      }
      
      if (hasNeedMatch) {
        final options = [
          "We have our eye on a specific player at this position.",
          "We believe we can address a key roster need with this selection.",
          "Our scouts are high on a player that should be available here.",
          "We have immediate needs that we're planning to address with this pick.",
          "Our draft board has fallen favorably, and we're targeting a player at this spot."
        ];
        return options[_random.nextInt(options.length)];
      }
    }
    
    // 4. Position-specific concerns
    final pickNumber = proposal.targetPick.pickNumber;
    if (pickNumber <= 15) {
      // Early picks often involve premium positions
      final premiumPositionOptions = [
        "We're targeting a blue-chip talent at a premium position with this pick.",
        "Our front office values the opportunity to select a game-changing player here.",
        "We believe there's a franchise cornerstone available at this position.",
        "Our draft strategy is built around making this selection."
      ];
      return premiumPositionOptions[_random.nextInt(premiumPositionOptions.length)];
    }
    
    // 5. Future pick preferences (when teams want current picks)
    else if (proposal.includesFuturePick) {
      final options = [
        "We're focused on building our roster now rather than acquiring future assets.",
        "We prefer more immediate draft capital over future picks.",
        "Our preference is for picks in this year's draft.",
        "We're not looking to add future draft capital at this time.",
        "Our team is in win-now mode and we need immediate contributors."
      ];
      return options[_random.nextInt(options.length)];
    }
    
    // 6. Generic rejections for when value is fair but team still declines
    else {
      final options = [
        "After careful consideration, we've decided to stay put and make our selection.",
        "We've received several offers and are going in a different direction.",
        "We're comfortable with our draft position and plan to make our pick.",
        "Our draft board has fallen favorably, so we're keeping the pick.",
        "We don't see enough value in moving back from this position.",
        "The timing isn't right for us on this deal.",
        "We've decided to pass on this opportunity."
      ];
      return options[_random.nextInt(options.length)];
    }
  }
  
  /// Get the next pick in the draft order
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

  /// Process a user-proposed trade with realistic acceptance criteria
  bool processUserTradeProposal(TradePackage proposal) {
    // Use realistic trade acceptance logic
    final shouldAccept = _shouldAcceptTradeRealistic(proposal);
    
    // Execute the trade if accepted
    if (shouldAccept) {
      _executeTrade(proposal);
      _statusMessage = "Trade accepted: ${proposal.tradeDescription}";
    }
    
    return shouldAccept;
  }
}