import 'dart:async';
import '../models/ff_player.dart';
import '../models/ff_team.dart';

/// Service for generating real-time value alerts during the draft
class FFValueAlertService {
  final StreamController<ValueAlert> _alertController = StreamController<ValueAlert>.broadcast();
  
  Stream<ValueAlert> get alertStream => _alertController.stream;
  
  /// Analyzes a completed pick and generates alerts
  void analyzePick({
    required FFPlayer player,
    required FFTeam team,
    required int pickNumber,
    required int round,
    required List<FFPlayer> remainingPlayers,
    required bool isUserTeam,
  }) {
    final alerts = <ValueAlert>[];
    final adp = player.stats?['adp']?.toDouble() ?? (pickNumber.toDouble() * 1.2);
    final adpDifference = pickNumber - adp;
    
    // Steal Alert - Player drafted significantly after ADP
    if (adpDifference <= -15) {
      alerts.add(ValueAlert(
        type: AlertType.STEAL,
        title: '🔥 STEAL ALERT!',
        message: '${player.name} drafted ${adpDifference.abs().toInt()} picks after ADP!',
        severity: AlertSeverity.HIGH,
        player: player,
        team: team,
        pickNumber: pickNumber,
        metadata: {'adp_difference': adpDifference},
      ));
    }
    
    // Reach Alert - Player drafted way before ADP
    else if (adpDifference >= 20) {
      alerts.add(ValueAlert(
        type: AlertType.REACH,
        title: '📈 REACH ALERT',
        message: '${player.name} drafted ${adpDifference.toInt()} picks before ADP',
        severity: AlertSeverity.MEDIUM,
        player: player,
        team: team,
        pickNumber: pickNumber,
        metadata: {'adp_difference': adpDifference},
      ));
    }
    
    // Position-specific alerts
    _checkPositionSpecificAlerts(alerts, player, team, round, remainingPlayers);
    
    // User-specific alerts
    if (isUserTeam) {
      _checkUserSpecificAlerts(alerts, player, team, round, remainingPlayers);
    }
    
    // Send all alerts
    for (final alert in alerts) {
      _alertController.add(alert);
    }
  }
  
  /// Analyzes remaining players and generates opportunity alerts
  void analyzeOpportunities({
    required List<FFPlayer> remainingPlayers,
    required int currentRound,
    required int currentPick,
    required FFTeam? userTeam,
  }) {
    final alerts = <ValueAlert>[];
    
    // Find players with exceptional value
    final valueOpportunities = _findValueOpportunities(remainingPlayers, currentPick);
    for (final player in valueOpportunities.take(3)) {
      final adp = player.stats?['adp']?.toDouble() ?? (currentPick.toDouble() * 1.2);
      final valueGap = adp - currentPick;
      
      alerts.add(ValueAlert(
        type: AlertType.VALUE_OPPORTUNITY,
        title: '💎 VALUE AVAILABLE',
        message: '${player.name} (${player.position}) - ${valueGap.toInt()} picks of value',
        severity: AlertSeverity.MEDIUM,
        player: player,
        pickNumber: currentPick,
        metadata: {'value_gap': valueGap},
      ));
    }
    
    // Position scarcity alerts
    if (userTeam != null) {
      _checkPositionScarcityAlerts(alerts, remainingPlayers, currentRound, userTeam);
    }
    
    // Late round gem alerts
    if (currentRound >= 10) {
      _checkLateRoundGemAlerts(alerts, remainingPlayers, currentRound);
    }
    
    // Send all alerts
    for (final alert in alerts) {
      _alertController.add(alert);
    }
  }
  
  /// Checks for position-specific drafting alerts
  void _checkPositionSpecificAlerts(
    List<ValueAlert> alerts,
    FFPlayer player,
    FFTeam team,
    int round,
    List<FFPlayer> remainingPlayers,
  ) {
    // Early kicker alert
    if (player.position == 'K' && round <= 13) {
      alerts.add(ValueAlert(
        type: AlertType.EARLY_KICKER,
        title: '🦶 EARLY KICKER',
        message: 'Kicker drafted in round $round - typically wait until round 15+',
        severity: AlertSeverity.LOW,
        player: player,
        team: team,
        pickNumber: ((round - 1) * 12) + (team.draftPosition ?? 1),
      ));
    }
    
    // Early defense alert
    if (player.position == 'DEF' && round <= 11) {
      alerts.add(ValueAlert(
        type: AlertType.EARLY_DEFENSE,
        title: '🛡️ EARLY DEFENSE',
        message: 'Defense drafted in round $round - typically wait until round 13+',
        severity: AlertSeverity.LOW,
        player: player,
        team: team,
        pickNumber: ((round - 1) * 12) + (team.draftPosition ?? 1),
      ));
    }
    
    // Third QB alert
    final qbCount = team.getPositionCount('QB');
    if (player.position == 'QB' && qbCount >= 2) {
      alerts.add(ValueAlert(
        type: AlertType.TOO_MANY_QBS,
        title: '🏈 THIRD QB',
        message: '${team.name} drafts 3rd QB - unusual strategy',
        severity: AlertSeverity.LOW,
        player: player,
        team: team,
        pickNumber: ((round - 1) * 12) + (team.draftPosition ?? 1),
      ));
    }
  }
  
