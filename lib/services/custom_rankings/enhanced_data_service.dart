import 'dart:math';
import 'package:mds_home/models/fantasy/player_ranking.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/services/fantasy/csv_rankings_service.dart';

class EnhancedDataService {
  final CSVRankingsService _csvService = CSVRankingsService();
  
  // Cache for player data and statistics
  Map<String, List<PlayerRanking>>? _cachedPlayersByPosition;
  Map<String, Map<String, double>>? _cachedStatistics;

  Future<List<PlayerRanking>> getPlayersForPosition(String position) async {
    await _ensureDataLoaded();
    return _cachedPlayersByPosition?[position] ?? [];
  }

  Future<double?> getPlayerStatValue(
    PlayerRanking player,
    EnhancedRankingAttribute attribute,
  ) async {
    // Handle real CSV data
    if (attribute.csvMappings.isNotEmpty) {
      return _extractCsvValue(player, attribute);
    }

    // Handle estimated data
    if (attribute.calculationType == 'estimated') {
      return _calculateEstimatedValue(player, attribute);
    }

    return null;
  }

  Future<double> getNormalizedStatValue(
    PlayerRanking player,
    EnhancedRankingAttribute attribute,
    String position,
  ) async {
    final rawValue = await getPlayerStatValue(player, attribute);
    if (rawValue == null) return 0.0;

    await _ensureStatisticsCalculated();
    
    final statKey = '${position}_${attribute.id}';
    final stats = _cachedStatistics?[statKey];
    
    if (stats == null) return 0.5; // Default middle value

    final min = stats['min'] ?? 0.0;
    final max = stats['max'] ?? 100.0;
    final mean = stats['mean'] ?? 50.0;
    final stdDev = stats['stdDev'] ?? 25.0;

    // Use different normalization based on calculation type
    switch (attribute.calculationType) {
      case 'inverse_rank':
        // For rankings, lower is better
        return _normalizeInverseRank(rawValue, min, max);
      case 'percentile':
        return _normalizePercentile(rawValue, stats);
      case 'z_score':
        return _normalizeZScore(rawValue, mean, stdDev);
      default:
        return _normalizeMinMax(rawValue, min, max);
    }
  }

  Future<Map<String, double>> getPositionStatistics(
    String position,
    String attributeId,
  ) async {
    await _ensureStatisticsCalculated();
    
    final statKey = '${position}_$attributeId';
    return _cachedStatistics?[statKey] ?? {};
  }

  Future<void> _ensureDataLoaded() async {
    if (_cachedPlayersByPosition != null) return;

    final allPlayers = await _csvService.fetchRankings();
    _cachedPlayersByPosition = {};

    for (final player in allPlayers) {
      final position = player.position;
      if (!_cachedPlayersByPosition!.containsKey(position)) {
        _cachedPlayersByPosition![position] = [];
      }
      _cachedPlayersByPosition![position]!.add(player);
    }
  }

  Future<void> _ensureStatisticsCalculated() async {
    if (_cachedStatistics != null) return;

    await _ensureDataLoaded();
    _cachedStatistics = {};

    for (final position in _cachedPlayersByPosition!.keys) {
      final players = _cachedPlayersByPosition![position]!;
      final attributes = EnhancedAttributeLibrary.getAttributesForPosition(position);

      for (final attribute in attributes) {
        final values = <double>[];
        
        for (final player in players) {
          final value = await getPlayerStatValue(player, attribute);
          if (value != null) values.add(value);
        }

        if (values.isNotEmpty) {
          final statKey = '${position}_${attribute.id}';
          _cachedStatistics![statKey] = _calculateStatistics(values);
        }
      }
    }
  }

  double? _extractCsvValue(PlayerRanking player, EnhancedRankingAttribute attribute) {
    for (final mapping in attribute.csvMappings) {
      // Check additional ranks first (main CSV data)
      if (player.additionalRanks.containsKey(mapping)) {
        final value = player.additionalRanks[mapping];
        if (value is num) {
          return _cleanNumericValue(value.toDouble(), mapping);
        }
      }

      // Check stats
      if (player.stats.containsKey(mapping)) {
        final value = player.stats[mapping];
        if (value is num) {
          return _cleanNumericValue(value.toDouble(), mapping);
        }
      }
    }
    return null;
  }

  double _cleanNumericValue(double value, String fieldName) {
    // Handle special cases for different field types
    switch (fieldName.toLowerCase()) {
      case 'auction value':
        // Remove dollar signs and clean auction values
        return value.abs();
      case 'adp':
        // ADP should be positive
        return value > 0 ? value : 999; // High value for missing ADP
      case 'projected points':
        // Points should be positive
        return value.abs();
      default:
        return value;
    }
  }

