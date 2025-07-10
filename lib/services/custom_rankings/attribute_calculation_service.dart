import 'package:mds_home/models/custom_rankings/ranking_attribute.dart';
import 'package:mds_home/models/fantasy/player_ranking.dart';

class AttributeCalculationService {
  
  Future<double> getNormalizedStat(
    PlayerRanking player,
    RankingAttribute attribute,
    String position,
  ) async {
    try {
      // Get the raw stat value from player data
      final rawValue = _getRawStatValue(player, attribute);
      
      if (rawValue == null) {
        return 0.0; // No data available
      }

      // Apply normalization (percentile-based ranking)
      return _normalizeValue(rawValue, attribute, position);
    } catch (e) {
      return 0.0; // Default to 0 if calculation fails
    }
  }

  double? _getRawStatValue(PlayerRanking player, RankingAttribute attribute) {
    // Check in additional ranks first (from CSV data)
    if (player.additionalRanks.containsKey(attribute.name)) {
      final value = player.additionalRanks[attribute.name];
      if (value is num) return value.toDouble();
    }

    // Check in stats
    if (player.stats.containsKey(attribute.name)) {
      final value = player.stats[attribute.name];
      if (value is num) return value.toDouble();
    }

    // Handle special cases and mappings
    return _handleSpecialStatMapping(player, attribute);
  }

  double? _handleSpecialStatMapping(PlayerRanking player, RankingAttribute attribute) {
    switch (attribute.name) {
      case 'previous_season_ppg':
        // This would come from historical data - for now use a placeholder
        return _estimatePreviousSeasonPPG(player);
      
      case 'target_share':
        // This would be calculated from team data - placeholder for now
        return _estimateTargetShare(player);
      
      case 'snap_percentage':
        // This would come from snap count data - placeholder for now
        return _estimateSnapPercentage(player);
      
      case 'completion_percentage':
        // For QBs, this might be in the data differently
        return _findCompletionPercentage(player);
      
      case 'int_rate':
        // Interception rate calculation
        return _calculateIntRate(player);
      
      case 'red_zone_targets':
        // Red zone specific data
        return _estimateRedZoneTargets(player);
      
      case 'air_yards':
        // Advanced metric
        return _estimateAirYards(player);
      
      default:
        return null;
    }
  }

  double _normalizeValue(double rawValue, RankingAttribute attribute, String position) {
    // For now, use a simple min-max normalization
    // In a real implementation, this would use percentiles from the full dataset
    
    final ranges = _getStatRanges(attribute, position);
    final min = ranges['min'] ?? 0.0;
    final max = ranges['max'] ?? 100.0;
    
    if (max == min) return 0.5; // Avoid division by zero
    
    // Normalize to 0-1 range
    double normalized = (rawValue - min) / (max - min);
    
    // Clamp to 0-1 range
    normalized = normalized.clamp(0.0, 1.0);
    
    // For some stats, lower is better (e.g., INT rate)
    if (_isLowerBetter(attribute)) {
      normalized = 1.0 - normalized;
    }
    
    return normalized;
  }

  Map<String, double> _getStatRanges(RankingAttribute attribute, String position) {
    // These would ideally be calculated from actual data
    // For now, using reasonable estimates
    
    switch (attribute.name) {
      case 'passing_yards_per_game':
        return {'min': 150.0, 'max': 320.0};
      case 'passing_tds':
        return {'min': 15.0, 'max': 45.0};
      case 'rushing_yards_per_game':
        if (position == 'QB') {
          return {'min': 0.0, 'max': 60.0};
        } else {
          return {'min': 20.0, 'max': 140.0};
        }
      case 'rushing_tds':
        return {'min': 0.0, 'max': 20.0};
      case 'receptions_per_game':
        return {'min': 2.0, 'max': 12.0};
      case 'receiving_yards_per_game':
        return {'min': 20.0, 'max': 130.0};
      case 'receiving_tds':
        return {'min': 2.0, 'max': 16.0};
      case 'target_share':
        return {'min': 0.1, 'max': 0.35};
      case 'previous_season_ppg':
        return {'min': 8.0, 'max': 25.0};
      case 'completion_percentage':
        return {'min': 0.55, 'max': 0.75};
      case 'int_rate':
        return {'min': 0.01, 'max': 0.04};
      case 'snap_percentage':
        return {'min': 0.3, 'max': 1.0};
      case 'red_zone_targets':
        return {'min': 5.0, 'max': 25.0};
      case 'air_yards':
        return {'min': 800.0, 'max': 1800.0};
      default:
        return {'min': 0.0, 'max': 100.0};
    }
  }

  bool _isLowerBetter(RankingAttribute attribute) {
    // Stats where lower values are better
    return attribute.name == 'int_rate';
  }

  // Placeholder estimation methods
  // In a real implementation, these would use actual historical/advanced data
  
  double _estimatePreviousSeasonPPG(PlayerRanking player) {
    // This would use actual previous season data
    // For now, estimate based on current ranking
    if (player.rank <= 12) return 18.0 + (12 - player.rank) * 0.5;
    if (player.rank <= 24) return 14.0 + (24 - player.rank) * 0.3;
    return 10.0 + (50 - player.rank.clamp(0, 50)) * 0.1;
  }

  double _estimateTargetShare(PlayerRanking player) {
    // Estimate based on position and ranking
    if (player.position == 'WR') {
      if (player.rank <= 12) return 0.25;
      if (player.rank <= 24) return 0.20;
      return 0.15;
    } else if (player.position == 'TE') {
      if (player.rank <= 6) return 0.18;
      if (player.rank <= 12) return 0.14;
      return 0.10;
    } else if (player.position == 'RB') {
      if (player.rank <= 12) return 0.12;
      return 0.08;
    }
    return 0.10;
  }

  double _estimateSnapPercentage(PlayerRanking player) {
    // Estimate based on ranking
    if (player.rank <= 12) return 0.85;
    if (player.rank <= 24) return 0.70;
    return 0.55;
  }

  double? _findCompletionPercentage(PlayerRanking player) {
    // Look for completion percentage in different formats
    final keys = ['completion_percentage', 'comp_pct', 'cmp_pct'];
    for (final key in keys) {
      if (player.additionalRanks.containsKey(key)) {
        final value = player.additionalRanks[key];
        if (value is num) {
          double pct = value.toDouble();
          // Convert to decimal if it's a percentage
          if (pct > 1.0) pct = pct / 100.0;
          return pct;
        }
      }
    }
    
    // Estimate for QBs
    if (player.position == 'QB') {
      if (player.rank <= 12) return 0.67;
      if (player.rank <= 24) return 0.63;
      return 0.60;
    }
    
    return null;
  }

  double? _calculateIntRate(PlayerRanking player) {
    // This would be calculated from actual interception data
    // For now, estimate inversely based on ranking
    if (player.position == 'QB') {
      if (player.rank <= 12) return 0.02;
      if (player.rank <= 24) return 0.025;
      return 0.03;
    }
    return null;
  }

  double _estimateRedZoneTargets(PlayerRanking player) {
    // Estimate based on position and ranking
    if (player.position == 'WR' || player.position == 'TE') {
      if (player.rank <= 12) return 15.0;
      if (player.rank <= 24) return 10.0;
      return 6.0;
    }
    return 3.0;
  }

  double _estimateAirYards(PlayerRanking player) {
    // Estimate based on WR ranking
    if (player.position == 'WR') {
      if (player.rank <= 12) return 1400.0;
      if (player.rank <= 24) return 1100.0;
      return 900.0;
    }
    return 500.0;
  }
}