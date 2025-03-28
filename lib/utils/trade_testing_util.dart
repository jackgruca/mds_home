import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../services/enhanced_trade_manager.dart';

/// Utility class for testing trade logic
class TradeTestingUtil {
  // Random number generator
  static final Random _random = Random();
  
  /// Generate test draft picks
  static List<DraftPick> generateTestDraftOrder({
    int totalPicks = 224,
    int teamsCount = 32,
  }) {
    List<DraftPick> draftOrder = [];
    
    for (int i = 1; i <= totalPicks; i++) {
      String teamName = "Team${(i - 1) % teamsCount + 1}";
      String round = ((i - 1) ~/ teamsCount + 1).toString();
      
      draftOrder.add(DraftPick(
        pickNumber: i,
        teamName: teamName,
        round: round,
        isActiveInDraft: true,
      ));
    }
    
    return draftOrder;
  }
  
  /// Generate test players
  static List<Player> generateTestPlayers({
    int playerCount = 300,
  }) {
    List<Player> players = [];
    
    // Position distribution
    List<String> positions = [
      'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'EDGE', 'DL', 'LB', 'CB', 'S'
    ];
    
    for (int i = 1; i <= playerCount; i++) {
      String position = positions[_random.nextInt(positions.length)];
      
      players.add(Player(
        id: i,
        name: "Player$i",
        position: position,
        rank: i,
        school: "University${_random.nextInt(50) + 1}",
      ));
    }
    
    return players;
  }
  
  /// Generate test team needs
  static List<TeamNeed> generateTestTeamNeeds({
    int teamsCount = 32,
  }) {
    List<TeamNeed> teamNeeds = [];
    
    // Position pool
    List<String> positions = [
      'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'EDGE', 'DL', 'LB', 'CB', 'S'
    ];
    
    for (int i = 1; i <= teamsCount; i++) {
      String teamName = "Team$i";
      
      // Generate 3-6 needs
      int needsCount = _random.nextInt(4) + 3;
      List<String> needs = [];
      
      // Ensure no duplicates
      while (needs.length < needsCount) {
        String position = positions[_random.nextInt(positions.length)];
        if (!needs.contains(position)) {
          needs.add(position);
        }
      }
      
      teamNeeds.add(TeamNeed(
        teamName: teamName,
        needs: needs,
      ));
    }
    
    return teamNeeds;
  }
  
  /// Run trade system tests
  static Map<String, dynamic> runTradeTests({
    required EnhancedTradeManager tradeManager,
    int testsCount = 10,
  }) {
    int offersGenerated = 0;
    int packageCount = 0;
    List<double> valueRatios = [];
    int qbTargeted = 0;
    int rivalPrevention = 0;
    
    // Run tests
    for (int i = 1; i <= testsCount; i++) {
      // Test regular trade offer generation
      int pickNumber = _random.nextInt(150) + 1;
      
      var offer = tradeManager.generateTradeOffersForPick(pickNumber);
      offersGenerated++;
      
      if (offer.packages.isNotEmpty) {
        packageCount += offer.packages.length;
        
        // Analyze packages
        for (var package in offer.packages) {
          double ratio = package.totalValueOffered / package.targetPickValue;
          valueRatios.add(ratio);
        }
      }
      
      // Test QB-specific trades
      var qbOffer = tradeManager.generateTradeOffersForPick(pickNumber, qbSpecific: true);
      offersGenerated++;
      
      if (qbOffer.packages.isNotEmpty) {
        qbTargeted++;
        packageCount += qbOffer.packages.length;
      }
    }
    
    // Calculate metrics
    double offerRate = packageCount / offersGenerated;
    double avgValueRatio = valueRatios.isNotEmpty ? 
        valueRatios.reduce((a, b) => a + b) / valueRatios.length : 0;
    double minRatio = valueRatios.isNotEmpty ? valueRatios.reduce(min) : 0;
    double maxRatio = valueRatios.isNotEmpty ? valueRatios.reduce(max) : 0;
    
    return {
      'testsCount': testsCount,
      'offersGenerated': offersGenerated,
      'packageCount': packageCount,
      'offerRate': offerRate,
      'avgValueRatio': avgValueRatio,
      'minRatio': minRatio,
      'maxRatio': maxRatio,
      'qbTargeted': qbTargeted,
    };
  }
}