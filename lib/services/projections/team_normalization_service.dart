import '../../models/projections/stat_prediction.dart';

class TeamNormalizationService {
  // Target total for team target share (slightly under 1.0 to account for RBs, etc.)
  static const double TARGET_TEAM_TOTAL = 0.95;
  
  // Minimum and maximum individual target share values
  static const double MIN_TARGET_SHARE = 0.01;
  static const double MAX_TARGET_SHARE = 0.45;

  /// Normalize target shares for a team when one player's share is updated
  /// Returns updated list of predictions with normalized target shares
  static List<StatPrediction> normalizeTeamTargetShares(
    List<StatPrediction> teamPredictions,
    String updatedPlayerId,
    double newTargetShare,
  ) {
    if (teamPredictions.isEmpty) return teamPredictions;

    // Validate the new target share
    final clampedTargetShare = newTargetShare.clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);
    
    // Find the updated player
    final updatedPlayerIndex = teamPredictions.indexWhere((p) => p.playerId == updatedPlayerId);
    if (updatedPlayerIndex == -1) return teamPredictions;

    final updatedPlayer = teamPredictions[updatedPlayerIndex];
    final oldTargetShare = updatedPlayer.nyTgtShare;
    final targetShareDelta = clampedTargetShare - oldTargetShare;

    // Create list of other players who can be adjusted
    final otherPlayers = teamPredictions
        .where((p) => p.playerId != updatedPlayerId)
        .toList();

    if (otherPlayers.isEmpty) {
      // Only one player on team, just update them
      final updated = updatedPlayer.copyWith(
        nyTgtShare: clampedTargetShare,
        isEdited: true,
      );
      return [updated];
    }

    // Calculate current total excluding the updated player
    final otherPlayersTotal = otherPlayers.fold<double>(
      0.0, 
      (sum, player) => sum + player.nyTgtShare,
    );

    // Calculate the new total that others should sum to
    final targetOthersTotal = TARGET_TEAM_TOTAL - clampedTargetShare;

    // If target others total is negative or too small, adjust the updated player's share
    if (targetOthersTotal < MIN_TARGET_SHARE * otherPlayers.length) {
      final maxPossibleShare = TARGET_TEAM_TOTAL - (MIN_TARGET_SHARE * otherPlayers.length);
      final adjustedTargetShare = maxPossibleShare.clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);
      
