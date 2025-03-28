// lib/services/trade_dialogue_generator.dart
import 'dart:math';
import '../models/trade_motivation.dart';
import '../models/trade_package.dart';
import 'team_classification.dart';

/// Generates natural language dialogue about trades
class TradeDialogueGenerator {
  final Random _random = Random();
  
  /// Generate an offer dialogue (AI offering to user)
  String generateOfferDialogue(TradePackage package, TradeMotivation motivation) {
    final String teamOffering = package.teamOffering;
    final String teamReceiving = package.teamReceiving;
    final int pickNumber = package.targetPick.pickNumber;
    final double valueRatio = package.totalValueOffered / package.targetPickValue;
    
    // Personalize message
    final String teamStatus = _getTeamStatusText(TeamClassification.getTeamStatus(teamOffering));
    final String offerValue = _getOfferValueText(valueRatio);
    
    // Base dialogue structure
    String dialogue = "The $teamOffering are interested in trading up to pick #$pickNumber. ";
    
    // Add motivation context
    if (motivation.isTargetingSpecificPlayer) {
      String position = motivation.targetedPosition.isNotEmpty ? motivation.targetedPosition : "impact player";
      dialogue += "They're looking to secure a $position that they believe can make an immediate difference. ";
    } else if (motivation.isPreventingRival) {
      String rival = motivation.rivalTeam.isNotEmpty ? motivation.rivalTeam : "division rival";
      dialogue += "They want to move ahead of the $rival who they believe is targeting the same player. ";
    } else if (motivation.isWinNowMove) {
      dialogue += "As a $teamStatus team, they're aggressive about adding elite talent for an immediate impact. ";
    }
    
    // Add offer context
    if (package.includesFuturePick) {
      dialogue += "Their offer includes future draft capital (${package.futurePickDescription}). ";
    }
    
    dialogue += "Based on our draft value chart, they're offering $offerValue. ";
    
    // Add relationship context if division rivals
    if (motivation.isDivisionRival) {
      dialogue += "Keep in mind that they're a division rival, so you might want to consider that in your decision. ";
    }
    
    // Add closing
    dialogue += "Would you like to accept this trade?";
    
    return dialogue;
  }
  
  /// Generate acceptance dialogue (when AI accepts user offer)
  String generateAcceptanceDialogue(TradePackage package, TradeMotivation? motivation) {
    // If we have motivation data, use that
    if (motivation != null) {
      return motivation.generateDialogue(isAccepting: true);
    }
    
    // Otherwise generate a generic acceptance
    final String teamOffering = package.teamOffering;
    final String teamReceiving = package.teamReceiving;
    final double valueRatio = package.totalValueOffered / package.targetPickValue;
    
    List<String> acceptanceReasons = [
      "This trade aligns with our draft strategy.",
      "The value works well for both teams.",
      "We believe this deal helps both of our teams.",
      "This package addresses our draft needs nicely.",
      "We're happy with the value here.",
      "The picks in this offer work well for our roster construction.",
    ];
    
    // Add value-based reasons
    if (valueRatio >= 1.1) {
      acceptanceReasons.addAll([
        "The value you're offering is very compelling.",
        "This represents strong value for our pick.",
        "Your offer exceeds what we were hoping for.",
        "We appreciate the strong value in this package.",
      ]);
    }
    
    // Choose a random reason
    String reason = acceptanceReasons[_random.nextInt(acceptanceReasons.length)];
    
    return "The $teamReceiving accept your trade offer. $reason";
  }
  
  /// Generate rejection dialogue (when AI rejects user offer)
  String generateRejectionDialogue(TradePackage package, TradeMotivation? motivation) {
    // If we have motivation data, use that
    if (motivation != null) {
      return motivation.generateDialogue(isAccepting: false);
    }
    
    // Otherwise generate a generic rejection
    final String teamOffering = package.teamOffering;
    final String teamReceiving = package.teamReceiving;
    final double valueRatio = package.totalValueOffered / package.targetPickValue;
    
    // Value-based rejections
    if (valueRatio < 0.9) {
      List<String> valueRejections = [
        "We're looking for more value in return for this pick.",
        "The draft capital doesn't quite match what we're looking for.",
        "We need more compensation to make this deal work.",
        "The value disparity is too significant for us to accept.",
        "We value this pick more highly than your current offer reflects.",
      ];
      return valueRejections[_random.nextInt(valueRejections.length)];
    }
    // If value is decent but still rejected
    else {
      List<String> otherRejections = [
        "We've decided to stay put and make our selection.",
        "After reviewing our draft board, we're going to keep the pick.",
        "We have our eye on a specific player at this position.",
        "Our scouts are high on a player that should be available here.",
        "We're going to pass on this offer and make our selection.",
        "We're comfortable with our draft position and plan to pick.",
      ];
      return otherRejections[_random.nextInt(otherRejections.length)];
    }
  }
  
  /// Generate dialogue for AI-to-AI trades
  String generateAITradeDialogue(TradePackage package, TradeMotivation? motivation) {
    final String teamOffering = package.teamOffering;
    final String teamReceiving = package.teamReceiving;
    final int pickNumber = package.targetPick.pickNumber;
    
    String dialogue = "The $teamOffering have traded up with the $teamReceiving to acquire pick #$pickNumber. ";
    
    // Add motivation if available
    if (motivation != null) {
      if (motivation.isTargetingSpecificPlayer) {
        String position = motivation.targetedPosition.isNotEmpty ? motivation.targetedPosition : "key player";
        dialogue += "They're targeting a $position. ";
      } else if (motivation.isPreventingRival) {
        String rival = motivation.rivalTeam.isNotEmpty ? motivation.rivalTeam : "competitor";
        dialogue += "They wanted to move ahead of the $rival. ";
      } else if (motivation.isWinNowMove) {
        dialogue += "This aggressive move signals their win-now mentality. ";
      } else if (motivation.isTierDropoff) {
        dialogue += "They likely saw a tier dropoff coming in talent. ";
      } else if (motivation.isPositionRun) {
        String position = motivation.targetedPosition.isNotEmpty ? motivation.targetedPosition : "position";
        dialogue += "With the recent run on $position, they made their move. ";
      }
    }
    
    // Add trade package context
    int picksOffered = package.picksOffered.length;
    if (package.includesFuturePick) {
      dialogue += "The deal includes $picksOffered pick${picksOffered != 1 ? 's' : ''} plus ${package.futurePickDescription}. ";
    } else if (picksOffered > 0) {
      dialogue += "The $teamReceiving received $picksOffered pick${picksOffered != 1 ? 's' : ''} in return. ";
    }
    
    return dialogue;
  }
  
  /// Get text describing team status
  String _getTeamStatusText(TeamBuildStatus status) {
    switch (status) {
      case TeamBuildStatus.rebuilding:
        return "rebuilding";
      case TeamBuildStatus.stable:
        return "competitive";
      case TeamBuildStatus.winNow:
        return "win-now";
      default:
        return "competitive";
    }
  }
  
  /// Get text describing offer value
  String _getOfferValueText(double valueRatio) {
    if (valueRatio >= 1.2) {
      return "excellent value";
    } else if (valueRatio >= 1.1) {
      return "very good value";
    } else if (valueRatio >= 1.05) {
      return "good value";
    } else if (valueRatio >= 0.95) {
      return "fair value";
    } else if (valueRatio >= 0.9) {
      return "slightly below market value";
    } else {
      return "below market value";
    }
  }
}