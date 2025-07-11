import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds_home/models/fantasy/player_ranking.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';

class EnhancedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for player data to avoid repeated Firebase calls
  static final Map<String, List<PlayerRanking>> _playerCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(hours: 1);

  Future<List<PlayerRanking>> getPlayersForPosition(String position) async {
    // Check cache first
    if (_playerCache.containsKey(position) && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry) {
      return _playerCache[position]!;
    }

    try {
      // Fetch from Firebase playerSeasonStats collection
      final querySnapshot = await _firestore
          .collection('playerSeasonStats')
          .where('position', isEqualTo: position)
          .where('season', isEqualTo: 2024) // Current season
          .orderBy('fantasy_points_ppr', descending: true)
          .limit(100) // Top 100 players per position
          .get();

      final players = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PlayerRanking(
          id: doc.id,
          name: data['player_display_name'] ?? data['player_name'] ?? 'Unknown',
          position: data['position'] ?? position,
          team: data['recent_team'] ?? 'UNK',
          rank: 0, // Will be calculated
          source: 'firebase',
          lastUpdated: DateTime.now(),
          stats: _extractStats(data),
          additionalRanks: _extractAdditionalRanks(data),
        );
      }).toList();

      // Cache the results
      _playerCache[position] = players;
      _lastCacheUpdate = DateTime.now();

      return players;
    } catch (e) {
      print('Error fetching players for position $position: $e');
      return [];
    }
  }

  Map<String, double> _extractStats(Map<String, dynamic> data) {
    final stats = <String, double>{};
    
    // Extract all numeric fields as stats
    for (final entry in data.entries) {
      if (entry.value is num) {
        stats[entry.key] = (entry.value as num).toDouble();
      }
    }
    
    return stats;
  }

  Map<String, dynamic> _extractAdditionalRanks(Map<String, dynamic> data) {
    final additionalRanks = <String, dynamic>{};
    
    // Copy all data as additional ranks for flexibility
    for (final entry in data.entries) {
      additionalRanks[entry.key] = entry.value;
    }
    
    return additionalRanks;
  }

  // Get all available stat fields for a position
  Future<List<String>> getAvailableStatsForPosition(String position) async {
    try {
      final querySnapshot = await _firestore
          .collection('playerSeasonStats')
          .where('position', isEqualTo: position)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return data.keys.where((key) => 
          key != 'player_id' && 
          key != 'player_name' && 
          key != 'player_display_name' &&
          key != 'player_display_name_lower' &&
          key != 'position' &&
          key != 'recent_team' &&
          key != 'season' &&
          data[key] is num
        ).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching available stats: $e');
      return [];
    }
  }

  // Get stat value for a specific player and attribute
  Future<double> getStatValue(PlayerRanking player, String statName) async {
    // First check player's stats
    if (player.stats.containsKey(statName)) {
      return player.stats[statName]!;
    }
    
    // Then check additional ranks
    if (player.additionalRanks.containsKey(statName)) {
      final value = player.additionalRanks[statName];
      if (value is num) return value.toDouble();
    }
    
    return 0.0;
  }

  // Get percentile ranking for a stat value within a position
  Future<double> getPercentileRanking(String position, String statName, double value) async {
    try {
      final players = await getPlayersForPosition(position);
      final values = players
          .map((p) => p.stats[statName] ?? 0.0)
          .where((v) => v > 0)
          .toList();
      
      if (values.isEmpty) return 0.5;
      
      values.sort();
      final index = values.indexWhere((v) => v >= value);
      
      if (index == -1) return 1.0; // Higher than all values
      
      return index / values.length;
    } catch (e) {
      print('Error calculating percentile: $e');
      return 0.5;
    }
  }

  // Get raw stat value for a player and attribute
  Future<double?> getPlayerStatValue(PlayerRanking player, EnhancedRankingAttribute attribute) async {
    // Try to get the stat value using the attribute's CSV mappings
    for (final mapping in attribute.csvMappings) {
      if (player.stats.containsKey(mapping)) {
        return player.stats[mapping];
      }
      if (player.additionalRanks.containsKey(mapping)) {
        final value = player.additionalRanks[mapping];
        if (value is num) return value.toDouble();
      }
    }
    
    // Try using the attribute name directly
    if (player.stats.containsKey(attribute.name)) {
      return player.stats[attribute.name];
    }
    if (player.additionalRanks.containsKey(attribute.name)) {
      final value = player.additionalRanks[attribute.name];
      if (value is num) return value.toDouble();
    }
    
    return null;
  }

  // Get normalized stat value (0-1 scale) for ranking purposes
  Future<double> getNormalizedStatValue(
    PlayerRanking player,
    EnhancedRankingAttribute attribute,
    String position,
  ) async {
    final rawValue = await getPlayerStatValue(player, attribute);
    if (rawValue == null) return 0.0;
    
    // Get all players for this position to calculate normalization
    final players = await getPlayersForPosition(position);
    final values = <double>[];
    
    for (final p in players) {
      final value = await getPlayerStatValue(p, attribute);
      if (value != null && value > 0) {
        values.add(value);
      }
    }
    
    if (values.isEmpty) return 0.0;
    
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    
    // Avoid division by zero
    if (maxValue == minValue) return 0.5;
    
    // Normalize to 0-1 scale
    double normalized = (rawValue - minValue) / (maxValue - minValue);
    
    // Handle inverse calculations (like interceptions, where lower is better)
    if (attribute.calculationType == 'inverse') {
      normalized = 1.0 - normalized;
    }
    
    return normalized.clamp(0.0, 1.0);
  }

  // Clear cache to force refresh
  void clearCache() {
    _playerCache.clear();
    _lastCacheUpdate = null;
  }
}