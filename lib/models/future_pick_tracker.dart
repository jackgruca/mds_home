// lib/models/future_pick_tracker.dart
import 'package:flutter/material.dart';
import 'future_pick.dart';

/// Tracker for future pick ownership across teams
class FuturePickTracker {
  // Map of team name -> list of future picks they own
  static final Map<String, List<FuturePick>> _teamFuturePicks = {};
  
  // Map of team name -> list of future picks they've traded away
  static final Map<String, List<FuturePick>> _tradedAwayPicks = {};
  
  /// Initialize with original team ownership (each team owns their own picks)
  static void initialize(List<String> teams) {
  _teamFuturePicks.clear();
  _tradedAwayPicks.clear();
  
  // Give each team their original picks (1-7 rounds)
  for (var team in teams) {
    _teamFuturePicks[team] = [];
    _tradedAwayPicks[team] = [];
    
    // Add default future picks for each round
    for (int round = 1; round <= 7; round++) {
      _teamFuturePicks[team]!.add(FuturePick.forRound(team, round));
    }
  }
  
  debugPrint("FuturePickTracker initialized with ${teams.length} teams");
}
  
  /// Record a trade of future picks
  static void recordFuturePickTrade(String fromTeam, String toTeam, List<FuturePick> picks) {
    for (var pick in picks) {
      // Check if the originating team owns this pick
      bool pickFound = false;
      
      // Find and remove from current owner
      if (_teamFuturePicks.containsKey(fromTeam)) {
        for (int i = 0; i < _teamFuturePicks[fromTeam]!.length; i++) {
          var ownedPick = _teamFuturePicks[fromTeam]![i];
          
          // Match by round and year
          if (ownedPick.estimatedRound == pick.estimatedRound && 
              ownedPick.year == pick.year) {
            _teamFuturePicks[fromTeam]!.removeAt(i);
            pickFound = true;
            
            // Add to traded away list for originating team
            _tradedAwayPicks[fromTeam] ??= [];
            _tradedAwayPicks[fromTeam]!.add(pick);
            
            // Give to receiving team
            _teamFuturePicks[toTeam] ??= [];
            _teamFuturePicks[toTeam]!.add(pick);
            
            break;
          }
        }
      }
      
      if (!pickFound) {
        debugPrint("WARNING: Attempted to trade future pick that team $fromTeam doesn't own: "
            "Round ${pick.estimatedRound}, ${pick.year}");
      }
    }
  }
  
  /// Get all future picks owned by a team
  static List<FuturePick> getTeamFuturePicks(String team) {
    return _teamFuturePicks[team] ?? [];
  }
  
  /// Get all future picks traded away by a team
  static List<FuturePick> getTeamTradedAwayPicks(String team) {
    return _tradedAwayPicks[team] ?? [];
  }
  
  /// Check if a team owns a specific future pick
  static bool teamOwnsFuturePick(String team, int round, {String year = '2026'}) {
    if (!_teamFuturePicks.containsKey(team)) return false;
    
    for (var pick in _teamFuturePicks[team]!) {
      if (pick.estimatedRound == round && pick.year == year) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Reset all future pick tracking
  static void reset() {
    _teamFuturePicks.clear();
    _tradedAwayPicks.clear();
  }
}