// lib/services/counter_offer_evaluator.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/trade_package.dart';
import '../models/trade_motivation.dart';
import 'draft_value_service.dart';
import 'team_classification.dart';

/// Evaluates counter offers with enhanced leverage dynamics
class CounterOfferEvaluator {
  final Random _random = Random();
  
  // Configuration parameters
  final double baseAcceptanceThreshold;
  final double userLeverageDiscount;
  final double rivalPremium;
  final bool enablePositionalValueAdjustments;
  
  // Max negotiation rounds before auto-decline
  final int maxNegotiationRounds;
  
  // Team history tracking
  final Map<String, int> _negotiationRoundsByTeam = {};
  final Map<String, List<double>> _previousOffersRatioByTeam = {};
  
  CounterOfferEvaluator({
    this.baseAcceptanceThreshold = 0.92, // Base minimum ratio for acceptance
    this.userLeverageDiscount = 0.08,    // 8% discount when user has leverage
    this.rivalPremium = 0.05,            // 5% premium for division rivals
    this.enablePositionalValueAdjustments = true,
    this.maxNegotiationRounds = 3,
  });

  /// Evaluate a counter offer with enhanced criteria
  EvaluationResult evaluateCounterOffer({
    required TradePackage originalOffer,
    required TradePackage counterOffer,
    TradeMotivation? motivation,
    bool isUserInitiated = false,
    int negotiationRound = 1,
  }) {
    // Calculate raw value ratio
    double valueRatio = counterOffer.totalValueOffered / counterOffer.targetPickValue;
    
    // Track negotiation history
    String teamPair = "${counterOffer.teamOffering}_${counterOffer.teamReceiving}";
    _negotiationRoundsByTeam[teamPair] = negotiationRound;
    
    if (!_previousOffersRatioByTeam.containsKey(teamPair)) {
      _previousOffersRatioByTeam[teamPair] = [];
    }
    _previousOffersRatioByTeam[teamPair]!.add(valueRatio);
    
    debugPrint('Evaluating counter offer with raw value ratio: $valueRatio');
    
    // Apply context-sensitive adjustments
    double adjustedValueRatio = valueRatio;
    
    // 1. Urgency-based adjustments
    if (motivation != null) {
      // Higher urgency = lower threshold for acceptance
      if (motivation.isPositionRun) {
        adjustedValueRatio += 0.05; // 5% boost during position runs
        debugPrint('Applied position run urgency boost: +0.05');
      }
      
      if (motivation.isTierDropoff) {
        adjustedValueRatio += 0.07; // 7% boost during talent tier dropoffs
        debugPrint('Applied tier dropoff urgency boost: +0.07');
      }
      
      if (motivation.isPreventingRival) {
        adjustedValueRatio += 0.06; // 6% boost when preventing a rival
        debugPrint('Applied rival prevention boost: +0.06');
        
        // Even more urgency for division rivals
        if (motivation.isDivisionRival) {
          adjustedValueRatio += 0.04; // Additional 4%
          debugPrint('Applied division rival boost: +0.04');
        }
      }
      
      if (motivation.isWinNowMove && motivation.teamStatus == TeamBuildStatus.winNow) {
        adjustedValueRatio += 0.05; // 5% boost for win-now teams making win-now moves
        debugPrint('Applied win-now team boost: +0.05');
      }
      
      // Premium position targeting (especially QB)
      if (motivation.isTargetingSpecificPlayer) {
        if (motivation.targetedPosition == 'QB') {
          adjustedValueRatio += 0.08; // 8% boost for QB targeting
          debugPrint('Applied QB targeting boost: +0.08');
        } else if (['OT', 'EDGE', 'CB'].contains(motivation.targetedPosition)) {
          adjustedValueRatio += 0.04; // 4% boost for premium positions
          debugPrint('Applied premium position boost: +0.04');
        }
      }
    }
    
    // 2. Leverage-based adjustments
    if (isUserInitiated) {
      adjustedValueRatio += 0.08; // 8% boost when user initiates (they have leverage)
      debugPrint('Applied user leverage boost: +0.08');
    }
    
    // For counter offers, the original receiver has leverage
    if (negotiationRound > 1 && counterOffer.teamOffering == originalOffer.teamReceiving) {
      adjustedValueRatio += 0.05; // 5% boost for counter offers from original receiver
      debugPrint('Applied counter offer leverage boost: +0.05');
    }
    
    // 3. Negotiation fatigue (teams more willing to accept after prolonged negotiation)
    if (negotiationRound > 1) {
      double fatigueBoost = (negotiationRound - 1) * 0.03; // +3% per round after first
      adjustedValueRatio += fatigueBoost;
      debugPrint('Applied negotiation fatigue boost: +$fatigueBoost');
    }
    
    // 4. Division rival premium (harder to trade within division)
    bool isDivisionRival = TeamClassification.areDivisionRivals(
      counterOffer.teamOffering,
      counterOffer.teamReceiving
    );
    
    if (isDivisionRival) {
      adjustedValueRatio -= 0.1; // 10% penalty for division rivals
      debugPrint('Applied division rival penalty: -0.1');
    }
    
    debugPrint('Final adjusted value ratio: $adjustedValueRatio');
    
    // Determine acceptance threshold based on context
    double acceptanceThreshold = _determineAcceptanceThreshold(
      originalOffer,
      counterOffer,
      negotiationRound,
      motivation
    );
    
    debugPrint('Acceptance threshold: $acceptanceThreshold');
    
    // Evaluate against threshold
    bool accepted = adjustedValueRatio >= acceptanceThreshold;
    
    // Generate reason and suggested improvements
    String reason;
    Map<String, dynamic>? suggestedImprovements;
    
    if (accepted) {
      reason = "Accepted";
      if (motivation != null) {
        reason += ": ${motivation.generateDialogue(isAccepting: true)}";
      } else {
        reason += ": The value works for our team's needs.";
      }
    } else {
      // Calculate value gap
      double valueMissing = (acceptanceThreshold - adjustedValueRatio) * counterOffer.targetPickValue;
      
      // Generate reason and suggestion based on context
      reason = _generateRejectionReason(
        counterOffer,
        adjustedValueRatio,
        acceptanceThreshold,
        motivation
      );
      
      suggestedImprovements = _generateImprovementSuggestions(
        counterOffer,
        valueMissing,
        negotiationRound,
        motivation
      );
    }
    
    return EvaluationResult(
      isAccepted: accepted,
      reason: reason,
      adjustedValueRatio: adjustedValueRatio,
      acceptanceThreshold: acceptanceThreshold,
      negotiationRound: negotiationRound,
      suggestedImprovements: suggestedImprovements,
    );
  }
  
