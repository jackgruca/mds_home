// lib/models/data_category.dart
import 'package:flutter/material.dart';

enum DataCategoryType {
  // Main Categories - Simple Structure
  playerSeasonStats,
  playerGameStats,
  gameStats,
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
      type: DataCategoryType.playerSeasonStats,
      name: 'Player Season Stats',
      description: 'Season-level player statistics with positional breakdowns',
      icon: Icons.person,
      color: Colors.blue,
      fields: [
        'passing_yards', 'passing_tds', 'rushing_yards', 'rushing_tds',
        'receiving_yards', 'receiving_tds', 'receptions', 'targets',
        'completions', 'attempts', 'interceptions', 'fumbles',
      ],
      routes: ['/player-season-stats', '/data/passing', '/data/rushing', '/data/receiving'],
    ),

    DataCategory(
      type: DataCategoryType.playerGameStats,
      name: 'Player Game Stats',
      description: 'Game-by-game player performance and logs',
      icon: Icons.sports_football,
      color: Colors.green,
      fields: [
        'game_id', 'week', 'opponent', 'home_away', 'game_result',
        'passing_yards', 'passing_tds', 'rushing_yards', 'rushing_tds',
        'receiving_yards', 'receiving_tds', 'fantasy_points_ppr',
      ],
      routes: ['/player-game-stats'],
    ),

    DataCategory(
      type: DataCategoryType.gameStats,
      name: 'Game Stats',
      description: 'Game-level data including scores, betting, and weather',
      icon: Icons.scoreboard,
      color: Colors.orange,
      fields: [
        'game_id', 'season', 'week', 'home_team', 'away_team',
        'home_score', 'away_score', 'spread_line', 'total_line',
        'temp', 'wind', 'roof', 'surface',
      ],
      routes: ['/games', '/historical-game-data'],
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