      return _distributeTargetShares(
        teamPredictions,
        updatedPlayerId,
        adjustedTargetShare,
      );
    }

    // Calculate proportional adjustment for other players
    final adjustmentRatio = otherPlayersTotal > 0 ? targetOthersTotal / otherPlayersTotal : 0.0;

    final updatedPredictions = <StatPrediction>[];

    for (final prediction in teamPredictions) {
      if (prediction.playerId == updatedPlayerId) {
        // Update the target player
        updatedPredictions.add(prediction.copyWith(
          nyTgtShare: clampedTargetShare,
          isEdited: true,
        ));
      } else {
        // Proportionally adjust other players
        final newShare = (prediction.nyTgtShare * adjustmentRatio)
            .clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);
        
        updatedPredictions.add(prediction.copyWith(
          nyTgtShare: newShare,
        ));
      }
    }

    // Verify and fine-tune the total
    return _fineTuneTeamTotal(updatedPredictions, updatedPlayerId);
  }

  /// Distribute target shares more evenly when constraints are violated
  static List<StatPrediction> _distributeTargetShares(
    List<StatPrediction> teamPredictions,
    String priorityPlayerId,
    double priorityPlayerShare,
  ) {
    final otherPlayers = teamPredictions
        .where((p) => p.playerId != priorityPlayerId)
        .toList();

    if (otherPlayers.isEmpty) {
      final priorityPlayer = teamPredictions.firstWhere((p) => p.playerId == priorityPlayerId);
      return [priorityPlayer.copyWith(nyTgtShare: priorityPlayerShare, isEdited: true)];
    }

    final remainingTotal = TARGET_TEAM_TOTAL - priorityPlayerShare;
    final sharePerOtherPlayer = remainingTotal / otherPlayers.length;

    final updatedPredictions = <StatPrediction>[];

    for (final prediction in teamPredictions) {
      if (prediction.playerId == priorityPlayerId) {
        updatedPredictions.add(prediction.copyWith(
          nyTgtShare: priorityPlayerShare,
          isEdited: true,
        ));
      } else {
        updatedPredictions.add(prediction.copyWith(
          nyTgtShare: sharePerOtherPlayer.clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE),
        ));
      }
    }

    return updatedPredictions;
  }

  /// Fine-tune the team total to match TARGET_TEAM_TOTAL
  static List<StatPrediction> _fineTuneTeamTotal(
    List<StatPrediction> teamPredictions,
    String protectedPlayerId,
  ) {
    final currentTotal = teamPredictions.fold<double>(
      0.0,
      (sum, player) => sum + player.nyTgtShare,
    );

    final difference = TARGET_TEAM_TOTAL - currentTotal;
    
    // If difference is small enough, no adjustment needed
    if (difference.abs() < 0.001) {
      return teamPredictions;
    }

    // Find players we can adjust (excluding protected player)
    final adjustablePlayers = teamPredictions
        .where((p) => p.playerId != protectedPlayerId)
        .toList();

    if (adjustablePlayers.isEmpty) {
      return teamPredictions;
    }

    final adjustmentPerPlayer = difference / adjustablePlayers.length;

    return teamPredictions.map((prediction) {
      if (prediction.playerId == protectedPlayerId) {
        return prediction;
      }

      final newShare = (prediction.nyTgtShare + adjustmentPerPlayer)
          .clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);

      return prediction.copyWith(nyTgtShare: newShare);
    }).toList();
  }

  /// Get team target share summary
  static Map<String, dynamic> getTeamTargetShareSummary(List<StatPrediction> teamPredictions) {
    if (teamPredictions.isEmpty) {
      return {
        'total': 0.0,
        'count': 0,
        'average': 0.0,
        'isValid': false,
        'difference': 0.0,
      };
    }

    final total = teamPredictions.fold<double>(0.0, (sum, p) => sum + p.nyTgtShare);
    final count = teamPredictions.length;
    final average = total / count;
    final difference = total - TARGET_TEAM_TOTAL;
    final isValid = total <= TARGET_TEAM_TOTAL + 0.01 && total >= TARGET_TEAM_TOTAL - 0.05;

    return {
      'total': total,
      'count': count,
      'average': average,
      'isValid': isValid,
      'difference': difference,
      'target': TARGET_TEAM_TOTAL,
    };
  }

  /// Validate team target shares
  static bool validateTeamTargetShares(List<StatPrediction> teamPredictions) {
    final summary = getTeamTargetShareSummary(teamPredictions);
    return summary['isValid'] as bool;
  }

  /// Reset team target shares to proportional distribution
  static List<StatPrediction> resetTeamToProportional(
    List<StatPrediction> teamPredictions,
  ) {
    if (teamPredictions.isEmpty) return teamPredictions;

    // Calculate proportional shares based on original values
    final totalOriginal = teamPredictions.fold<double>(
      0.0,
      (sum, p) => sum + (p.originalValues['nyTgtShare'] as double? ?? p.nyTgtShare),
    );

    if (totalOriginal == 0) {
      // Equal distribution if no original data
      final equalShare = TARGET_TEAM_TOTAL / teamPredictions.length;
      return teamPredictions.map((p) => p.copyWith(
        nyTgtShare: equalShare,
        isEdited: false,
      )).toList();
    }

    return teamPredictions.map((prediction) {
      final originalShare = prediction.originalValues['nyTgtShare'] as double? ?? prediction.nyTgtShare;
      final proportionalShare = (originalShare / totalOriginal) * TARGET_TEAM_TOTAL;
      
      return prediction.copyWith(
        nyTgtShare: proportionalShare.clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE),
        isEdited: false,
      );
    }).toList();
  }

  /// Get suggested target share for a new player added to team
  static double getSuggestedTargetShare(List<StatPrediction> existingTeamPlayers) {
    if (existingTeamPlayers.isEmpty) {
      return TARGET_TEAM_TOTAL * 0.3; // 30% if first player
    }

    final currentTotal = existingTeamPlayers.fold<double>(0.0, (sum, p) => sum + p.nyTgtShare);
    final remaining = TARGET_TEAM_TOTAL - currentTotal;

    if (remaining <= 0) {
      return MIN_TARGET_SHARE;
    }

    // Suggest a reasonable share based on team depth
    if (existingTeamPlayers.length <= 2) {
      return (remaining * 0.6).clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);
    } else if (existingTeamPlayers.length <= 4) {
      return (remaining * 0.4).clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);
    } else {
      return (remaining * 0.2).clamp(MIN_TARGET_SHARE, MAX_TARGET_SHARE);
    }
  }

  /// Get recommendations for team optimization
  static Map<String, dynamic> getTeamOptimizationRecommendations(
    List<StatPrediction> teamPredictions,
  ) {
    final summary = getTeamTargetShareSummary(teamPredictions);
    final recommendations = <String>[];

    if (!summary['isValid']) {
      final difference = summary['difference'] as double;
      if (difference > 0.01) {
        recommendations.add('Team total (${(summary['total'] as double).toStringAsFixed(3)}) exceeds target. Consider reducing shares.');
      } else if (difference < -0.05) {
        recommendations.add('Team total (${(summary['total'] as double).toStringAsFixed(3)}) is well below target. Consider increasing shares.');
      }
    }

    // Find players with unusually high/low shares
    final sortedPlayers = List<StatPrediction>.from(teamPredictions)
      ..sort((a, b) => b.nyTgtShare.compareTo(a.nyTgtShare));

    if (sortedPlayers.isNotEmpty && sortedPlayers.first.nyTgtShare > 0.35) {
      recommendations.add('${sortedPlayers.first.playerName} has a very high target share (${(sortedPlayers.first.nyTgtShare * 100).toStringAsFixed(1)}%)');
    }

    if (sortedPlayers.length > 1 && sortedPlayers.last.nyTgtShare < 0.05) {
      recommendations.add('${sortedPlayers.last.playerName} has a very low target share (${(sortedPlayers.last.nyTgtShare * 100).toStringAsFixed(1)}%)');
    }

    return {
      'summary': summary,
      'recommendations': recommendations,
      'sortedPlayers': sortedPlayers,
    };
  }
}