  /// Apply leverage adjustments to the value ratio
  double _applyLeverageAdjustments(
    double baseRatio,
    TradePackage originalOffer,
    TradePackage counterOffer,
    TradeMotivation? motivation,
    bool isUserInitiated,
    int negotiationRound
  ) {
    double adjustedRatio = baseRatio;
    
    // Determine who has leverage in this situation
    bool isInitialCounterOffer = negotiationRound == 1;
    bool isOriginalOfferorResponding = counterOffer.teamReceiving == originalOffer.teamOffering;
    
    // Apply user leverage
    if (isUserInitiated) {
      adjustedRatio += userLeverageDiscount;
      debugPrint('Applied user leverage: +$userLeverageDiscount');
    }
    
    // Apply counter-offer leverage (initial responder has more leverage)
    if (isInitialCounterOffer && !isOriginalOfferorResponding) {
      adjustedRatio += 0.05; // 5% boost for first counter
      debugPrint('Applied initial counter-offer boost: +0.05');
    }
    
    // Apply urgency-based leverage
    if (motivation != null) {
      if (motivation.isPositionRun || motivation.isTierDropoff) {
        // Less leverage during position runs or tier dropoffs (more urgency)
        adjustedRatio -= 0.03;
        debugPrint('Applied urgency penalty: -0.03');
      }
      
      if (motivation.isPreventingRival) {
        // Less leverage when trying to prevent a rival (more urgency)
        adjustedRatio -= 0.04;
        debugPrint('Applied rival prevention penalty: -0.04');
      }
    }
    
    // Apply negotiation fatigue (less leverage in later rounds)
    double fatiguePenalty = (negotiationRound - 1) * 0.03;
    adjustedRatio -= fatiguePenalty;
    
    if (fatiguePenalty > 0) {
      debugPrint('Applied negotiation fatigue: -$fatiguePenalty');
    }
    
    return adjustedRatio;
  }
  
