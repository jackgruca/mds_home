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
  // RB raw stat fields (for raw stats view)
  static const Map<String, Map<String, dynamic>> _rbRawStatFields = {
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
  };
  
  // RB rank fields (for ranks view)
  static const Map<String, Map<String, dynamic>> _rbRankFields = {
    'EPA_rank_num': {'name': 'EPA Rank', 'format': 'rank', 'description': 'EPA rank number'},
    'td_rank_num': {'name': 'TD Rank', 'format': 'rank', 'description': 'TD rank number'},
    'run_rank_num': {'name': 'Rush Rank', 'format': 'rank', 'description': 'Rush share rank number'},
    'YPG_rank_num': {'name': 'YPG Rank', 'format': 'rank', 'description': 'Yards per game rank number'},
    'tgt_rank_num': {'name': 'Tgt Rank', 'format': 'rank', 'description': 'Target share rank number'},
    'third_rank_num': {'name': '3rd Rank', 'format': 'rank', 'description': 'Third down rate rank number'},
    'conversion_rank_num': {'name': 'RZ Rank', 'format': 'rank', 'description': 'Red zone conversion rank number'},
    'explosive_rank_num': {'name': 'Expl Rank', 'format': 'rank', 'description': 'Explosive rate rank number'},
    'RYOE_rank_num': {'name': 'RYOE Rank', 'format': 'rank', 'description': 'RYOE rank number'},
    'eff_rank_num': {'name': 'Eff Rank', 'format': 'rank', 'description': 'Efficiency rank number'},
  };

  // WR raw stat fields (for raw stats view)
  static const Map<String, Map<String, dynamic>> _wrRawStatFields = {
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
  };
  
  // WR rank fields (for ranks view)
  static const Map<String, Map<String, dynamic>> _wrRankFields = {
    'EPA_rank_num': {'name': 'EPA Rank', 'format': 'rank', 'description': 'EPA rank number'},
    'td_rank_num': {'name': 'TD Rank', 'format': 'rank', 'description': 'TD rank number'},
    'tgt_rank_num': {'name': 'Tgt Rank', 'format': 'rank', 'description': 'Target share rank number'},
    'YPG_rank_num': {'name': 'YPG Rank', 'format': 'rank', 'description': 'Yards per game rank number'},
    'conversion_rank_num': {'name': 'RZ Rank', 'format': 'rank', 'description': 'Red zone conversion rank number'},
    'explosive_rank_num': {'name': 'Expl Rank', 'format': 'rank', 'description': 'Explosive rate rank number'},
    'sep_rank_num': {'name': 'Sep Rank', 'format': 'rank', 'description': 'Separation rank number'},
    'intended_air_rank_num': {'name': 'aDOT Rank', 'format': 'rank', 'description': 'Air yards rank number'},
    'catch_rank_num': {'name': 'Catch Rank', 'format': 'rank', 'description': 'Catch percentage rank number'},
    'third_down_rank_num': {'name': '3rd Rank', 'format': 'rank', 'description': 'Third down rate rank number'},
    'yacOE_rank_num': {'name': 'YAC+ Rank', 'format': 'rank', 'description': 'YAC above expected rank number'},
  };

  // TE raw stat fields (for raw stats view)
  static const Map<String, Map<String, dynamic>> _teRawStatFields = {
    'totalEPA': {'name': 'EPA', 'format': 'decimal1', 'description': 'Total Expected Points Added'},
    'totalTD': {'name': 'TDs', 'format': 'decimal1', 'description': 'Total touchdowns'},
    'tgt_share': {'name': 'Tgt Share', 'format': 'percentage', 'description': 'Team target share'},
    'numYards': {'name': 'Yards', 'format': 'integer', 'description': 'Receiving yards'},
    'numRec': {'name': 'Rec', 'format': 'integer', 'description': 'Total receptions'},
    'conversion': {'name': 'RZ Conv', 'format': 'percentage', 'description': 'Red zone conversion rate'},
    'explosive_rate': {'name': 'Expl Rate', 'format': 'percentage', 'description': 'Explosive play rate (15+ yards)'},
    'avg_separation': {'name': 'Sep', 'format': 'decimal1', 'description': 'Average separation'},
    'avg_intended_air_yards': {'name': 'aDOT', 'format': 'decimal1', 'description': 'Average intended air yards'},
    'catch_percentage': {'name': 'Catch %', 'format': 'percentage', 'description': 'Catch percentage'},
    'yac_above_expected': {'name': 'YAC+', 'format': 'decimal1', 'description': 'YAC above expected'},
    'third_down_rate': {'name': '3rd Down', 'format': 'percentage', 'description': 'Third down conversion rate'},
  };
  
  // TE rank fields (for ranks view)
  static const Map<String, Map<String, dynamic>> _teRankFields = {
    'EPA_rank_num': {'name': 'EPA Rank', 'format': 'rank', 'description': 'EPA rank number'},
    'td_rank_num': {'name': 'TD Rank', 'format': 'rank', 'description': 'TD rank number'},
    'tgt_rank_num': {'name': 'Tgt Rank', 'format': 'rank', 'description': 'Target share rank number'},
    'YPG_rank_num': {'name': 'YPG Rank', 'format': 'rank', 'description': 'Yards per game rank number'},
    'conversion_rank_num': {'name': 'RZ Rank', 'format': 'rank', 'description': 'Red zone conversion rank number'},
    'explosive_rank_num': {'name': 'Expl Rank', 'format': 'rank', 'description': 'Explosive rate rank number'},
    'sep_rank_num': {'name': 'Sep Rank', 'format': 'rank', 'description': 'Separation rank number'},
    'intended_air_rank_num': {'name': 'aDOT Rank', 'format': 'rank', 'description': 'Air yards rank number'},
    'catch_rank_num': {'name': 'Catch Rank', 'format': 'rank', 'description': 'Catch percentage rank number'},
    'third_down_rank_num': {'name': '3rd Rank', 'format': 'rank', 'description': 'Third down rate rank number'},
    'yacOE_rank_num': {'name': 'YAC+ Rank', 'format': 'rank', 'description': 'YAC above expected rank number'},
  };

  // QB raw stat fields (for raw stats view)
  static const Map<String, Map<String, dynamic>> _qbRawStatFields = {
    'ctotalEPA': {'name': 'Total EPA', 'format': 'decimal1', 'description': 'Combined passing and rushing EPA'},
    'ctotalEP': {'name': 'Total EP', 'format': 'decimal1', 'description': 'Combined passing and rushing Expected Points'},
    'cCPOE': {'name': 'CPOE', 'format': 'decimal3', 'description': 'Completion percentage over expected'},
    'cactualization': {'name': 'Actualization', 'format': 'decimal3', 'description': 'Actualization rate'},
    'cYPG': {'name': 'YPG', 'format': 'decimal1', 'description': 'Combined passing and rushing yards per game'},
    'cTDperGame': {'name': 'TD/G', 'format': 'decimal2', 'description': 'Combined passing and rushing touchdowns per game'},
    'intPerGame': {'name': 'INT/G', 'format': 'decimal2', 'description': 'Interceptions per game'},
    'cthirdConvert': {'name': '3rd Down %', 'format': 'percentage', 'description': 'Third down conversion rate'},
  };
  
  // QB rank fields (for ranks view)
  static const Map<String, Map<String, dynamic>> _qbRankFields = {
    'EPA_rank_num': {'name': 'EPA Rank', 'format': 'rank', 'description': 'EPA rank number'},
    'EP_rank_num': {'name': 'EP Rank', 'format': 'rank', 'description': 'Expected Points rank number'},
    'CPOE_rank_num': {'name': 'CPOE Rank', 'format': 'rank', 'description': 'CPOE rank number'},
    'YPG_rank_num': {'name': 'YPG Rank', 'format': 'rank', 'description': 'Yards per game rank number'},
    'TD_rank_num': {'name': 'TD Rank', 'format': 'rank', 'description': 'TD rank number'},
    'actualization_rank_num': {'name': 'Act Rank', 'format': 'rank', 'description': 'Actualization rank number'},
    'int_rank_num': {'name': 'INT Rank', 'format': 'rank', 'description': 'Interception rate rank number'},
    'third_rank_num': {'name': '3rd Rank', 'format': 'rank', 'description': 'Third down rate rank number'},
  };

  // Get raw stat fields for a specific position (for raw stats view)
  static Map<String, Map<String, dynamic>> getRawStatFields(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return {..._baseStatFields, ..._qbRawStatFields};
      case 'rb':
        return {..._baseStatFields, ..._rbRawStatFields};
      case 'wr':
        return {..._baseStatFields, ..._wrRawStatFields};
      case 'te':
        return {..._baseStatFields, ..._teRawStatFields};
      default:
        return _baseStatFields;
    }
  }
  
  // Get rank fields for a specific position (for ranks view)
  static Map<String, Map<String, dynamic>> getRankFields(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return {..._baseStatFields, ..._qbRankFields};
      case 'rb':
        return {..._baseStatFields, ..._rbRankFields};
      case 'wr':
        return {..._baseStatFields, ..._wrRankFields};
      case 'te':
        return {..._baseStatFields, ..._teRankFields};
      default:
        return _baseStatFields;
    }
  }
  
  // Get stat fields for a specific position (backwards compatibility)
  static Map<String, Map<String, dynamic>> getStatFields(String position, {bool showRanks = false}) {
    return showRanks ? getRankFields(position) : getRawStatFields(position);
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
      case 'rank':
        return '#${numValue.toInt()}';
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