import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OffenseTierService {
  static const String _passOffenseCollection = 'pass_offense_rankings';
  static const String _runOffenseCollection = 'run_offense_rankings';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate pass offense tiers based on R script logic
  Future<List<Map<String, dynamic>>> calculatePassOffenseTiers(String season) async {
    try {
      final querySnapshot = await _firestore
          .collection(_passOffenseCollection)
          .where('season', isEqualTo: int.parse(season))
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final offenseData = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'posteam': data['posteam'] ?? '',
          'season': data['season'] ?? season,
          'totalEP': (data['totalEP'] ?? 0.0).toDouble(),
          'totalYds': (data['totalYds'] ?? 0.0).toDouble(),
          'totalTD': (data['totalTD'] ?? 0).toInt(),
          'successRate': (data['successRate'] ?? 0.0).toDouble(),
        };
      }).toList();

      // Calculate percentile ranks for each metric (mirroring R script)
      _calculatePercentileRanks(offenseData, [
        'totalEP',
        'totalYds', 
        'totalTD',
        'successRate'
      ]);

      // Calculate composite ranking using formula from R script
      // myRank = yds_rank+TD_rank+success_rank (EP_rank not used in final calculation)
      for (var offense in offenseData) {
        offense['myRank'] = offense['yds_rank'] + 
                           offense['TD_rank'] + 
                           offense['success_rank'];
      }

      // Sort by composite rank (descending - higher is better)
      offenseData.sort((a, b) => b['myRank'].compareTo(a['myRank']));

      // Assign rank numbers and tiers
      for (int i = 0; i < offenseData.length; i++) {
        offenseData[i]['myRankNum'] = i + 1;
        offenseData[i]['passOffenseTier'] = _calculateOffenseTier(i + 1);
      }

      return offenseData;
    } catch (e) {
      throw Exception('Failed to calculate pass offense tiers: $e');
    }
  }

  /// Calculate run offense tiers based on R script logic
  Future<List<Map<String, dynamic>>> calculateRunOffenseTiers(String season) async {
    try {
      final querySnapshot = await _firestore
          .collection(_runOffenseCollection)
          .where('season', isEqualTo: int.parse(season))
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final offenseData = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'posteam': data['posteam'] ?? '',
          'season': data['season'] ?? season,
          'totalEP': (data['totalEP'] ?? 0.0).toDouble(),
          'totalYds': (data['totalYds'] ?? 0.0).toDouble(),
          'totalTD': (data['totalTD'] ?? 0).toInt(),
          'successRate': (data['successRate'] ?? 0.0).toDouble(),
        };
      }).toList();

      // Calculate percentile ranks for each metric (mirroring R script)
      _calculatePercentileRanks(offenseData, [
        'totalEP',
        'totalYds', 
        'totalTD',
        'successRate'
      ]);

      // Calculate composite ranking using formula from R script
      // myRank = yds_rank+TD_rank+success_rank (EP_rank not used in final calculation)
      for (var offense in offenseData) {
        offense['myRank'] = offense['yds_rank'] + 
                           offense['TD_rank'] + 
                           offense['success_rank'];
      }

      // Sort by composite rank (descending - higher is better)
      offenseData.sort((a, b) => b['myRank'].compareTo(a['myRank']));

      // Assign rank numbers and tiers
      for (int i = 0; i < offenseData.length; i++) {
        offenseData[i]['myRankNum'] = i + 1;
        offenseData[i]['runOffenseTier'] = _calculateOffenseTier(i + 1);
      }

      return offenseData;
    } catch (e) {
      throw Exception('Failed to calculate run offense tiers: $e');
    }
  }

  /// Calculate percentile ranks for all metrics
  void _calculatePercentileRanks(List<Map<String, dynamic>> data, List<String> metrics) {
    if (data.isEmpty) return;

    for (String metric in metrics) {
      _calculatePercentileRank(data, metric, '${metric.replaceAll('total', '').toLowerCase()}_rank');
    }
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

  /// Calculate offense tier based on rank number (mirroring R script logic)
  /// Uses 32 teams (1-4, 5-8, 9-12, 13-16, 17-20, 21-24, 25-28, 29-32)
  int _calculateOffenseTier(int rankNum) {
    if (rankNum <= 4) return 1;
    if (rankNum <= 8) return 2;
    if (rankNum <= 12) return 3;
    if (rankNum <= 16) return 4;
    if (rankNum <= 20) return 5;
    if (rankNum <= 24) return 6;
    if (rankNum <= 28) return 7;
    return 8;
  }

  /// Get pass offense rankings for a specific season
  Future<List<Map<String, dynamic>>> getPassOffenseRankings(String season) async {
    return await calculatePassOffenseTiers(season);
  }

  /// Get run offense rankings for a specific season
  Future<List<Map<String, dynamic>>> getRunOffenseRankings(String season) async {
    return await calculateRunOffenseTiers(season);
  }

  /// Get combined offense rankings (both pass and run)
  Future<Map<String, Map<String, dynamic>>> getCombinedOffenseRankings(String season) async {
    final passRankings = await calculatePassOffenseTiers(season);
    final runRankings = await calculateRunOffenseTiers(season);
    
    final combined = <String, Map<String, dynamic>>{};
    
    // Add pass offense data
    for (var passOffense in passRankings) {
      final team = passOffense['posteam'] as String;
      combined[team] = {
        'team': team,
        'season': season,
        'passOffenseTier': passOffense['passOffenseTier'],
        'passOffenseRank': passOffense['myRankNum'],
        'passYards': passOffense['totalYds'],
        'passTDs': passOffense['totalTD'],
        'passSuccessRate': passOffense['successRate'],
      };
    }
    
    // Add run offense data
    for (var runOffense in runRankings) {
      final team = runOffense['posteam'] as String;
      if (combined.containsKey(team)) {
        combined[team]!['runOffenseTier'] = runOffense['runOffenseTier'];
        combined[team]!['runOffenseRank'] = runOffense['myRankNum'];
        combined[team]!['runYards'] = runOffense['totalYds'];
        combined[team]!['runTDs'] = runOffense['totalTD'];
        combined[team]!['runSuccessRate'] = runOffense['successRate'];
      }
    }
    
    return combined;
  }

  /// Get offense tier distribution for a season
  Future<Map<String, Map<int, int>>> getOffenseTierDistribution(String season) async {
    final passRankings = await calculatePassOffenseTiers(season);
    final runRankings = await calculateRunOffenseTiers(season);
    
    final passDistribution = <int, int>{};
    final runDistribution = <int, int>{};
    
    for (int tier = 1; tier <= 8; tier++) {
      passDistribution[tier] = passRankings.where((offense) => offense['passOffenseTier'] == tier).length;
      runDistribution[tier] = runRankings.where((offense) => offense['runOffenseTier'] == tier).length;
    }
    
    return {
      'pass': passDistribution,
      'run': runDistribution,
    };
  }

  /// Get team offense summary
  Future<Map<String, Map<String, dynamic>>> getTeamOffenseSummary(String season) async {
    final combined = await getCombinedOffenseRankings(season);
    
    final summary = <String, Map<String, dynamic>>{};
    
    for (var entry in combined.entries) {
      final team = entry.key;
      final data = entry.value;
      
      summary[team] = {
        'team': team,
        'overallOffenseTier': ((data['passOffenseTier'] ?? 8) + (data['runOffenseTier'] ?? 8)) / 2,
        'passOffenseTier': data['passOffenseTier'] ?? 8,
        'runOffenseTier': data['runOffenseTier'] ?? 8,
        'passOffenseRank': data['passOffenseRank'] ?? 32,
        'runOffenseRank': data['runOffenseRank'] ?? 32,
        'totalYards': (data['passYards'] ?? 0.0) + (data['runYards'] ?? 0.0),
        'totalTDs': (data['passTDs'] ?? 0) + (data['runTDs'] ?? 0),
        'avgSuccessRate': ((data['passSuccessRate'] ?? 0.0) + (data['runSuccessRate'] ?? 0.0)) / 2,
      };
    }
    
    return summary;
  }
} 