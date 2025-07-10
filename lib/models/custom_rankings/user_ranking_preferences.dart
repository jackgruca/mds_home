import 'package:cloud_firestore/cloud_firestore.dart';

class UserRankingPreferences {
  final String userId;
  final List<String> savedQuestionnaireIds;
  final String? defaultQuestionnaireId;
  final Map<String, double> positionWeights;
  final DateTime lastUpdated;
  final Map<String, dynamic> preferences;

  UserRankingPreferences({
    required this.userId,
    required this.savedQuestionnaireIds,
    this.defaultQuestionnaireId,
    this.positionWeights = const {},
    required this.lastUpdated,
    this.preferences = const {},
  });

  factory UserRankingPreferences.fromJson(Map<String, dynamic> json) {
    return UserRankingPreferences(
      userId: json['userId'] as String,
      savedQuestionnaireIds: List<String>.from(json['savedQuestionnaireIds'] as List<dynamic>? ?? []),
      defaultQuestionnaireId: json['defaultQuestionnaireId'] as String?,
      positionWeights: Map<String, double>.from(
        (json['positionWeights'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'savedQuestionnaireIds': savedQuestionnaireIds,
      'defaultQuestionnaireId': defaultQuestionnaireId,
      'positionWeights': positionWeights,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'preferences': preferences,
    };
  }

  UserRankingPreferences copyWith({
    String? userId,
    List<String>? savedQuestionnaireIds,
    String? defaultQuestionnaireId,
    Map<String, double>? positionWeights,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
  }) {
    return UserRankingPreferences(
      userId: userId ?? this.userId,
      savedQuestionnaireIds: savedQuestionnaireIds ?? this.savedQuestionnaireIds,
      defaultQuestionnaireId: defaultQuestionnaireId ?? this.defaultQuestionnaireId,
      positionWeights: positionWeights ?? this.positionWeights,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      preferences: preferences ?? this.preferences,
    );
  }

  UserRankingPreferences addQuestionnaire(String questionnaireId) {
    if (!savedQuestionnaireIds.contains(questionnaireId)) {
      return copyWith(
        savedQuestionnaireIds: [...savedQuestionnaireIds, questionnaireId],
        lastUpdated: DateTime.now(),
      );
    }
    return this;
  }

  UserRankingPreferences removeQuestionnaire(String questionnaireId) {
    final updatedIds = savedQuestionnaireIds.where((id) => id != questionnaireId).toList();
    return copyWith(
      savedQuestionnaireIds: updatedIds,
      defaultQuestionnaireId: defaultQuestionnaireId == questionnaireId ? null : defaultQuestionnaireId,
      lastUpdated: DateTime.now(),
    );
  }

  UserRankingPreferences setDefaultQuestionnaire(String questionnaireId) {
    if (savedQuestionnaireIds.contains(questionnaireId)) {
      return copyWith(
        defaultQuestionnaireId: questionnaireId,
        lastUpdated: DateTime.now(),
      );
    }
    return this;
  }
}