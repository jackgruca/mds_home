import 'dart:math';
import 'package:mds_home/models/fantasy/player_ranking.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'enhanced_data_service.dart';

class PlayerRankData {
  final PlayerRanking player;
  final double value;
  final int rank;

  const PlayerRankData({
    required this.player,
    required this.value,
    required this.rank,
  });

  PlayerRankData copyWith({
    PlayerRanking? player,
    double? value,
    int? rank,
  }) {
    return PlayerRankData(
      player: player ?? this.player,
      value: value ?? this.value,
      rank: rank ?? this.rank,
    );
  }
}

class EnhancedCalculationEngine {
  final EnhancedDataService _dataService = EnhancedDataService();

  Future<List<CustomRankingResult>> calculateRankings({
    required String questionnaireId,
    required String position,
    required List<EnhancedRankingAttribute> attributes,
    String tieBreaker = 'consensus_rank',
  }) async {
    // Get all players for the position
    final players = await _dataService.getPlayersForPosition(position);
    
    if (players.isEmpty) {
      throw Exception('No players found for position: $position');
    }

    // Calculate rank-based scores for each player
    final results = await _calculateRankBasedScores(
      questionnaireId: questionnaireId,
      players: players,
      attributes: attributes,
      position: position,
    );

    // Sort by total score (ascending - lower is better) and apply tie-breaking
    results.sort((a, b) {
      final scoreComparison = a.totalScore.compareTo(b.totalScore);
      if (scoreComparison != 0) return scoreComparison;
      
      // Apply tie-breaking logic
      return _applyTieBreaker(a, b, tieBreaker);
    });

    // Assign final ranks
    for (int i = 0; i < results.length; i++) {
      results[i] = results[i].copyWith(rank: i + 1);
    }

    return results;
  }

  Future<List<CustomRankingResult>> _calculateRankBasedScores({
    required String questionnaireId,
    required List<PlayerRanking> players,
    required List<EnhancedRankingAttribute> attributes,
    required String position,
  }) async {
    // For each attribute, calculate the rank of each player
    final attributeRanks = <String, List<PlayerRankData>>{};
    
    for (final attribute in attributes) {
      final playerValues = <PlayerRankData>[];
      
      // Get raw values for all players for this attribute
      for (final player in players) {
        final rawValue = await _dataService.getPlayerStatValue(player, attribute);
        if (rawValue != null) {
          playerValues.add(PlayerRankData(
            player: player,
            value: rawValue,
            rank: 0, // Will be calculated
          ));
        }
      }
      
      // Sort by value (descending for most stats, ascending for "lower is better" stats)
      if (attribute.calculationType == 'inverse') {
        // For stats like interceptions where lower is better
        playerValues.sort((a, b) => a.value.compareTo(b.value));
      } else {
        // For most stats where higher is better
        playerValues.sort((a, b) => b.value.compareTo(a.value));
      }
      
      // Assign ranks (1-based)
      for (int i = 0; i < playerValues.length; i++) {
        playerValues[i] = playerValues[i].copyWith(rank: i + 1);
      }
      
      attributeRanks[attribute.id] = playerValues;
    }
    
    // Calculate weighted average rank for each player
    final results = <CustomRankingResult>[];
    
    for (final player in players) {
      final attributeScores = <String, double>{};
      final normalizedStats = <String, double>{};
      final rawStats = <String, double>{};
      double totalWeightedRank = 0.0;
      double totalWeight = 0.0;
      
      for (final attribute in attributes) {
        final rankData = attributeRanks[attribute.id];
        if (rankData != null) {
          PlayerRankData? playerRankData;
          try {
            playerRankData = rankData.firstWhere(
              (data) => data.player.id == player.id,
            );
          } catch (e) {
            // Player not found in this attribute's rankings
            playerRankData = PlayerRankData(
              player: player,
              value: 0.0,
              rank: rankData.length + 1, // Worst possible rank
            );
          }
          
          final rank = playerRankData.rank.toDouble();
          final weightedRank = rank * attribute.weight;
          
          attributeScores[attribute.id] = weightedRank;
          normalizedStats[attribute.id] = rank;
          rawStats[attribute.id] = playerRankData.value;
          
          totalWeightedRank += weightedRank;
          totalWeight += attribute.weight;
        }
      }
      
      // Calculate average weighted rank (lower is better)
      final averageRank = totalWeight > 0 ? totalWeightedRank / totalWeight : 999.0;
      
      results.add(CustomRankingResult(
        id: '${questionnaireId}_${player.id}_${DateTime.now().millisecondsSinceEpoch}',
        questionnaireId: questionnaireId,
        playerId: player.id,
        playerName: player.name,
        position: player.position,
        team: player.team,
        totalScore: averageRank,
        rank: 0, // Will be set after final sorting
        attributeScores: attributeScores,
        normalizedStats: normalizedStats,
        rawStats: rawStats,
        calculatedAt: DateTime.now(),
      ));
    }
    
    return results;
  }

