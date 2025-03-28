// lib/services/position_value_tracker.dart
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/player.dart';

/// Tracks the changing value of positions throughout the draft
class PositionValueTracker {
  // Base position value tiers based on historical draft data
  final Map<String, double> _basePositionValues = {
    'QB': 1.7,   // Quarterbacks have highest premium
    'OT': 1.2,   // Offensive tackles
    'EDGE': 1.2, // Edge rushers
    'CB': 1.15,  // Cornerbacks
    'WR': 1.12,  // Wide receivers
    'DL': 1.05,  // Defensive line
    'S': 1.0,    // Safeties
    'TE': 0.95,  // Tight ends
    'IOL': 0.9,  // Interior offensive line
    'RB': 0.85,  // Running backs typically devalued
    'LB': 0.9,   // Linebackers
  };
  
  // Current position scarcity values (dynamic throughout draft)
  final Map<String, double> _positionScarcity = {};
  
  // Recent selections to track position trends
  final Queue<Player> _recentSelections = Queue<Player>();
  final int _maxTrackingCount = 15; // How many recent picks to track
  
  // Position market temperature (how "hot" positions are)
  final Map<String, double> _positionTemperature = {};
  
  // Position tiers for tracking talent dropoffs
  final Map<String, List<int>> _positionTiers = {
    'QB': [3, 8, 15, 30, 60],      // Quarterback tiers
    'RB': [5, 15, 30, 50, 100],    // Running back tiers
    'WR': [5, 15, 25, 40, 80],     // Wide receiver tiers
    'TE': [8, 20, 40, 70, 120],    // Tight end tiers
    'OT': [5, 15, 30, 50, 90],     // Offensive tackle tiers
    'IOL': [15, 30, 50, 80, 120],  // Interior O-line tiers
    'EDGE': [5, 15, 25, 45, 80],   // Edge rusher tiers
    'DL': [10, 25, 40, 70, 110],   // Defensive line tiers
    'LB': [10, 25, 45, 75, 120],   // Linebacker tiers
    'CB': [5, 15, 30, 55, 90],     // Cornerback tiers
    'S': [10, 25, 45, 80, 130],    // Safety tiers
  };
  
  PositionValueTracker() {
    // Initialize scarcity values to 1.0
    for (var pos in _basePositionValues.keys) {
      _positionScarcity[pos] = 1.0;
      _positionTemperature[pos] = 1.0;
    }
  }
  
  /// Record a player selection to update position values
  void recordSelection(Player player) {
    // Add to recent selections queue
    _recentSelections.add(player);
    
    // Maintain maximum size
    if (_recentSelections.length > _maxTrackingCount) {
      _recentSelections.removeFirst();
    }
    
    // Update position scarcity
    _updatePositionScarcity(player.position);
    
    // Update position temperature
    _updatePositionTemperature();
  }
  
  /// Get the current value multiplier for a position
  double getPositionValueMultiplier(String position) {
    // Base value
    double baseValue = _basePositionValues[position] ?? 1.0;
    
    // Scarcity adjustment
    double scarcityMultiplier = _positionScarcity[position] ?? 1.0;
    
    // Temperature adjustment
    double temperatureMultiplier = _positionTemperature[position] ?? 1.0;
    
    // Calculate total multiplier
    double totalMultiplier = baseValue * scarcityMultiplier * temperatureMultiplier;
    
    // Ensure multiplier stays in reasonable range
    return min(2.0, max(0.7, totalMultiplier));
  }
  
  /// Update position scarcity based on recent picks
  void _updatePositionScarcity(String position) {
    const debugMode = false;
    
    // Update scarcity for the selected position
    _positionScarcity[position] = (_positionScarcity[position] ?? 1.0) * 1.03;
    
    // Cap at a maximum value
    _positionScarcity[position] = min(_positionScarcity[position]!, 1.3);
    
    // Slightly decrease scarcity for other positions
    for (var pos in _positionScarcity.keys) {
      if (pos != position) {
        _positionScarcity[pos] = max(0.85, (_positionScarcity[pos] ?? 1.0) * 0.995);
      }
    }
    
    if (debugMode) {
      debugPrint("Updated position scarcity for $position to ${_positionScarcity[position]}");
    }
  }
  
