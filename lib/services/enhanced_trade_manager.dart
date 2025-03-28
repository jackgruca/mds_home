// lib/services/enhanced_trade_manager.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../models/trade_offer.dart';
import '../models/trade_motivation.dart';
import 'draft_value_service.dart';
import 'team_classification.dart';
import 'position_value_tracker.dart';
import 'trade_window_detector.dart';
import 'rival_detector.dart';
import 'trade_dialog_generator.dart';
import 'advanced_package_generator.dart';
import 'counter_offer_evaluator.dart';
import 'trade_frequency_calibrator.dart';

/// Results of the trade interest assessment including motivation
class TradeInterestResult {
  final String teamName;
  final bool isInterested;
  final TradeMotivation motivation;
  final double interestLevel; // 0.0-1.0 scale
  
  const TradeInterestResult({
    required this.teamName,
    required this.isInterested,
    required this.motivation,
    required this.interestLevel,
  });
}

/// Enhanced trade management with Phase 3 improvements
class EnhancedTradeManager {
  // Core data
  final List<DraftPick> draftOrder;
  final List<TeamNeed> teamNeeds;
  final List<Player> availablePlayers;
  final List<String>? userTeams;
  final bool enableVerboseLogging;
  final StringBuffer _logBuffer = StringBuffer();
  
  // Enhanced services
  final PositionValueTracker _positionTracker;
  final TradeWindowDetector _windowDetector;
  final RivalDetector _rivalDetector;
  final TradeDialogueGenerator _dialogueGenerator;
  final AdvancedPackageGenerator _packageGenerator;
  final CounterOfferEvaluator _counterOfferEvaluator;
  final TradeFrequencyCalibrator _frequencyCalibrator;
  
  // Random for probability calculations
  final Random _random = Random();
  
  // Current draft state and tracking
  final Map<String, Set<int>> _recentlyConsideredPicks = {};
  final Map<String, List<String>> _previousTradePartners = {};
  final Map<String, List<int>> _completedTradePickNumbers = {};
  final Map<String, TradeMotivation> _cachedMotivations = {};
  
  // Configuration parameters
  final double baseTradeFrequency;
  final double userTeamTradeFrequency;
  final bool enableQBPremium;
  final bool enablePositionPremium;
  final bool enableDivisionRivalDetection;
  final bool enableRealisticPackages;
  final bool enableDetailedRejectionReasons;
  final Map<String, double> _valueCache = {};
  final Map<int, List<TradeWindow>> _windowCache = {};
  final Map<String, List<TradeInterestResult>> _interestCache = {};
  
  // Constants
  static const int _maxTrackedPicksPerTeam = 10;
  static const int _maxTrackedTradePartners = 5;

  int _completedPicks = 0;
  int _currentPick = 0;
  
  EnhancedTradeManager({
    required this.draftOrder,
    required this.teamNeeds,
    required this.availablePlayers,
    this.userTeams,
    this.baseTradeFrequency = 0.3,
    this.userTeamTradeFrequency = 0.5,
    this.enableQBPremium = true,
    this.enablePositionPremium = true,
    this.enableDivisionRivalDetection = true,
    this.enableRealisticPackages = true,
    this.enableDetailedRejectionReasons = true,
    this.enableVerboseLogging = false,
    PositionValueTracker? positionTracker,
    TradeWindowDetector? windowDetector,
    RivalDetector? rivalDetector,
    TradeDialogueGenerator? dialogueGenerator,
    AdvancedPackageGenerator? packageGenerator,
    CounterOfferEvaluator? counterOfferEvaluator,
    TradeFrequencyCalibrator? frequencyCalibrator,
  }) : 
    _positionTracker = positionTracker ?? PositionValueTracker(),
    _windowDetector = windowDetector ?? TradeWindowDetector(),
    _rivalDetector = rivalDetector ?? RivalDetector(),
    _dialogueGenerator = dialogueGenerator ?? TradeDialogueGenerator(),
    _packageGenerator = packageGenerator ?? AdvancedPackageGenerator(),
    _counterOfferEvaluator = counterOfferEvaluator ?? CounterOfferEvaluator(),
    _frequencyCalibrator = frequencyCalibrator ?? TradeFrequencyCalibrator(
      baseFrequency: baseTradeFrequency
    ) {
      // Initialize frequency calibrator with total pick count
      _frequencyCalibrator.initialize(totalPicks: draftOrder.length);
      _logTradeOperation('Trade system initialized with ${draftOrder.length} picks and ${teamNeeds.length} teams');
    }

