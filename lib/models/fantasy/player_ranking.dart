import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerRanking {
  final String id;
  final String name;
  final String position;
  final String team;
  final int rank;
  final String source;
  final DateTime lastUpdated;
  final Map<String, dynamic> stats;
  final String? notes;
  final Map<String, dynamic> additionalRanks;

  PlayerRanking({
    required this.id,
    required this.name,
    required this.position,
    required this.team,
    required this.rank,
    required this.source,
    required this.lastUpdated,
    this.stats = const {},
    this.notes,
    this.additionalRanks = const {},
  });

  factory PlayerRanking.fromJson(Map<String, dynamic> json) {
    return PlayerRanking(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      team: json['team'] as String,
      rank: json['rank'] as int,
      source: json['source'] as String,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      stats: json['stats'] as Map<String, dynamic>? ?? {},
      notes: json['notes'] as String?,
      additionalRanks: json['additionalRanks'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'team': team,
      'rank': rank,
      'source': source,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'stats': stats,
      'notes': notes,
      'additionalRanks': additionalRanks,
    };
  }

  PlayerRanking copyWith({
    String? id,
    String? name,
    String? position,
    String? team,
    int? rank,
    String? source,
    DateTime? lastUpdated,
    Map<String, dynamic>? stats,
    String? notes,
    Map<String, dynamic>? additionalRanks,
  }) {
    return PlayerRanking(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      team: team ?? this.team,
      rank: rank ?? this.rank,
      source: source ?? this.source,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      stats: stats ?? this.stats,
      notes: notes ?? this.notes,
      additionalRanks: additionalRanks ?? this.additionalRanks,
    );
  }
} 