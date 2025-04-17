// lib/services/draft_history_service.dart
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';

class DraftHistoryEntry {
  final List<Player> availablePlayers;
  final List<DraftPick> draftPicks;
  final List<TeamNeed> teamNeeds;
  final List<TradePackage> executedTrades;
  final int currentPickIndex;
  final String statusMessage;
  
  DraftHistoryEntry({
    required this.availablePlayers,
    required this.draftPicks,
    required this.teamNeeds,
    required this.executedTrades,
    required this.currentPickIndex,
    required this.statusMessage,
  });
}

class DraftHistoryService {
  // Store the last state where user made a decision
  DraftHistoryEntry? _lastUserDecisionState;
  
  // Save the current state as the last user decision point
  void saveCurrentState({
    required List<Player> availablePlayers,
    required List<DraftPick> draftPicks,
    required List<TeamNeed> teamNeeds,
    required List<TradePackage> executedTrades,
    required int currentPickIndex,
    required String statusMessage,
  }) {
    _lastUserDecisionState = DraftHistoryEntry(
      availablePlayers: List<Player>.from(availablePlayers),
      draftPicks: List<DraftPick>.from(draftPicks),
      teamNeeds: List<TeamNeed>.from(teamNeeds),
      executedTrades: List<TradePackage>.from(executedTrades),
      currentPickIndex: currentPickIndex,
      statusMessage: statusMessage,
    );

    debugPrint('Saved draft state at pick #$currentPickIndex');
  }
  
  // Check if there's a state to restore
  bool canUndo() => _lastUserDecisionState != null;
  
  // Get the saved state
  DraftHistoryEntry? getLastUserDecisionState() {
    return _lastUserDecisionState;
  }
  
  // Clear history
  void clear() {
    _lastUserDecisionState = null;
  }
}