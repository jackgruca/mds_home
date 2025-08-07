// lib/services/nfl_roster_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import '../models/nfl_trade/nfl_player.dart';

class NFLRosterService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get players for a specific team with filtering and sorting options
  static Future<List<NFLPlayer>> getTeamRoster(
    String teamAbbreviation, {
    String? position,
    String season = '2024',
    int limit = 100,
    String sortBy = 'overall_rating', // Default sort by rating
    bool ascending = false,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getNflRosters');
      
      Map<String, dynamic> filters = {
        'team': teamAbbreviation,
        'season': season,
        'is_active': true, // Only get active players
      };

      if (position != null && position != 'All') {
        filters['position'] = position;
      }

      final result = await callable.call<Map<String, dynamic>>({
        'filters': filters,
        'limit': limit,
        'orderBy': sortBy,
        'orderDirection': ascending ? 'asc' : 'desc',
      });

      final data = result.data;
      List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(data['data'] ?? []);
      
      return rows.map((row) => _convertFirebaseRowToNFLPlayer(row, teamAbbreviation)).toList();
      
    } catch (e) {
      // print('Error fetching team roster: $e');
      return [];
    }
  }

  /// Get all available positions for a team
  static Future<List<String>> getTeamPositions(String teamAbbreviation) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getNflRosters');
      
      final result = await callable.call<Map<String, dynamic>>({
        'filters': {
          'team': teamAbbreviation,
          'season': '2024',
          'is_active': true,
        },
        'limit': 100,
      });

      final data = result.data;
      List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(data['data'] ?? []);
      
      Set<String> positions = rows
          .map((row) => row['position']?.toString() ?? '')
          .where((pos) => pos.isNotEmpty)
          .toSet();
      
      List<String> sortedPositions = positions.toList()..sort();
      return ['All', ...sortedPositions];
      
    } catch (e) {
      // print('Error fetching team positions: $e');
      return ['All'];
    }
  }

  /// Convert Firebase roster row to NFLPlayer object
  static NFLPlayer _convertFirebaseRowToNFLPlayer(Map<String, dynamic> row, String team) {
    // Extract basic info
    String name = row['full_name']?.toString() ?? 'Unknown Player';
    String position = row['position']?.toString() ?? 'UNK';
    int age = _parseInt(row['age_at_season']) ?? 25;
    int experience = _parseInt(row['years_exp']) ?? 0;
    
    // Calculate market value based on available data
    double marketValue = _calculatePlayerMarketValue(row);
    
    // Calculate overall rating (simplified - you may have better rating data)
    double overallRating = _calculateOverallRating(row);
    
    // Get position importance
    double positionImportance = _getPositionImportance(position);
    
    // Calculate age-adjusted value
    double ageAdjustedValue = marketValue * _getAgeFactor(age);
    
    // Estimate annual salary (simplified - you may have contract data)
    double annualSalary = _estimateAnnualSalary(marketValue, experience, position);
    
    return NFLPlayer(
      playerId: '${name.replaceAll(' ', '_')}_${team}_${row['season'] ?? '2024'}',
      name: name,
      position: position,
      team: team,
      age: age,
      experience: experience,
      marketValue: marketValue,
      contractStatus: _determineContractStatus(experience),
      contractYearsRemaining: _estimateContractYearsRemaining(experience),
      annualSalary: annualSalary,
      overallRating: overallRating,
      positionRank: _calculatePositionRank(overallRating),
      ageAdjustedValue: ageAdjustedValue,
      positionImportance: positionImportance,
      durabilityScore: _calculateDurabilityScore(row),
      hasInjuryConcerns: _checkInjuryConcerns(row),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  static double _calculatePlayerMarketValue(Map<String, dynamic> row) {
    // Base value calculation - you can enhance this with more sophisticated logic
    String position = row['position']?.toString() ?? '';
    int experience = _parseInt(row['years_exp']) ?? 0;
    int age = _parseInt(row['age_at_season']) ?? 25;
    
    // Base values by position (in millions)
    Map<String, double> positionBaseValues = {
      'QB': 35.0,
      'RB': 15.0,
      'WR': 20.0,
      'TE': 12.0,
      'OT': 18.0,
      'OG': 10.0,
      'C': 12.0,
      'DE': 16.0,
      'DT': 14.0,
      'EDGE': 20.0,
      'LB': 12.0,
      'CB': 18.0,
      'S': 14.0,
      'K': 4.0,
      'P': 3.0,
    };
    
    double baseValue = positionBaseValues[position] ?? 10.0;
    
    // Experience multiplier
    double experienceMultiplier = 0.7 + (experience * 0.05); // 70% base + 5% per year of experience
    experienceMultiplier = experienceMultiplier.clamp(0.5, 1.5);
    
    // Age penalty
    double agePenalty = age <= 27 ? 1.0 : (age <= 30 ? 0.9 : (age <= 33 ? 0.7 : 0.5));
    
    return (baseValue * experienceMultiplier * agePenalty).clamp(1.0, 60.0);
  }

  static double _calculateOverallRating(Map<String, dynamic> row) {
    // Simplified rating calculation - enhance with actual performance metrics
    int experience = _parseInt(row['years_exp']) ?? 0;
    int age = _parseInt(row['age_at_season']) ?? 25;
    String position = row['position']?.toString() ?? '';
    
    double baseRating = 70.0; // Base rating for average NFL player
    
    // Experience bonus
    baseRating += (experience * 2.0).clamp(0.0, 20.0);
    
    // Age curve
    if (age <= 23) baseRating += 5.0; // Young player potential
    else if (age <= 28) baseRating += 10.0; // Prime years
    else if (age <= 32) baseRating += 5.0; // Veteran experience
    else baseRating -= 5.0; // Aging penalty
    
    // Premium position slight boost
    if (['QB', 'EDGE', 'OT', 'CB'].contains(position)) {
      baseRating += 3.0;
    }
    
    return baseRating.clamp(60.0, 99.0);
  }

  static double _getPositionImportance(String position) {
    const Map<String, double> importance = {
      'QB': 1.0,
      'EDGE': 0.9,
      'OT': 0.85,
      'CB': 0.8,
      'WR': 0.75,
      'DT': 0.7,
      'S': 0.65,
      'LB': 0.6,
      'TE': 0.55,
      'RB': 0.5,
      'OG': 0.45,
      'C': 0.5,
      'DE': 0.75,
      'K': 0.2,
      'P': 0.15,
    };
    return importance[position] ?? 0.4;
  }

  static double _getAgeFactor(int age) {
    if (age <= 25) return 1.1; // Young player premium
    if (age <= 28) return 1.0; // Prime years
    if (age <= 31) return 0.9; // Veteran discount
    return 0.7; // Aging player discount
  }

  static double _estimateAnnualSalary(double marketValue, int experience, String position) {
    // Rough salary estimation based on market value
    double basePercentage = 0.15; // 15% of market value as base
    
    // Adjust based on experience (rookies have lower salaries)
    if (experience <= 3) {
      basePercentage = 0.08; // Rookie contracts
    } else if (experience <= 6) {
      basePercentage = 0.12; // Second contracts
    }
    
    return (marketValue * basePercentage).clamp(0.8, 50.0);
  }

  static String _determineContractStatus(int experience) {
    if (experience <= 3) {
      return 'rookie';
    }
    if (experience <= 6) {
      return 'extension';
    }
    return 'veteran';
  }

  static int _estimateContractYearsRemaining(int experience) {
    if (experience <= 1) {
      return 3; // Rookie contract
    }
    if (experience <= 4) {
      return 2; // Near end of rookie deal
    }
    return 2 + (experience % 3); // Veteran contracts vary
  }

  static double _calculatePositionRank(double overallRating) {
    // Convert overall rating to percentile rank
    return ((overallRating - 60.0) / 40.0 * 100.0).clamp(0.0, 100.0);
  }

  static double _calculateDurabilityScore(Map<String, dynamic> row) {
    // Simplified durability score - enhance with injury history if available
    bool isActive = row['is_active'] == true;
    bool isInjuredReserve = row['is_injured_reserve'] == true;
    
    if (isInjuredReserve) {
      return 60.0;
    }
    if (!isActive) {
      return 70.0;
    }
    return 85.0; // Default good durability for active players
  }

  static bool _checkInjuryConcerns(Map<String, dynamic> row) {
    return row['is_injured_reserve'] == true;
  }
}