  double _calculateEstimatedValue(PlayerRanking player, EnhancedRankingAttribute attribute) {
    // Estimate based on consensus rank and projected points
    final rank = player.rank.toDouble();
    final projectedPoints = player.additionalRanks['Projected Points'] as num? ?? 0;
    
    switch (attribute.id) {
      case 'passing_yards_per_game':
        return _estimatePassingYards(rank, projectedPoints.toDouble());
      case 'passing_tds':
        return _estimatePassingTDs(rank, projectedPoints.toDouble());
      case 'rushing_yards_per_game':
        return _estimateRushingYards(rank, projectedPoints.toDouble(), player.position);
      case 'receptions_per_game':
        return _estimateReceptions(rank, projectedPoints.toDouble(), player.position);
      case 'receiving_yards_per_game':
        return _estimateReceivingYards(rank, projectedPoints.toDouble(), player.position);
      case 'target_share':
        return _estimateTargetShare(rank, projectedPoints.toDouble(), player.position);
      case 'completion_percentage':
        return _estimateCompletionPct(rank);
      case 'red_zone_targets':
        return _estimateRedZoneTargets(rank, player.position);
      default:
        return 0.0;
    }
  }

  // Estimation methods based on positional rankings and projected points
  double _estimatePassingYards(double rank, double projectedPoints) {
    // QB passing yards estimation
    if (rank <= 12) return 280 - (rank * 8); // Top QBs: 280-184 yards/game
    if (rank <= 24) return 180 - ((rank - 12) * 5); // Mid QBs: 180-120 yards/game
    return max(100, 120 - ((rank - 24) * 2)); // Low QBs: 120-100 yards/game
  }

  double _estimatePassingTDs(double rank, double projectedPoints) {
    if (rank <= 12) return 32 - (rank * 1.5); // Top QBs: 32-14 TDs
    if (rank <= 24) return 20 - ((rank - 12) * 0.8); // Mid QBs: 20-10 TDs
    return max(8, 15 - ((rank - 24) * 0.5)); // Low QBs: 15-8 TDs
  }

  double _estimateRushingYards(double rank, double projectedPoints, String position) {
    if (position == 'QB') {
      if (rank <= 6) return 40 - (rank * 4); // Mobile QBs: 40-16 yards/game
      return max(5, 15 - (rank * 0.5)); // Pocket QBs: 15-5 yards/game
    } else if (position == 'RB') {
      if (rank <= 12) return 90 - (rank * 3); // Elite RBs: 90-54 yards/game
      if (rank <= 24) return 60 - ((rank - 12) * 2); // Good RBs: 60-36 yards/game
      return max(20, 40 - ((rank - 24) * 1)); // Backup RBs: 40-20 yards/game
    }
    return 0.0;
  }

  double _estimateReceptions(double rank, double projectedPoints, String position) {
    if (position == 'WR') {
      if (rank <= 12) return 7.5 - (rank * 0.3); // Elite WRs: 7.5-4.9 rec/game
      if (rank <= 36) return 5.5 - ((rank - 12) * 0.15); // Good WRs: 5.5-1.9 rec/game
      return max(2, 4 - ((rank - 36) * 0.1)); // Flex WRs: 4-2 rec/game
    } else if (position == 'TE') {
      if (rank <= 6) return 5.5 - (rank * 0.4); // Elite TEs: 5.5-3.1 rec/game
      if (rank <= 12) return 4 - ((rank - 6) * 0.3); // Good TEs: 4-2.2 rec/game
      return max(1.5, 3 - ((rank - 12) * 0.15)); // Streaming TEs: 3-1.5 rec/game
    } else if (position == 'RB') {
      if (rank <= 12) return 4 - (rank * 0.2); // Pass-catching RBs: 4-1.6 rec/game
      return max(1, 2.5 - ((rank - 12) * 0.1)); // Other RBs: 2.5-1 rec/game
    }
    return 0.0;
  }

  double _estimateReceivingYards(double rank, double projectedPoints, String position) {
    if (position == 'WR') {
      if (rank <= 12) return 80 - (rank * 3); // Elite WRs: 80-44 yards/game
      if (rank <= 36) return 50 - ((rank - 12) * 1.5); // Good WRs: 50-14 yards/game
      return max(15, 35 - ((rank - 36) * 1)); // Flex WRs: 35-15 yards/game
    } else if (position == 'TE') {
      if (rank <= 6) return 65 - (rank * 4); // Elite TEs: 65-41 yards/game
      if (rank <= 12) return 45 - ((rank - 6) * 3); // Good TEs: 45-27 yards/game
      return max(20, 35 - ((rank - 12) * 2)); // Streaming TEs: 35-20 yards/game
    } else if (position == 'RB') {
      if (rank <= 12) return 30 - (rank * 1.5); // Pass-catching RBs: 30-12 yards/game
      return max(5, 20 - ((rank - 12) * 1)); // Other RBs: 20-5 yards/game
    }
    return 0.0;
  }

