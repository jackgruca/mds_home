import '../../models/custom_weight_config.dart';

/// Service for calculating custom rankings based on user-defined weights
class RankingCalculationService {
  
  /// Calculate custom rankings for any position
  static List<Map<String, dynamic>> calculateCustomRankings(
    List<Map<String, dynamic>> players,
    CustomWeightConfig weightConfig,
  ) {
    if (players.isEmpty) {
      return players;
    }

    // Create a copy of players to avoid modifying original data
    final List<Map<String, dynamic>> playersWithCustomRanks = 
        players.map((player) => Map<String, dynamic>.from(player)).toList();

    // Calculate percentile ranks for each stat first
    final Map<String, List<double>> statValues = _extractStatValues(playersWithCustomRanks, weightConfig.position);
    final Map<String, Map<String, double>> percentileRanks = _calculatePercentileRanks(statValues, weightConfig.position);

    // Calculate custom myRank for each player
    for (final player in playersWithCustomRanks) {
      final customRank = _calculatePlayerCustomRank(player, weightConfig, percentileRanks);
      player['myRankNum'] = customRank;
    }

    // Sort by custom rank and assign new rank numbers and tiers
    playersWithCustomRanks.sort((a, b) => (a['myRankNum'] as double).compareTo(b['myRankNum'] as double));
    
    for (int i = 0; i < playersWithCustomRanks.length; i++) {
      playersWithCustomRanks[i]['myRankNum'] = i + 1;
      playersWithCustomRanks[i]['tier'] = _assignTier(i + 1);
    }

    return playersWithCustomRanks;
  }

  /// Calculate custom rankings for RB position (backward compatibility)
  static List<Map<String, dynamic>> calculateCustomRBRankings(
    List<Map<String, dynamic>> players,
    CustomWeightConfig weightConfig,
  ) {
    return calculateCustomRankings(players, weightConfig);
  }

  /// Calculate custom rankings for QB position
  static List<Map<String, dynamic>> calculateCustomQBRankings(
    List<Map<String, dynamic>> players,
    CustomWeightConfig weightConfig,
  ) {
    return calculateCustomRankings(players, weightConfig);
  }

  /// Calculate custom rankings for WR position
  static List<Map<String, dynamic>> calculateCustomWRRankings(
    List<Map<String, dynamic>> players,
    CustomWeightConfig weightConfig,
  ) {
    return calculateCustomRankings(players, weightConfig);
  }

  /// Calculate custom rankings for TE position
  static List<Map<String, dynamic>> calculateCustomTERankings(
    List<Map<String, dynamic>> players,
    CustomWeightConfig weightConfig,
  ) {
    return calculateCustomRankings(players, weightConfig);
  }

  /// Extract stat values for all players for each relevant stat
  static Map<String, List<double>> _extractStatValues(List<Map<String, dynamic>> players, String position) {
    final Map<String, List<double>> statValues = {};
    
    // Get stat field mappings for the position
    final Map<String, String> statFieldMappings = getStatFieldMappings(position);

    // Extract values for each stat
    for (final entry in statFieldMappings.entries) {
      final statName = entry.key;
      final fieldName = entry.value;
      final values = <double>[];
      
      for (final player in players) {
        final value = player[fieldName];
        double numValue = 0.0;
        
        if (value is num) {
          numValue = value.toDouble();
        } else if (value is String) {
          numValue = double.tryParse(value) ?? 0.0;
        }
        
        if (numValue.isFinite) {
          values.add(numValue);
        } else {
          values.add(0.0);
        }
      }
      
      statValues[statName] = values;
    }
    
    return statValues;
  }

  /// Calculate percentile ranks for each stat (1.0 = best, 0.0 = worst)
  static Map<String, Map<String, double>> _calculatePercentileRanks(Map<String, List<double>> statValues, String position) {
    final Map<String, Map<String, double>> percentileRanks = {};
    
    // Define "bad" stats where lower is better (currently just INT for QB)
    const badStats = {'INT', 'interceptions'};
    
    for (final entry in statValues.entries) {
      final statName = entry.key;
      final values = List<double>.from(entry.value);
      values.sort();
      
      final Map<String, double> valueToPercentile = {};
      
      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        double percentile = (i + 1) / values.length;
        
        // For "bad" stats (like INTs), we want lower values to have higher percentiles
        if (badStats.contains(statName)) {
          percentile = 1.0 - percentile;
        }
        
        valueToPercentile[value.toString()] = percentile;
      }
      
      percentileRanks[statName] = valueToPercentile;
    }
    
