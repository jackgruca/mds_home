import 'package:cloud_firestore/cloud_firestore.dart';
import '../fantasy/player_ranking.dart';

class CustomRankingResult {
  final String id;
  final String questionnaireId;
  final String playerId;
  final String playerName;
  final String position;
  final String team;
  final double totalScore;
  final int rank;
  final Map<String, double> attributeScores;
  final Map<String, double> normalizedStats;
  final DateTime calculatedAt;
  final String source;

  CustomRankingResult({
    required this.id,
    required this.questionnaireId,
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.team,
    required this.totalScore,
    required this.rank,
    required this.attributeScores,
    required this.normalizedStats,
    required this.calculatedAt,
    this.source = 'custom',
  });

  factory CustomRankingResult.fromJson(Map<String, dynamic> json) {
    return CustomRankingResult(
      id: json['id'] as String,
      questionnaireId: json['questionnaireId'] as String,
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      team: json['team'] as String,
      totalScore: (json['totalScore'] as num).toDouble(),
      rank: json['rank'] as int,
      attributeScores: Map<String, double>.from(
        (json['attributeScores'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      normalizedStats: Map<String, double>.from(
        (json['normalizedStats'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      calculatedAt: (json['calculatedAt'] as Timestamp).toDate(),
      source: json['source'] as String? ?? 'custom',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionnaireId': questionnaireId,
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'team': team,
      'totalScore': totalScore,
      'rank': rank,
      'attributeScores': attributeScores,
      'normalizedStats': normalizedStats,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
      'source': source,
    };
  }

  PlayerRanking toPlayerRanking() {
    return PlayerRanking(
      id: playerId,
      name: playerName,
      position: position,
      team: team,
      rank: rank,
      source: source,
      lastUpdated: calculatedAt,
      stats: normalizedStats,
      additionalRanks: {
        'Custom Score': totalScore,
        'Custom Rank': rank,
        ...attributeScores.map((key, value) => MapEntry('${key}_score', value)),
      },
    );
  }

  CustomRankingResult copyWith({
    String? id,
    String? questionnaireId,
    String? playerId,
    String? playerName,
    String? position,
    String? team,
    double? totalScore,
    int? rank,
    Map<String, double>? attributeScores,
    Map<String, double>? normalizedStats,
    DateTime? calculatedAt,
    String? source,
  }) {
    return CustomRankingResult(
      id: id ?? this.id,
      questionnaireId: questionnaireId ?? this.questionnaireId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      position: position ?? this.position,
      team: team ?? this.team,
      totalScore: totalScore ?? this.totalScore,
      rank: rank ?? this.rank,
      attributeScores: attributeScores ?? this.attributeScores,
      normalizedStats: normalizedStats ?? this.normalizedStats,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      source: source ?? this.source,
    );
  }

  double getAttributeScore(String attributeId) {
    return attributeScores[attributeId] ?? 0.0;
  }

  double getNormalizedStat(String statName) {
    return normalizedStats[statName] ?? 0.0;
  }

  String get formattedScore => totalScore.toStringAsFixed(2);
}