  Future<Map<String, double>> _getRawStats(
      PlayerRanking player, List<EnhancedRankingAttribute> attributes) async {
    final rawStats = <String, double>{};
    for (final attribute in attributes) {
      final rawValue = await _dataService.getPlayerStatValue(player, attribute);
      rawStats[attribute.id] = rawValue ?? 0.0;
    }
    return rawStats;
  }

  Future<Map<String, double>> _getNormalizedStats(
    PlayerRanking player,
    List<EnhancedRankingAttribute> attributes,
    String position,
  ) async {
    final normalizedStats = <String, double>{};

    for (final attribute in attributes) {
      final normalizedValue = await _dataService.getNormalizedStatValue(
        player,
        attribute,
        position,
      );
      normalizedStats[attribute.id] = normalizedValue;
    }

    return normalizedStats;
  }

  int _applyTieBreaker(CustomRankingResult a, CustomRankingResult b, String tieBreaker) {
    switch (tieBreaker) {
      case 'consensus_rank':
        // Use player rank from original data (lower is better)
        return a.rank.compareTo(b.rank);
      case 'projected_points':
        // Use projected points (higher is better)
        final aPoints = a.normalizedStats['projected_points_raw'] ?? 0.0;
        final bPoints = b.normalizedStats['projected_points_raw'] ?? 0.0;
        return bPoints.compareTo(aPoints);
      case 'adp':
        // Use ADP (lower is better)
        final aAdp = a.normalizedStats['adp_raw'] ?? 999.0;
        final bAdp = b.normalizedStats['adp_raw'] ?? 999.0;
        return aAdp.compareTo(bAdp);
      case 'alphabetical':
        return a.playerName.compareTo(b.playerName);
      default:
        return 0;
    }
  }

  Future<RankingAnalysis> analyzeRankings(List<CustomRankingResult> results) async {
    if (results.isEmpty) {
      return RankingAnalysis.empty();
    }

    final scores = results.map((r) => r.totalScore).toList();
    final analysis = RankingAnalysis(
      totalPlayers: results.length,
      averageScore: scores.reduce((a, b) => a + b) / scores.length,
      highestScore: scores.reduce(max),
      lowestScore: scores.reduce(min),
      scoreRange: scores.reduce(max) - scores.reduce(min),
      standardDeviation: _calculateStandardDeviation(scores),
      topTierCutoff: _calculatePercentile(scores, 0.25), // Top 25%
      tierBreaks: _calculateTierBreaks(scores),
    );

    return analysis;
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }

  double _calculatePercentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0.0;
    
