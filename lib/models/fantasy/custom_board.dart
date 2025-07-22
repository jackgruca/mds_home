import 'package:cloud_firestore/cloud_firestore.dart';

class CustomRank {
  final String playerId;
  final int rank;
  final String? notes;

  CustomRank({
    required this.playerId,
    required this.rank,
    this.notes,
  });

  factory CustomRank.fromJson(Map<String, dynamic> json) {
    return CustomRank(
      playerId: json['playerId'] as String,
      rank: json['rank'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'rank': rank,
      'notes': notes,
    };
  }
}

class CustomBoard {
  final String id;
  final String userId;
  final String name;
  final bool isPublic;
  final List<CustomRank> rankings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final Map<String, dynamic>? settings;

  CustomBoard({
    required this.id,
    required this.userId,
    required this.name,
    required this.isPublic,
    required this.rankings,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.settings,
  });

  factory CustomBoard.fromJson(Map<String, dynamic> json) {
    return CustomBoard(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      isPublic: json['isPublic'] as bool,
      rankings: (json['rankings'] as List<dynamic>)
          .map((e) => CustomRank.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      description: json['description'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'isPublic': isPublic,
      'rankings': rankings.map((r) => r.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'settings': settings,
    };
  }

  CustomBoard copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isPublic,
    List<CustomRank>? rankings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    Map<String, dynamic>? settings,
  }) {
    return CustomBoard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      rankings: rankings ?? this.rankings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      settings: settings ?? this.settings,
    );
  }
} 