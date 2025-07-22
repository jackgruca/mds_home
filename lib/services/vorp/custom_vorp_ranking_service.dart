import 'dart:convert';
import 'dart:html' as html;
import '../../models/vorp/custom_position_ranking.dart';

class CustomVorpRankingService {
  static const String _storageKey = 'custom_vorp_rankings';
  static const String _bigBoardStorageKey = 'custom_big_boards';
  static const String _defaultUserId = 'anonymous_user'; // For MVP without auth

  // Get all custom position rankings
  Future<List<CustomPositionRanking>> getAllRankings() async {
    try {
      final storage = html.window.localStorage;
      final rankingsJson = storage[_storageKey];
      
      if (rankingsJson == null || rankingsJson.isEmpty) {
        return [];
      }

      final List<dynamic> rankingsList = json.decode(rankingsJson);
      return rankingsList
          .map((ranking) => CustomPositionRanking.fromJson(ranking as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading custom rankings: $e');
      return [];
    }
  }

  // Get rankings for a specific position
  Future<List<CustomPositionRanking>> getRankingsByPosition(String position) async {
    final allRankings = await getAllRankings();
    return allRankings.where((ranking) => ranking.position == position).toList();
  }

  // Get a specific ranking by ID
  Future<CustomPositionRanking?> getRankingById(String id) async {
    final allRankings = await getAllRankings();
    return allRankings.where((ranking) => ranking.id == id).firstOrNull;
  }

  // Save a new custom ranking
  Future<bool> saveRanking(CustomPositionRanking ranking) async {
    try {
      final allRankings = await getAllRankings();
      
      // Check if ranking with this ID already exists
      final existingIndex = allRankings.indexWhere((r) => r.id == ranking.id);
      
      if (existingIndex != -1) {
        // Update existing ranking
        allRankings[existingIndex] = ranking.copyWith(updatedAt: DateTime.now());
      } else {
        // Add new ranking
        allRankings.add(ranking);
      }

      // Save to localStorage
      final storage = html.window.localStorage;
      storage[_storageKey] = json.encode(allRankings.map((r) => r.toJson()).toList());
      
      return true;
    } catch (e) {
      print('Error saving custom ranking: $e');
      return false;
    }
  }

  // Update an existing ranking
  Future<bool> updateRanking(String id, CustomPositionRanking updatedRanking) async {
    try {
      final allRankings = await getAllRankings();
      final index = allRankings.indexWhere((r) => r.id == id);
      
      if (index == -1) {
        return false; // Ranking not found
      }

      allRankings[index] = updatedRanking.copyWith(
        id: id, // Ensure ID remains the same
        updatedAt: DateTime.now(),
      );

      final storage = html.window.localStorage;
      storage[_storageKey] = json.encode(allRankings.map((r) => r.toJson()).toList());
      
      return true;
    } catch (e) {
      print('Error updating custom ranking: $e');
      return false;
    }
  }

  // Delete a ranking
  Future<bool> deleteRanking(String id) async {
    try {
      final allRankings = await getAllRankings();
      allRankings.removeWhere((ranking) => ranking.id == id);

      final storage = html.window.localStorage;
      storage[_storageKey] = json.encode(allRankings.map((r) => r.toJson()).toList());
      
      return true;
    } catch (e) {
      print('Error deleting custom ranking: $e');
      return false;
    }
  }

  // Create a new ranking ID
  String generateRankingId() {
    return 'custom_ranking_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Create a new CustomPositionRanking from player data
  CustomPositionRanking createRankingFromPlayers({
    required String position,
    required String name,
    required List<Map<String, dynamic>> players, // Player data from existing ranking screens
  }) {
    final now = DateTime.now();
    final playerRanks = players.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      
      return CustomPlayerRank(
        playerId: player['id']?.toString() ?? '',
        playerName: player['name']?.toString() ?? '',
        team: player['team']?.toString() ?? '',
        customRank: index + 1, // 1-based ranking
        projectedPoints: (player['projectedPoints'] as num?)?.toDouble() ?? 0.0,
        vorp: (player['vorp'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return CustomPositionRanking(
      id: generateRankingId(),
      userId: _defaultUserId,
      position: position,
      name: name,
      playerRanks: playerRanks,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Get summary stats for dashboard
  Future<Map<String, int>> getRankingSummary() async {
    final allRankings = await getAllRankings();
    final summary = <String, int>{};
    
    for (final ranking in allRankings) {
      summary[ranking.position] = (summary[ranking.position] ?? 0) + 1;
    }
    
    return summary;
  }

  // Export rankings to JSON
  Future<String> exportRankingsToJson() async {
    final allRankings = await getAllRankings();
    return json.encode({
      'rankings': allRankings.map((r) => r.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    });
  }

  // Import rankings from JSON
  Future<bool> importRankingsFromJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final rankingsData = data['rankings'] as List<dynamic>;
      
      final rankings = rankingsData
          .map((r) => CustomPositionRanking.fromJson(r as Map<String, dynamic>))
          .toList();

      // Save all imported rankings
      for (final ranking in rankings) {
        await saveRanking(ranking);
      }
      
      return true;
    } catch (e) {
      print('Error importing rankings: $e');
      return false;
    }
  }

  // Clear all rankings (for testing/reset)
  Future<void> clearAllRankings() async {
    final storage = html.window.localStorage;
    storage.remove(_storageKey);
    storage.remove(_bigBoardStorageKey);
  }

  // Big Board Operations (Phase 2 preparation)
  
  // Save custom big board
  Future<bool> saveBigBoard(CustomBigBoard bigBoard) async {
    try {
      final storage = html.window.localStorage;
      final bigBoardsJson = storage[_bigBoardStorageKey] ?? '[]';
      final List<dynamic> bigBoardsList = json.decode(bigBoardsJson);
      
      // Check if big board with this ID exists
      final existingIndex = bigBoardsList.indexWhere((bb) => bb['id'] == bigBoard.id);
      
      if (existingIndex != -1) {
        bigBoardsList[existingIndex] = bigBoard.toJson();
      } else {
        bigBoardsList.add(bigBoard.toJson());
      }

      storage[_bigBoardStorageKey] = json.encode(bigBoardsList);
      return true;
    } catch (e) {
      print('Error saving custom big board: $e');
      return false;
    }
  }

  // Get all custom big boards
  Future<List<CustomBigBoard>> getAllBigBoards() async {
    try {
      final storage = html.window.localStorage;
      final bigBoardsJson = storage[_bigBoardStorageKey];
      
      if (bigBoardsJson == null || bigBoardsJson.isEmpty) {
        return [];
      }

      final List<dynamic> bigBoardsList = json.decode(bigBoardsJson);
      return bigBoardsList
          .map((bb) => CustomBigBoard.fromJson(bb as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading custom big boards: $e');
      return [];
    }
  }
}