    // For rank-based scoring, lower is better, so sort ascending
    final sorted = List<double>.from(values)..sort((a, b) => a.compareTo(b));
    final index = (percentile * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  List<double> _calculateTierBreaks(List<double> scores) {
    if (scores.isEmpty) return [];
    
    // For rank-based scoring, lower is better, so sort ascending
    final sorted = List<double>.from(scores)..sort((a, b) => a.compareTo(b));
    
    return [
      _calculatePercentile(sorted, 0.1),  // Elite tier (top 10% - lowest scores)
      _calculatePercentile(sorted, 0.25), // High tier (top 25%)
      _calculatePercentile(sorted, 0.5),  // Mid tier (top 50%)
      _calculatePercentile(sorted, 0.75), // Low tier (top 75%)
    ];
  }

  String getTierLabel(double score, List<double> tierBreaks) {
    if (tierBreaks.isEmpty) return 'Unknown';
    
    // For rank-based scoring, lower scores are better
    if (score <= tierBreaks[0]) return 'Elite';
    if (score <= tierBreaks[1]) return 'High';
    if (score <= tierBreaks[2]) return 'Mid';
    if (score <= tierBreaks[3]) return 'Low';
    return 'Deep';
  }

  Future<List<AttributeImpact>> analyzeAttributeImpact(
    List<CustomRankingResult> results,
    List<EnhancedRankingAttribute> attributes,
  ) async {
    final impacts = <AttributeImpact>[];

    for (final attribute in attributes) {
      final attributeScores = results
          .map((r) => r.attributeScores[attribute.id] ?? 0.0)
          .toList();

      final totalScores = results.map((r) => r.totalScore).toList();
      
      final correlation = _calculateCorrelation(attributeScores, totalScores);
      final averageContribution = attributeScores.isNotEmpty 
          ? attributeScores.reduce((a, b) => a + b) / attributeScores.length
          : 0.0;

      impacts.add(AttributeImpact(
        attribute: attribute,
        correlation: correlation,
        averageContribution: averageContribution,
        maxContribution: attributeScores.isNotEmpty ? attributeScores.reduce(max) : 0.0,
        weight: attribute.weight,
        effectiveWeight: correlation * attribute.weight,
      ));
    }

    // Sort by effective weight (impact on final rankings)
    impacts.sort((a, b) => b.effectiveWeight.compareTo(a.effectiveWeight));

    return impacts;
  }

  double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((val) => val * val).reduce((a, b) => a + b);
    final sumY2 = y.map((val) => val * val).reduce((a, b) => a + b);

    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    return denominator != 0 ? numerator / denominator : 0.0;
  }

  // Debug method to verify ranking system
  void debugRankingSystem(List<CustomRankingResult> results, List<EnhancedRankingAttribute> attributes) {
    print('=== RANKING SYSTEM DEBUG ===');
    print('Total players: ${results.length}');
    print('Attributes: ${attributes.map((a) => '${a.displayName} (${(a.weight * 100).toStringAsFixed(0)}%)').join(', ')}');
    
    final top10 = results.take(10).toList();
    print('\nTop 10 Rankings:');
    for (int i = 0; i < top10.length; i++) {
      final result = top10[i];
      print('${i + 1}. ${result.playerName} (${result.position}) - Score: ${result.totalScore.toStringAsFixed(2)}');
      
      // Show attribute rankings
      final attributeRanks = <String>[];
      for (final attr in attributes) {
        final rank = result.normalizedStats[attr.id]?.toStringAsFixed(1) ?? 'N/A';
        attributeRanks.add('${attr.displayName}: #$rank');
      }
      print('   ${attributeRanks.join(', ')}');
    }
    print('=========================');
  }
}

class RankingAnalysis {
  final int totalPlayers;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double scoreRange;
  final double standardDeviation;
  final double topTierCutoff;
  final List<double> tierBreaks;

  const RankingAnalysis({
    required this.totalPlayers,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.scoreRange,
    required this.standardDeviation,
    required this.topTierCutoff,
    required this.tierBreaks,
  });

  factory RankingAnalysis.empty() {
    return const RankingAnalysis(
      totalPlayers: 0,
      averageScore: 0.0,
      highestScore: 0.0,
      lowestScore: 0.0,
      scoreRange: 0.0,
      standardDeviation: 0.0,
      topTierCutoff: 0.0,
      tierBreaks: [],
    );
  }

  bool get hasGoodSeparation => standardDeviation > 0.1;
  bool get isWellDistributed => scoreRange > 0.5;
}

class AttributeImpact {
  final EnhancedRankingAttribute attribute;
  final double correlation;
  final double averageContribution;
  final double maxContribution;
  final double weight;
  final double effectiveWeight;

  const AttributeImpact({
    required this.attribute,
    required this.correlation,
    required this.averageContribution,
    required this.maxContribution,
    required this.weight,
    required this.effectiveWeight,
  });

  String get impactLevel {
    if (effectiveWeight > 0.15) return 'High';
    if (effectiveWeight > 0.08) return 'Medium';
    if (effectiveWeight > 0.03) return 'Low';
    return 'Minimal';
  }

  double get efficiency => weight > 0 ? effectiveWeight / weight : 0.0;
}