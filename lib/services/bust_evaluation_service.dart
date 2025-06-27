import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bust_evaluation.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart';

class BustEvaluationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static List<BustEvaluationPlayer>? _cachedPlayers;
  static List<BustTimelineData>? _cachedTimeline;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(hours: 1);

  // Search players by name with fuzzy matching
  static Future<List<BustEvaluationPlayer>> searchPlayers(String query) async {
    if (query.isEmpty) return [];
    
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    final lowercaseQuery = query.toLowerCase();
    return _cachedPlayers!.where((player) {
      return player.playerName.toLowerCase().contains(lowercaseQuery);
    }).take(20).toList(); // Limit to 20 results for performance
  }

  // Get all players (for random selection, etc.)
  static Future<List<BustEvaluationPlayer>> getAllPlayers() async {
    await _ensureDataCached();
    return _cachedPlayers ?? [];
  }

  // Get players by position
  static Future<List<BustEvaluationPlayer>> getPlayersByPosition(String position) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    return _cachedPlayers!.where((player) => player.position == position).toList();
  }

  // Get players by draft round
  static Future<List<BustEvaluationPlayer>> getPlayersByDraftRound(int round) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    return _cachedPlayers!.where((player) => player.draftRound == round).toList();
  }

  // Get players by bust category
  static Future<List<BustEvaluationPlayer>> getPlayersByCategory(String category) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    return _cachedPlayers!.where((player) => player.bustCategory == category).toList();
  }

  // Get a specific player by ID
  static Future<BustEvaluationPlayer?> getPlayer(String gsisId) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return null;

    try {
      return _cachedPlayers!.firstWhere((player) => player.gsisId == gsisId);
    } catch (e) {
      return null;
    }
  }

  // Get timeline data for a specific player
  static Future<List<BustTimelineData>> getPlayerTimeline(String gsisId) async {
    await _ensureTimelineCached();
    if (_cachedTimeline == null) return [];

    return _cachedTimeline!.where((data) => data.gsisId == gsisId).toList()
      ..sort((a, b) => a.leagueYear.compareTo(b.leagueYear));
  }

  // Get random controversial players (those with interesting stories)
  static Future<List<BustEvaluationPlayer>> getRandomControversialPlayers() async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    // Filter for players that are either significant busts or steals from early rounds
    final controversial = _cachedPlayers!.where((player) {
      return (player.draftRound <= 3 && player.bustCategory == 'Bust') ||
             (player.draftRound >= 4 && player.bustCategory == 'Steal') ||
             (player.performanceScore != null && 
              (player.performanceScore! < 0.4 || player.performanceScore! > 1.8));
    }).toList();

    controversial.shuffle();
    return controversial.take(10).toList();
  }

  // Get top performers by position
  static Future<List<BustEvaluationPlayer>> getTopPerformers(String position, {int limit = 10}) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    final positionPlayers = _cachedPlayers!.where((player) => 
      player.position == position && player.performanceScore != null
    ).toList();

    positionPlayers.sort((a, b) => 
      (b.performanceScore ?? 0).compareTo(a.performanceScore ?? 0)
    );

    return positionPlayers.take(limit).toList();
  }

  // Get biggest busts by position
  static Future<List<BustEvaluationPlayer>> getBiggestBusts(String position, {int limit = 10}) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    final positionPlayers = _cachedPlayers!.where((player) => 
      player.position == position && 
      player.performanceScore != null &&
      player.draftRound <= 3 // Only early round picks can be true "busts"
    ).toList();

    positionPlayers.sort((a, b) => 
      (a.performanceScore ?? 0).compareTo(b.performanceScore ?? 0)
    );

    return positionPlayers.take(limit).toList();
  }

  // Get players from a specific draft class
  static Future<List<BustEvaluationPlayer>> getDraftClass(int year) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    return _cachedPlayers!.where((player) => player.rookieYear == year).toList()
      ..sort((a, b) => a.draftRound.compareTo(b.draftRound));
  }

  // Get statistics about the dataset
  static Future<Map<String, dynamic>> getDatasetStats() async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return {};

    final players = _cachedPlayers!;
    final positionCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final roundCounts = <int, int>{};

    for (final player in players) {
      positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
      categoryCounts[player.bustCategory] = (categoryCounts[player.bustCategory] ?? 0) + 1;
      roundCounts[player.draftRound] = (roundCounts[player.draftRound] ?? 0) + 1;
    }

    return {
      'total_players': players.length,
      'positions': positionCounts,
      'categories': categoryCounts,
      'rounds': roundCounts,
      'years_covered': '2010-2024',
    };
  }

  // Private method to ensure player data is cached
  static Future<void> _ensureDataCached() async {
    if (_cachedPlayers != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry) {
      return; // Cache is still valid
    }

    try {
      print('🔄 Loading bust evaluation data from Firestore...');
      final querySnapshot = await _firestore
          .collection('bust_evaluation')
          .orderBy('performance_score', descending: true)
          .get();

      _cachedPlayers = querySnapshot.docs
          .map((doc) => BustEvaluationPlayer.fromMap(doc.data()))
          .toList();

      _lastCacheUpdate = DateTime.now();
      print('✅ Loaded ${_cachedPlayers!.length} players');
    } catch (e) {
      print('❌ Error loading bust evaluation data: $e');
      _cachedPlayers = [];
    }
  }

  // Private method to ensure timeline data is cached
  static Future<void> _ensureTimelineCached() async {
    if (_cachedTimeline != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry) {
      return; // Cache is still valid
    }

    try {
      print('🔄 Loading timeline data from Firestore...');
      final querySnapshot = await _firestore
          .collection('bust_evaluation_timeline')
          .orderBy('league_year')
          .get();

      _cachedTimeline = querySnapshot.docs
          .map((doc) => BustTimelineData.fromMap(doc.data()))
          .toList();

      print('✅ Loaded ${_cachedTimeline!.length} timeline records');
    } catch (e) {
      print('❌ Error loading timeline data: $e');
      _cachedTimeline = [];
    }
  }

  // Clear cache (useful for testing or forcing refresh)
  static void clearCache() {
    _cachedPlayers = null;
    _cachedTimeline = null;
    _lastCacheUpdate = null;
  }

  // Get suggested players based on current search/filters
  static Future<List<BustEvaluationPlayer>> getSuggestedPlayers({
    String? position,
    String? category,
    int? round,
  }) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];

    var filtered = _cachedPlayers!.where((player) {
      if (position != null && player.position != position) return false;
      if (category != null && player.bustCategory != category) return false;
      if (round != null && player.draftRound != round) return false;
      return true;
    }).toList();

    // Sort by performance score and return interesting cases
    filtered.sort((a, b) => (b.performanceScore ?? 0).compareTo(a.performanceScore ?? 0));
    
    // Mix of top and bottom performers for variety
    final suggestions = <BustEvaluationPlayer>[];
    if (filtered.length > 10) {
      suggestions.addAll(filtered.take(5)); // Top performers
      suggestions.addAll(filtered.skip(filtered.length - 5)); // Bottom performers
    } else {
      suggestions.addAll(filtered);
    }

    return suggestions;
  }

  // Get players similar to the given player (same position and draft round)
  static Future<List<BustEvaluationPlayer>> getSimilarPlayers(
    BustEvaluationPlayer player, {
    int limit = 5,
  }) async {
    await _ensureDataCached();
    if (_cachedPlayers == null) return [];
    
    // Filter for same position and draft round, excluding the player themselves
    final similarPlayers = _cachedPlayers!.where((p) => 
      p.position == player.position && 
      p.draftRound == player.draftRound &&
      p.gsisId != player.gsisId &&
      p.seasonsPlayed >= 3 // Only include players with sufficient career data
    ).toList();
    
    // Sort by performance score (best to worst)
    similarPlayers.sort((a, b) {
      final aScore = a.performanceScore ?? 0;
      final bScore = b.performanceScore ?? 0;
      return bScore.compareTo(aScore);
    });
    
    // Return up to the limit, but ensure we get a good spread
    final result = <BustEvaluationPlayer>[];
    final categories = <String, List<BustEvaluationPlayer>>{};
    
    // Group by bust category
    for (final p in similarPlayers) {
      categories.putIfAbsent(p.bustCategory, () => []).add(p);
    }
    
    // Try to get representatives from each category
    final categoryOrder = ['Steal', 'Met Expectations', 'Disappointing', 'Bust'];
    for (final category in categoryOrder) {
      final playersInCategory = categories[category] ?? [];
      if (playersInCategory.isNotEmpty && result.length < limit) {
        result.add(playersInCategory.first);
      }
    }
    
    // Fill remaining slots with best available
    for (final p in similarPlayers) {
      if (!result.contains(p) && result.length < limit) {
        result.add(p);
      }
    }
    
    return result.take(limit).toList();
  }

  // Get comparison stats for similar players
  static Future<List<Map<String, dynamic>>> getSimilarPlayerStats(
    BustEvaluationPlayer player,
  ) async {
    final similarPlayers = await getSimilarPlayers(player);
    
    return similarPlayers.map((p) => {
      'player': p, // Return the actual player object
      'name': p.playerName,
      'draft_info': '${p.position} • R${p.draftRound} (${p.rookieYear})',
      'seasons': p.seasonsPlayed,
      'performance_score': p.performanceScore,
      'category': p.bustCategory,
      'key_stats': _getKeyStatsForPosition(p),
    }).toList();
  }

  static Map<String, dynamic> _getKeyStatsForPosition(BustEvaluationPlayer player) {
    switch (player.position) {
      case 'WR':
      case 'TE':
        return {
          'rec_yds': player.careerRecYds.toInt(),
          'receptions': player.careerReceptions.toInt(),
          'rec_tds': player.careerRecTd.toInt(),
          'targets': player.careerTargets.toInt(),
        };
      case 'RB':
        return {
          'rush_yds': player.careerRushYds.toInt(),
          'rec_yds': player.careerRecYds.toInt(),
          'total_tds': (player.careerRushTd + player.careerRecTd).toInt(),
          'carries': player.careerCarries.toInt(),
        };
      case 'QB':
        return {
          'pass_yds': player.careerPassYds.toInt(),
          'pass_tds': player.careerPassTd.toInt(),
          'interceptions': player.careerInt.toInt(),
          'attempts': player.careerAttempts.toInt(),
        };
      default:
        return {};
    }
  }
} 