  /// Apply positional value adjustments
  double _applyPositionalAdjustments(double ratio, String position) {
    // Premium position adjustments
    Map<String, double> positionAdjustments = {
      'QB': 0.05,     // Quarterbacks are highly valued
      'OT': 0.03,     // Offensive tackles are premium
      'EDGE': 0.03,   // Edge rushers are premium
      'CB': 0.02,     // Cornerbacks are valuable
      'WR': 0.02,     // Wide receivers are valuable
      'DL': 0.01,     // Defensive line
      'TE': 0.0,      // Tight ends - neutral
      'S': 0.0,       // Safeties - neutral
      'IOL': -0.01,   // Interior offensive line
      'LB': -0.01,    // Linebackers
      'RB': -0.02,    // Running backs typically devalued
    };
    
    double adjustment = positionAdjustments[position] ?? 0.0;
    
    // Apply adjustment - penalize for premium positions, boost for devalued ones
    // This is because when trading up for a premium position, the receiving team
    // should demand more, not less.
    return ratio - adjustment;
  }
  
  /// Determine the acceptance threshold based on context
  double _determineAcceptanceThreshold(
    TradePackage originalOffer,
    TradePackage counterOffer,
    int negotiationRound,
    TradeMotivation? motivation
  ) {
    // Start with base threshold
    double threshold = baseAcceptanceThreshold;
    
    // Adjust based on round position
    int round = DraftValueService.getRoundForPick(counterOffer.targetPick.pickNumber);
    if (round == 1) {
      if (counterOffer.targetPick.pickNumber <= 10) {
        threshold += 0.05; // Higher threshold for top 10 picks
      } else {
        threshold += 0.03; // Higher threshold for other 1st round picks
      }
    } else if (round == 2) {
      threshold += 0.01; // Slightly higher threshold for 2nd round
    }
    
    // Adjust for motivation intensity
    if (motivation != null) {
      int motivationCount = 0;
      if (motivation.isTargetingSpecificPlayer) motivationCount++;
      if (motivation.isPreventingRival) motivationCount++;
      if (motivation.isWinNowMove) motivationCount++;
      if (motivation.isPositionRun) motivationCount++;
      if (motivation.isTierDropoff) motivationCount++;
      
      // More motivations = more urgency = lower threshold
      threshold -= (motivationCount * 0.01);
    }
    
    // Adjust based on negotiation history
    if (negotiationRound > 1) {
      // Previous offers affect willingness to accept
      String teamPair = "${counterOffer.teamOffering}_${counterOffer.teamReceiving}";
      
      if (_previousOffersRatioByTeam.containsKey(teamPair) && 
          _previousOffersRatioByTeam[teamPair]!.length > 1) {
        
        // Check if offers are improving over time
        List<double> previousRatios = _previousOffersRatioByTeam[teamPair]!;
        double previousRatio = previousRatios[previousRatios.length - 2];
        double currentRatio = previousRatios.last;
        
        // If offers are improving rapidly, be more lenient
        if (currentRatio > previousRatio + 0.05) {
          threshold -= 0.02; // Good faith negotiating
        }
        // If offers aren't improving much, be more demanding
        else if (currentRatio <= previousRatio + 0.01) {
          threshold += 0.02; // Bad faith negotiating
        }
      }
      
      // Later rounds get more lenient due to negotiation fatigue
      threshold -= (negotiationRound - 1) * 0.01;
    }
    
    // Add slight randomness to threshold (±0.01)
    threshold += (_random.nextDouble() * 0.02) - 0.01;
    
    // Ensure threshold stays in reasonable bounds
    return min(0.98, max(0.85, threshold));
  }
  
