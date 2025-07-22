import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_questionnaire.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/models/custom_rankings/user_ranking_preferences.dart';
import 'package:mds_home/models/fantasy/player_ranking.dart';
import 'package:mds_home/services/fantasy/csv_rankings_service.dart';
import 'attribute_calculation_service.dart';

class CustomRankingService {
  static const String _collectionQuestionnaires = 'custom_ranking_questionnaires';
  static const String _collectionResults = 'custom_ranking_results';
  static const String _collectionPreferences = 'user_ranking_preferences';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CSVRankingsService _csvService = CSVRankingsService();
  final AttributeCalculationService _calculationService = AttributeCalculationService();

  // Questionnaire Management
  Future<String> saveQuestionnaire(CustomRankingQuestionnaire questionnaire) async {
    try {
      final docRef = await _firestore
          .collection(_collectionQuestionnaires)
          .add(questionnaire.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save questionnaire: $e');
    }
  }

  Future<CustomRankingQuestionnaire?> getQuestionnaire(String id) async {
    try {
      final doc = await _firestore
          .collection(_collectionQuestionnaires)
          .doc(id)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return CustomRankingQuestionnaire.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get questionnaire: $e');
    }
  }

  Future<List<CustomRankingQuestionnaire>> getUserQuestionnaires(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionQuestionnaires)
          .where('userId', isEqualTo: userId)
          .orderBy('lastModified', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CustomRankingQuestionnaire.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user questionnaires: $e');
    }
  }

  Future<void> updateQuestionnaire(CustomRankingQuestionnaire questionnaire) async {
    try {
      await _firestore
          .collection(_collectionQuestionnaires)
          .doc(questionnaire.id)
          .update(questionnaire.copyWith(lastModified: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update questionnaire: $e');
    }
  }

  Future<void> deleteQuestionnaire(String id) async {
    try {
      await _firestore
          .collection(_collectionQuestionnaires)
          .doc(id)
          .delete();
      
      // Also delete associated results
      final resultsQuery = await _firestore
          .collection(_collectionResults)
          .where('questionnaireId', isEqualTo: id)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in resultsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete questionnaire: $e');
    }
  }

  // Rankings Generation
  Future<List<CustomRankingResult>> generateRankings(CustomRankingQuestionnaire questionnaire) async {
    try {
      // Get base player data from CSV
      final baseRankings = await _csvService.fetchRankings();
      final positionPlayers = baseRankings
          .where((player) => player.position == questionnaire.position)
          .toList();

      if (positionPlayers.isEmpty) {
        throw Exception('No players found for position: ${questionnaire.position}');
      }

      // Calculate rankings for each player
      final results = <CustomRankingResult>[];
      
      for (int i = 0; i < positionPlayers.length; i++) {
        final player = positionPlayers[i];
        final result = await _calculatePlayerRanking(questionnaire, player, i);
        results.add(result);
      }

      // Sort by total score and assign ranks
      results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      
      final rankedResults = <CustomRankingResult>[];
      for (int i = 0; i < results.length; i++) {
        rankedResults.add(results[i].copyWith(rank: i + 1));
      }

      // Save results to Firebase
      await _saveRankingResults(rankedResults);

      return rankedResults;
    } catch (e) {
      throw Exception('Failed to generate rankings: $e');
    }
  }

  Future<CustomRankingResult> _calculatePlayerRanking(
    CustomRankingQuestionnaire questionnaire,
    PlayerRanking player,
    int index,
  ) async {
    final attributeScores = <String, double>{};
    final normalizedStats = <String, double>{};
    final rawStats = <String, double>{};
    double totalScore = 0.0;

    for (final attribute in questionnaire.attributes) {
      // Get normalized stat value for this attribute
      final normalizedValue = await _calculationService.getNormalizedStat(
        player,
        attribute,
        questionnaire.position,
      );
      
      normalizedStats[attribute.name] = normalizedValue;
      
      // Get raw stat value
      final rawValue = _calculationService.getRawStatValue(player, attribute);
      rawStats[attribute.id] = rawValue ?? 0.0;
      
      // Calculate weighted score for this attribute
      final attributeScore = normalizedValue * attribute.weight;
      attributeScores[attribute.id] = attributeScore;
      
      totalScore += attributeScore;
    }

    return CustomRankingResult(
      id: '${questionnaire.id}_${player.id}_${DateTime.now().millisecondsSinceEpoch}',
      questionnaireId: questionnaire.id,
      playerId: player.id,
      playerName: player.name,
      position: player.position,
      team: player.team,
      totalScore: totalScore,
      rank: 0, // Will be set after sorting
      attributeScores: attributeScores,
      normalizedStats: normalizedStats,
      rawStats: rawStats,
      calculatedAt: DateTime.now(),
    );
  }

  Future<void> _saveRankingResults(List<CustomRankingResult> results) async {
    try {
      final batch = _firestore.batch();
      
      for (final result in results) {
        final docRef = _firestore.collection(_collectionResults).doc(result.id);
        batch.set(docRef, result.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save ranking results: $e');
    }
  }

  // Results Retrieval
  Future<List<CustomRankingResult>> getRankingResults(String questionnaireId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionResults)
          .where('questionnaireId', isEqualTo: questionnaireId)
          .orderBy('rank')
          .get();

      return querySnapshot.docs
          .map((doc) => CustomRankingResult.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get ranking results: $e');
    }
  }

  // User Preferences Management
  Future<UserRankingPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionPreferences)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserRankingPreferences.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  Future<void> saveUserPreferences(UserRankingPreferences preferences) async {
    try {
      await _firestore
          .collection(_collectionPreferences)
          .doc(preferences.userId)
          .set(preferences.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user preferences: $e');
    }
  }

  // Export functionality
  Future<Map<String, dynamic>> exportRankings(String questionnaireId) async {
    try {
      final questionnaire = await getQuestionnaire(questionnaireId);
      final results = await getRankingResults(questionnaireId);
      
      if (questionnaire == null) {
        throw Exception('Questionnaire not found');
      }

      return {
        'questionnaire': questionnaire.toJson(),
        'results': results.map((r) => r.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'metadata': {
          'position': questionnaire.position,
          'attributeCount': questionnaire.attributes.length,
          'playerCount': results.length,
        },
      };
    } catch (e) {
      throw Exception('Failed to export rankings: $e');
    }
  }

  // Quick ranking comparison
  Future<List<PlayerRanking>> convertToPlayerRankings(List<CustomRankingResult> results) async {
    return results.map((result) => result.toPlayerRanking()).toList();
  }

  // Get public questionnaires for inspiration
  Future<List<CustomRankingQuestionnaire>> getPublicQuestionnaires({
    String? position,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionQuestionnaires)
          .where('isPublic', isEqualTo: true)
          .orderBy('lastModified', descending: true);

      if (position != null) {
        query = query.where('position', isEqualTo: position);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => CustomRankingQuestionnaire.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get public questionnaires: $e');
    }
  }
}