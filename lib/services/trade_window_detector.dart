// lib/services/trade_window_detector.dart
import 'dart:collection';
import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/trade_motivation.dart';

/// Detects trade windows based on position runs and talent tier dropoffs
class TradeWindowDetector {
  // Recent selections to track position runs
  final Queue<Player> _recentSelections = Queue<Player>();
  final int _maxSelections = 15; // Track the last 15 picks
  
  // Position run thresholds
  final int _runThreshold = 2; // Number of same positions to consider a "run"
  final int _lookbackWindow = 5; // How far back to check for position runs
  
  // Tracking for tier dropoffs by position
  final Map<String, List<int>> _rankTiers = {
    'QB': [5, 15, 35, 75, 150],    // Quarterback tiers
    'RB': [10, 25, 60, 110, 175],  // Running back tiers
    'WR': [5, 20, 45, 85, 150],    // Wide receiver tiers
    'TE': [15, 35, 75, 125, 200],  // Tight end tiers
    'OT': [10, 25, 50, 100, 180],  // Offensive tackle tiers
    'IOL': [20, 45, 75, 125, 200], // Interior O-line tiers
    'EDGE': [10, 25, 50, 100, 175], // Edge rusher tiers
    'DL': [15, 35, 65, 115, 190],  // Defensive line tiers
    'LB': [20, 40, 70, 120, 200],  // Linebacker tiers
    'CB': [10, 25, 50, 90, 160],   // Cornerback tiers
    'S': [15, 35, 65, 110, 175],   // Safety tiers
  };
  
  // Cached trade windows to avoid recalculation
  final Map<int, List<TradeWindow>> _cachedWindows = {};
  
  /// Record a player selection to track position runs
  void recordSelection(Player player) {
    _recentSelections.add(player);
    
    // Maintain maximum size
    if (_recentSelections.length > _maxSelections) {
      _recentSelections.removeFirst();
    }
    
    // Clear cached windows since they're now outdated
    _cachedWindows.clear();
  }

  /// Get all active position runs
  Map<String, int> getActivePositionRuns() {
    Map<String, int> positionCounts = {};
    int recentChecks = 0;
    
    // Count positions in the last 7 picks
    for (var player in _recentSelections.toList().reversed) {
      if (recentChecks >= 7) break;
      recentChecks++;
      
      positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
    }
    
    // Filter to only positions with 2+ selections
    return Map.fromEntries(
      positionCounts.entries.where((e) => e.value >= 2)
    );
  }
  
  /// Get active trade windows for the current pick
  List<TradeWindow> getTradeWindows(int pickNumber, List<Player> availablePlayers) {
    // Check cache first
    if (_cachedWindows.containsKey(pickNumber)) {
      return _cachedWindows[pickNumber]!;
    }
    
    List<TradeWindow> activeWindows = [];
    
    // Detect position runs
    activeWindows.addAll(_detectPositionRuns());
    
    // Detect talent tier dropoffs
    activeWindows.addAll(_detectTierDropoffs(availablePlayers));
    
    // Cache the results
    _cachedWindows[pickNumber] = activeWindows;
    
    return activeWindows;
  }
  
  /// Detect position runs in recent selections
  List<TradeWindow> _detectPositionRuns() {
    Map<String, int> positionCounts = {};
    List<TradeWindow> windows = [];
    
    // Count positions in the recent lookback window
    int count = 0;
    for (var player in _recentSelections.toList().reversed) {
      if (count >= _lookbackWindow) break;
      count++;
      
      positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
    }
    
    // Find positions with runs
    for (var entry in positionCounts.entries) {
      if (entry.value >= _runThreshold) {
        windows.add(TradeWindow.positionRun(entry.key, entry.value));
      }
    }
    
    return windows;
  }
  
  /// Detect talent tier dropoffs in available players
  List<TradeWindow> _detectTierDropoffs(List<Player> availablePlayers) {
    Map<String, List<Player>> positionGroups = {};
    List<TradeWindow> windows = [];
    
    // Group available players by position
    for (var player in availablePlayers) {
      if (!positionGroups.containsKey(player.position)) {
        positionGroups[player.position] = [];
      }
      positionGroups[player.position]!.add(player);
    }
    
    // Check each position group for tier dropoffs
    for (var entry in positionGroups.entries) {
      final position = entry.key;
      final players = entry.value;
      
      // Skip if not enough players or no tier data
      if (players.length < 2 || !_rankTiers.containsKey(position)) {
        continue;
      }
      
      // Sort by rank
      players.sort((a, b) => a.rank.compareTo(b.rank));
      
      // Get tier thresholds for this position
      final tiers = _rankTiers[position]!;
      
      // Find current tier and count players in it
      int currentTier = -1;
      for (int i = 0; i < tiers.length; i++) {
        if (players.first.rank <= tiers[i]) {
          currentTier = i;
          break;
        }
      }
      
      // If no tier found, skip
      if (currentTier == -1) continue;
      
      // Count players in the current tier
      int playersInTier = 0;
      int tierThreshold = tiers[currentTier];
      
      for (var player in players) {
        if (player.rank <= tierThreshold) {
          playersInTier++;
        } else {
          break; // Once we hit next tier, stop counting
        }
      }
      
      // If only 1-2 players left in tier, create a trade window
      if (playersInTier <= 2) {
        windows.add(TradeWindow.tierDropoff(playersInTier, position));
      }
    }
    
    return windows;
  }
  
  /// Check if we're approaching a QB run scenario
  bool isQBRunLikely(List<Player> availablePlayers) {
    // Get available QBs in the top 50
    List<Player> topQBs = availablePlayers
        .where((p) => p.position == "QB" && p.rank <= 50)
        .toList();
    
    // If only 1-2 top QBs left, teams might get aggressive
    if (topQBs.isNotEmpty && topQBs.length <= 2) {
      return true;
    }
    
    // Check recent picks for QB selections (might trigger a run)
    int recentQBs = 0;
    int lookback = 0;
    
    for (var player in _recentSelections.toList().reversed) {
      if (lookback >= 3) break; // Only check last 3 picks
      
      if (player.position == "QB") {
        recentQBs++;
      }
      lookback++;
    }
    
    // If a QB was taken recently and good ones are available, might trigger a run
    return recentQBs > 0 && topQBs.isNotEmpty;
  }
  
  /// Check for specific team need alignment
  bool hasUrgentPositionalNeed(String position, List<String> teamNeeds, List<Player> availablePlayers) {
    // Position is a top-3 need
    bool isTopNeed = teamNeeds.take(3).contains(position);
    if (!isTopNeed) return false;
    
    // Check for limited availability at the position
    List<Player> positionPlayers = availablePlayers
        .where((p) => p.position == position && p.rank <= 100)
        .toList();
    
    // If few quality players left at needed position
    return positionPlayers.length <= 3;
  }
  
  /// Clear state and cached data
  void reset() {
    _recentSelections.clear();
    _cachedWindows.clear();
  }
}