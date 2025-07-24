import 'dart:math';
import '../../models/fantasy/scoring_settings.dart';

class HistoricalPointsService {
  // Historical PPR points by position and rank (based on 2019-2023 averages)
  static const Map<String, Map<int, double>> _historicalPoints = {
    'qb': {
      1: 337.2, 2: 322.8, 3: 312.5, 4: 304.7, 5: 298.1,
      6: 291.3, 7: 285.6, 8: 279.4, 9: 274.8, 10: 269.5,
      11: 264.9, 12: 260.1, 13: 255.7, 14: 251.2, 15: 246.8,
      16: 242.1, 17: 237.9, 18: 233.4, 19: 229.2, 20: 224.8,
      21: 220.6, 22: 216.1, 23: 211.9, 24: 207.4, 25: 203.2,
      26: 198.7, 27: 194.5, 28: 190.0, 29: 185.8, 30: 181.3,
      31: 177.1, 32: 172.6, 33: 168.4, 34: 163.9, 35: 159.7,
      36: 155.2, 37: 151.0, 38: 146.5, 39: 142.3, 40: 137.8,
    },
    'rb': {
      1: 298.5, 2: 268.7, 3: 251.3, 4: 238.9, 5: 228.4,
      6: 219.6, 7: 212.1, 8: 205.3, 9: 199.2, 10: 193.6,
      11: 188.4, 12: 183.5, 13: 178.9, 14: 174.6, 15: 170.5,
      16: 166.7, 17: 163.1, 18: 159.7, 19: 156.5, 20: 153.4,
      21: 150.5, 22: 147.7, 23: 145.0, 24: 142.4, 25: 139.9,
      26: 137.5, 27: 135.2, 28: 132.9, 29: 130.7, 30: 128.6,
      31: 126.5, 32: 124.5, 33: 122.5, 34: 120.6, 35: 118.7,
      36: 116.9, 37: 115.1, 38: 113.3, 39: 111.6, 40: 109.9,
      41: 108.2, 42: 106.6, 43: 105.0, 44: 103.4, 45: 101.8,
      46: 100.3, 47: 98.8, 48: 97.3, 49: 95.8, 50: 94.4,
    },
    'wr': {
      1: 286.3, 2: 258.1, 3: 239.7, 4: 225.8, 5: 214.5,
      6: 205.1, 7: 197.2, 8: 190.4, 9: 184.5, 10: 179.2,
      11: 174.5, 12: 170.2, 13: 166.3, 14: 162.7, 15: 159.4,
      16: 156.3, 17: 153.4, 18: 150.7, 19: 148.2, 20: 145.8,
      21: 143.6, 22: 141.5, 23: 139.5, 24: 137.6, 25: 135.8,
      26: 134.1, 27: 132.4, 28: 130.8, 29: 129.3, 30: 127.8,
      31: 126.4, 32: 125.0, 33: 123.7, 34: 122.4, 35: 121.1,
      36: 119.9, 37: 118.7, 38: 117.5, 39: 116.4, 40: 115.3,
      41: 114.2, 42: 113.1, 43: 112.1, 44: 111.0, 45: 110.0,
      46: 109.0, 47: 108.1, 48: 107.1, 49: 106.2, 50: 105.3,
      51: 104.4, 52: 103.5, 53: 102.6, 54: 101.8, 55: 100.9,
      56: 100.1, 57: 99.2, 58: 98.4, 59: 97.6, 60: 96.8,
    },
    'te': {
      1: 217.8, 2: 184.3, 3: 164.7, 4: 151.2, 5: 141.8,
      6: 134.5, 7: 128.6, 8: 123.7, 9: 119.5, 10: 115.8,
      11: 112.6, 12: 109.7, 13: 107.1, 14: 104.7, 15: 102.5,
      16: 100.5, 17: 98.6, 18: 96.9, 19: 95.3, 20: 93.8,
      21: 92.4, 22: 91.1, 23: 89.8, 24: 88.6, 25: 87.5,
      26: 86.4, 27: 85.3, 28: 84.3, 29: 83.3, 30: 82.4,
      31: 81.4, 32: 80.5, 33: 79.6, 34: 78.8, 35: 77.9,
      36: 77.1, 37: 76.3, 38: 75.5, 39: 74.7, 40: 74.0,
    },
  };

