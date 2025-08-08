import 'package:flutter/foundation.dart';

/// Configuration for custom ranking weights
class CustomWeightConfig {
  final String position;
  final Map<String, double> weights;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomWeightConfig({
    required this.position,
    required this.weights,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create default weights for RB position
  static CustomWeightConfig createDefaultRBWeights() {
    return CustomWeightConfig(
      position: 'rb',
      name: 'Default',
      weights: {
        'EPA': 0.15,
        'TD': 0.15,
        'Rush Share': 0.15,
        'YPG': 0.15,
        'Target Share': 0.05,
        'Third Down': 0.10,
        'RZ': 0.05,
        'Explosive': 0.10,
        'RYOE': 0.05,
        'Efficiency': 0.05,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create default weights for QB position
  static CustomWeightConfig createDefaultQBWeights() {
    return CustomWeightConfig(
      position: 'qb',
      name: 'Default',
      weights: {
        'EPA': 0.20,
        'EP': 0.15,
        'CPOE': 0.15,
        'YPG': 0.10,
        'TD': 0.15,
        'Actualization': 0.10,
        'INT': 0.05,
        'Third Down': 0.10,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create default weights for WR position
  static CustomWeightConfig createDefaultWRWeights() {
    return CustomWeightConfig(
      position: 'wr',
      name: 'Default',
      weights: {
        'EPA': 0.15,
        'TD': 0.10,
        'Target Share': 0.15,
        'YPG': 0.10,
        'RZ': 0.10,
        'Explosive': 0.10,
        'Separation': 0.05,
        'Air Yards': 0.05,
        'Catch%': 0.10,
        'Third Down': 0.05,
        'YAC+': 0.05,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create default weights for TE position
  static CustomWeightConfig createDefaultTEWeights() {
    return CustomWeightConfig(
      position: 'te',
      name: 'Default',
      weights: {
        'EPA': 0.15,
        'TD': 0.15,
        'Target Share': 0.15,
        'YPG': 0.10,
        'RZ': 0.15,
        'Explosive': 0.05,
        'Separation': 0.05,
        'Air Yards': 0.05,
        'Catch%': 0.10,
        'Third Down': 0.05,
        'YAC+': 0.00,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create default weights for EDGE position
  static CustomWeightConfig createDefaultEdgeWeights() {
    return CustomWeightConfig(
      position: 'edge',
      name: 'Default',
      weights: {
        'Sacks': 0.30,
        'QB Hits': 0.20,
        'Pressure': 0.25,
        'TFLs': 0.15,
        'Forced Fumbles': 0.10,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create default weights for IDL position
  static CustomWeightConfig createDefaultIdlWeights() {
    return CustomWeightConfig(
      position: 'idl',
      name: 'Default',
      weights: {
        'Tackles': 0.25,
        'TFLs': 0.20,
        'Run Stuffs': 0.30,
        'Stuff Rate': 0.15,
        'Interior Pressure': 0.10,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create default weights for consensus rankings
  static CustomWeightConfig createDefaultConsensusWeights() {
    return CustomWeightConfig(
      position: 'consensus',
      name: 'Default',
      weights: {
        'PFF': 0.15,
        'CBS': 0.15,
        'ESPN': 0.15,
        'FFToday': 0.15,
        'FootballGuys': 0.15,
        'Yahoo': 0.15,
        'NFL': 0.10,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create weights with updated values
  CustomWeightConfig copyWith({
    String? position,
    Map<String, double>? weights,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomWeightConfig(
      position: position ?? this.position,
      weights: weights ?? Map.from(this.weights),
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'weights': weights,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CustomWeightConfig.fromJson(Map<String, dynamic> json) {
    return CustomWeightConfig(
      position: json['position'] as String,
      weights: Map<String, double>.from(json['weights'] as Map),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get total weight sum (should be 1.0)
  double get totalWeight => weights.values.fold(0.0, (sum, weight) => sum + weight);

  /// Check if weights are normalized (sum to 1.0)
  bool get isNormalized => (totalWeight - 1.0).abs() < 0.001;

  /// Normalize weights to sum to 1.0
  CustomWeightConfig normalize() {
    final total = totalWeight;
    if (total == 0.0) return this;
    
    final normalizedWeights = weights.map(
      (key, value) => MapEntry(key, value / total),
    );
    
    return copyWith(weights: normalizedWeights);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomWeightConfig &&
        other.position == position &&
        other.name == name &&
        mapEquals(other.weights, weights);
  }

  @override
  int get hashCode {
    return Object.hash(
      position,
      name,
      Object.hashAll(weights.entries.map((e) => Object.hash(e.key, e.value))),
    );
  }

  @override
  String toString() {
    return 'CustomWeightConfig(position: $position, name: $name, weights: $weights)';
  }
}