  /// Checks for user-specific alerts and recommendations
  void _checkUserSpecificAlerts(
    List<ValueAlert> alerts,
    FFPlayer player,
    FFTeam team,
    int round,
    List<FFPlayer> remainingPlayers,
  ) {
    final positionCounts = team.getPositionCounts();
    
    // Excellent value pick
    final adp = player.stats?['adp']?.toDouble() ?? (round * 12.0);
    final pickNumber = ((round - 1) * 12) + (team.draftPosition ?? 1);
    final adpDifference = pickNumber - adp;
    
    if (adpDifference <= -8) {
      alerts.add(ValueAlert(
        type: AlertType.GOOD_VALUE,
        title: '✅ GOOD VALUE',
        message: 'Nice pick! ${player.name} drafted ${adpDifference.abs().toInt()} spots after ADP',
        severity: AlertSeverity.HIGH,
        player: player,
        team: team,
        pickNumber: pickNumber,
        metadata: {'adp_difference': adpDifference},
      ));
    }
    
    // Position need filled
    bool fillsNeed = false;
    if (player.position == 'QB' && positionCounts['QB']! == 0) fillsNeed = true;
    if (player.position == 'RB' && positionCounts['RB']! < 2) fillsNeed = true;
    if (player.position == 'WR' && positionCounts['WR']! < 2) fillsNeed = true;
    if (player.position == 'TE' && positionCounts['TE']! == 0) fillsNeed = true;
    
    if (fillsNeed) {
      alerts.add(ValueAlert(
        type: AlertType.NEED_FILLED,
        title: '🎯 NEED FILLED',
        message: 'Great pick! ${player.position} was a position of need',
        severity: AlertSeverity.MEDIUM,
        player: player,
        team: team,
        pickNumber: pickNumber,
      ));
    }
  }
  
  /// Checks for position scarcity alerts
  void _checkPositionScarcityAlerts(
    List<ValueAlert> alerts,
    List<FFPlayer> remainingPlayers,
    int currentRound,
    FFTeam userTeam,
  ) {
    // Count remaining players by position
    final remainingCounts = <String, int>{};
    for (final player in remainingPlayers) {
      remainingCounts[player.position] = (remainingCounts[player.position] ?? 0) + 1;
    }
    
    final userCounts = userTeam.getPositionCounts();
    
    // QB scarcity
    if (userCounts['QB']! == 0 && remainingCounts['QB']! <= 8 && currentRound <= 10) {
      alerts.add(ValueAlert(
        type: AlertType.POSITION_SCARCITY,
        title: '⚠️ QB SCARCITY',
        message: 'Only ${remainingCounts['QB']} starting QBs left - consider drafting soon',
        severity: AlertSeverity.HIGH,
        pickNumber: currentRound * 12,
        metadata: {'position': 'QB', 'remaining': remainingCounts['QB']},
      ));
    }
    
    // TE scarcity
    if (userCounts['TE']! == 0 && remainingCounts['TE']! <= 6 && currentRound <= 8) {
      alerts.add(ValueAlert(
        type: AlertType.POSITION_SCARCITY,
        title: '⚠️ TE SCARCITY',
        message: 'Only ${remainingCounts['TE']} top TEs left - position running thin',
        severity: AlertSeverity.MEDIUM,
        pickNumber: currentRound * 12,
        metadata: {'position': 'TE', 'remaining': remainingCounts['TE']},
      ));
    }
  }
  
  /// Checks for late round gem alerts
  void _checkLateRoundGemAlerts(
    List<ValueAlert> alerts,
    List<FFPlayer> remainingPlayers,
    int currentRound,
  ) {
    // Find players with much better rank than current round suggests
    for (final player in remainingPlayers.take(20)) {
      if (player.rank != null && player.rank! <= 100) {
        final expectedRound = ((player.rank! - 1) ~/ 12) + 1;
        if (currentRound > expectedRound + 3) {
          alerts.add(ValueAlert(
            type: AlertType.LATE_ROUND_GEM,
            title: '💎 LATE ROUND GEM',
            message: '${player.name} still available - ranked #${player.rank}',
            severity: AlertSeverity.MEDIUM,
            player: player,
            pickNumber: currentRound * 12,
            metadata: {'rank': player.rank, 'expected_round': expectedRound},
          ));
        }
      }
    }
  }
  
  /// Finds value opportunities in remaining players
  List<FFPlayer> _findValueOpportunities(List<FFPlayer> remainingPlayers, int currentPick) {
    return remainingPlayers.where((player) {
      final adp = player.stats?['adp']?.toDouble();
      if (adp == null) return false;
      return currentPick > adp + 8; // Available 8+ picks after ADP
    }).toList()
      ..sort((a, b) {
        final adpA = a.stats?['adp']?.toDouble() ?? 999.0;
        final adpB = b.stats?['adp']?.toDouble() ?? 999.0;
        return adpA.compareTo(adpB);
      });
  }
  
  /// Disposes the service
  void dispose() {
    _alertController.close();
  }
}

/// Represents a value alert during the draft
class ValueAlert {
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final FFPlayer? player;
  final FFTeam? team;
  final int? pickNumber;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ValueAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.player,
    this.team,
    this.pickNumber,
    this.metadata = const {},
  }) : timestamp = DateTime.now();

  /// Duration to display the alert
  Duration get displayDuration {
    switch (severity) {
      case AlertSeverity.HIGH:
        return const Duration(seconds: 5);
      case AlertSeverity.MEDIUM:
        return const Duration(seconds: 4);
      case AlertSeverity.LOW:
        return const Duration(seconds: 3);
    }
  }
}

enum AlertType {
  STEAL,
  REACH,
  VALUE_OPPORTUNITY,
  POSITION_SCARCITY,
  EARLY_KICKER,
  EARLY_DEFENSE,
  TOO_MANY_QBS,
  GOOD_VALUE,
  NEED_FILLED,
  LATE_ROUND_GEM,
}

enum AlertSeverity { HIGH, MEDIUM, LOW }