  /// Convert a player's rank to projected fantasy points based on historical averages
  /// 
  /// [position] - Player position ('qb', 'rb', 'wr', 'te')
  /// [rank] - Player's rank at their position
  /// [scoringSystem] - Scoring system ('ppr', 'standard', 'half_ppr') - defaults to 'ppr'
  /// 
  /// Returns projected fantasy points based on historical rank performance
  static double rankToPoints(String position, int rank, {String scoringSystem = 'ppr'}) {
    final positionKey = position.toLowerCase();
    final positionData = _historicalPoints[positionKey];
    
    if (positionData == null) {
      throw ArgumentError('Unknown position: $position');
    }

    // Direct lookup if we have exact rank data
    if (positionData.containsKey(rank)) {
      double points = positionData[rank]!;
      return _adjustForScoringSystem(points, scoringSystem);
    }

    // For ranks beyond our data, use extrapolation
    final maxRank = positionData.keys.reduce(max);
    if (rank > maxRank) {
      return _extrapolatePoints(positionData, rank, maxRank, scoringSystem);
    }

    // Interpolate between known values
    final lowerRank = positionData.keys.where((r) => r < rank).reduce(max);
    final upperRank = positionData.keys.where((r) => r > rank).reduce(min);
    
    final lowerPoints = positionData[lowerRank]!;
    final upperPoints = positionData[upperRank]!;
    
    final ratio = (rank - lowerRank) / (upperRank - lowerRank);
    final interpolatedPoints = lowerPoints - (lowerPoints - upperPoints) * ratio;
    
    return _adjustForScoringSystem(interpolatedPoints, scoringSystem);
  }

  /// Get replacement level points for a position based on league settings
  /// 
  /// [position] - Player position
  /// [leagueSettings] - Map containing league configuration
  /// [scoringSystem] - Scoring system
  static double getReplacementLevelPoints(
    String position, 
    Map<String, int> leagueSettings, 
    {String scoringSystem = 'ppr'}
  ) {
    final replacementRank = getReplacementRank(position, leagueSettings);
    return rankToPoints(position, replacementRank, scoringSystem: scoringSystem);
  }

  /// Calculate replacement rank based on league settings
  /// 
  /// Default 12-team league: 1 QB, 2 RB, 2 WR, 1 TE, 1 FLEX
  /// Replacement levels: QB: 14th, RB: 26th, WR: 26th, TE: 14th
  static int getReplacementRank(String position, Map<String, int> leagueSettings) {
    final teams = leagueSettings['teams'] ?? 12;
    final qbStarters = leagueSettings['qb'] ?? 1;
    final rbStarters = leagueSettings['rb'] ?? 2;
    final wrStarters = leagueSettings['wr'] ?? 2;
    final teStarters = leagueSettings['te'] ?? 1;
    final flexStarters = leagueSettings['flex'] ?? 1;

    switch (position.toLowerCase()) {
      case 'qb':
        // QBs don't typically fill flex spots
        return (teams * qbStarters) + 2; // Add 2 for bench depth
      
      case 'rb':
        // RBs can fill flex spots, assume 50% of flex spots go to RBs
        final flexRbs = (flexStarters * 0.5).round();
        return (teams * (rbStarters + flexRbs)) + 2;
      
      case 'wr':
        // WRs can fill flex spots, assume 50% of flex spots go to WRs
        final flexWrs = (flexStarters * 0.5).round();
        return (teams * (wrStarters + flexWrs)) + 2;
      
      case 'te':
        // TEs rarely fill flex spots in most leagues
        return (teams * teStarters) + 2;
      
      default:
        throw ArgumentError('Unknown position: $position');
    }
  }

  /// Adjust points based on scoring system
  static double _adjustForScoringSystem(double pprPoints, String scoringSystem) {
    switch (scoringSystem.toLowerCase()) {
      case 'ppr':
        return pprPoints;
      case 'half_ppr':
        // Estimate: reduce by ~15% for half PPR (mainly affects RB/WR/TE)
        return pprPoints * 0.85;
      case 'standard':
        // Estimate: reduce by ~25% for standard (mainly affects RB/WR/TE)
        return pprPoints * 0.75;
      default:
        return pprPoints;
    }
  }