    return percentileRanks;
  }

  /// Calculate custom rank for a single player
  static double _calculatePlayerCustomRank(
    Map<String, dynamic> player,
    CustomWeightConfig weightConfig,
    Map<String, Map<String, double>> percentileRanks,
  ) {
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    // Get stat field mappings for the position
    final Map<String, String> statFieldMappings = getStatFieldMappings(weightConfig.position);

    for (final entry in weightConfig.weights.entries) {
      final statName = entry.key;
      final weight = entry.value;
      final fieldName = statFieldMappings[statName];
      
      if (fieldName == null || weight <= 0) continue;
      
      final value = player[fieldName];
      double numValue = 0.0;
      
      if (value is num) {
        numValue = value.toDouble();
      } else if (value is String) {
        numValue = double.tryParse(value) ?? 0.0;
      }
      
      if (!numValue.isFinite) numValue = 0.0;
      
      // Get percentile rank for this stat value
      final statPercentiles = percentileRanks[statName];
      if (statPercentiles != null) {
        final percentile = statPercentiles[numValue.toString()] ?? 0.0;
        
        // Convert percentile to rank (1.0 percentile = rank 1.0, 0.0 percentile = rank 100.0)
        // We want lower rank numbers for better players
        final rank = (1.0 - percentile) * 100.0;
        
        weightedSum += weight * rank;
        totalWeight += weight;
      }
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 100.0;
  }

  /// Assign tier based on rank number (8-tier system)
  static int _assignTier(int rankNum) {
    if (rankNum <= 4) return 1;
    if (rankNum <= 8) return 2;
    if (rankNum <= 12) return 3;
    if (rankNum <= 16) return 4;
    if (rankNum <= 20) return 5;
    if (rankNum <= 24) return 6;
    if (rankNum <= 28) return 7;
    return 8;
  }

  /// Get default weight configuration for a position
  static CustomWeightConfig getDefaultWeights(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return CustomWeightConfig.createDefaultQBWeights();
      case 'rb':
        return CustomWeightConfig.createDefaultRBWeights();
      case 'wr':
        return CustomWeightConfig.createDefaultWRWeights();
      case 'te':
        return CustomWeightConfig.createDefaultTEWeights();
      default:
        throw ArgumentError('Position $position not supported yet');
    }
  }

  /// Get stat field mappings for a position
  static Map<String, String> getStatFieldMappings(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return {
          'EPA': 'totalEPA',
          'EP': 'ep_per_game',
          'CPOE': 'cpoe',
          'YPG': 'YPG',
          'TD': 'totalTD',
          'Actualization': 'actualization',
          'INT': 'interceptions',
          'Third Down': 'third_down_pct',
        };
      case 'rb':
        return {
          'EPA': 'totalEPA',
          'TD': 'totalTD',
          'Rush Share': 'run_share',
          'YPG': 'YPG',
          'Target Share': 'tgt_share',
          'Third Down': 'third_down_rate',
          'RZ': 'conversion',
          'Explosive': 'explosive_rate',
          'RYOE': 'avg_RYOE_perAtt',
          'Efficiency': 'avg_eff',
        };
      case 'wr':
        return {
          'EPA': 'totalEPA',
          'TD': 'totalTD',
          'Target Share': 'tgt_share',
          'YPG': 'YPG',
          'RZ': 'conversion',
          'Explosive': 'explosive_rate',
          'Separation': 'avg_cushion',
          'Air Yards': 'air_yards_share',
          'Catch%': 'catch_percentage',
          'Third Down': 'third_down_rate',
          'YAC+': 'yac_above_expected',
        };
      case 'te':
        return {
          'EPA': 'totalEPA',
          'TD': 'totalTD',
          'Target Share': 'tgt_share',
          'YPG': 'YPG',
          'RZ': 'conversion',
          'Explosive': 'explosive_rate',
          'Separation': 'avg_cushion',
          'Air Yards': 'air_yards_share',
          'Catch%': 'catch_percentage',
          'Third Down': 'third_down_rate',
          'YAC+': 'yac_above_expected',
        };
      default:
        return {};
    }
  }

  /// Get descriptions for weight variables
  static Map<String, String> getWeightDescriptions(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return {
          'EPA': 'Expected Points Added - overall impact on team scoring',
          'EP': 'Expected Points per game',
          'CPOE': 'Completion percentage over expected',
          'YPG': 'Passing yards per game',
          'TD': 'Total passing touchdowns',
          'Actualization': 'QB actualization rate',
          'INT': 'Interceptions thrown (lower is better)',
          'Third Down': 'Third down conversion percentage',
        };
      case 'rb':
        return {
          'EPA': 'Expected Points Added - overall impact on team scoring',
          'TD': 'Total touchdowns - rushing and receiving combined',
          'Rush Share': 'Percentage of team rush attempts',
          'YPG': 'Rushing yards per game',
          'Target Share': 'Percentage of team passing targets',
          'Third Down': 'Third down conversion rate',
          'RZ': 'Red zone touchdown conversion rate',
          'Explosive': 'Rate of explosive plays (15+ yards)',
          'RYOE': 'Rush yards over expected per attempt',
          'Efficiency': 'Overall efficiency rating',
        };
      case 'wr':
        return {
          'EPA': 'Expected Points Added - overall impact on team scoring',
          'TD': 'Total receiving touchdowns',
          'Target Share': 'Percentage of team passing targets',
          'YPG': 'Receiving yards per game',
          'RZ': 'Red zone touchdown conversion rate',
          'Explosive': 'Rate of explosive plays (20+ yards)',
          'Separation': 'Average separation from coverage',
          'Air Yards': 'Share of team air yards',
          'Catch%': 'Catch percentage on targets',
          'Third Down': 'Third down conversion rate',
          'YAC+': 'Yards after catch above expected',
        };
      case 'te':
        return {
          'EPA': 'Expected Points Added - overall impact on team scoring',
          'TD': 'Total receiving touchdowns',
          'Target Share': 'Percentage of team passing targets',
          'YPG': 'Receiving yards per game',
          'RZ': 'Red zone touchdown conversion rate',
          'Explosive': 'Rate of explosive plays (15+ yards)',
          'Separation': 'Average separation from coverage',
          'Air Yards': 'Share of team air yards',
          'Catch%': 'Catch percentage on targets',
          'Third Down': 'Third down conversion rate',
          'YAC+': 'Yards after catch above expected',
        };
      default:
        return {};
    }
  }

  /// Validate weight configuration
  static bool isValidWeightConfig(CustomWeightConfig config) {
    if (config.weights.isEmpty) return false;
    
    // Check that all weights are non-negative
    for (final weight in config.weights.values) {
      if (weight < 0.0 || !weight.isFinite) return false;
    }
    
    // Check that total weight is reasonable (between 0.5 and 1.5)
    final total = config.totalWeight;
    return total >= 0.5 && total <= 1.5;
  }
}