// lib/services/player_trends_service.dart

import 'dart:math';
import 'csv_player_stats_service.dart';


enum TrendDirection { up, down, steady }

class PlayerTrend {
  final String playerId;
  final String playerName;
  final String team;
  final String position;
  final String positionGroup;
  
  // Season stats
  final double seasonAvgPPR;
  final double seasonAvgStandard;
  final int totalGames;
  
  // Recent stats (last 4 games)
  final double recentAvgPPR;
  final double recentAvgStandard;
  final int recentGames;
  
  // Trend calculations
  final double pprTrendChange;
  final double standardTrendChange;
  final TrendDirection pprTrendDirection;
  final TrendDirection standardTrendDirection;
  final double consistency; // Standard deviation of recent games
  
  // Position-specific recent stats
  final Map<String, double> recentPositionStats;
  final Map<String, double> seasonPositionStats;

  PlayerTrend({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.position,
    required this.positionGroup,
    required this.seasonAvgPPR,
    required this.seasonAvgStandard,
    required this.totalGames,
    required this.recentAvgPPR,
    required this.recentAvgStandard,
    required this.recentGames,
    required this.pprTrendChange,
    required this.standardTrendChange,
    required this.pprTrendDirection,
    required this.standardTrendDirection,
    required this.consistency,
    required this.recentPositionStats,
    required this.seasonPositionStats,
  });
}

class PlayerTrendsService {
  static const int recentWeeksThreshold = 4;
  static const double trendThreshold = 1.0; // Points change to be considered trending

  /// Get player trends for a specific position and season
  static Future<List<PlayerTrend>> getPlayerTrends({
    required String season,
    required String position,
    int minGames = 6,
    int minRecentGames = 3,
    int recentGamesCount = 4,
  }) async {
    print('DEBUG: Getting player trends for season=$season, position=$position');

    // Get all weekly stats for the season/position
    final allStats = await CsvPlayerStatsService.getPlayerStats(
      season: season,
      position: position,
      limit: 1000, // Get all players
    );

    print('DEBUG: Got ${allStats.length} stat records');

    // Group by player
    final Map<String, List<Map<String, dynamic>>> playerWeeks = {};
    for (final stat in allStats) {
      final playerId = stat['player_id']?.toString() ?? '';
      if (playerId.isEmpty) continue;
      
      playerWeeks.putIfAbsent(playerId, () => []);
      playerWeeks[playerId]!.add(stat);
    }

    print('DEBUG: Grouped into ${playerWeeks.length} unique players');

    final List<PlayerTrend> trends = [];

    for (final entry in playerWeeks.entries) {
      final playerId = entry.key;
      final weeklyStats = entry.value;

      // Sort by week
      weeklyStats.sort((a, b) {
        final weekA = int.tryParse(a['week']?.toString() ?? '0') ?? 0;
        final weekB = int.tryParse(b['week']?.toString() ?? '0') ?? 0;
        return weekA.compareTo(weekB);
      });

      if (weeklyStats.length < minGames) continue;

      // Get player info from first entry
      final firstStat = weeklyStats.first;
      final playerName = firstStat['player_name']?.toString() ?? 'Unknown';
      final team = firstStat['team']?.toString() ?? 'UNK';
      final pos = firstStat['position']?.toString() ?? 'UNK';
      final posGroup = firstStat['position_group']?.toString() ?? 'UNK';

      // Calculate season averages
      final seasonPPR = weeklyStats
          .map((s) => (s['fantasy_points_ppr'] as num?)?.toDouble() ?? 0.0)
          .toList();
      final seasonStandard = weeklyStats
          .map((s) => (s['fantasy_points'] as num?)?.toDouble() ?? 0.0)
          .toList();

      final seasonAvgPPR = seasonPPR.isNotEmpty 
          ? seasonPPR.reduce((a, b) => a + b) / seasonPPR.length 
          : 0.0;
      final seasonAvgStandard = seasonStandard.isNotEmpty
          ? seasonStandard.reduce((a, b) => a + b) / seasonStandard.length
          : 0.0;

      // Get recent games (last N weeks)
      final recentStats = weeklyStats.length >= recentGamesCount
          ? weeklyStats.sublist(weeklyStats.length - recentGamesCount)
          : weeklyStats.length > 1 
              ? weeklyStats.sublist(weeklyStats.length - (weeklyStats.length - 1))
              : weeklyStats;

      if (recentStats.length < minRecentGames) continue;

      // Calculate recent averages
      final recentPPR = recentStats
          .map((s) => (s['fantasy_points_ppr'] as num?)?.toDouble() ?? 0.0)
          .toList();
      final recentStandard = recentStats
          .map((s) => (s['fantasy_points'] as num?)?.toDouble() ?? 0.0)
          .toList();

      final recentAvgPPR = recentPPR.isNotEmpty
          ? recentPPR.reduce((a, b) => a + b) / recentPPR.length
          : 0.0;
      final recentAvgStandard = recentStandard.isNotEmpty
          ? recentStandard.reduce((a, b) => a + b) / recentStandard.length
          : 0.0;

      // Calculate trend changes
      final pprChange = recentAvgPPR - seasonAvgPPR;
      final standardChange = recentAvgStandard - seasonAvgStandard;

      // Determine trend directions
      final pprDirection = pprChange > trendThreshold
          ? TrendDirection.up
          : pprChange < -trendThreshold
              ? TrendDirection.down
              : TrendDirection.steady;

      final standardDirection = standardChange > trendThreshold
          ? TrendDirection.up
          : standardChange < -trendThreshold
              ? TrendDirection.down
              : TrendDirection.steady;

      // Calculate consistency (lower = more consistent)
      final pprVariance = _calculateVariance(recentPPR, recentAvgPPR);
      final consistency = pprVariance > 0 ? sqrt(pprVariance) : 0.0;

      // Calculate position-specific stats
      final recentPositionStats = _calculatePositionStats(recentStats, pos);
      final seasonPositionStats = _calculatePositionStats(weeklyStats, pos);

      trends.add(PlayerTrend(
        playerId: playerId,
        playerName: playerName,
        team: team,
        position: pos,
        positionGroup: posGroup,
        seasonAvgPPR: seasonAvgPPR,
        seasonAvgStandard: seasonAvgStandard,
        totalGames: weeklyStats.length,
        recentAvgPPR: recentAvgPPR,
        recentAvgStandard: recentAvgStandard,
        recentGames: recentStats.length,
        pprTrendChange: pprChange,
        standardTrendChange: standardChange,
        pprTrendDirection: pprDirection,
        standardTrendDirection: standardDirection,
        consistency: consistency,
        recentPositionStats: recentPositionStats,
        seasonPositionStats: seasonPositionStats,
      ));
    }

    print('DEBUG: Generated ${trends.length} player trends');
    return trends;
  }

