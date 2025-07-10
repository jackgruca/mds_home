import 'package:cloud_firestore/cloud_firestore.dart';
import 'ranking_attribute.dart';

class CustomRankingQuestionnaire {
  final String id;
  final String userId;
  final String name;
  final String position;
  final List<RankingAttribute> attributes;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isPublic;
  final String? description;
  final Map<String, dynamic> metadata;

  CustomRankingQuestionnaire({
    required this.id,
    required this.userId,
    required this.name,
    required this.position,
    required this.attributes,
    required this.createdAt,
    required this.lastModified,
    this.isPublic = false,
    this.description,
    this.metadata = const {},
  });

  factory CustomRankingQuestionnaire.fromJson(Map<String, dynamic> json) {
    return CustomRankingQuestionnaire(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((attr) => RankingAttribute.fromJson(attr as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastModified: (json['lastModified'] as Timestamp).toDate(),
      isPublic: json['isPublic'] as bool? ?? false,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'position': position,
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
      'isPublic': isPublic,
      'description': description,
      'metadata': metadata,
    };
  }

  CustomRankingQuestionnaire copyWith({
    String? id,
    String? userId,
    String? name,
    String? position,
    List<RankingAttribute>? attributes,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isPublic,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return CustomRankingQuestionnaire(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      position: position ?? this.position,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isPublic: isPublic ?? this.isPublic,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  double get totalWeight => attributes.fold(0.0, (total, attr) => total + attr.weight);
  
  bool get isValid => attributes.isNotEmpty && totalWeight > 0;
}