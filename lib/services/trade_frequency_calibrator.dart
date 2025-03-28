// lib/services/trade_frequency_calibrator.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/player.dart';

/// Calibrates trade frequency to match realistic NFL draft patterns
class TradeFrequencyCalibrator {
  // Base frequency parameters
  final double baseFrequency;
  final double userTeamMultiplier;
  final double qbDrivenMultiplier;
  final double earlyRoundMultiplier;
  
  // Current draft state tracking
  int _totalPicks = 0;
  int _completedPicks = 0;
  int _tradedPicks = 0;
  
  // Round-specific trade frequencies
  final Map<int, double> _roundFrequencies = {
    1: 1.5,  // 50% more trades in round 1
    2: 1.3,  // 30% more trades in round 2
    3: 1.1,  // 10% more trades in round 3
    4: 0.9,  // 10% fewer trades in round 4
    5: 0.8,  // 20% fewer trades in round 5
    6: 0.7,  // 30% fewer trades in round 6
    7: 0.6,  // 40% fewer trades in round 7
  };
  
  // Random for probability calculations
  final Random _random = Random();
  
  TradeFrequencyCalibrator({
    this.baseFrequency = 0.3,
    this.userTeamMultiplier = 1.5,
    this.qbDrivenMultiplier = 1.3,
    this.earlyRoundMultiplier = 1.2,
  });
  
  /// Initialize with total number of picks in the draft
  void initialize({required int totalPicks}) {
    _totalPicks = totalPicks;
    _completedPicks = 0;
    _tradedPicks = 0;
  }
  
  /// Calculate the current trade rate based on draft progress
  double _calculateCurrentTradeRate() {
    if (_completedPicks == 0) return 1.0;
    
    // Calculate current trade percentage
    double currentRate = _tradedPicks / _completedPicks;
    
    // Target percentages by draft segment
    double targetRate;
    double draftProgress = _completedPicks / _totalPicks;
    
    if (draftProgress < 0.25) {
      // Early draft - higher frequency
      targetRate = 0.15; // 15% trades
    } else if (draftProgress < 0.5) {
      // Mid-early draft
      targetRate = 0.12; // 12% trades
    } else if (draftProgress < 0.75) {
      // Mid-late draft
      targetRate = 0.08; // 8% trades
    } else {
      // Late draft - lower frequency
      targetRate = 0.05; // 5% trades
    }
    
    // Calculate adjustment factor - increase if below target, decrease if above
    if (currentRate < targetRate * 0.7) {
      // Well below target - increase rate
      return 1.3;
    } else if (currentRate < targetRate) {
      // Slightly below target - small increase
      return 1.1;
    } else if (currentRate > targetRate * 1.3) {
      // Well above target - decrease rate
      return 0.7;
    } else if (currentRate > targetRate) {
      // Slightly above target - small decrease
      return 0.9;
    }
    
    // On target
    return 1.0;
  }
  
  /// Record that a trade was executed
  void recordTradeExecuted() {
    _tradedPicks++;
    _completedPicks++;
  }
  
  /// Record that a pick was completed without a trade
  void recordPickCompleted() {
    _completedPicks++;
  }
  
  /// Get current trade statistics
  Map<String, dynamic> getTradeStats() {
    return {
      'totalPicks': _totalPicks,
      'completedPicks': _completedPicks,
      'tradedPicks': _tradedPicks,
      'tradePercentage': _completedPicks > 0 ? '${(_tradedPicks / _completedPicks * 100).toStringAsFixed(1)}%' : '0%',
    };
  }
  
  /// Reset all counters
  void reset() {
    _completedPicks = 0;
    _tradedPicks = 0;
  }
  // Add position-specific trade frequency modifiers
  final Map<String, double> _positionFrequencyModifiers = {
    'QB': 1.8,    // QB trades much more frequent
    'OT': 1.3,    // Tackles often traded for
    'EDGE': 1.4,  // Edge rushers highly sought
    'CB': 1.2,    // Cornerbacks
    'WR': 1.3,    // Wide receivers
    'TE': 1.1,    // Tight ends
    'IOL': 0.9,   // Interior linemen less frequent
    'RB': 0.8,    // Running backs less frequently traded for
    'LB': 0.9,    // Linebackers
    'S': 0.9,     // Safeties
    'DL': 1.0,    // Defensive line
  };
  
  // Add this method to enhance position-based trade frequency
  double _applyPositionalFactors(double baseFrequency, List<Player> availablePlayers) {
    // Look at top available players
    List<Player> topPlayers = availablePlayers
        .where((p) => p.rank <= 50)
        .take(5)
        .toList();
    
    if (topPlayers.isEmpty) return baseFrequency;
    
    // Calculate average positional modifier
    double totalModifier = 0;
    for (var player in topPlayers) {
      totalModifier += _positionFrequencyModifiers[player.position] ?? 1.0;
    }
    
    double avgModifier = totalModifier / topPlayers.length;
    
    // Apply modifier with dampening
    return baseFrequency * (1.0 + ((avgModifier - 1.0) * 0.5));
  }
  
  // Add this method to track "hot spots" in the draft
  bool isTradeHotspot(int pickNumber) {
    // These pick ranges historically see more trade activity
    List<List<int>> hotspots = [
      [1, 5],      // Top 5 picks
      [10, 15],    // End of blue-chip prospects
      [25, 32],    // End of 1st round
      [33, 40],    // Start of 2nd round
      [60, 65],    // End of 2nd round
      [65, 75],    // Start of 3rd round
      [95, 105],   // End of 3rd round
    ];
    
    for (var hotspot in hotspots) {
      if (pickNumber >= hotspot[0] && pickNumber <= hotspot[1]) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Determine if we should generate a trade for this pick (enhanced)
  bool shouldGenerateTrade({
    required int pickNumber,
    required List<Player> availablePlayers,
    bool isUserTeamPick = false,
    bool isQBDriven = false,
  }) {
    // Calculate current trade frequency
    double currentTradeRate = _calculateCurrentTradeRate();
    
    // Apply pick-specific adjustments
    int round = (pickNumber / 32).ceil();
    double roundMultiplier = _roundFrequencies[round] ?? 1.0;
    
    // Apply multipliers
    double adjustedFrequency = baseFrequency * roundMultiplier * currentTradeRate;
    
    // Apply user team boost
    if (isUserTeamPick) {
      adjustedFrequency *= userTeamMultiplier;
    }
    
    // Apply QB premium
    if (isQBDriven) {
      adjustedFrequency *= qbDrivenMultiplier;
    }
    
    // Apply positional considerations
    adjustedFrequency = _applyPositionalFactors(adjustedFrequency, availablePlayers);
    
    // Apply hotspot boost if applicable
    if (isTradeHotspot(pickNumber)) {
      adjustedFrequency *= 1.5; // 50% boost in trade hotspots
    }
    
    // Cap at reasonable limits
    adjustedFrequency = min(0.8, max(0.05, adjustedFrequency));
    
    // Log the calculation
    debugPrint(
      'Trade probability for pick #$pickNumber: $adjustedFrequency ' '(User: $isUserTeamPick, QB: $isQBDriven, Round: $round)'
    );
    
    // Make random decision
    return _random.nextDouble() < adjustedFrequency;
  }
}