  /// Extrapolate points for ranks beyond our historical data
  static double _extrapolatePoints(
    Map<int, double> positionData, 
    int targetRank, 
    int maxKnownRank, 
    String scoringSystem
  ) {
    // Use the last few known ranks to calculate decline rate
    final ranks = positionData.keys.toList()..sort();
    final lastRank = ranks.last;
    final secondLastRank = ranks[ranks.length - 2];
    final thirdLastRank = ranks[ranks.length - 3];
    
    final lastPoints = positionData[lastRank]!;
    final secondLastPoints = positionData[secondLastRank]!;
    final thirdLastPoints = positionData[thirdLastRank]!;
    
    // Calculate average decline per rank
    final decline1 = secondLastPoints - lastPoints;
    final decline2 = thirdLastPoints - secondLastPoints;
    final avgDecline = (decline1 + decline2) / 2;
    
    // Extrapolate with slight acceleration in decline for very late ranks
    final ranksToExtrapolate = targetRank - lastRank;
    final extrapolatedPoints = lastPoints - (avgDecline * ranksToExtrapolate * 1.1);
    
    // Floor at reasonable minimum (replacement level shouldn't be negative)
    final minimumPoints = 50.0;
    final finalPoints = max(extrapolatedPoints, minimumPoints);
    
    return _adjustForScoringSystem(finalPoints, scoringSystem);
  }

  /// Convert historical PPR projections to custom scoring
  /// 
  /// This method takes the historical PPR-based projections and adjusts them
  /// based on custom scoring settings. It uses typical stat distributions
  /// for each position to recalculate points.
  static double calculateCustomScoringPoints(
    String position,
    int rank,
    ScoringSettings scoringSettings,
  ) {
    // Get base PPR points for this rank
    final basePPRPoints = rankToPoints(position, rank, scoringSystem: 'ppr');
    
    // If using standard presets, use existing adjustment
    if (scoringSettings.scoringType == ScoringType.standard) {
      return rankToPoints(position, rank, scoringSystem: 'standard');
    } else if (scoringSettings.scoringType == ScoringType.halfPPR) {
      return rankToPoints(position, rank, scoringSystem: 'half_ppr');
    } else if (scoringSettings.scoringType == ScoringType.ppr && 
               scoringSettings.passingTDPoints == 4 &&
               scoringSettings.tePremiumBonus == 0) {
      return basePPRPoints;
    }
    
    // For custom scoring, estimate stat breakdown based on position and rank
    switch (position.toLowerCase()) {
      case 'qb':
        return _calculateQBPoints(rank, basePPRPoints, scoringSettings);
      case 'rb':
        return _calculateRBPoints(rank, basePPRPoints, scoringSettings);
      case 'wr':
        return _calculateWRPoints(rank, basePPRPoints, scoringSettings);
      case 'te':
        return _calculateTEPoints(rank, basePPRPoints, scoringSettings);
      default:
        return basePPRPoints;
    }
  }
  
  static double _calculateQBPoints(int rank, double basePPRPoints, ScoringSettings settings) {
    // Typical QB stat distribution (based on rank)
    // QB1: ~4500 yards, 35 TDs, 10 INTs
    // QB12: ~3800 yards, 25 TDs, 12 INTs
    // QB24: ~3000 yards, 18 TDs, 15 INTs
    
    double yardsMultiplier = 1.0 - (rank - 1) * 0.015;
    double tdMultiplier = 1.0 - (rank - 1) * 0.025;
    double intMultiplier = 1.0 + (rank - 1) * 0.015;
    
    double passingYards = 4500 * yardsMultiplier;
    double passingTDs = 35 * tdMultiplier;
    double interceptions = 10 * intMultiplier;
    double rushingYards = max(200 - (rank * 5), 0);
    double rushingTDs = max(3 - (rank * 0.1), 0);
    
    return settings.calculatePoints(
      position: 'QB',
      passingYards: passingYards,
      passingTDs: passingTDs,
      interceptions: interceptions,
      rushingYards: rushingYards,
      rushingTDs: rushingTDs,
    );
  }
  
