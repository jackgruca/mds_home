import 'package:flutter/foundation.dart';

/// Configuration for consensus ranking weights including custom rankings
class ConsensusWeightConfig {
  final Map<String, double> platformWeights;
  final bool includeCustomRankings;
  final double customRankingsWeight;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsensusWeightConfig({
    required this.platformWeights,
    this.includeCustomRankings = false,
    this.customRankingsWeight = 0.0,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create default consensus weights without custom rankings
  static ConsensusWeightConfig createDefault() {
    return ConsensusWeightConfig(
      platformWeights: {
        'PFF': 0.15,
        'CBS': 0.15,
        'ESPN': 0.15,
        'FFToday': 0.15,
        'FootballGuys': 0.15,
        'Yahoo': 0.15,
        'NFL': 0.10,
      },
      includeCustomRankings: false,
      customRankingsWeight: 0.0,
      name: 'Default Consensus',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create consensus weights that include custom rankings with equal weighting
  static ConsensusWeightConfig createWithCustomRankings() {
    return ConsensusWeightConfig(
      platformWeights: {
        'PFF': 0.125,
        'CBS': 0.125,
        'ESPN': 0.125,
        'FFToday': 0.125,
        'FootballGuys': 0.125,
        'Yahoo': 0.125,
        'NFL': 0.125,
      },
      includeCustomRankings: true,
      customRankingsWeight: 0.125, // Equal weight with other platforms
      name: 'Consensus + Custom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create consensus weights with custom weighting for platforms and custom rankings
  static ConsensusWeightConfig createCustom({
    required Map<String, double> platformWeights,
    required double customRankingsWeight,
    String? name,
  }) {
    return ConsensusWeightConfig(
      platformWeights: platformWeights,
      includeCustomRankings: customRankingsWeight > 0.0,
      customRankingsWeight: customRankingsWeight,
      name: name ?? 'Custom Consensus',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get all weights including custom rankings if included
  Map<String, double> get allWeights {
    final weights = Map<String, double>.from(platformWeights);
    if (includeCustomRankings && customRankingsWeight > 0.0) {
      weights['My Custom Rankings'] = customRankingsWeight;
    }
    return weights;
  }

  /// Get total weight sum (should be 1.0)
  double get totalWeight {
    double total = platformWeights.values.fold(0.0, (sum, weight) => sum + weight);
    if (includeCustomRankings) {
      total += customRankingsWeight;
    }
    return total;
  }

  /// Check if weights are normalized (sum to 1.0)
  bool get isNormalized => (totalWeight - 1.0).abs() < 0.001;

  /// Normalize weights to sum to 1.0
  ConsensusWeightConfig normalize() {
    final total = totalWeight;
    if (total == 0.0) return this;
    
    final normalizedPlatformWeights = platformWeights.map(
      (key, value) => MapEntry(key, value / total),
    );
    
    final normalizedCustomWeight = includeCustomRankings ? customRankingsWeight / total : 0.0;
    
    return copyWith(
      platformWeights: normalizedPlatformWeights,
      customRankingsWeight: normalizedCustomWeight,
    );
  }

  /// Create weights with updated values
  ConsensusWeightConfig copyWith({
    Map<String, double>? platformWeights,
    bool? includeCustomRankings,
    double? customRankingsWeight,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsensusWeightConfig(
      platformWeights: platformWeights ?? Map.from(this.platformWeights),
      includeCustomRankings: includeCustomRankings ?? this.includeCustomRankings,
      customRankingsWeight: customRankingsWeight ?? this.customRankingsWeight,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Enable custom rankings with specified weight
  ConsensusWeightConfig enableCustomRankings(double weight) {
    return copyWith(
      includeCustomRankings: true,
      customRankingsWeight: weight,
    );
  }

  /// Disable custom rankings
  ConsensusWeightConfig disableCustomRankings() {
    return copyWith(
      includeCustomRankings: false,
      customRankingsWeight: 0.0,
    );
  }

  /// Update weight for a specific platform or custom rankings
  ConsensusWeightConfig updateWeight(String source, double weight) {
    if (source == 'My Custom Rankings') {
      return copyWith(
        includeCustomRankings: weight > 0.0,
        customRankingsWeight: weight,
      );
    } else {
      final updatedWeights = Map<String, double>.from(platformWeights);
      updatedWeights[source] = weight;
      return copyWith(platformWeights: updatedWeights);
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'platformWeights': platformWeights,
      'includeCustomRankings': includeCustomRankings,
      'customRankingsWeight': customRankingsWeight,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ConsensusWeightConfig.fromJson(Map<String, dynamic> json) {
    return ConsensusWeightConfig(
      platformWeights: Map<String, double>.from(json['platformWeights'] as Map),
      includeCustomRankings: json['includeCustomRankings'] as bool? ?? false,
      customRankingsWeight: (json['customRankingsWeight'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsensusWeightConfig &&
        other.name == name &&
        other.includeCustomRankings == includeCustomRankings &&
        other.customRankingsWeight == customRankingsWeight &&
        mapEquals(other.platformWeights, platformWeights);
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      includeCustomRankings,
      customRankingsWeight,
      Object.hashAll(platformWeights.entries.map((e) => Object.hash(e.key, e.value))),
    );
  }

  @override
  String toString() {
    return 'ConsensusWeightConfig(name: $name, includeCustom: $includeCustomRankings, customWeight: $customRankingsWeight, platformWeights: $platformWeights)';
  }
}