  static double _calculateVariance(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  static Map<String, double> _calculatePositionStats(
      List<Map<String, dynamic>> stats, String position) {
    if (stats.isEmpty) return {};

    final Map<String, double> totals = {};
    final int gameCount = stats.length;

    for (final stat in stats) {
      switch (position) {
        case 'QB':
          totals['passing_yards'] = (totals['passing_yards'] ?? 0) + 
              ((stat['passing_yards'] as num?)?.toDouble() ?? 0);
          totals['passing_tds'] = (totals['passing_tds'] ?? 0) + 
              ((stat['passing_tds'] as num?)?.toDouble() ?? 0);
          totals['interceptions'] = (totals['interceptions'] ?? 0) + 
              ((stat['interceptions'] as num?)?.toDouble() ?? 0);
          break;
        case 'RB':
          totals['rushing_yards'] = (totals['rushing_yards'] ?? 0) + 
              ((stat['rushing_yards'] as num?)?.toDouble() ?? 0);
          totals['rushing_tds'] = (totals['rushing_tds'] ?? 0) + 
              ((stat['rushing_tds'] as num?)?.toDouble() ?? 0);
          totals['carries'] = (totals['carries'] ?? 0) + 
              ((stat['carries'] as num?)?.toDouble() ?? 0);
          totals['receptions'] = (totals['receptions'] ?? 0) + 
              ((stat['receptions'] as num?)?.toDouble() ?? 0);
          totals['receiving_yards'] = (totals['receiving_yards'] ?? 0) + 
              ((stat['receiving_yards'] as num?)?.toDouble() ?? 0);
          break;
        case 'WR':
        case 'TE':
          totals['receptions'] = (totals['receptions'] ?? 0) + 
              ((stat['receptions'] as num?)?.toDouble() ?? 0);
          totals['receiving_yards'] = (totals['receiving_yards'] ?? 0) + 
              ((stat['receiving_yards'] as num?)?.toDouble() ?? 0);
          totals['receiving_tds'] = (totals['receiving_tds'] ?? 0) + 
              ((stat['receiving_tds'] as num?)?.toDouble() ?? 0);
          totals['targets'] = (totals['targets'] ?? 0) + 
              ((stat['targets'] as num?)?.toDouble() ?? 0);
          break;
      }
    }

    // Convert totals to averages
    final Map<String, double> averages = {};
    for (final entry in totals.entries) {
      averages[entry.key] = entry.value / gameCount;
    }

    return averages;
  }

  /// Get trending up players (biggest positive trend changes)
  static List<PlayerTrend> getTrendingUp(List<PlayerTrend> trends, {int limit = 10}) {
    final trendingUp = trends.where((t) => t.pprTrendDirection == TrendDirection.up).toList();
    trendingUp.sort((a, b) => b.pprTrendChange.compareTo(a.pprTrendChange));
    return trendingUp.take(limit).toList();
  }

  /// Get trending down players (biggest negative trend changes)
  static List<PlayerTrend> getTrendingDown(List<PlayerTrend> trends, {int limit = 10}) {
    final trendingDown = trends.where((t) => t.pprTrendDirection == TrendDirection.down).toList();
    trendingDown.sort((a, b) => a.pprTrendChange.compareTo(b.pprTrendChange));
    return trendingDown.take(limit).toList();
  }

  /// Get most consistent players (lowest variance)
  static List<PlayerTrend> getMostConsistent(List<PlayerTrend> trends, {int limit = 10}) {
    final consistent = List<PlayerTrend>.from(trends);
    consistent.sort((a, b) => a.consistency.compareTo(b.consistency));
    return consistent.take(limit).toList();
  }
}