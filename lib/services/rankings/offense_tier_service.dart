import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OffenseTierService {
  static const String _passOffenseCollection = 'pass_offense_rankings';
  static const String _runOffenseCollection = 'run_offense_rankings';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Safely convert value to double, handling nulls and different number types
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  /// Safely convert value to int, handling nulls and different number types
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

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
          'totalEP': _safeToDouble(data['totalEP']),
          'totalYds': _safeToDouble(data['totalYds']),
          'totalTD': _safeToInt(data['totalTD']),
          'successRate': _safeToDouble(data['successRate']),
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
        final ydsRank = _safeToDouble(offense['yds_rank']);
        final tdRank = _safeToDouble(offense['TD_rank']);
        final successRank = _safeToDouble(offense['success_rank']);
        offense['myRank'] = ydsRank + tdRank + successRank;
      }

      // Sort by composite rank (ascending - lower is better, since rank 1 is best)
      offenseData.sort((a, b) => (_safeToDouble(a['myRank'])).compareTo(_safeToDouble(b['myRank'])));

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
          'totalEP': _safeToDouble(data['totalEP']),
          'totalYds': _safeToDouble(data['totalYds']),
          'totalTD': _safeToInt(data['totalTD']),
          'successRate': _safeToDouble(data['successRate']),
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
        final ydsRank = _safeToDouble(offense['yds_rank']);
        final tdRank = _safeToDouble(offense['TD_rank']);
        final successRank = _safeToDouble(offense['success_rank']);
        offense['myRank'] = ydsRank + tdRank + successRank;
      }

      // Sort by composite rank (ascending - lower is better, since rank 1 is best)
      offenseData.sort((a, b) => (_safeToDouble(a['myRank'])).compareTo(_safeToDouble(b['myRank'])));

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
      String rankField;
      switch (metric) {
        case 'totalEP':
          rankField = 'EP_rank';
          break;
        case 'totalYds':
          rankField = 'yds_rank';
          break;
        case 'totalTD':
          rankField = 'TD_rank';
          break;
        case 'successRate':
          rankField = 'success_rank';
          break;
        default:
          rankField = '${metric.replaceAll('total', '').toLowerCase()}_rank';
      }
      _calculatePercentileRank(data, metric, rankField);
    }
  }

  /// Calculate actual rank numbers for a specific metric (1 = best, higher values = better rank)
  void _calculatePercentileRank(List<Map<String, dynamic>> data, String valueKey, String rankKey) {
    if (data.isEmpty) return;
    
    // Create a list of items with their values for sorting
    final itemsWithValues = data.map((item) => {
      'item': item,
      'value': _safeToDouble(item[valueKey]),
    }).toList();
    
    // Sort by value (descending - higher values get better ranks)
    itemsWithValues.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
    
    // Assign rank numbers (1-based, where 1 = highest value)
    for (int i = 0; i < itemsWithValues.length; i++) {
      final item = itemsWithValues[i]['item'] as Map<String, dynamic>;
      item[rankKey] = i + 1;
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