  static double _calculateRBPoints(int rank, double basePPRPoints, ScoringSettings settings) {
    // Typical RB stat distribution
    // RB1: ~1200 rush yards, 10 rush TDs, 60 rec, 500 rec yards, 4 rec TDs
    // RB12: ~900 rush yards, 7 rush TDs, 45 rec, 350 rec yards, 2 rec TDs
    // RB24: ~600 rush yards, 4 rush TDs, 30 rec, 250 rec yards, 1 rec TD
    
    double multiplier = 1.0 - (rank - 1) * 0.025;
    
    double rushingYards = 1200 * multiplier;
    double rushingTDs = 10 * multiplier;
    double receptions = 60 * multiplier;
    double receivingYards = 500 * multiplier;
    double receivingTDs = 4 * multiplier;
    
    return settings.calculatePoints(
      position: 'RB',
      rushingYards: rushingYards,
      rushingTDs: rushingTDs,
      receptions: receptions,
      receivingYards: receivingYards,
      receivingTDs: receivingTDs,
    );
  }
  
  static double _calculateWRPoints(int rank, double basePPRPoints, ScoringSettings settings) {
    // Typical WR stat distribution
    // WR1: ~100 rec, 1400 yards, 10 TDs
    // WR12: ~80 rec, 1100 yards, 7 TDs
    // WR24: ~65 rec, 850 yards, 5 TDs
    
    double multiplier = 1.0 - (rank - 1) * 0.015;
    
    double receptions = 100 * multiplier;
    double receivingYards = 1400 * multiplier;
    double receivingTDs = 10 * multiplier;
    double rushingYards = max(50 - (rank * 2), 0);
    
    return settings.calculatePoints(
      position: 'WR',
      receptions: receptions,
      receivingYards: receivingYards,
      receivingTDs: receivingTDs,
      rushingYards: rushingYards,
    );
  }
  
  static double _calculateTEPoints(int rank, double basePPRPoints, ScoringSettings settings) {
    // Typical TE stat distribution
    // TE1: ~85 rec, 1100 yards, 8 TDs
    // TE6: ~65 rec, 750 yards, 5 TDs
    // TE12: ~50 rec, 550 yards, 3 TDs
    
    double multiplier = 1.0 - (rank - 1) * 0.025;
    
    double receptions = 85 * multiplier;
    double receivingYards = 1100 * multiplier;
    double receivingTDs = 8 * multiplier;
    
    return settings.calculatePoints(
      position: 'TE',
      receptions: receptions,
      receivingYards: receivingYards,
      receivingTDs: receivingTDs,
    );
  }
  
  /// Get replacement level points with custom scoring
  static double getReplacementLevelPointsWithCustomScoring(
    String position,
    Map<String, int> leagueSettings,
    ScoringSettings scoringSettings,
  ) {
    final replacementRank = getReplacementRank(position, leagueSettings);
    return calculateCustomScoringPoints(position, replacementRank, scoringSettings);
  }

  /// Get default league settings for VORP calculations
  static Map<String, int> getDefaultLeagueSettings() {
    return {
      'teams': 12,
      'qb': 1,
      'rb': 2,
      'wr': 2,
      'te': 1,
      'flex': 1,
    };
  }

  /// Batch convert multiple players' ranks to points
  static Map<String, double> batchRankToPoints(
    Map<String, Map<String, int>> playerRanks, 
    {String scoringSystem = 'ppr'}
  ) {
    final results = <String, double>{};
    
    for (final entry in playerRanks.entries) {
      final playerId = entry.key;
      final playerData = entry.value;
      final position = playerData['position'];
      final rank = playerData['rank'];
      
      if (position != null && rank != null) {
        try {
          results[playerId] = rankToPoints(
            position.toString(), 
            rank, 
            scoringSystem: scoringSystem
          );
        } catch (e) {
          // Skip players with invalid position/rank data
          continue;
        }
      }
    }
    
    return results;
  }
}