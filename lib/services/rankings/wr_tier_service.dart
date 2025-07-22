import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class WRTierService {
  static const String _collectionName = 'wrRankings';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate WR tiers based on the R script logic
  Future<List<Map<String, dynamic>>> calculateWRTiers(String season) async {
    try {
      // Get WR data from Firestore (this would be populated from your R script data)
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('season', isEqualTo: int.parse(season))
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final wrData = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'receiver_player_id': data['receiver_player_id'] ?? '',
          'receiver_player_name': data['receiver_player_name'] ?? '',
          'posteam': data['posteam'] ?? '',
          'season': data['season'] ?? season,
          'totalEPA': (data['totalEPA'] ?? 0.0).toDouble(),
          'tgt_share': (data['tgt_share'] ?? 0.0).toDouble(),
          'numYards': (data['numYards'] ?? 0.0).toDouble(),
          'numTD': (data['numTD'] ?? 0).toInt(),
          'numRec': (data['numRec'] ?? 0).toInt(),
          'conversion_rate': (data['conversion_rate'] ?? 0.0).toDouble(),
          'explosive_rate': (data['explosive_rate'] ?? 0.0).toDouble(),
          'avg_separation': (data['avg_separation'] ?? 0.0).toDouble(),
          'avg_intended_air_yards': (data['avg_intended_air_yards'] ?? 0.0).toDouble(),
          'catch_percentage': (data['catch_percentage'] ?? 0.0).toDouble(),
        };
      }).toList();

      // Calculate percentile ranks for each metric (mirroring R script)
      _calculatePercentileRanks(wrData);

      // Calculate composite ranking using weighted formula from R script
      for (var wr in wrData) {
        // myRank = (2*EPA_rank)+tgt_rank+yards_rank+(.5*conversion_rank)+(.5*explosive_rank)+sep_rank+catch_rank
        wr['myRank'] = (2 * wr['EPA_rank']) +
            wr['tgt_rank'] +
            wr['yards_rank'] +
            (0.5 * wr['conversion_rank']) +
            (0.5 * wr['explosive_rank']) +
            wr['sep_rank'] +
            wr['catch_rank'];
      }

      // Sort by composite rank (descending - higher is better)
      wrData.sort((a, b) => b['myRank'].compareTo(a['myRank']));

      // Assign rank numbers and tiers
      for (int i = 0; i < wrData.length; i++) {
        wrData[i]['myRankNum'] = i + 1;
        wrData[i]['wr_tier'] = _calculateTier(i + 1);
      }

      return wrData;
    } catch (e) {
      throw Exception('Failed to calculate WR tiers: $e');
    }
  }

  /// Calculate percentile ranks for all metrics
  void _calculatePercentileRanks(List<Map<String, dynamic>> wrData) {
    if (wrData.isEmpty) return;

    // Calculate percentile rank for each metric
    _calculatePercentileRank(wrData, 'totalEPA', 'EPA_rank');
    _calculatePercentileRank(wrData, 'tgt_share', 'tgt_rank');
    _calculatePercentileRank(wrData, 'numYards', 'yards_rank');
    _calculatePercentileRank(wrData, 'conversion_rate', 'conversion_rank');
    _calculatePercentileRank(wrData, 'explosive_rate', 'explosive_rank');
    _calculatePercentileRank(wrData, 'avg_separation', 'sep_rank');
    _calculatePercentileRank(wrData, 'avg_intended_air_yards', 'intended_air_rank');
    _calculatePercentileRank(wrData, 'catch_percentage', 'catch_rank');
  }

  /// Calculate percentile rank for a specific metric
  void _calculatePercentileRank(List<Map<String, dynamic>> data, String valueKey, String rankKey) {
    // Sort by value (ascending)
    final sortedValues = data.map((item) => item[valueKey] as double).toList()..sort();
    
    // Calculate percentile rank for each item
    for (var item in data) {
      final value = item[valueKey] as double;
      final rank = sortedValues.indexOf(value);
      final percentileRank = rank / (sortedValues.length - 1);
      item[rankKey] = percentileRank;
    }
  }

  /// Calculate tier based on rank number (mirroring R script logic)
  int _calculateTier(int rankNum) {
    if (rankNum <= 4) return 1;
    if (rankNum <= 8) return 2;
    if (rankNum <= 12) return 3;
    if (rankNum <= 16) return 4;
    if (rankNum <= 20) return 5;
    if (rankNum <= 24) return 6;
    if (rankNum <= 28) return 7;
    return 8;
  }

  /// Get WR rankings for a specific season
  Future<List<Map<String, dynamic>>> getWRRankings(String season) async {
    return await calculateWRTiers(season);
  }

  /// Get WR rankings with filters
  Future<List<Map<String, dynamic>>> getWRRankingsWithFilters({
    required String season,
    String? team,
    int? tier,
    int? minRank,
    int? maxRank,
  }) async {
    var rankings = await calculateWRTiers(season);

    // Apply filters
    if (team != null && team != 'All') {
      rankings = rankings.where((wr) => wr['posteam'] == team).toList();
    }

    if (tier != null && tier > 0) {
      rankings = rankings.where((wr) => wr['wr_tier'] == tier).toList();
    }

    if (minRank != null) {
      rankings = rankings.where((wr) => wr['myRankNum'] >= minRank).toList();
    }

    if (maxRank != null) {
      rankings = rankings.where((wr) => wr['myRankNum'] <= maxRank).toList();
    }

    return rankings;
  }

  /// Get tier distribution for a season
  Future<Map<int, int>> getTierDistribution(String season) async {
    final rankings = await calculateWRTiers(season);
    final distribution = <int, int>{};

    for (int tier = 1; tier <= 8; tier++) {
      distribution[tier] = rankings.where((wr) => wr['wr_tier'] == tier).length;
    }

    return distribution;
  }

  /// Get team WR tier summary
  Future<Map<String, Map<String, dynamic>>> getTeamWRSummary(String season) async {
    final rankings = await calculateWRTiers(season);
    final teamSummary = <String, Map<String, dynamic>>{};

    for (var wr in rankings) {
      final team = wr['posteam'] as String;
      if (!teamSummary.containsKey(team)) {
        teamSummary[team] = {
          'count': 0,
          'avg_tier': 0.0,
          'best_tier': 8,
          'total_epa': 0.0,
          'total_yards': 0.0,
          'total_tds': 0,
        };
      }

      teamSummary[team]!['count'] += 1;
      teamSummary[team]!['best_tier'] = min<int>(teamSummary[team]!['best_tier'] as int, wr['wr_tier'] as int);
      teamSummary[team]!['total_epa'] += wr['totalEPA'];
      teamSummary[team]!['total_yards'] += wr['numYards'];
      teamSummary[team]!['total_tds'] += wr['numTD'];
    }

    // Calculate average tier for each team
    for (var team in teamSummary.keys) {
      final teamWRs = rankings.where((wr) => wr['posteam'] == team).toList();
      if (teamWRs.isNotEmpty) {
        final tierSum = teamWRs.map((wr) => wr['wr_tier'] as int).reduce((a, b) => a + b);
        final avgTier = tierSum / teamWRs.length;
        teamSummary[team]!['avg_tier'] = avgTier;
      }
    }

    return teamSummary;
  }
} 