  /// Generate a contextual rejection reason based on motivation
String _generateRejectionReason(
  TradePackage counterOffer,
  double adjustedValueRatio,
  double acceptanceThreshold,
  TradeMotivation? motivation
) {
  double valueDelta = acceptanceThreshold - adjustedValueRatio;
  
  // If we have motivation context, use it
  if (motivation != null) {
    // Value is very close to threshold
    if (valueDelta < 0.03) {
      if (motivation.isTargetingSpecificPlayer) {
        return "We're close, but we need a bit more value to move up for our targeted ${motivation.targetedPosition}.";
      } else if (motivation.isPreventingRival) {
        return "The offer is close, but we'd need slightly more to make this move ahead of our competitor.";
      } else if (motivation.isTierDropoff) {
        return "We're seeing a talent dropoff after this pick, so we'd need a bit more to make this work.";
      } else {
        return "We're getting closer, but we still need a bit more value to make this work.";
      }
    }
    // Moderate gap
    else if (valueDelta < 0.08) {
      if (motivation.isTargetingSpecificPlayer) {
        String position = motivation.targetedPosition.isNotEmpty ? motivation.targetedPosition : "player";
        return "This offer undervalues our interest in selecting a $position at this position. We need more compensation.";
      } else if (motivation.isPreventingRival) {
        return "We're motivated to make this move, but the offer needs to be more substantial to justify jumping ahead of ${motivation.rivalTeam}.";
      } else {
        return "The offer still undervalues our pick. We would need more compensation to consider this deal.";
      }
    }
    // Large gap
    else {
      if (motivation.isWinNowMove) {
        return "As a win-now team, we're looking for much more immediate value to make this deal work.";
      } else if (motivation.isPositionRun) {
        return "With the current run on ${motivation.targetedPosition}, this offer falls well short of what we'd need.";
      } else {
        return "This offer falls significantly short of our valuation. We need substantially more to move forward.";
      }
    }
  }
  
  // Generic reasons if no motivation context
  if (valueDelta < 0.03) {
    return "We're close, but we need a bit more value to make this work.";
  } else if (valueDelta < 0.08) {
    return "The offer still undervalues our pick. We would need more compensation to consider this deal.";
  } else {
    return "This offer falls significantly short of our valuation. We need substantially more to move forward.";
  }
}

/// Generate suggestions for improving the counter offer
Map<String, dynamic> _generateImprovementSuggestions(
  TradePackage counterOffer,
  double valueMissing,
  int negotiationRound,
  TradeMotivation? motivation
) {
  // Convert missing value to point approximation
  int pointsMissing = valueMissing.round();
  
  // Determine which round would provide approximately the missing value
  int suggestedRound = 7; // Default to 7th round
  
  if (pointsMissing > 300) {
    suggestedRound = 2; // Need a 2nd rounder
  } else if (pointsMissing > 150) {
    suggestedRound = 3; // Need a 3rd rounder
  } else if (pointsMissing > 80) {
    suggestedRound = 4; // Need a 4th rounder
  } else if (pointsMissing > 40) {
    suggestedRound = 5; // Need a 5th rounder
  } else if (pointsMissing > 20) {
    suggestedRound = 6; // Need a 6th rounder
  }
  
  // Determine if a future pick would be acceptable
  bool futurePickAcceptable = negotiationRound >= 2 || 
                             (motivation != null && motivation.teamStatus == TeamBuildStatus.rebuilding);
  
  // Create suggestion message with context
  String suggestionText;
  if (motivation != null && motivation.isTargetingSpecificPlayer) {
    suggestionText = "To move up for a ${motivation.targetedPosition}, adding a ${suggestedRound}th round pick would likely make this deal acceptable.";
  } else if (motivation != null && motivation.isPreventingRival) {
    suggestionText = "To make this trade ahead of ${motivation.rivalTeam}, you'd need to add approximately a ${suggestedRound}th round value.";
  } else {
    suggestionText = "Adding a ${suggestedRound}th round pick would likely make this deal acceptable.";
  }
  
  // Future pick suggestion with context
  String? futureText;
  if (futurePickAcceptable) {
    if (motivation != null && motivation.teamStatus == TeamBuildStatus.rebuilding) {
      futureText = "As a rebuilding team, we would also strongly consider a future ${suggestedRound}th round pick instead.";
    } else {
      futureText = "We would also consider a future ${suggestedRound}th round pick instead.";
    }
  }
  
  return {
    'pointsMissing': pointsMissing,
    'suggestedRound': suggestedRound,
    'futurePickAcceptable': futurePickAcceptable,
    'suggestionText': suggestionText,
    'futureText': futureText,
  };
}
  
  /// Reset negotiation history for testing/debugging
  void resetNegotiationHistory() {
    _negotiationRoundsByTeam.clear();
    _previousOffersRatioByTeam.clear();
  }
}

/// Result of a counter offer evaluation
class EvaluationResult {
  final bool isAccepted;
  final String reason;
  final double adjustedValueRatio;
  final double acceptanceThreshold;
  final int negotiationRound;
  final Map<String, dynamic>? suggestedImprovements;
  
  const EvaluationResult({
    required this.isAccepted,
    required this.reason,
    required this.adjustedValueRatio,
    required this.acceptanceThreshold,
    required this.negotiationRound,
    this.suggestedImprovements,
  });
  
  @override
  String toString() {
    return 'EvaluationResult(accepted: $isAccepted, reason: "$reason", adjustedRatio: $adjustedValueRatio, threshold: $acceptanceThreshold)';
  }
}