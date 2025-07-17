import 'package:cloud_firestore/cloud_firestore.dart';

class TETierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate TE ranking following similar methodology to WR
  /// Formula: myRank = (2*EPA_rank) + tgt_rank + yards_rank + (0.5*conversion_rank) + (0.5*explosive_rank) + sep_rank + catch_rank
  double calculateTERank({
    required double totalEPA,
    required double targetShare,
    required double numYards,
    required double conversionRate,
    required double explosiveRate,
    required double avgSeparation,
    required double catchPercentage,
    required List<Map<String, dynamic>> allTEs,
  }) {
    // Calculate percentile ranks for each metric
    final epaRank = _calculatePercentileRank(totalEPA, allTEs.map((te) => te['totalEPA'] as double).toList());
    final tgtRank = _calculatePercentileRank(targetShare, allTEs.map((te) => te['tgt_share'] as double).toList());
    final yardsRank = _calculatePercentileRank(numYards, allTEs.map((te) => te['numYards'] as double).toList());
    final conversionRank = _calculatePercentileRank(conversionRate, allTEs.map((te) => te['conversion_rate'] as double).toList());
    final explosiveRank = _calculatePercentileRank(explosiveRate, allTEs.map((te) => te['explosive_rate'] as double).toList());
    final sepRank = _calculatePercentileRank(avgSeparation, allTEs.map((te) => te['avg_separation'] as double).toList());
    final catchRank = _calculatePercentileRank(catchPercentage, allTEs.map((te) => te['catch_percentage'] as double).toList());

    // Apply formula weights
    return (2 * epaRank) + tgtRank + yardsRank + (0.5 * conversionRank) + (0.5 * explosiveRank) + sepRank + catchRank;
  }

  /// Calculate percentile rank (0-100 scale)
  double _calculatePercentileRank(double value, List<double> allValues) {
    final sortedValues = allValues.where((v) => v.isFinite).toList()..sort();
    if (sortedValues.isEmpty) return 50.0;
    
    final position = sortedValues.where((v) => v < value).length;
    return (position / sortedValues.length) * 100;
  }

  /// Assign tier based on ranking (8-tier system)
  int calculateTier(double rankScore, List<double> allRankScores) {
    final sortedScores = allRankScores.where((s) => s.isFinite).toList()..sort();
    if (sortedScores.isEmpty) return 8;
    
    final percentile = _calculatePercentileRank(rankScore, sortedScores);
    
    // 8-tier system based on percentiles
    if (percentile >= 87.5) return 1;  // Top 12.5%
    if (percentile >= 75.0) return 2;  // 75-87.5%
    if (percentile >= 62.5) return 3;  // 62.5-75%
    if (percentile >= 50.0) return 4;  // 50-62.5%
    if (percentile >= 37.5) return 5;  // 37.5-50%
    if (percentile >= 25.0) return 6;  // 25-37.5%
    if (percentile >= 12.5) return 7;  // 12.5-25%
    return 8;                          // Bottom 12.5%
  }

  /// Process TE data and calculate rankings
  Future<List<Map<String, dynamic>>> processTERankings(List<Map<String, dynamic>> rawData) async {
    // Add calculated fields to each TE
    final processedData = rawData.map((te) {
      final Map<String, dynamic> processed = Map.from(te);
      
      // Ensure required fields have default values
      processed['totalEPA'] = processed['totalEPA'] ?? 0.0;
      processed['tgt_share'] = processed['tgt_share'] ?? 0.0;
      processed['numYards'] = processed['numYards'] ?? 0.0;
      processed['conversion_rate'] = processed['conversion_rate'] ?? 0.0;
      processed['explosive_rate'] = processed['explosive_rate'] ?? 0.0;
      processed['avg_separation'] = processed['avg_separation'] ?? 0.0;
      processed['catch_percentage'] = processed['catch_percentage'] ?? 0.0;
      processed['numRec'] = processed['numRec'] ?? 0;
      processed['numTD'] = processed['numTD'] ?? 0;
      
      return processed;
    }).toList();

    // Calculate rankings for all TEs
    for (final te in processedData) {
      final rankScore = calculateTERank(
        totalEPA: te['totalEPA'].toDouble(),
        targetShare: te['tgt_share'].toDouble(),
        numYards: te['numYards'].toDouble(),
        conversionRate: te['conversion_rate'].toDouble(),
        explosiveRate: te['explosive_rate'].toDouble(),
        avgSeparation: te['avg_separation'].toDouble(),
        catchPercentage: te['catch_percentage'].toDouble(),
        allTEs: processedData,
      );
      te['myRank'] = rankScore;
    }

    // Calculate tiers
    final allRankScores = processedData.map((te) => te['myRank'] as double).toList();
    for (final te in processedData) {
      te['te_tier'] = calculateTier(te['myRank'] as double, allRankScores);
    }

    // Sort by ranking (lower score = better rank)
    processedData.sort((a, b) => (a['myRank'] as double).compareTo(b['myRank'] as double));
    
    // Assign rank numbers
    for (int i = 0; i < processedData.length; i++) {
      processedData[i]['myRankNum'] = i + 1;
    }

    return processedData;
  }

  /// Get TE rankings with optional filters
  Future<List<Map<String, dynamic>>> getTERankingsWithFilters({
    String? season,
    int? tier,
  }) async {
    Query query = _firestore.collection('te_rankings');

    if (season != null && season != 'All Seasons') {
      query = query.where('season', isEqualTo: season);
    }

    if (tier != null) {
      query = query.where('te_tier', isEqualTo: tier);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get TE tier summary statistics
  Map<String, dynamic> getTETierSummary(List<Map<String, dynamic>> tes) {
    if (tes.isEmpty) return {};

    final tierCounts = <int, int>{};
    double totalYards = 0;
    double totalTDs = 0;
    double totalTargetShare = 0;
    double totalCatchRate = 0;

    for (final te in tes) {
      final tier = te['te_tier'] as int? ?? 8;
      tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
      
      totalYards += (te['numYards'] as num?)?.toDouble() ?? 0.0;
      totalTDs += (te['numTD'] as num?)?.toDouble() ?? 0.0;
      totalTargetShare += (te['tgt_share'] as num?)?.toDouble() ?? 0.0;
      totalCatchRate += (te['catch_percentage'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'totalPlayers': tes.length,
      'tierDistribution': tierCounts,
      'averageYards': totalYards / tes.length,
      'averageTDs': totalTDs / tes.length,
      'averageTargetShare': totalTargetShare / tes.length,
      'averageCatchRate': totalCatchRate / tes.length,
    };
  }

  /// Filter TEs by criteria
  List<Map<String, dynamic>> filterTEs(
    List<Map<String, dynamic>> tes, {
    String? team,
    int? minYards,
    int? minTDs,
    double? minTargetShare,
    double? minCatchRate,
  }) {
    return tes.where((te) {
      if (team != null && te['posteam'] != team) return false;
      if (minYards != null && ((te['numYards'] as num?)?.toInt() ?? 0) < minYards) return false;
      if (minTDs != null && ((te['numTD'] as num?)?.toInt() ?? 0) < minTDs) return false;
      if (minTargetShare != null && ((te['tgt_share'] as num?)?.toDouble() ?? 0.0) < minTargetShare) return false;
      if (minCatchRate != null && ((te['catch_percentage'] as num?)?.toDouble() ?? 0.0) < minCatchRate) return false;
      return true;
    }).toList();
  }
} 