  double _estimateTargetShare(double rank, double projectedPoints, String position) {
    if (position == 'WR') {
      if (rank <= 12) return 0.25 - (rank * 0.01); // Elite WRs: 25-13% target share
      if (rank <= 36) return 0.18 - ((rank - 12) * 0.005); // Good WRs: 18-6% target share
      return max(0.08, 0.15 - ((rank - 36) * 0.003)); // Flex WRs: 15-8% target share
    } else if (position == 'TE') {
      if (rank <= 6) return 0.18 - (rank * 0.015); // Elite TEs: 18-9% target share
      if (rank <= 12) return 0.12 - ((rank - 6) * 0.01); // Good TEs: 12-6% target share
      return max(0.05, 0.1 - ((rank - 12) * 0.005)); // Streaming TEs: 10-5% target share
    } else if (position == 'RB') {
      if (rank <= 12) return 0.12 - (rank * 0.006); // Pass-catching RBs: 12-5% target share
      return max(0.03, 0.08 - ((rank - 12) * 0.003)); // Other RBs: 8-3% target share
    }
    return 0.0;
  }

  double _estimateCompletionPct(double rank) {
    if (rank <= 12) return 0.68 - (rank * 0.005); // Elite QBs: 68-62%
    if (rank <= 24) return 0.64 - ((rank - 12) * 0.003); // Good QBs: 64-60%
    return max(0.58, 0.62 - ((rank - 24) * 0.002)); // Backup QBs: 62-58%
  }

  double _estimateRedZoneTargets(double rank, String position) {
    if (position == 'WR') {
      if (rank <= 12) return 18 - (rank * 0.8); // Elite WRs: 18-8 RZ targets
      if (rank <= 36) return 12 - ((rank - 12) * 0.3); // Good WRs: 12-5 RZ targets
      return max(2, 8 - ((rank - 36) * 0.2)); // Flex WRs: 8-2 RZ targets
    } else if (position == 'TE') {
      if (rank <= 6) return 15 - (rank * 1.2); // Elite TEs: 15-8 RZ targets
      if (rank <= 12) return 10 - ((rank - 6) * 0.8); // Good TEs: 10-5 RZ targets
      return max(2, 7 - ((rank - 12) * 0.5)); // Streaming TEs: 7-2 RZ targets
    }
    return 0.0;
  }

  Map<String, double> _calculateStatistics(List<double> values) {
    if (values.isEmpty) return {};

    values.sort();
    final length = values.length;
    final sum = values.reduce((a, b) => a + b);
    final mean = sum / length;
    
    final variance = values
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b) / length;
    final stdDev = sqrt(variance);

    return {
      'min': values.first,
      'max': values.last,
      'mean': mean,
      'median': length.isOdd 
          ? values[length ~/ 2]
          : (values[length ~/ 2 - 1] + values[length ~/ 2]) / 2,
      'stdDev': stdDev,
      'q1': values[length ~/ 4],
      'q3': values[(3 * length) ~/ 4],
    };
  }

  double _normalizeMinMax(double value, double min, double max) {
    if (max == min) return 0.5;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  double _normalizeInverseRank(double value, double min, double max) {
    if (max == min) return 0.5;
    // For rankings, invert so that rank 1 = 1.0, higher ranks = lower scores
    return ((max - value) / (max - min)).clamp(0.0, 1.0);
  }

  double _normalizePercentile(double value, Map<String, double> stats) {
    final q1 = stats['q1'] ?? 0.0;
    final median = stats['median'] ?? 0.0;
    final q3 = stats['q3'] ?? 0.0;
    final max = stats['max'] ?? 0.0;

    if (value <= q1) return 0.25;
    if (value <= median) return 0.25 + 0.25 * ((value - q1) / (median - q1));
    if (value <= q3) return 0.5 + 0.25 * ((value - median) / (q3 - median));
    return 0.75 + 0.25 * ((value - q3) / (max - q3));
  }

  double _normalizeZScore(double value, double mean, double stdDev) {
    if (stdDev == 0) return 0.5;
    final zScore = (value - mean) / stdDev;
    // Convert z-score to 0-1 range (roughly -3 to +3 maps to 0 to 1)
    return ((zScore + 3) / 6).clamp(0.0, 1.0);
  }

  void clearCache() {
    _cachedPlayersByPosition = null;
    _cachedStatistics = null;
  }
}