// lib/models/trade_motivation.dart
import 'package:flutter/material.dart';

/// Encapsulates the various motivations for a team to trade
class TradeMotivation {
  // Primary motivation flags
  final bool isTargetingSpecificPlayer;  // Team wants a specific player
  final bool isPreventingRival;          // Team wants to get ahead of a rival
  final bool isAccumulatingCapital;      // Team wants more picks (trading down)
  final bool isWinNowMove;               // Win-now team targeting immediate impact
  final bool isExploitingValue;          // Team sees value discrepancy to exploit
  
  // Additional context
  final String targetedPosition;         // Position of interest if relevant
  final String rivalTeam;                // Rival team they're trying to beat
  final String targetedPlayerName;       // Specific player name if known
  final bool isDivisionRival;            // Whether teams are division rivals
  
  // Team classification for context
  final TeamBuildStatus teamStatus;      // Rebuilding, stable, or win-now
  
  // Trade timing factors
  final bool isTierDropoff;              // Trade motivated by talent tier dropoff
  final bool isPositionRun;              // Trade motivated by a position run
  
  // Trade dialogue snippet to explain motivation
  final String motivationDescription;
  
  const TradeMotivation({
    this.isTargetingSpecificPlayer = false,
    this.isPreventingRival = false,
    this.isAccumulatingCapital = false,
    this.isWinNowMove = false,
    this.isExploitingValue = false,
    this.targetedPosition = '',
    this.rivalTeam = '',
    this.targetedPlayerName = '',
    this.isDivisionRival = false,
    this.teamStatus = TeamBuildStatus.stable,
    this.isTierDropoff = false,
    this.isPositionRun = false,
    this.motivationDescription = '',
  });
  
  /// Get a human-readable primary motivation
  String get primaryMotivation {
    if (isTargetingSpecificPlayer) {
      return "Targeting a specific ${targetedPosition.isNotEmpty ? targetedPosition : 'player'}";
    }
    if (isPreventingRival) {
      return "Preventing ${rivalTeam.isNotEmpty ? rivalTeam : 'a rival'} from selecting a ${targetedPosition.isNotEmpty ? targetedPosition : 'key player'}";
    }
    if (isAccumulatingCapital) {
      return "Accumulating draft capital for a ${teamStatus == TeamBuildStatus.rebuilding ? 'rebuild' : 'future moves'}";
    }
    if (isWinNowMove) {
      return "Making a win-now move for immediate impact";
    }
    if (isExploitingValue) {
      return "Exploiting a value opportunity in the draft";
    }
    return "General trade interest";
  }
  
  /// Create a detailed dialogue about the trade motivation
  String generateDialogue({bool isAccepting = true}) {
    if (!isAccepting) {
      // Generate rejection dialogue
      if (isTargetingSpecificPlayer && targetedPlayerName.isNotEmpty) {
        return "We're targeting $targetedPlayerName at this position and aren't interested in trading back.";
      } else if (isTargetingSpecificPlayer) {
        return "We have a specific ${targetedPosition.isNotEmpty ? targetedPosition : 'player'} in mind that we believe will be available with this pick.";
      } else if (isTierDropoff) {
        return "Our draft board shows a significant dropoff after this pick, so we're staying put.";
      } else if (isPositionRun) {
        return "With the recent run on ${targetedPosition.isNotEmpty ? targetedPosition : 'this position'}, we need to make our selection now.";
      }
      return "After reviewing the offer, we've decided to stay put and make our selection.";
    } else {
      // Generate acceptance dialogue
      if (isAccumulatingCapital && teamStatus == TeamBuildStatus.rebuilding) {
        return "As a rebuilding team, we value the additional draft capital to address multiple roster needs.";
      } else if (isWinNowMove) {
        return "We're in win-now mode and believe this player can make an immediate impact.";
      } else if (isPreventingRival && rivalTeam.isNotEmpty) {
        return "We wanted to move ahead of $rivalTeam who we believe was targeting the same player.";
      } else if (isExploitingValue) {
        return "We saw great value in this deal based on our draft board.";
      } else if (isPositionRun) {
        return "With the recent run on ${targetedPosition.isNotEmpty ? targetedPosition : 'this position'}, we needed to move up to secure our target.";
      }
      return "This trade aligns with our draft strategy and team-building approach.";
    }
  }
  
  /// Create a copy with modified fields
  TradeMotivation copyWith({
    bool? isTargetingSpecificPlayer,
    bool? isPreventingRival,
    bool? isAccumulatingCapital,
    bool? isWinNowMove,
    bool? isExploitingValue,
    String? targetedPosition,
    String? rivalTeam,
    String? targetedPlayerName,
    bool? isDivisionRival,
    TeamBuildStatus? teamStatus,
    bool? isTierDropoff,
    bool? isPositionRun,
    String? motivationDescription,
  }) {
    return TradeMotivation(
      isTargetingSpecificPlayer: isTargetingSpecificPlayer ?? this.isTargetingSpecificPlayer,
      isPreventingRival: isPreventingRival ?? this.isPreventingRival,
      isAccumulatingCapital: isAccumulatingCapital ?? this.isAccumulatingCapital,
      isWinNowMove: isWinNowMove ?? this.isWinNowMove,
      isExploitingValue: isExploitingValue ?? this.isExploitingValue,
      targetedPosition: targetedPosition ?? this.targetedPosition,
      rivalTeam: rivalTeam ?? this.rivalTeam,
      targetedPlayerName: targetedPlayerName ?? this.targetedPlayerName,
      isDivisionRival: isDivisionRival ?? this.isDivisionRival,
      teamStatus: teamStatus ?? this.teamStatus,
      isTierDropoff: isTierDropoff ?? this.isTierDropoff,
      isPositionRun: isPositionRun ?? this.isPositionRun,
      motivationDescription: motivationDescription ?? this.motivationDescription,
    );
  }
}

/// Represents a team's current building status
enum TeamBuildStatus {
  rebuilding,  // Team is in rebuild mode (accumulating picks)
  stable,      // Team is in a stable position (balanced approach)
  winNow       // Team is in win-now mode (targeting immediate impact)
}

/// Contains context about a trade window of opportunity
class TradeWindow {
  final bool isOpen;                 // Whether this is an active trade window
  final String reason;               // Reason for the trade window
  final double probabilityMultiplier; // How much this window affects trade probability
  
  const TradeWindow({
    this.isOpen = false,
    this.reason = '',
    this.probabilityMultiplier = 1.0,
  });
  
  /// Create a trade window for position runs
  factory TradeWindow.positionRun(String position, int recentSelections) {
    double multiplier = 1.0 + (recentSelections * 0.2); // Increase by 20% per selection
    return TradeWindow(
      isOpen: recentSelections >= 2,
      reason: 'Recent run on $position (last $recentSelections picks)',
      probabilityMultiplier: multiplier,
    );
  }
  
  /// Create a trade window for talent tier dropoffs
  factory TradeWindow.tierDropoff(int playersRemaining, String position) {
    // If 1 or fewer players remain in this tier, high urgency
    bool isUrgent = playersRemaining <= 1;
    double multiplier = isUrgent ? 2.0 : 1.3;
    
    return TradeWindow(
      isOpen: true,
      reason: 'Only $playersRemaining ${position.isNotEmpty ? position : "top"} ' 'player${playersRemaining == 1 ? "" : "s"} remaining before talent dropoff',
      probabilityMultiplier: multiplier,
    );
  }
}