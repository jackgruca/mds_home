import 'package:cloud_firestore/cloud_firestore.dart';

class RankingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Base stat fields common to all positions
  static const Map<String, Map<String, dynamic>> _baseStatFields = {
    'myRankNum': {'name': 'Rank', 'format': 'integer', 'description': 'Overall ranking'},
    'rank_number': {'name': 'Rank', 'format': 'integer', 'description': 'Overall ranking'},
    'player_name': {'name': 'Player', 'format': 'string', 'description': 'Player name'},
    'posteam': {'name': 'Team', 'format': 'string', 'description': 'Team'},
    'team': {'name': 'Team', 'format': 'string', 'description': 'Team'},
    'tier': {'name': 'Tier', 'format': 'integer', 'description': 'Player tier'},
    'qb_tier': {'name': 'Tier', 'format': 'integer', 'description': 'Player tier'},
    'season': {'name': 'Season', 'format': 'integer', 'description': 'Season'},
    'numGames': {'name': 'Games', 'format': 'integer', 'description': 'Games played'},
    'games': {'name': 'Games', 'format': 'integer', 'description': 'Games played'},
  };

  // Position-specific stat fields based on R code
  static const Map<String, Map<String, dynamic>> _rbStatFields = {
    'totalEPA': {'name': 'EPA', 'format': 'decimal1', 'description': 'Total Expected Points Added'},
    'totalTD': {'name': 'Total TDs', 'format': 'integer', 'description': 'Total touchdowns'},
    'run_share': {'name': 'Rush Share', 'format': 'percentage', 'description': 'Team rush share'},
    'YPG': {'name': 'Rush YPG', 'format': 'decimal1', 'description': 'Rushing yards per game'},
    'tgt_share': {'name': 'Target Share', 'format': 'percentage', 'description': 'Team target share'},
    'conversion': {'name': 'RZ Conv', 'format': 'percentage', 'description': 'Red zone conversion rate'},
    'explosive_rate': {'name': 'Expl Rate', 'format': 'percentage', 'description': 'Explosive play rate (15+ yards)'},
    'avg_eff': {'name': 'Efficiency', 'format': 'decimal1', 'description': 'Average efficiency'},
    'avg_RYOE_perAtt': {'name': 'RYOE/Att', 'format': 'decimal1', 'description': 'Rush yards over expected per attempt'},
    'third_down_rate': {'name': '3rd Down %', 'format': 'percentage', 'description': 'Third down conversion rate'},
    'myRank': {'name': 'Rank Score', 'format': 'decimal4', 'description': 'Composite ranking score'},
    // Rank fields
    'EPA_rank': {'name': 'EPA Rank', 'format': 'percentage', 'description': 'EPA percentile rank'},
    'td_rank': {'name': 'TD Rank', 'format': 'percentage', 'description': 'TD percentile rank'},
    'run_rank': {'name': 'Rush Rank', 'format': 'percentage', 'description': 'Rush share percentile rank'},
    'YPG_rank': {'name': 'YPG Rank', 'format': 'percentage', 'description': 'Yards per game percentile rank'},
    'tgt_rank': {'name': 'Tgt Rank', 'format': 'percentage', 'description': 'Target share percentile rank'},
    'third_rank': {'name': '3rd Rank', 'format': 'percentage', 'description': 'Third down rate percentile rank'},
    'conversion_rank': {'name': 'RZ Rank', 'format': 'percentage', 'description': 'Red zone conversion percentile rank'},
    'explosive_rank': {'name': 'Expl Rank', 'format': 'percentage', 'description': 'Explosive rate percentile rank'},
    'RYOE_rank': {'name': 'RYOE Rank', 'format': 'percentage', 'description': 'RYOE percentile rank'},
    'eff_rank': {'name': 'Eff Rank', 'format': 'percentage', 'description': 'Efficiency percentile rank'},
  };

  static const Map<String, Map<String, dynamic>> _wrStatFields = {
    'totalEPA': {'name': 'EPA', 'format': 'decimal1', 'description': 'Total Expected Points Added'},
    'totalTD': {'name': 'Rec TDs', 'format': 'integer', 'description': 'Receiving touchdowns'},
    'tgt_share': {'name': 'Target Share', 'format': 'percentage', 'description': 'Team target share'},
    'numYards': {'name': 'Rec Yards', 'format': 'integer', 'description': 'Receiving yards'},
    'numRec': {'name': 'Receptions', 'format': 'integer', 'description': 'Total receptions'},
    'conversion': {'name': 'RZ Conv', 'format': 'percentage', 'description': 'Red zone conversion rate'},
    'explosive_rate': {'name': 'Expl Rate', 'format': 'percentage', 'description': 'Explosive play rate (15+ yards)'},
    'avg_separation': {'name': 'Separation', 'format': 'decimal1', 'description': 'Average separation'},
    'avg_intended_air_yards': {'name': 'aDOT', 'format': 'decimal1', 'description': 'Average depth of target'},
    'catch_percentage': {'name': 'Catch %', 'format': 'percentage', 'description': 'Catch percentage'},
    'yac_above_expected': {'name': 'YAC+', 'format': 'decimal1', 'description': 'YAC above expected'},
    'third_down_rate': {'name': '3rd Down %', 'format': 'percentage', 'description': 'Third down conversion rate'},
    'myRank': {'name': 'Rank Score', 'format': 'decimal4', 'description': 'Composite ranking score'},
    // Rank fields
    'EPA_rank': {'name': 'EPA Rank', 'format': 'percentage', 'description': 'EPA percentile rank'},
    'tgt_rank': {'name': 'Tgt Rank', 'format': 'percentage', 'description': 'Target share percentile rank'},
    'YPG_rank': {'name': 'YPG Rank', 'format': 'percentage', 'description': 'Yards per game percentile rank'},
    'td_rank': {'name': 'TD Rank', 'format': 'percentage', 'description': 'TD percentile rank'},
    'conversion_rank': {'name': 'RZ Rank', 'format': 'percentage', 'description': 'Red zone conversion percentile rank'},
    'explosive_rank': {'name': 'Expl Rank', 'format': 'percentage', 'description': 'Explosive rate percentile rank'},
    'sep_rank': {'name': 'Sep Rank', 'format': 'percentage', 'description': 'Separation percentile rank'},
    'intended_air_rank': {'name': 'aDOT Rank', 'format': 'percentage', 'description': 'Air yards percentile rank'},
    'catch_rank': {'name': 'Catch Rank', 'format': 'percentage', 'description': 'Catch percentage percentile rank'},
    'third_down_rank': {'name': '3rd Rank', 'format': 'percentage', 'description': 'Third down rate percentile rank'},
    'yacOE_rank': {'name': 'YAC+ Rank', 'format': 'percentage', 'description': 'YAC above expected percentile rank'},
  };

  static const Map<String, Map<String, dynamic>> _teStatFields = {
    // Raw stats
    'totalEPA': {'name': 'EPA', 'format': 'decimal1', 'description': 'Total Expected Points Added'},
    'totalTD': {'name': 'TDs', 'format': 'decimal1', 'description': 'Total touchdowns'},
    'tgt_share': {'name': 'Tgt Share', 'format': 'percentage', 'description': 'Team target share'},
    'numYards': {'name': 'Yards', 'format': 'integer', 'description': 'Receiving yards'},
    'numGames': {'name': 'Games', 'format': 'integer', 'description': 'Games played'},
    'numRec': {'name': 'Rec', 'format': 'integer', 'description': 'Total receptions'},
    'conversion': {'name': 'RZ Conv', 'format': 'percentage', 'description': 'Red zone conversion rate'},
    'explosive_rate': {'name': 'Expl Rate', 'format': 'percentage', 'description': 'Explosive play rate (15+ yards)'},
    'avg_separation': {'name': 'Sep', 'format': 'decimal1', 'description': 'Average separation'},
    'avg_intended_air_yards': {'name': 'aDOT', 'format': 'decimal1', 'description': 'Average intended air yards'},
    'catch_percentage': {'name': 'Catch %', 'format': 'percentage', 'description': 'Catch percentage'},
    'yac_above_expected': {'name': 'YAC+', 'format': 'decimal1', 'description': 'YAC above expected'},
    'third_down_rate': {'name': '3rd Down', 'format': 'percentage', 'description': 'Third down conversion rate'},
    // Rank fields
    'EPA_rank': {'name': 'EPA Rank', 'format': 'percentage', 'description': 'EPA percentile rank'},
    'td_rank': {'name': 'TD Rank', 'format': 'percentage', 'description': 'TD percentile rank'},
    'tgt_rank': {'name': 'Tgt Rank', 'format': 'percentage', 'description': 'Target share percentile rank'},
    'YPG_rank': {'name': 'YPG Rank', 'format': 'percentage', 'description': 'Yards per game percentile rank'},
    'conversion_rank': {'name': 'RZ Rank', 'format': 'percentage', 'description': 'Red zone conversion percentile rank'},
    'explosive_rank': {'name': 'Expl Rank', 'format': 'percentage', 'description': 'Explosive rate percentile rank'},
    'sep_rank': {'name': 'Sep Rank', 'format': 'percentage', 'description': 'Separation percentile rank'},
    'intended_air_rank': {'name': 'aDOT Rank', 'format': 'percentage', 'description': 'Air yards percentile rank'},
    'catch_rank': {'name': 'Catch Rank', 'format': 'percentage', 'description': 'Catch percentage percentile rank'},
    'third_down_rank': {'name': '3rd Rank', 'format': 'percentage', 'description': 'Third down rate percentile rank'},
    'yacOE_rank': {'name': 'YAC+ Rank', 'format': 'percentage', 'description': 'YAC above expected percentile rank'},
    // Final ranking
    'myRank': {'name': 'Rank Score', 'format': 'decimal3', 'description': 'Composite ranking score'},
    'myRankNum': {'name': 'Rank', 'format': 'integer', 'description': 'Overall ranking'},
  };

  static const Map<String, Map<String, dynamic>> _qbStatFields = {
    'total_epa': {'name': 'EPA', 'format': 'decimal1', 'description': 'Total Expected Points Added'},
    'yards_per_game': {'name': 'YPG', 'format': 'decimal1', 'description': 'Yards per game'},
    'tds_per_game': {'name': 'TD/G', 'format': 'decimal1', 'description': 'Touchdowns per game'},
    'ints_per_game': {'name': 'INT/G', 'format': 'decimal1', 'description': 'Interceptions per game'},
    'avg_cpoe': {'name': 'CPOE', 'format': 'decimal1', 'description': 'Completion percentage over expected'},
    'third_down_conversion_rate': {'name': '3rd Down %', 'format': 'percentage', 'description': 'Third down conversion rate'},
    'actualization': {'name': 'Actualization', 'format': 'decimal2', 'description': 'Actualization rate'},
    'pass_attempts': {'name': 'Attempts', 'format': 'integer', 'description': 'Pass attempts'},
    'games': {'name': 'Games', 'format': 'integer', 'description': 'Games played'},
    'myRank': {'name': 'Rank Score', 'format': 'decimal4', 'description': 'Composite ranking score'},
    // Rank fields
    'EPA_rank': {'name': 'EPA Rank', 'format': 'percentage', 'description': 'EPA percentile rank'},
    'YPG_rank': {'name': 'YPG Rank', 'format': 'percentage', 'description': 'Yards per game percentile rank'},
    'TD_rank': {'name': 'TD Rank', 'format': 'percentage', 'description': 'TD percentile rank'},
    'third_rank': {'name': '3rd Rank', 'format': 'percentage', 'description': 'Third down rate percentile rank'},
    'CPOE_rank': {'name': 'CPOE Rank', 'format': 'percentage', 'description': 'CPOE percentile rank'},
    'actualization_rank': {'name': 'Act Rank', 'format': 'percentage', 'description': 'Actualization percentile rank'},
  };

  // Get stat fields for a specific position
  static Map<String, Map<String, dynamic>> getStatFields(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return {..._baseStatFields, ..._qbStatFields};
      case 'rb':
        return {..._baseStatFields, ..._rbStatFields};
      case 'wr':
        return {..._baseStatFields, ..._wrStatFields};
      case 'te':
        return {..._baseStatFields, ..._teStatFields};
      default:
        return _baseStatFields;
    }
  }

  // Get collection name for position with fallback
  static String getCollectionName(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return 'qb_rankings_comprehensive';
      case 'rb':
        return 'rb_rankings_comprehensive';
      case 'wr':
        return 'wr_rankings_comprehensive'; 
      case 'te':
        return 'te_rankings_comprehensive';
      default:
        return 'rankings';
    }
  }
  
  // Get fallback collection name if comprehensive doesn't exist
  static String getFallbackCollectionName(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return 'qbRankings';
      case 'rb':
        return 'rb_rankings';
      case 'wr':
        return 'wrRankings';
      case 'te':
        return 'te_rankings';
      default:
        return 'rankings';
    }
  }

  // Load rankings for a specific position with fallback
  static Future<List<Map<String, dynamic>>> loadRankings({
    required String position,
    String? season,
    String? tier,
  }) async {
    try {
      // Try comprehensive collection first
      String collectionName = getCollectionName(position);
      Query query = _firestore.collection(collectionName);
      
      QuerySnapshot snapshot;
      try {
        snapshot = await query.limit(1).get();
        if (snapshot.docs.isEmpty) {
          // If comprehensive collection is empty, try fallback
          collectionName = getFallbackCollectionName(position);
          query = _firestore.collection(collectionName);
        }
      } catch (e) {
        // If comprehensive collection doesn't exist, use fallback
        collectionName = getFallbackCollectionName(position);
        query = _firestore.collection(collectionName);
      }
      
      // Apply season filter
      if (season != null && season != 'All Seasons') {
        final seasonInt = int.tryParse(season);
        if (seasonInt != null) {
          query = query.where('season', isEqualTo: seasonInt);
        }
      }
      
      snapshot = await query.get();
      final rankings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
      
      // Apply tier filter
      if (tier != null && tier != 'All') {
        final tierInt = int.tryParse(tier.split(' ').last);
        if (tierInt != null) {
          // Try different tier field names depending on position
          return rankings.where((player) {
            if (position.toLowerCase() == 'qb') {
              return player['qb_tier'] == tierInt || player['qbTier'] == tierInt || player['tier'] == tierInt;
            } else {
              return player['qbTier'] == tierInt || player['tier'] == tierInt;
            }
          }).toList();
        }
      }
      
      return rankings;
    } catch (e) {
      throw Exception('Failed to load $position rankings: $e');
    }
  }

  // Calculate percentiles for stats
  static Map<String, Map<double, double>> calculatePercentiles(
    List<Map<String, dynamic>> data,
    List<String> statFields,
  ) {
    final Map<String, Map<double, double>> percentileCache = {};
    
    for (final field in statFields) {
      // Skip string fields that shouldn't be processed as numbers
      if (_isStringField(field)) {
        continue;
      }
      
      final values = data
          .map((player) {
            final value = player[field];
            if (value is num) {
              return value.toDouble();
            } else if (value is String) {
              return double.tryParse(value) ?? 0.0;
            }
            return 0.0;
          })
          .where((val) => val.isFinite)
          .toList();
          
      if (values.isNotEmpty) {
        values.sort();
        final Map<double, double> percentiles = {};
        
        for (final player in data) {
          final value = player[field];
          double numValue = 0.0;
          if (value is num) {
            numValue = value.toDouble();
          } else if (value is String) {
            numValue = double.tryParse(value) ?? 0.0;
          }
          
          if (numValue.isFinite) {
            final rank = values.indexOf(numValue) + 1;
            final percentile = rank / values.length;
            percentiles[numValue] = percentile;
          }
        }
        
        percentileCache[field] = percentiles;
      }
    }
    
    return percentileCache;
  }

  // Helper method to identify string fields that shouldn't be processed as numbers
  static bool _isStringField(String field) {
    const stringFields = {
      'player_name',
      'receiver_player_name', 
      'passer_player_name',
      'team',
      'posteam',
      'player_position',
      'position',
      'player_id',
      'receiver_player_id',
      'passer_player_id',
      'id'
    };
    return stringFields.contains(field);
  }

  // Format stat value based on format type
  static String formatStatValue(dynamic value, String format) {
    if (value == null) return '-';
    
    // If it's already a string, return it as-is for string format
    if (format == 'string') {
      return value.toString();
    }
    
    // Try to convert to number for numeric formats
    double numValue;
    if (value is num) {
      numValue = value.toDouble();
    } else if (value is String) {
      numValue = double.tryParse(value) ?? 0.0;
    } else {
      return value.toString();
    }
    
    switch (format) {
      case 'percentage':
        return '${(numValue * 100).toStringAsFixed(1)}%';
      case 'decimal1':
        return numValue.toStringAsFixed(1);
      case 'decimal2':
        return numValue.toStringAsFixed(2);
      case 'decimal3':
        return numValue.toStringAsFixed(3);
      case 'decimal4':
        return numValue.toStringAsFixed(4);
      case 'integer':
        return numValue.toInt().toString();
      default:
        return value.toString();
    }
  }

  // Get tier color
  static Map<int, int> getTierColors() {
    return {
      1: 0xFF7C3AED, // Purple
      2: 0xFF2563EB, // Blue  
      3: 0xFF059669, // Green
      4: 0xFFD97706, // Orange
      5: 0xFFDC2626, // Red
      6: 0xFF7C2D12, // Brown
      7: 0xFF374151, // Gray
      8: 0xFF1F2937, // Dark gray
    };
  }

  // Season options
  static List<String> getSeasonOptions() {
    return ['All Seasons', '2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016'];
  }

  // Tier options  
  static List<String> getTierOptions() {
    return ['All', 'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4', 'Tier 5', 'Tier 6', 'Tier 7', 'Tier 8'];
  }
}