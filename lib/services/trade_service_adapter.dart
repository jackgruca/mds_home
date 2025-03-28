// lib/services/trade_service_adapter.dart
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../models/trade_offer.dart';
import '../models/trade_motivation.dart';
import 'enhanced_trade_manager.dart';
import 'trade_dialog_generator.dart';

/// Bridge adapter that implements the TradeService interface 
/// but uses the new EnhancedTradeManager internally
class TradeServiceAdapter {
  // The new implementation
  final EnhancedTradeManager _manager;
  
  // Dialogue generator for narratives
  final TradeDialogueGenerator _dialogueGenerator;
  
  // Motivation cache for recent trades
  final Map<String, TradeMotivation> _tradeMotivations = {};
  
  TradeServiceAdapter({
    required List<DraftPick> draftOrder,
    required List<TeamNeed> teamNeeds,
    required List<Player> availablePlayers,
    List<String>? userTeams,
    bool enableUserTradeConfirmation = true,
    double tradeRandomnessFactor = 0.5,
    bool enableQBPremium = true,
  }) : 
    _manager = EnhancedTradeManager(
    draftOrder: draftOrder,
    teamNeeds: teamNeeds,
    availablePlayers: availablePlayers,
    userTeams: userTeams,
    baseTradeFrequency: tradeRandomnessFactor,
    enableQBPremium: enableQBPremium,
),

    _dialogueGenerator = TradeDialogueGenerator();
  
  /// Generate trade offers for a specific pick (implements original API)
  TradeOffer generateTradeOffersForPick(int pickNumber, {bool qbSpecific = false}) {
    return _manager.generateTradeOffersForPick(pickNumber, qbSpecific: qbSpecific);
  }
  
  /// Process a user trade proposal (implements original API)
  bool evaluateTradeProposal(TradePackage proposal) {
    return _manager.evaluateTradeProposal(proposal);
  }
  
  /// Process a counter offer with leverage premium (implements original API)
  bool evaluateCounterOffer(TradePackage originalOffer, TradePackage counterOffer) {
    // Counter offers have leverage, so they have higher acceptance chance
    return _manager.evaluateTradeProposal(counterOffer);
  }
  
  /// Get a realistic rejection reason if trade is declined (implements original API)
  String getTradeRejectionReason(TradePackage proposal) {
    // Get cached motivation if we have one
    TradeMotivation? motivation = _tradeMotivations[proposal.teamReceiving];
    
    // Generate rejection dialogue
    return _dialogueGenerator.generateRejectionDialogue(proposal, motivation);
  }
  
  /// Calculate the total number of picks given up vs. received (implements original API)
  Map<String, int> calculatePickCounts(TradePackage package) {
    int picksGiven = package.picksOffered.length;
    int picksReceived = 1 + package.additionalTargetPicks.length;
    
    if (package.includesFuturePick) {
      // Estimate future picks from description
      if (package.futurePickDescription != null) {
        // Simple estimation - count "and" + 1, or at least 1
        if (package.futurePickDescription!.contains(" and ")) {
          picksGiven += package.futurePickDescription!.split(" and ").length;
        } else {
          picksGiven += 1;
        }
      } else {
        picksGiven += 1;
      }
    }
    
    return {
      'given': picksGiven,
      'received': picksReceived,
    };
  }
  
  /// Record a new trade motivation
  void recordTradeMotivation(String team, TradeMotivation motivation) {
    _tradeMotivations[team] = motivation;
  }
  
  /// Get a trade motivation for a team (if available)
  TradeMotivation? getTradeMotivation(String team) {
    return _tradeMotivations[team];
  }
  
  /// Generate narrative for a trade
  String generateTradeNarrative(TradePackage package) {
    TradeMotivation? motivation = _tradeMotivations[package.teamOffering];
    return _dialogueGenerator.generateAITradeDialogue(package, motivation);
  }
  
  /// Clear any cached state
  void clearState() {
    _tradeMotivations.clear();
  }
}