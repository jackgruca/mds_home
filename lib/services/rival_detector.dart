// lib/services/rival_detector.dart
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/player.dart';
import 'team_classification.dart';

/// Detects rival team conflicts and competition for players
class RivalDetector {
  /// Check if a rival team is likely to select a player at a specific position
  bool isRivalTargetingPosition({
    required String teamName,
    required String position,
    required List<DraftPick> draftOrder,
    required List<TeamNeed> teamNeeds,
    required int currentPick,
    int maxCheckDistance = 15, // Now with default, not required
  }) {
    // Get division rivals
    List<String> rivals = TeamClassification.getDivisionRivals(teamName);
    
    // Get the next several picks
    List<DraftPick> upcomingPicks = draftOrder
        .where((pick) => 
            pick.pickNumber > currentPick && 
            pick.pickNumber <= currentPick + maxCheckDistance &&
            !pick.isSelected)
        .toList();
    
    upcomingPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Check if any of these picks belong to rivals
    for (var pick in upcomingPicks) {
      if (rivals.contains(TeamClassification.cleanTeamName(pick.teamName))) {
        // Check if this rival needs the position
        TeamNeed? rivalNeeds = _findTeamNeeds(teamNeeds, pick.teamName);
        
        // If the position is in the rival's top 3 needs, they're likely targeting it
        if (rivalNeeds != null && rivalNeeds.needs.take(3).contains(position)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Find the closest rival team that might be targeting a player
  String findClosestRivalForPosition({
    required String teamName,
    required String position,
    required List<DraftPick> draftOrder,
    required List<TeamNeed> teamNeeds,
    required int currentPick,
    int maxCheckDistance = 15, // Now with default, not required
  }) {
    // Get division rivals
    List<String> rivals = TeamClassification.getDivisionRivals(teamName);
    
    // Get the next several picks
    List<DraftPick> upcomingPicks = draftOrder
        .where((pick) => 
            pick.pickNumber > currentPick && 
            pick.pickNumber <= currentPick + maxCheckDistance &&
            !pick.isSelected)
        .toList();
    
    upcomingPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Check if any of these picks belong to rivals
    for (var pick in upcomingPicks) {
      String cleanTeamName = TeamClassification.cleanTeamName(pick.teamName);
      if (rivals.contains(cleanTeamName)) {
        // Check if this rival needs the position
        TeamNeed? rivalNeeds = _findTeamNeeds(teamNeeds, pick.teamName);
        
        // If the position is in the rival's top 3 needs, they're likely targeting it
        if (rivalNeeds != null && rivalNeeds.needs.take(3).contains(position)) {
          return cleanTeamName;
        }
      }
    }
    
    return ""; // No rival found
  }
  
  /// Find a team that's close to selecting and needs a specific position
  String findCompetitorForPosition({
    required String position,
    required List<DraftPick> draftOrder,
    required List<TeamNeed> teamNeeds,
    required int currentPick,
    required int nextTeamPick,
    int maxCheckDistance = 10, // Now with default, not required
  }) {
    // If current team has the next pick anyway, no competitors
    if (nextTeamPick <= currentPick + 1) {
      return "";
    }
    
    // Get the picks between current and team's next pick
    List<DraftPick> interveningPicks = draftOrder
        .where((pick) => 
            pick.pickNumber > currentPick && 
            pick.pickNumber < nextTeamPick &&
            !pick.isSelected)
        .toList();
    
    interveningPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Limit to reasonable distance
    if (interveningPicks.length > maxCheckDistance) {
      interveningPicks = interveningPicks.take(maxCheckDistance).toList();
    }
    
    // Check if any of these picks belong to teams needing the position
    for (var pick in interveningPicks) {
      TeamNeed? competitorNeeds = _findTeamNeeds(teamNeeds, pick.teamName);
      
      // If the position is in the competitor's top 3 needs, they're likely targeting it
      if (competitorNeeds != null && competitorNeeds.needs.take(3).contains(position)) {
        return pick.teamName;
      }
    }
    
    return ""; // No competitor found
  }
  
  /// Check if there are multiple teams between current pick and team's next pick
  /// that need players at a specific position
  bool isPositionHighlyContested({
    required String position,
    required List<DraftPick> draftOrder,
    required List<TeamNeed> teamNeeds,
    required int currentPick,
    required int nextTeamPick,
    int maxCheckDistance = 10, // Now with default, not required
  }) {
    if (nextTeamPick <= currentPick + 1) {
      return false;
    }
    
    // Get the picks between current and team's next pick
    List<DraftPick> interveningPicks = draftOrder
        .where((pick) => 
            pick.pickNumber > currentPick && 
            pick.pickNumber < nextTeamPick &&
            !pick.isSelected)
        .toList();
    
    // Limit to reasonable distance
    if (interveningPicks.length > maxCheckDistance) {
      interveningPicks = interveningPicks.take(maxCheckDistance).toList();
    }
    
    // Count how many teams need this position
    int countCompetitors = 0;
    for (var pick in interveningPicks) {
      TeamNeed? competitorNeeds = _findTeamNeeds(teamNeeds, pick.teamName);
      
      // If the position is in competitor's needs, count it
      if (competitorNeeds != null && competitorNeeds.needs.contains(position)) {
        countCompetitors++;
        
        // If in top 3 needs, count it more heavily
        if (competitorNeeds.needs.take(3).contains(position)) {
          countCompetitors++;
        }
      }
    }
    
    // Position is highly contested if multiple teams need it
    return countCompetitors >= 3;
  }
  
  /// Check if there's a top player likely to be taken before the team's next pick
  bool isTopPlayerAtRisk({
    required List<Player> availablePlayers,
    required String position,
    required int currentPick,
    required int nextTeamPick,
    int topPlayerThreshold = 50, // Now with default, not required
  }) {
    // Find top players at the position
    List<Player> topPositionPlayers = availablePlayers
        .where((p) => 
            p.position == position && 
            p.rank <= topPlayerThreshold)
        .toList();
    
    if (topPositionPlayers.isEmpty) {
      return false;
    }
    
    // Sort by rank
    topPositionPlayers.sort((a, b) => a.rank.compareTo(b.rank));
    
    // If there's only 1 top player and teams will pick before this team's next pick
    if (topPositionPlayers.length == 1 && nextTeamPick > currentPick + 1) {
      return true;
    }
    
    // If there are very few top players and many picks before team's next
    int picksBetween = nextTeamPick - currentPick - 1;
    return topPositionPlayers.length <= 2 && picksBetween >= 3;
  }
  
  /// Find team needs for a given team
  TeamNeed? _findTeamNeeds(List<TeamNeed> teamNeeds, String teamName) {
    try {
      return teamNeeds.firstWhere((need) => need.teamName == teamName);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if a position is considered premium
  bool isPremiumPosition(String position) {
    const Set<String> premiumPositions = {
      'QB', 'OT', 'EDGE', 'CB', 'WR'
    };
    
    return premiumPositions.contains(position);
  }
  
  /// Check for high-value players at specific positions
  List<Player> findHighValuePlayers({
    required List<Player> availablePlayers,
    required int pickNumber,
    List<String>? positions,
    int slideThreshold = 10,
  }) {
    // Filter for players who have "slid" past their rank
    return availablePlayers
        .where((p) => 
            (positions == null || positions.contains(p.position)) &&
            (pickNumber - p.rank) >= slideThreshold)
        .toList();
  }
  
  /// Detect teams competing for positional groups (e.g., offensive line, secondary)
  List<String> detectPositionGroupCompetition({
    required List<TeamNeed> teamNeeds,
    required List<DraftPick> upcomingPicks,
    required String positionGroup,
    int threshold = 2,
  }) {
    // Map position groups to individual positions
    Map<String, List<String>> positionGroups = {
      'OL': ['OT', 'IOL', 'G', 'C'],
      'DL': ['EDGE', 'IDL', 'DT', 'DE'],
      'SECONDARY': ['CB', 'S'],
      'SKILL': ['WR', 'RB', 'TE'],
      'PASS_RUSH': ['EDGE', 'OLB'],
    };
    
    List<String> positions = positionGroups[positionGroup] ?? [positionGroup];
    List<String> competingTeams = [];
    
    // Check each team with an upcoming pick
    for (var pick in upcomingPicks) {
      TeamNeed? needs = _findTeamNeeds(teamNeeds, pick.teamName);
      if (needs == null) continue;
      
      // Count how many positions from this group are needed
      int matchCount = 0;
      for (var position in positions) {
        if (needs.needs.contains(position)) {
          matchCount++;
        }
      }
      
      // If team needs multiple positions from group or has one as top need
      if (matchCount >= threshold || 
          (matchCount > 0 && needs.needs.take(2).any((p) => positions.contains(p)))) {
        competingTeams.add(pick.teamName);
      }
    }
    
    return competingTeams;
  }
}