    /// Log a trade operation with timestamp
    void _logTradeOperation(String message, {bool isError = false, bool force = false}) {
      if (!enableVerboseLogging && !force && !isError) return;
      
      final timestamp = DateTime.now().toString().substring(11, 19);
      final prefix = isError ? '❌ ERROR' : '🔄 INFO';
      final logMessage = '[$timestamp] $prefix: $message';
      
      _logBuffer.writeln(logMessage);
      
      // Also print to console for immediate feedback
      if (isError) {
        debugPrint('\x1B[31m$logMessage\x1B[0m'); // Red for errors
      } else if (force) {
        debugPrint('\x1B[33m$logMessage\x1B[0m'); // Yellow for important events
      } else if (enableVerboseLogging) {
        debugPrint(logMessage);
      }
    }
  
  TradeMotivation? getTradeMotivation(String team) {
  return _cachedMotivations[team];
}

  /// Generate trade offers for a specific pick with improved motivation and packaging
  TradeOffer generateTradeOffersForPick(int pickNumber, {bool qbSpecific = false}) {
    _logTradeOperation('Generating offers for pick #$pickNumber${qbSpecific ? " (QB-specific)" : ""}', force: true);

  // Update current pick tracking
  _currentPick = pickNumber;

    // Get the target pick
    DraftPick? targetPick = _findPickByNumber(pickNumber);
    if (targetPick == null) {
      _logTradeOperation('Pick #$pickNumber not found in draft order', isError: true);
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Check if this is a user team's pick
    final bool isUserTeamPick = userTeams?.contains(targetPick.teamName) ?? false;
    
    // First, determine if the team with the pick is open to trading down
    bool isWillingToTrade = _isTeamWillingToTradeDown(targetPick);
    if (!isWillingToTrade && !isUserTeamPick) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Calibrate trade frequency - skip evaluation sometimes for realism
    bool shouldEvaluate = _frequencyCalibrator.shouldGenerateTrade(
      pickNumber: pickNumber,
      availablePlayers: availablePlayers,
      isUserTeamPick: isUserTeamPick,
      isQBDriven: qbSpecific,
    );
    
    // For user team picks, always evaluate (user decides)
    if (!isUserTeamPick && !shouldEvaluate && !qbSpecific) {
      return TradeOffer(packages: [], pickNumber: pickNumber);
    }
    
    // Find teams interested in trading up to this pick
    List<TradeInterestResult> interestedTeams = _findTeamsWithTradeMotivation(
      targetPick: targetPick,
      qbSpecific: qbSpecific
    );
    
    // Generate trade packages for interested teams
    List<TradePackage> packages = [];
    
    for (var result in interestedTeams) {
      // Get available picks for this team
      List<DraftPick> teamPicks = _getAvailableTeamPicks(result.teamName);
      
      // Skip if team has no picks to trade
      if (teamPicks.isEmpty) continue;
      
      // Cache motivation for later use
      _cachedMotivations[result.teamName] = result.motivation;
      
      // Create trade packages based on motivation
      List<TradePackage> teamPackages = _packageGenerator.generatePackages(
        teamOffering: result.teamName,
        teamReceiving: targetPick.teamName,
        availablePicks: teamPicks,
        targetPick: targetPick,
        motivation: result.motivation,
        isQBDriven: qbSpecific || result.motivation.targetedPosition == 'QB',
      );
      
      // Add to our collection
      packages.addAll(teamPackages);
      
      // Record that this team has considered this pick
      _recordPickConsideration(result.teamName, pickNumber);
    }
    
    _logTradeOperation('Generated ${packages.length} trade packages for pick #$pickNumber', force: true);

    return TradeOffer(
      packages: packages,
      pickNumber: pickNumber,
      isUserInvolved: isUserTeamPick,
    );
  }

  /// Get cached pick value or calculate and store it
  double _getCachedPickValue(int pickNumber) {
    final cacheKey = 'pick_value_$pickNumber';
    if (_valueCache.containsKey(cacheKey)) {
      return _valueCache[cacheKey]!;
    }
    
    final value = DraftValueService.getValueForPick(pickNumber);
    _valueCache[cacheKey] = value;
    return value;
  }
  
  /// Find teams that have a motivation to trade up to the given pick
  List<TradeInterestResult> _findTeamsWithTradeMotivation({
    required DraftPick targetPick,
    bool qbSpecific = false,
  }) {
    List<TradeInterestResult> results = [];
    final int pickNumber = targetPick.pickNumber;
    String targetTeam = targetPick.teamName;
    final cacheKey = 'interest_${pickNumber}_${qbSpecific ? 'qb' : 'std'}_$_completedPicks';
    
    // Return cached results if available (and not stale)
    if (_interestCache.containsKey(cacheKey)) {
      _logTradeOperation('Using cached interest results for pick #$pickNumber');
      return _interestCache[cacheKey]!;
    }
    
    // Determine if we're in an active trade window
    List<TradeWindow> activeWindows = _windowDetector.getTradeWindows(
      pickNumber, 
      availablePlayers
    );
    bool hasActiveWindow = activeWindows.any((w) => w.isOpen);
    
    // Get base probability multiplier from trade windows
    double windowProbabilityMultiplier = 1.0;
    if (hasActiveWindow) {
      for (var window in activeWindows.where((w) => w.isOpen)) {
        windowProbabilityMultiplier = max(windowProbabilityMultiplier, window.probabilityMultiplier);
      }
    }
    
    // Check all teams for potential trade interest
    for (var teamNeed in teamNeeds) {
      final team = teamNeed.teamName;
      
      // Skip the team with the current pick
      if (team == targetTeam) continue;
      
      // Skip user teams - they'll initiate their own trades
      if (userTeams?.contains(team) ?? false) continue;
      
      // Skip if this team recently considered this pick
      if (_hasRecentlyConsideredPick(team, pickNumber)) continue;
      
      // Get team's next pick
      DraftPick? nextPick = _getTeamNextPickAfter(team, pickNumber);
      if (nextPick == null) continue; // Skip if team has no future picks
      
      // Get team's build status
      TeamBuildStatus status = TeamClassification.getTeamStatus(team);
      
      // Check if this is a rival
      bool isDivisionRival = enableDivisionRivalDetection && 
                             TeamClassification.areDivisionRivals(team, targetTeam);
      
      // Create a motivation based on team needs and context
      TradeMotivation motivation = _generateTradeMotivation(
        team,
        teamNeed,
        targetPick,
        nextPick,
        qbSpecific,
        activeWindows
      );
      
      // Calculate probability based on motivation
      double tradeProbability = _calculateProbabilityFromMotivation(
        motivation,
        targetPick,
        nextPick,
        windowProbabilityMultiplier,
        isDivisionRival
      );
      
      // Make trade decision
      bool isInterested = tradeProbability > 0 && _random.nextDouble() < tradeProbability;
      
      if (isInterested) {
        results.add(TradeInterestResult(
          teamName: team,
          isInterested: true,
          motivation: motivation,
          interestLevel: tradeProbability,
        ));
      }
    }
    
    // Cache the results before returning
    _interestCache[cacheKey] = results;
    
    return results;
  }
  
  /// Apply memory optimization techniques
  void _optimizeMemoryUsage() {
    // Limit cache sizes
    if (_valueCache.length > 1000) {
      // Remove oldest entries
      final keysToKeep = _valueCache.keys.toList().sublist(_valueCache.length - 500);
      _valueCache.removeWhere((key, _) => !keysToKeep.contains(key));
    }
    
    if (_windowCache.length > 20) {
      // Only keep recent windows
      final keysToRemove = _windowCache.keys.toList()
          .where((pick) => pick < _currentPick - 10)
          .toList();
      for (var key in keysToRemove) {
        _windowCache.remove(key);
      }
    }
    
    if (_interestCache.length > 10) {
      _interestCache.clear(); // Interest data can change a lot, so clear rather than partial removal
    }
  }

  /// Generate a trade motivation for a team to trade up
  TradeMotivation _generateTradeMotivation(
    String team,
    TeamNeed teamNeed,
    DraftPick targetPick,
    DraftPick nextPick,
    bool qbSpecific,
    List<TradeWindow> activeWindows
  ) {
    TeamBuildStatus status = TeamClassification.getTeamStatus(team);
    
    // Default empty motivation
    TradeMotivation motivation = TradeMotivation(
      teamStatus: status,
    );
    
    // If QB-specific request, focus on that
    if (qbSpecific) {
      // Is QB a need for this team?
      bool qbIsTopNeed = teamNeed.needs.take(3).contains('QB');
      if (!qbIsTopNeed) {
        // Not interested in QB
        return motivation;
      }
      
      // Check if top QBs are available
      List<Player> topQBs = availablePlayers
          .where((p) => p.position == 'QB' && p.rank <= targetPick.pickNumber + 10)
          .toList();
      
      if (topQBs.isNotEmpty) {
        return TradeMotivation(
          teamStatus: status,
          isTargetingSpecificPlayer: true,
          targetedPosition: 'QB',
          motivationDescription: "Trading up for a franchise quarterback",
        );
      }
      
      return motivation;
    }
    
    // Check team needs
    if (teamNeed.needs.isEmpty) {
      return motivation;
    }
    
    // Get top need position
    String topNeedPosition = teamNeed.needs.first;
    
    // Check for position runs in active windows
    bool positionRunActive = activeWindows.any((w) => 
      w.isOpen && 
      w.reason.contains("run") && 
      w.reason.contains(topNeedPosition)
    );
    
    // Check for tier dropoffs in active windows
    bool tierDropoffImminent = activeWindows.any((w) => 
      w.isOpen && 
      w.reason.contains("dropoff") && 
      w.reason.contains(topNeedPosition)
    );
    
    // Check for rival about to pick
    String rivalTeam = _rivalDetector.findClosestRivalForPosition(
      teamName: team,
      position: topNeedPosition,
      draftOrder: draftOrder,
      teamNeeds: teamNeeds,
      currentPick: targetPick.pickNumber,
    );
    
    // Check for competitors (non-rival) about to pick
    String competitor = _rivalDetector.findCompetitorForPosition(
      position: topNeedPosition,
      draftOrder: draftOrder,
      teamNeeds: teamNeeds,
      currentPick: targetPick.pickNumber,
      nextTeamPick: nextPick.pickNumber,
    );
    
    // Check if top player at need position might not be available
    bool topPlayerAtRisk = _rivalDetector.isTopPlayerAtRisk(
      availablePlayers: availablePlayers,
      position: topNeedPosition,
      currentPick: targetPick.pickNumber,
      nextTeamPick: nextPick.pickNumber,
    );
    
    // Now determine the primary motivation
    if (positionRunActive) {
      // React to a position run
      return TradeMotivation(
        teamStatus: status,
        isTargetingSpecificPlayer: true,
        targetedPosition: topNeedPosition,
        isPositionRun: true,
        motivationDescription: "Reacting to a run on $topNeedPosition players",
      );
    }
    else if (tierDropoffImminent) {
      // React to a tier dropoff
      return TradeMotivation(
        teamStatus: status,
        isTargetingSpecificPlayer: true,
        targetedPosition: topNeedPosition,
        isTierDropoff: true,
        motivationDescription: "Trading up before a talent tier dropoff at $topNeedPosition",
      );
    }
    else if (rivalTeam.isNotEmpty) {
      // Get ahead of a rival
      return TradeMotivation(
        teamStatus: status,
        isPreventingRival: true,
        rivalTeam: rivalTeam,
        targetedPosition: topNeedPosition,
        isDivisionRival: true,
        motivationDescription: "Trading up to select a $topNeedPosition ahead of division rival $rivalTeam",
      );
    }
    else if (competitor.isNotEmpty) {
      // Get ahead of a competitor
      return TradeMotivation(
        teamStatus: status,
        isPreventingRival: true,
        rivalTeam: competitor,
        targetedPosition: topNeedPosition,
        motivationDescription: "Trading up to select a $topNeedPosition ahead of $competitor",
      );
    }
    else if (topPlayerAtRisk) {
      // Target a specific player at risk
      return TradeMotivation(
        teamStatus: status,
        isTargetingSpecificPlayer: true,
        targetedPosition: topNeedPosition,
        motivationDescription: "Trading up to secure a top $topNeedPosition before they're gone",
      );
    }
    else if (status == TeamBuildStatus.winNow && targetPick.pickNumber <= 100) {
      // Win-now move for immediate impact
      return TradeMotivation(
        teamStatus: status,
        isWinNowMove: true,
        targetedPosition: topNeedPosition,
        motivationDescription: "Win-now team trading up for immediate impact player",
      );
    }
    else if (_isValueOpportunity(targetPick, topNeedPosition)) {
      // Value-based move
      return TradeMotivation(
        teamStatus: status,
        isExploitingValue: true,
        targetedPosition: topNeedPosition,
        motivationDescription: "Trading up to select high-value player that's sliding",
      );
    }
    
    // Default to minimal interest in trading up
    return TradeMotivation(
      teamStatus: status,
      isExploitingValue: true,
      targetedPosition: topNeedPosition,
      motivationDescription: "Trading up based on draft board value",
    );
  }
  
  /// Calculate trade probability based on motivation
  double _calculateProbabilityFromMotivation(
    TradeMotivation motivation,
    DraftPick targetPick,
    DraftPick nextPick,
    double windowMultiplier,
    bool isDivisionRival
  ) {
    // Start with base frequency
    double probability = baseTradeFrequency;
    
    // Apply window multiplier from position runs/tier dropoffs
    probability *= windowMultiplier;
    
    // Round-based modifiers (different trade frequencies)
    int round = DraftValueService.getRoundForPick(targetPick.pickNumber);
    if (round == 1) {
      probability *= 1.5; // More trades in 1st round
    } else if (round == 2) {
      probability *= 1.3; // More trades in 2nd round
    } else if (round >= 5) {
      probability *= 0.7; // Fewer trades in later rounds
    }
    
    // Apply multipliers based on motivation flags
    if (motivation.isTargetingSpecificPlayer) {
      probability *= 1.5; // Targeting specific player is strong motivation
      
      // If position is premium, even stronger
      if (motivation.targetedPosition == 'QB') {
        probability *= 1.5; // Extremely strong for QBs
      } else if (['OT', 'EDGE', 'CB', 'WR'].contains(motivation.targetedPosition)) {
        probability *= 1.2; // Stronger for premium positions
      }
    }
    
    if (motivation.isPreventingRival) {
      probability *= 1.4; // Preventing rival is strong motivation
      
      // Even stronger if division rival
      if (motivation.isDivisionRival) {
        probability *= 1.2;
      }
    }
    
    if (motivation.isWinNowMove) {
      probability *= 1.3; // Win now teams more aggressive
    }
    
    if (motivation.isTierDropoff) {
      probability *= 1.6; // Very strong motivation - get the last player in tier
    }
    
    if (motivation.isPositionRun) {
      probability *= 1.5; // Strong motivation during position runs
    }
    
    // Reduce probability if it's a division rival (harder to trade with rivals)
    if (isDivisionRival) {
      probability *= 0.6; // 40% reduction for division rivals
    }
    
    // Normalize probability to reasonable range
    probability = min(0.85, max(0.05, probability));
    
    return probability;
  }
  
  /// Check if team is willing to trade down
  bool _isTeamWillingToTradeDown(DraftPick pick) {
    String team = pick.teamName;
    int pickNumber = pick.pickNumber;
    
    // User teams are always willing (user decides)
    if (userTeams?.contains(team) ?? false) {
      return true;
    }
    
    // Get team needs
    TeamNeed? teamNeed = teamNeeds.firstWhere(
      (need) => need.teamName == team,
      orElse: () => TeamNeed(teamName: team, needs: []),
    );
    
    // Get team status
    TeamBuildStatus status = TeamClassification.getTeamStatus(team);
    
    // Base willingness (different by pick position)
    double baseWillingness;
    if (pickNumber <= 5) {
      baseWillingness = 0.2; // Low for top 5 picks
    } else if (pickNumber <= 10) {
      baseWillingness = 0.25; // Low for top 10 picks
    } else if (pickNumber <= 32) {
      baseWillingness = 0.4; // Moderate for 1st round
    } else if (pickNumber <= 100) {
      baseWillingness = 0.5; // Average for day 2
    } else {
      baseWillingness = 0.7; // High for day 3
    }
    
    // Adjust based on team status
    if (status == TeamBuildStatus.rebuilding) {
      baseWillingness += 0.2; // Rebuilding teams more willing to trade down
    } else if (status == TeamBuildStatus.winNow) {
      baseWillingness -= 0.1; // Win-now teams less willing to trade down
    }
    
    // Check for targeted player at team needs
    if (teamNeed.needs.isNotEmpty) {
      String topNeed = teamNeed.needs.first;
      
      // Check if a great player at their position of need is available
      List<Player> topNeedPlayers = availablePlayers
          .where((p) => p.position == topNeed && p.rank <= pickNumber + 5)
          .toList();
      
      if (topNeedPlayers.isNotEmpty) {
        baseWillingness -= 0.3; // Much less likely to trade if top need player available
      }
    }
    
    // Check for QB-specific scenario (teams almost never trade down from QB)
    bool qbNeed = teamNeed.needs.take(3).contains("QB");
    bool topQBAvailable = availablePlayers
        .any((p) => p.position == "QB" && p.rank <= pickNumber + 5);
    
    if (qbNeed && topQBAvailable) {
      baseWillingness -= 0.4; // Very unlikely to trade down from QB
    }
    
    // Check if in an active trade window
    List<TradeWindow> windows = _windowDetector.getTradeWindows(pickNumber, availablePlayers);
    bool inActiveWindow = windows.any((w) => w.isOpen);
    
    if (inActiveWindow) {
      // More likely to keep pick during tier dropoff
      if (windows.any((w) => w.isOpen && w.reason.contains("dropoff"))) {
        baseWillingness -= 0.2;
      }
      // More likely to keep during position run on needed position
      else if (windows.any((w) => 
          w.isOpen && 
          w.reason.contains("run") && 
          teamNeed.needs.any((need) => w.reason.contains(need))
      )) {
        baseWillingness -= 0.25;
      }
    }
    
    // Make final random decision
    return _random.nextDouble() < baseWillingness;
  }
  
  /// Check if there's a value opportunity at the pick
  bool _isValueOpportunity(DraftPick pick, String position) {
    int pickNumber = pick.pickNumber;
    
    // Find players at the position who have slid
    List<Player> slidingPlayers = availablePlayers
        .where((p) => p.position == position && (pickNumber - p.rank) >= 10)
        .toList();
    
    return slidingPlayers.isNotEmpty;
  }
  
  /// Evaluate a trade proposal with enhanced logic
  bool evaluateTradeProposal(TradePackage proposal) {
    final teamReceiving = proposal.teamReceiving;
    final teamOffering = proposal.teamOffering;
    
    // If we have a cached motivation, use it for context
    TradeMotivation? motivation = _cachedMotivations[teamOffering];
    
    // Consider team relationship context
    bool teamsHaveRecentTrade = _havePreviouslyTraded(teamOffering, teamReceiving);
    bool isDivisionRival = TeamClassification.areDivisionRivals(teamOffering, teamReceiving);
    
    // Check if this is a counter offer
    bool isCounterOffer = false; // Would need context from previous offers
    
    // Evaluate with enhanced counter offer evaluator
    EvaluationResult result = _counterOfferEvaluator.evaluateCounterOffer(
      originalOffer: proposal, // Not a real counter, but using same method
      counterOffer: proposal,
      motivation: motivation,
      isUserInitiated: userTeams?.contains(teamOffering) ?? false,
    );
    
    return result.isAccepted;
  }
  
  /// Evaluate a counter offer with proper leverage dynamics
  EvaluationResult evaluateCounterOffer(
    TradePackage originalOffer,
    TradePackage counterOffer,
    {int negotiationRound = 1}
  ) {
    // Get motivation if available
    TradeMotivation? motivation;
    if (_cachedMotivations.containsKey(counterOffer.teamOffering)) {
      motivation = _cachedMotivations[counterOffer.teamOffering];
    } else if (_cachedMotivations.containsKey(counterOffer.teamReceiving)) {
      motivation = _cachedMotivations[counterOffer.teamReceiving];
    }
    
    // Check if this is user initiated
    bool isUserInitiated = userTeams?.contains(counterOffer.teamOffering) ?? false;
    
    // Use the counter offer evaluator
    return _counterOfferEvaluator.evaluateCounterOffer(
      originalOffer: originalOffer,
      counterOffer: counterOffer,
      motivation: motivation,
      isUserInitiated: isUserInitiated,
      negotiationRound: negotiationRound,
    );
  }
  
  /// Get a rejection reason with suggested improvements
  Map<String, dynamic> getRejectionDetails(TradePackage proposal) {
    // Get motivation if available
    TradeMotivation? motivation = _cachedMotivations[proposal.teamOffering];
    
    // Evaluate with counter offer evaluator to get detailed rejection
    EvaluationResult result = _counterOfferEvaluator.evaluateCounterOffer(
      originalOffer: proposal,
      counterOffer: proposal,
      motivation: motivation,
      isUserInitiated: userTeams?.contains(proposal.teamOffering) ?? false,
    );
    
    // Create response with details
    return {
      'reason': result.reason,
      'adjustedValueRatio': result.adjustedValueRatio,
      'acceptanceThreshold': result.acceptanceThreshold,
      'improvements': result.suggestedImprovements,
    };
  }
  
  /// Generate a trade narrative
  String generateTradeNarrative(TradePackage package) {
    // Get motivation if available
    TradeMotivation? motivation;
    if (_cachedMotivations.containsKey(package.teamOffering)) {
      motivation = _cachedMotivations[package.teamOffering];
    }
    
    // Use dialogue generator
    return _dialogueGenerator.generateAITradeDialogue(package, motivation);
  }
  
  /// Get a team's next pick after specified number
  DraftPick? _getTeamNextPickAfter(String team, int afterPickNumber) {
    List<DraftPick> laterPicks = draftOrder.where((pick) =>
      pick.teamName == team &&
      pick.pickNumber > afterPickNumber &&
      !pick.isSelected
    ).toList();
    
    if (laterPicks.isEmpty) return null;
    
    laterPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    return laterPicks.first;
  }
  
  /// Get all available picks for a team
  List<DraftPick> _getAvailableTeamPicks(String team) {
    return draftOrder.where((pick) =>
      pick.teamName == team &&
      !pick.isSelected
    ).toList();
  }
  
  /// Find a pick by number
  DraftPick? _findPickByNumber(int pickNumber) {
    try {
      return draftOrder.firstWhere(
        (pick) => pick.pickNumber == pickNumber && !pick.isSelected,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Record that a team has considered trading for a pick
  void _recordPickConsideration(String team, int pickNumber) {
    if (!_recentlyConsideredPicks.containsKey(team)) {
      _recentlyConsideredPicks[team] = {};
    }
    _recentlyConsideredPicks[team]!.add(pickNumber);
    
    // Limit the number of recorded picks per team
    if (_recentlyConsideredPicks[team]!.length > _maxTrackedPicksPerTeam) {
      // Remove oldest entries (we don't have timestamps, so this is an approximation)
      List<int> picks = _recentlyConsideredPicks[team]!.toList();
      picks.sort();
      _recentlyConsideredPicks[team] = picks.skip(picks.length - _maxTrackedPicksPerTeam).toSet();
    }
  }
  
  /// Check if a team has recently considered a pick
  bool _hasRecentlyConsideredPick(String team, int pickNumber) {
    return _recentlyConsideredPicks.containsKey(team) &&
           _recentlyConsideredPicks[team]!.contains(pickNumber);
  }
  
  /// Check if teams have previously traded
  bool _havePreviouslyTraded(String team1, String team2) {
    return (_previousTradePartners.containsKey(team1) && 
            _previousTradePartners[team1]!.contains(team2)) ||
           (_previousTradePartners.containsKey(team2) && 
            _previousTradePartners[team2]!.contains(team1));
  }
  
  /// Record a completed trade
  void recordCompletedTrade(TradePackage package) {
    String offering = package.teamOffering;
    String receiving = package.teamReceiving;
    
    // Record as trade partners
    if (!_previousTradePartners.containsKey(offering)) {
      _previousTradePartners[offering] = [];
    }
    if (!_previousTradePartners.containsKey(receiving)) {
      _previousTradePartners[receiving] = [];
    }
    
    _previousTradePartners[offering]!.add(receiving);
    _previousTradePartners[receiving]!.add(offering);
    
    // Maintain limited history
    if (_previousTradePartners[offering]!.length > _maxTrackedTradePartners) {
      _previousTradePartners[offering] = _previousTradePartners[offering]!
          .sublist(_previousTradePartners[offering]!.length - _maxTrackedTradePartners);
    }
    if (_previousTradePartners[receiving]!.length > _maxTrackedTradePartners) {
      _previousTradePartners[receiving] = _previousTradePartners[receiving]!
          .sublist(_previousTradePartners[receiving]!.length - _maxTrackedTradePartners);
    }
    
    // Record completed trade for pick
    if (!_completedTradePickNumbers.containsKey(receiving)) {
      _completedTradePickNumbers[receiving] = [];
    }
    _completedTradePickNumbers[receiving]!.add(package.targetPick.pickNumber);
    
    // Update calibrator for tracking trade frequency
    _frequencyCalibrator.recordTradeExecuted();
  }
  
  /// Get trade frequency statistics
  Map<String, dynamic> getTradeFrequencyStats() {
    return _frequencyCalibrator.getTradeStats();
  }
  
  /// Record player selection for position tracking
  void recordPlayerSelection(Player player) {
    _positionTracker.recordSelection(player);
    _windowDetector.recordSelection(player);
  }
  
  /// Reset state for a new draft
  void reset() {
    _recentlyConsideredPicks.clear();
    _previousTradePartners.clear();
    _completedTradePickNumbers.clear();
    _cachedMotivations.clear();
    _positionTracker.reset();
    _windowDetector.reset();
    _frequencyCalibrator.reset();
    _counterOfferEvaluator.resetNegotiationHistory();
  }
  /// Get the trade operation log
  String getTradeOperationLog() {
    return _logBuffer.toString();
  }
  
  /// Clear the log buffer
  void clearLog() {
    _logBuffer.clear();
  }

    /// Reset all caches
  void _resetCaches() {
    _valueCache.clear();
    _windowCache.clear();
    _interestCache.clear();
  }
  
  /// Record pick completion - call this after each pick
  void recordPickCompleted() {
    _completedPicks++;
    _frequencyCalibrator.recordPickCompleted();
    
    // Periodically optimize memory
    if (_completedPicks % 10 == 0) {
      _optimizeMemoryUsage();
    }
  }
}
