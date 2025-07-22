import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/fantasy/custom_position_ranking.dart';
import '../../services/fantasy/historical_points_service.dart';
import '../../services/fantasy/vorp_service.dart';

class CustomRankingService {
  static const String _keyPrefix = 'custom_ranking_';
  static const String _bigBoardKeyPrefix = 'custom_bigboard_';
  static const String _allRankingsKey = 'all_custom_rankings';
  static const String _allBigBoardsKey = 'all_custom_bigboards';

  /// Generate unique ID for rankings
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Save a custom position ranking
  static Future<bool> saveCustomRanking(CustomPositionRanking ranking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the ranking data
      final key = '$_keyPrefix${ranking.id}';
      final success = await prefs.setString(key, ranking.toJsonString());
      
      if (success) {
        // Update the list of all rankings
        await _updateRankingsList(ranking);
      }
      
      return success;
    } catch (e) {
      print('Error saving custom ranking: $e');
      return false;
    }
  }

  /// Load a custom position ranking by ID
  static Future<CustomPositionRanking?> loadCustomRanking(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$id';
      final jsonString = prefs.getString(key);
      
      if (jsonString != null) {
        return CustomPositionRanking.fromJsonString(jsonString);
      }
      
      return null;
    } catch (e) {
      print('Error loading custom ranking: $e');
      return null;
    }
  }

  /// Get all custom rankings
  static Future<List<CustomPositionRanking>> getAllCustomRankings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rankingsListJson = prefs.getString(_allRankingsKey);
      
      if (rankingsListJson == null) return [];
      
      final rankingsList = jsonDecode(rankingsListJson) as List<dynamic>;
      final rankings = <CustomPositionRanking>[];
      
      for (final rankingData in rankingsList) {
        final id = rankingData['id'] as String;
        final ranking = await loadCustomRanking(id);
        if (ranking != null) {
          rankings.add(ranking);
        }
      }
      
      // Sort by most recently updated
      rankings.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return rankings;
    } catch (e) {
      print('Error getting all custom rankings: $e');
      return [];
    }
  }

  /// Get custom rankings by position
  static Future<List<CustomPositionRanking>> getCustomRankingsByPosition(String position) async {
    final allRankings = await getAllCustomRankings();
    return allRankings.where((r) => r.position.toLowerCase() == position.toLowerCase()).toList();
  }

  /// Delete a custom ranking
  static Future<bool> deleteCustomRanking(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove the ranking data
      final key = '$_keyPrefix$id';
      await prefs.remove(key);
      
      // Update the rankings list
      await _removeFromRankingsList(id);
      
      return true;
    } catch (e) {
      print('Error deleting custom ranking: $e');
      return false;
    }
  }

  /// Create custom ranking from existing rankings data
  static Future<CustomPositionRanking?> createCustomRankingFromExisting(
    String name,
    String position,
    List<Map<String, dynamic>> playersData,
    {Map<String, int>? leagueSettings,
    String scoringSystem = 'ppr'}
  ) async {
    try {
      final id = _generateId();
      final now = DateTime.now();
      
      // Convert players data to CustomPlayerRank objects
      final playerRanks = <CustomPlayerRank>[];
      for (int i = 0; i < playersData.length; i++) {
        final playerData = playersData[i];
        final customRank = CustomPlayerRank.fromPlayerData(playerData, i + 1);
        playerRanks.add(customRank);
      }

      // Calculate VORP for the players
      final rankingsWithVORP = await _calculateVORPForRanking(
        playerRanks,
        position,
        leagueSettings ?? HistoricalPointsService.getDefaultLeagueSettings(),
        scoringSystem,
      );

      final ranking = CustomPositionRanking(
        id: id,
        position: position.toLowerCase(),
        name: name,
        playerRanks: rankingsWithVORP,
        createdAt: now,
        updatedAt: now,
        leagueSettings: leagueSettings,
        scoringSystem: scoringSystem,
      );

      final success = await saveCustomRanking(ranking);
      return success ? ranking : null;
    } catch (e) {
      print('Error creating custom ranking: $e');
      return null;
    }
  }

  /// Update existing custom ranking
  static Future<bool> updateCustomRanking(CustomPositionRanking ranking) async {
    final updatedRanking = ranking.copyWith(updatedAt: DateTime.now());
    return await saveCustomRanking(updatedRanking);
  }

  /// Reorder players in a custom ranking
  static Future<CustomPositionRanking?> reorderCustomRanking(
    String rankingId,
    List<String> orderedPlayerIds,
  ) async {
    try {
      final ranking = await loadCustomRanking(rankingId);
      if (ranking == null) return null;

      final reorderedRanking = ranking.reorderPlayers(orderedPlayerIds);
      
      // Recalculate VORP with new rankings
      final rankingsWithVORP = await _calculateVORPForRanking(
        reorderedRanking.playerRanks,
        reorderedRanking.position,
        reorderedRanking.leagueSettings,
        reorderedRanking.scoringSystem,
      );

      final finalRanking = reorderedRanking.copyWith(playerRanks: rankingsWithVORP);
      
      final success = await saveCustomRanking(finalRanking);
      return success ? finalRanking : null;
    } catch (e) {
      print('Error reordering custom ranking: $e');
      return null;
    }
  }

  /// Calculate VORP for custom ranking
  static Future<List<CustomPlayerRank>> _calculateVORPForRanking(
    List<CustomPlayerRank> playerRanks,
    String position,
    Map<String, int> leagueSettings,
    String scoringSystem,
  ) async {
    try {
      final replacementPoints = HistoricalPointsService.getReplacementLevelPoints(
        position,
        leagueSettings,
        scoringSystem: scoringSystem,
      );

      final updatedRanks = <CustomPlayerRank>[];
      
      for (final player in playerRanks) {
        final projectedPoints = HistoricalPointsService.rankToPoints(
          position,
          player.customRank,
          scoringSystem: scoringSystem,
        );
        
        final vorp = projectedPoints - replacementPoints;
        
        updatedRanks.add(player.copyWith(
          projectedPoints: projectedPoints,
          vorp: vorp,
        ));
      }

      return updatedRanks;
    } catch (e) {
      print('Error calculating VORP: $e');
      return playerRanks; // Return original if calculation fails
    }
  }

  /// Save custom big board
  static Future<bool> saveCustomBigBoard(CustomBigBoard bigBoard) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the big board data
      final key = '$_bigBoardKeyPrefix${bigBoard.id}';
      final success = await prefs.setString(key, bigBoard.toJsonString());
      
      if (success) {
        // Update the list of all big boards
        await _updateBigBoardsList(bigBoard);
      }
      
      return success;
    } catch (e) {
      print('Error saving custom big board: $e');
      return false;
    }
  }

  /// Load custom big board by ID
  static Future<CustomBigBoard?> loadCustomBigBoard(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_bigBoardKeyPrefix$id';
      final jsonString = prefs.getString(key);
      
      if (jsonString != null) {
        return CustomBigBoard.fromJsonString(jsonString);
      }
      
      return null;
    } catch (e) {
      print('Error loading custom big board: $e');
      return null;
    }
  }

  /// Get all custom big boards
  static Future<List<CustomBigBoard>> getAllCustomBigBoards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bigBoardsListJson = prefs.getString(_allBigBoardsKey);
      
      if (bigBoardsListJson == null) return [];
      
      final bigBoardsList = jsonDecode(bigBoardsListJson) as List<dynamic>;
      final bigBoards = <CustomBigBoard>[];
      
      for (final bigBoardData in bigBoardsList) {
        final id = bigBoardData['id'] as String;
        final bigBoard = await loadCustomBigBoard(id);
        if (bigBoard != null) {
          bigBoards.add(bigBoard);
        }
      }
      
      // Sort by most recently updated
      bigBoards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return bigBoards;
    } catch (e) {
      print('Error getting all custom big boards: $e');
      return [];
    }
  }

  /// Create custom big board from position rankings
  static Future<CustomBigBoard?> createCustomBigBoard(
    String name,
    Map<String, String> positionRankingIds, // position -> ranking ID
  ) async {
    try {
      final id = _generateId();
      final now = DateTime.now();
      
      final positionRankings = <String, CustomPositionRanking>{};
      
      // Load all position rankings
      for (final entry in positionRankingIds.entries) {
        final position = entry.key;
        final rankingId = entry.value;
        
        final ranking = await loadCustomRanking(rankingId);
        if (ranking != null) {
          positionRankings[position] = ranking;
        }
      }

      if (positionRankings.isEmpty) {
        print('No valid position rankings found');
        return null;
      }

      final bigBoard = CustomBigBoard(
        id: id,
        name: name,
        positionRankings: positionRankings,
        createdAt: now,
        updatedAt: now,
      );

      final success = await saveCustomBigBoard(bigBoard);
      return success ? bigBoard : null;
    } catch (e) {
      print('Error creating custom big board: $e');
      return null;
    }
  }

  /// Delete custom big board
  static Future<bool> deleteCustomBigBoard(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove the big board data
      final key = '$_bigBoardKeyPrefix$id';
      await prefs.remove(key);
      
      // Update the big boards list
      await _removeFromBigBoardsList(id);
      
      return true;
    } catch (e) {
      print('Error deleting custom big board: $e');
      return false;
    }
  }

  /// Update rankings list in localStorage
  static Future<void> _updateRankingsList(CustomPositionRanking ranking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rankingsListJson = prefs.getString(_allRankingsKey);
      
      List<dynamic> rankingsList;
      if (rankingsListJson != null) {
        rankingsList = jsonDecode(rankingsListJson) as List<dynamic>;
      } else {
        rankingsList = [];
      }

      // Remove existing entry if it exists
      rankingsList.removeWhere((item) => item['id'] == ranking.id);
      
      // Add updated entry
      rankingsList.add({
        'id': ranking.id,
        'name': ranking.name,
        'position': ranking.position,
        'updatedAt': ranking.updatedAt.toIso8601String(),
      });

      await prefs.setString(_allRankingsKey, jsonEncode(rankingsList));
    } catch (e) {
      print('Error updating rankings list: $e');
    }
  }

  /// Remove ranking from list
  static Future<void> _removeFromRankingsList(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rankingsListJson = prefs.getString(_allRankingsKey);
      
      if (rankingsListJson != null) {
        final rankingsList = jsonDecode(rankingsListJson) as List<dynamic>;
        rankingsList.removeWhere((item) => item['id'] == id);
        await prefs.setString(_allRankingsKey, jsonEncode(rankingsList));
      }
    } catch (e) {
      print('Error removing from rankings list: $e');
    }
  }

  /// Update big boards list in localStorage
  static Future<void> _updateBigBoardsList(CustomBigBoard bigBoard) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bigBoardsListJson = prefs.getString(_allBigBoardsKey);
      
      List<dynamic> bigBoardsList;
      if (bigBoardsListJson != null) {
        bigBoardsList = jsonDecode(bigBoardsListJson) as List<dynamic>;
      } else {
        bigBoardsList = [];
      }

      // Remove existing entry if it exists
      bigBoardsList.removeWhere((item) => item['id'] == bigBoard.id);
      
      // Add updated entry
      bigBoardsList.add({
        'id': bigBoard.id,
        'name': bigBoard.name,
        'updatedAt': bigBoard.updatedAt.toIso8601String(),
      });

      await prefs.setString(_allBigBoardsKey, jsonEncode(bigBoardsList));
    } catch (e) {
      print('Error updating big boards list: $e');
    }
  }

  /// Remove big board from list
  static Future<void> _removeFromBigBoardsList(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bigBoardsListJson = prefs.getString(_allBigBoardsKey);
      
      if (bigBoardsListJson != null) {
        final bigBoardsList = jsonDecode(bigBoardsListJson) as List<dynamic>;
        bigBoardsList.removeWhere((item) => item['id'] == id);
        await prefs.setString(_allBigBoardsKey, jsonEncode(bigBoardsList));
      }
    } catch (e) {
      print('Error removing from big boards list: $e');
    }
  }

  /// Clear all custom rankings (for testing/reset)
  static Future<bool> clearAllCustomRankings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all ranking keys and remove them
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_keyPrefix) || key == _allRankingsKey) {
          await prefs.remove(key);
        }
      }
      
      return true;
    } catch (e) {
      print('Error clearing custom rankings: $e');
      return false;
    }
  }

  /// Clear all custom big boards
  static Future<bool> clearAllCustomBigBoards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all big board keys and remove them
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_bigBoardKeyPrefix) || key == _allBigBoardsKey) {
          await prefs.remove(key);
        }
      }
      
      return true;
    } catch (e) {
      print('Error clearing custom big boards: $e');
      return false;
    }
  }

  /// Get storage usage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      int rankingCount = 0;
      int bigBoardCount = 0;
      int totalSize = 0;
      
      for (final key in allKeys) {
        if (key.startsWith(_keyPrefix)) {
          rankingCount++;
          final value = prefs.getString(key);
          if (value != null) totalSize += value.length;
        } else if (key.startsWith(_bigBoardKeyPrefix)) {
          bigBoardCount++;
          final value = prefs.getString(key);
          if (value != null) totalSize += value.length;
        }
      }
      
      return {
        'rankingCount': rankingCount,
        'bigBoardCount': bigBoardCount,
        'totalSizeBytes': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting storage stats: $e');
      return {};
    }
  }
}