  /// Update position temperature (how "hot" positions are) based on recent trends
  void _updatePositionTemperature() {
    // Count recent selections by position
    Map<String, int> recentPositionCounts = {};
    for (var player in _recentSelections) {
      recentPositionCounts[player.position] = (recentPositionCounts[player.position] ?? 0) + 1;
    }
    
    // First, cool down all positions slightly
    for (var pos in _positionTemperature.keys) {
      // Temperature naturally decays
      _positionTemperature[pos] = (_positionTemperature[pos] ?? 1.0) * 0.96;
      
      // Ensure minimum temperature
      _positionTemperature[pos] = max(0.9, _positionTemperature[pos]!);
    }
    
    // Then heat up positions with recent activity
    for (var entry in recentPositionCounts.entries) {
      String position = entry.key;
      int count = entry.value;
      
      if (count >= 2) {
        // Position is heating up - higher temperature
        double heatFactor = 1.0 + (count * 0.05); // 5% increase per selection
        
        // For "runs" of 3+ players, increase more dramatically
        if (count >= 3) {
          heatFactor += 0.1;
        }
        
        _positionTemperature[position] = (_positionTemperature[position] ?? 1.0) * heatFactor;
        
        // Cap at maximum temperature
        _positionTemperature[position] = min(1.5, _positionTemperature[position]!);
      }
    }
  }
  
  /// Check if there's a position run happening
  bool isPositionRunActive(String position, {int threshold = 2}) {
    int count = 0;
    int recentChecks = 0;
    
    // Check most recent selections
    for (var player in _recentSelections.toList().reversed) {
      if (recentChecks >= 5) break; // Only check last 5 picks
      recentChecks++;
      
      if (player.position == position) {
        count++;
      }
    }
    
    return count >= threshold;
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
  
  /// Check if we're approaching a talent tier dropoff
  bool isTierDropoffImminent(String position, List<Player> availablePlayers) {
    // Get position tiers
    List<int> tiers = _positionTiers[position] ?? [];
    if (tiers.isEmpty) return false;
    
    // Get available players at the position
    List<Player> positionPlayers = availablePlayers
        .where((p) => p.position == position)
        .toList();
    
    // Sort by rank
    positionPlayers.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Need at least one player for a dropoff
    if (positionPlayers.isEmpty) return false;
    
    // Find the current tier
    int currentTier = -1;
    int currentTierThreshold = 0;
    
    for (int i = 0; i < tiers.length; i++) {
      if (positionPlayers.first.rank <= tiers[i]) {
        currentTier = i;
        currentTierThreshold = tiers[i];
        break;
      }
    }
    
    // If no tier found or already in the last tier
    if (currentTier == -1) return false;
    
    // Count players in the current tier
    int playersInTier = 0;
    for (var player in positionPlayers) {
      if (player.rank <= currentTierThreshold) {
        playersInTier++;
      } else {
        break;
      }
    }
    
    // We have a tier dropoff if only 1-2 players left in the current tier
    return playersInTier > 0 && playersInTier <= 2;
  }
  
  /// Detect tier dropoffs across all positions
  Map<String, int> detectTierDropoffs(List<Player> availablePlayers) {
    Map<String, int> dropoffs = {};
    
    for (var position in _positionTiers.keys) {
      List<int> tiers = _positionTiers[position]!;
      
      // Get available players at this position
      List<Player> positionPlayers = availablePlayers
          .where((p) => p.position == position)
          .toList();
      
      if (positionPlayers.isEmpty) continue;
      
      // Sort by rank
      positionPlayers.sort((a, b) => a.rank.compareTo(b.rank));
      
      // Find current tier
      int currentTier = -1;
      int currentTierThreshold = 0;
      
      for (int i = 0; i < tiers.length; i++) {
        if (positionPlayers.first.rank <= tiers[i]) {
          currentTier = i;
          currentTierThreshold = tiers[i];
          break;
        }
      }
      
      if (currentTier == -1) continue;
      
      // Count players in current tier
      int playersInTier = 0;
      for (var player in positionPlayers) {
        if (player.rank <= currentTierThreshold) {
          playersInTier++;
        } else {
          break;
        }
      }
      
      // Record dropoff if few players remain
      if (playersInTier > 0 && playersInTier <= 2) {
        dropoffs[position] = playersInTier;
      }
    }
    
    return dropoffs;
  }
  
  /// Get a premium multiplier for player involved in a position run or dropoff
  double getContextAdjustedPremium(String position, List<Player> availablePlayers) {
    double premium = 1.0;
    
    // Check for position run
    bool inRun = isPositionRunActive(position);
    if (inRun) {
      premium *= 1.15; // 15% premium during position runs
    }
    
    // Check for tier dropoff
    bool inDropoff = isTierDropoffImminent(position, availablePlayers);
    if (inDropoff) {
      premium *= 1.2; // 20% premium for last players in tier
    }
    
    return premium;
  }
  
  /// Get the current "heat map" of position values
  Map<String, double> getPositionHeatMap() {
    Map<String, double> heatMap = {};
    
    for (var position in _basePositionValues.keys) {
      heatMap[position] = getPositionValueMultiplier(position);
    }
    
    return heatMap;
  }
  
  /// Reset tracking state
  void reset() {
    _recentSelections.clear();
    
    // Reset scarcity to baseline
    for (var pos in _basePositionValues.keys) {
      _positionScarcity[pos] = 1.0;
      _positionTemperature[pos] = 1.0;
    }
  }
}