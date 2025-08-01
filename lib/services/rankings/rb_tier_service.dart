import 'package:cloud_firestore/cloud_firestore.dart';

class RBTierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate RB ranking following R script methodology
  /// Formula: myRank = (2*EPA_rank) + rush_share_rank + yards_rank + (0.5*conversion_rank) + (0.5*explosive_rank) + target_share_rank + reception_rank
  double calculateRBRank({
    required double totalEPA,
    required double rushShare,
    required double numYards,
    required double conversionRate,
    required double explosiveRate,
    required double targetShare,
    required double numRec,
    required List<Map<String, dynamic>> allRBs,
  }) {
    // Calculate percentile ranks for each metric
    final epaRank = _calculatePercentileRank(totalEPA, allRBs.map((rb) => rb['totalEPA'] as double).toList());
    final rushShareRank = _calculatePercentileRank(rushShare, allRBs.map((rb) => rb['rush_share'] as double).toList());
    final yardsRank = _calculatePercentileRank(numYards, allRBs.map((rb) => rb['numYards'] as double).toList());
    final conversionRank = _calculatePercentileRank(conversionRate, allRBs.map((rb) => rb['conversion_rate'] as double).toList());
    final explosiveRank = _calculatePercentileRank(explosiveRate, allRBs.map((rb) => rb['explosive_rate'] as double).toList());
    final targetShareRank = _calculatePercentileRank(targetShare, allRBs.map((rb) => rb['tgt_share'] as double).toList());
    final receptionRank = _calculatePercentileRank(numRec, allRBs.map((rb) => rb['numRec'] as double).toList());

    // Apply formula weights
    return (2 * epaRank) + rushShareRank + yardsRank + (0.5 * conversionRank) + (0.5 * explosiveRank) + targetShareRank + receptionRank;
  }

  /// Calculate percentile rank (0-100 scale)
  double _calculatePercentileRank(double value, List<double> allValues) {
    final sortedValues = allValues.where((v) => v.isFinite).toList()..sort();
    if (sortedValues.isEmpty) return 50.0;
    
    final position = sortedValues.where((v) => v < value).length;
    return (position / sortedValues.length) * 100;
  }

  /// Assign tier based on rank number - RB uses 8 players per tier
  int calculateTier(int rankNum) {
    if (rankNum <= 8) return 1;
    if (rankNum <= 16) return 2;
    if (rankNum <= 24) return 3;
    if (rankNum <= 32) return 4;
    if (rankNum <= 40) return 5;
    if (rankNum <= 48) return 6;
    if (rankNum <= 56) return 7;
    return 8; // All remaining players
  }

  /// Process RB data and calculate rankings
  Future<List<Map<String, dynamic>>> processRBRankings(List<Map<String, dynamic>> rawData) async {
    // Add calculated fields to each RB
    final processedData = rawData.map((rb) {
      final Map<String, dynamic> processed = Map.from(rb);
      
      // Ensure required fields have default values
      processed['totalEPA'] = processed['totalEPA'] ?? 0.0;
      processed['rush_share'] = processed['rush_share'] ?? 0.0;
      processed['numYards'] = processed['numYards'] ?? 0.0;
      processed['conversion_rate'] = processed['conversion_rate'] ?? 0.0;
      processed['explosive_rate'] = processed['explosive_rate'] ?? 0.0;
      processed['tgt_share'] = processed['tgt_share'] ?? 0.0;
      processed['numRec'] = processed['numRec'] ?? 0.0;
      processed['numTD'] = processed['numTD'] ?? 0;
      
      return processed;
    }).toList();

    // Calculate rankings for all RBs
    for (final rb in processedData) {
      final rankScore = calculateRBRank(
        totalEPA: rb['totalEPA'].toDouble(),
        rushShare: rb['rush_share'].toDouble(),
        numYards: rb['numYards'].toDouble(),
        conversionRate: rb['conversion_rate'].toDouble(),
        explosiveRate: rb['explosive_rate'].toDouble(),
        targetShare: rb['tgt_share'].toDouble(),
        numRec: rb['numRec'].toDouble(),
        allRBs: processedData,
      );
      rb['myRank'] = rankScore;
    }

    // Sort by ranking (higher score = better rank)
    processedData.sort((a, b) => (b['myRank'] as double).compareTo(a['myRank'] as double));
    
    // Assign rank numbers and calculate tiers
    for (int i = 0; i < processedData.length; i++) {
      processedData[i]['myRankNum'] = i + 1;
      processedData[i]['rb_tier'] = calculateTier(i + 1);
    }

    return processedData;
  }

  /// Get RB rankings with optional filters
  Future<List<Map<String, dynamic>>> getRBRankingsWithFilters({
    String? season,
    int? tier,
  }) async {
    Query query = _firestore.collection('rb_rankings');

    if (season != null && season != 'All Seasons') {
      query = query.where('season', isEqualTo: season);
    }

    if (tier != null) {
      query = query.where('rb_tier', isEqualTo: tier);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get RB tier summary statistics
  Map<String, dynamic> getRBTierSummary(List<Map<String, dynamic>> rbs) {
    if (rbs.isEmpty) return {};

    final tierCounts = <int, int>{};
    double totalYards = 0;
    double totalTDs = 0;
    double totalTargetShare = 0;

    for (final rb in rbs) {
      final tier = rb['rb_tier'] as int? ?? 8;
      tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
      
      totalYards += (rb['numYards'] as num?)?.toDouble() ?? 0.0;
      totalTDs += (rb['numTD'] as num?)?.toDouble() ?? 0.0;
      totalTargetShare += (rb['tgt_share'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'totalPlayers': rbs.length,
      'tierDistribution': tierCounts,
      'averageYards': totalYards / rbs.length,
      'averageTDs': totalTDs / rbs.length,
      'averageTargetShare': totalTargetShare / rbs.length,
    };
  }

  /// Filter RBs by criteria
  List<Map<String, dynamic>> filterRBs(
    List<Map<String, dynamic>> rbs, {
    String? team,
    int? minYards,
    int? minTDs,
    double? minTargetShare,
  }) {
    return rbs.where((rb) {
      if (team != null && rb['posteam'] != team) return false;
      if (minYards != null && ((rb['numYards'] as num?)?.toInt() ?? 0) < minYards) return false;
      if (minTDs != null && ((rb['numTD'] as num?)?.toInt() ?? 0) < minTDs) return false;
      if (minTargetShare != null && ((rb['tgt_share'] as num?)?.toDouble() ?? 0.0) < minTargetShare) return false;
      return true;
    }).toList();
  }
} 