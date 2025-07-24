// lib/models/data_category.dart
import 'package:flutter/material.dart';

enum DataCategoryType {
  basic,
  advanced,
  nextGen,
  fantasy,
  situational,
  physical,
}

class DataCategory {
  final DataCategoryType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> fields;
  final List<String> routes;

  const DataCategory({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.fields,
    required this.routes,
  });

  static const List<DataCategory> allCategories = [
    DataCategory(
      type: DataCategoryType.basic,
      name: 'Basic Stats',
      description: 'Traditional counting statistics - yards, touchdowns, completions',
      icon: Icons.bar_chart,
      color: Colors.blue,
      fields: [
        'passing_yards', 'passing_tds', 'rushing_yards', 'rushing_tds',
        'receiving_yards', 'receiving_tds', 'receptions', 'carries',
        'completions', 'attempts', 'interceptions', 'fumbles',
      ],
      routes: ['/data/basic-stats', '/player-season-stats'],
    ),

    DataCategory(
      type: DataCategoryType.advanced,
      name: 'Advanced Analytics',
      description: 'EPA, Success Rate, DVOA, and efficiency metrics',
      icon: Icons.analytics,
      color: Colors.green,
      fields: [
        'epa', 'success_rate', 'cpoe', 'dvoa', 'air_yards',
        'yac', 'pressure_rate', 'passer_rating', 'qb_epa',
        'rushing_epa', 'receiving_epa', 'target_share',
      ],
      routes: ['/data/advanced-stats'],
    ),

    DataCategory(
      type: DataCategoryType.nextGen,
      name: 'Next Gen Stats',
      description: 'Player tracking data - separation, time to throw, expected metrics',
      icon: Icons.speed,
      color: Colors.purple,
      fields: [
        'time_to_throw', 'avg_separation', 'completion_above_expectation',
        'rush_yards_over_expected', 'avg_cushion', 'aggressiveness',
        'max_speed', 'acceleration', 'avg_time_to_los',
      ],
      routes: ['/data/next-gen-stats'],
    ),

    DataCategory(
      type: DataCategoryType.fantasy,
      name: 'Fantasy & Betting',
      description: 'Fantasy points, projections, DFS metrics, and betting correlations',
      icon: Icons.sports_football,
      color: Colors.orange,
      fields: [
        'fantasy_points', 'fantasy_points_ppr', 'adp', 'vorp',
        'target_share', 'red_zone_touches', 'goal_line_carries',
        'snap_share', 'air_yards_share', 'wopr',
      ],
      routes: ['/data/fantasy-stats', '/rankings'],
    ),

    DataCategory(
      type: DataCategoryType.situational,
      name: 'Situational Analysis',
      description: 'Weather, game script, down/distance, and contextual performance',
      icon: Icons.thermostat,
      color: Colors.teal,
      fields: [
        'temp', 'wind', 'surface', 'dome', 'home_team', 'away_team',
        'score_differential', 'game_script', 'down', 'distance',
        'field_position', 'quarter', 'time_remaining',
      ],
      routes: ['/historical-game-data', '/data/situational'],
    ),

    DataCategory(
      type: DataCategoryType.physical,
      name: 'Physical & Biographical',
      description: 'Combine metrics, draft history, contracts, and player background',
      icon: Icons.person,
      color: Colors.indigo,
      fields: [
        'height', 'weight', 'age', 'college', 'draft_round',
        'draft_pick', 'forty_yard_dash', 'vertical_jump', 'bench_press',
        'broad_jump', 'three_cone', 'twenty_yard_shuttle',
      ],
      routes: ['/data/combine', '/data/contracts'],
    ),
  ];

  static DataCategory? getCategoryByType(DataCategoryType type) {
    try {
      return allCategories.firstWhere((category) => category.type == type);
    } catch (e) {
      return null;
    }
  }

  static List<DataCategory> getCategoriesForFields(List<String> fields) {
    final matchingCategories = <DataCategory>[];
    
    for (final category in allCategories) {
      final matchingFields = fields.where(
        (field) => category.fields.any(
          (categoryField) => field.toLowerCase().contains(categoryField.toLowerCase())
        )
      ).toList();
      
      if (matchingFields.isNotEmpty) {
        matchingCategories.add(category);
      }
    }
    
    return matchingCategories;
  }

  static bool fieldBelongsToCategory(String field, DataCategoryType type) {
    final category = getCategoryByType(type);
    if (category == null) return false;
    
    return category.fields.any(
      (categoryField) => field.toLowerCase().contains(categoryField.toLowerCase())
    );
  }
}

class DataQuery {
  final List<DataCategoryType> selectedCategories;
  final Map<String, dynamic> filters;
  final String? playerFilter;
  final String? teamFilter;
  final String? seasonFilter;
  final String? positionFilter;

  const DataQuery({
    required this.selectedCategories,
    required this.filters,
    this.playerFilter,
    this.teamFilter,
    this.seasonFilter,
    this.positionFilter,
  });

  bool get isMultiCategory => selectedCategories.length > 1;

  List<String> get relevantFields {
    final fields = <String>[];
    for (final categoryType in selectedCategories) {
      final category = DataCategory.getCategoryByType(categoryType);
      if (category != null) {
        fields.addAll(category.fields);
      }
    }
    return fields.toSet().toList();
  }

  DataQuery copyWith({
    List<DataCategoryType>? selectedCategories,
    Map<String, dynamic>? filters,
    String? playerFilter,
    String? teamFilter,
    String? seasonFilter,
    String? positionFilter,
  }) {
    return DataQuery(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      filters: filters ?? this.filters,
      playerFilter: playerFilter ?? this.playerFilter,
      teamFilter: teamFilter ?? this.teamFilter,
      seasonFilter: seasonFilter ?? this.seasonFilter,
      positionFilter: positionFilter ?? this.positionFilter,
    );
  }
}