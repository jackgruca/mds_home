class RankingAttribute {
  final String id;
  final String name;
  final String displayName;
  final String category;
  final String position;
  final double weight;
  final String? description;
  final String? unit;
  final bool isPerGame;
  final bool isCustom;
  final Map<String, dynamic> metadata;

  RankingAttribute({
    required this.id,
    required this.name,
    required this.displayName,
    required this.category,
    required this.position,
    required this.weight,
    this.description,
    this.unit,
    this.isPerGame = false,
    this.isCustom = false,
    this.metadata = const {},
  });

  factory RankingAttribute.fromJson(Map<String, dynamic> json) {
    return RankingAttribute(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      category: json['category'] as String,
      position: json['position'] as String,
      weight: (json['weight'] as num).toDouble(),
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      isPerGame: json['isPerGame'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'category': category,
      'position': position,
      'weight': weight,
      'description': description,
      'unit': unit,
      'isPerGame': isPerGame,
      'isCustom': isCustom,
      'metadata': metadata,
    };
  }

  RankingAttribute copyWith({
    String? id,
    String? name,
    String? displayName,
    String? category,
    String? position,
    double? weight,
    String? description,
    String? unit,
    bool? isPerGame,
    bool? isCustom,
    Map<String, dynamic>? metadata,
  }) {
    return RankingAttribute(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      position: position ?? this.position,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      isPerGame: isPerGame ?? this.isPerGame,
      isCustom: isCustom ?? this.isCustom,
      metadata: metadata ?? this.metadata,
    );
  }

  String get formattedWeight => '${(weight * 100).toStringAsFixed(0)}%';
  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'volume':
        return '📊';
      case 'efficiency':
        return '🎯';
      case 'previous performance':
        return '📈';
      case 'red zone':
        return '🏆';
      case 'advanced':
        return '🔬';
      default:
        return '⚡';
    }
  }
}

class AttributeConstants {
  static final Map<String, List<RankingAttribute>> positionAttributes = {
    'QB': [
      RankingAttribute(
        id: 'passing_yards_per_game',
        name: 'passing_yards_per_game',
        displayName: 'Passing Yards/Game',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Average passing yards per game',
        unit: 'yards',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'passing_tds',
        name: 'passing_tds',
        displayName: 'Passing TDs',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Total passing touchdowns',
        unit: 'TDs',
      ),
      RankingAttribute(
        id: 'rushing_yards_per_game',
        name: 'rushing_yards_per_game',
        displayName: 'Rushing Yards/Game',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Average rushing yards per game',
        unit: 'yards',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'rushing_tds',
        name: 'rushing_tds',
        displayName: 'Rushing TDs',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Total rushing touchdowns',
        unit: 'TDs',
      ),
      RankingAttribute(
        id: 'previous_season_ppg',
        name: 'previous_season_ppg',
        displayName: 'Previous Season PPG',
        category: 'Previous Performance',
        position: 'QB',
        weight: 0.0,
        description: 'Points per game from previous season',
        unit: 'points',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'completion_percentage',
        name: 'completion_percentage',
        displayName: 'Completion %',
        category: 'Efficiency',
        position: 'QB',
        weight: 0.0,
        description: 'Completion percentage',
        unit: '%',
      ),
      RankingAttribute(
        id: 'int_rate',
        name: 'int_rate',
        displayName: 'INT Rate',
        category: 'Efficiency',
        position: 'QB',
        weight: 0.0,
        description: 'Interception rate',
        unit: '%',
      ),
    ],
    'RB': [
      RankingAttribute(
        id: 'rushing_yards_per_game',
        name: 'rushing_yards_per_game',
        displayName: 'Rushing Yards/Game',
        category: 'Volume',
        position: 'RB',
        weight: 0.0,
        description: 'Average rushing yards per game',
        unit: 'yards',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'rushing_tds',
        name: 'rushing_tds',
        displayName: 'Rushing TDs',
        category: 'Volume',
        position: 'RB',
        weight: 0.0,
        description: 'Total rushing touchdowns',
        unit: 'TDs',
      ),
      RankingAttribute(
        id: 'receptions_per_game',
        name: 'receptions_per_game',
        displayName: 'Receptions/Game',
        category: 'Volume',
        position: 'RB',
        weight: 0.0,
        description: 'Average receptions per game',
        unit: 'receptions',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'receiving_yards_per_game',
        name: 'receiving_yards_per_game',
        displayName: 'Receiving Yards/Game',
        category: 'Volume',
        position: 'RB',
        weight: 0.0,
        description: 'Average receiving yards per game',
        unit: 'yards',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'target_share',
        name: 'target_share',
        displayName: 'Target Share',
        category: 'Efficiency',
        position: 'RB',
        weight: 0.0,
        description: 'Percentage of team targets',
        unit: '%',
      ),
      RankingAttribute(
        id: 'previous_season_ppg',
        name: 'previous_season_ppg',
        displayName: 'Previous Season PPG',
        category: 'Previous Performance',
        position: 'RB',
        weight: 0.0,
        description: 'Points per game from previous season',
        unit: 'points',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'snap_percentage',
        name: 'snap_percentage',
        displayName: 'Snap %',
        category: 'Efficiency',
        position: 'RB',
        weight: 0.0,
        description: 'Percentage of team snaps',
        unit: '%',
      ),
    ],
    'WR': [
      RankingAttribute(
        id: 'receptions_per_game',
        name: 'receptions_per_game',
        displayName: 'Receptions/Game',
        category: 'Volume',
        position: 'WR',
        weight: 0.0,
        description: 'Average receptions per game',
        unit: 'receptions',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'receiving_yards_per_game',
        name: 'receiving_yards_per_game',
        displayName: 'Receiving Yards/Game',
        category: 'Volume',
        position: 'WR',
        weight: 0.0,
        description: 'Average receiving yards per game',
        unit: 'yards',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'receiving_tds',
        name: 'receiving_tds',
        displayName: 'Receiving TDs',
        category: 'Volume',
        position: 'WR',
        weight: 0.0,
        description: 'Total receiving touchdowns',
        unit: 'TDs',
      ),
      RankingAttribute(
        id: 'target_share',
        name: 'target_share',
        displayName: 'Target Share',
        category: 'Efficiency',
        position: 'WR',
        weight: 0.0,
        description: 'Percentage of team targets',
        unit: '%',
      ),
      RankingAttribute(
        id: 'red_zone_targets',
        name: 'red_zone_targets',
        displayName: 'Red Zone Targets',
        category: 'Red Zone',
        position: 'WR',
        weight: 0.0,
        description: 'Total red zone targets',
        unit: 'targets',
      ),
      RankingAttribute(
        id: 'previous_season_ppg',
        name: 'previous_season_ppg',
        displayName: 'Previous Season PPG',
        category: 'Previous Performance',
        position: 'WR',
        weight: 0.0,
        description: 'Points per game from previous season',
        unit: 'points',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'air_yards',
        name: 'air_yards',
        displayName: 'Air Yards',
        category: 'Advanced',
        position: 'WR',
        weight: 0.0,
        description: 'Total air yards',
        unit: 'yards',
      ),
    ],
    'TE': [
      RankingAttribute(
        id: 'receptions_per_game',
        name: 'receptions_per_game',
        displayName: 'Receptions/Game',
        category: 'Volume',
        position: 'TE',
        weight: 0.0,
        description: 'Average receptions per game',
        unit: 'receptions',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'receiving_yards_per_game',
        name: 'receiving_yards_per_game',
        displayName: 'Receiving Yards/Game',
        category: 'Volume',
        position: 'TE',
        weight: 0.0,
        description: 'Average receiving yards per game',
        unit: 'yards',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'receiving_tds',
        name: 'receiving_tds',
        displayName: 'Receiving TDs',
        category: 'Volume',
        position: 'TE',
        weight: 0.0,
        description: 'Total receiving touchdowns',
        unit: 'TDs',
      ),
      RankingAttribute(
        id: 'target_share',
        name: 'target_share',
        displayName: 'Target Share',
        category: 'Efficiency',
        position: 'TE',
        weight: 0.0,
        description: 'Percentage of team targets',
        unit: '%',
      ),
      RankingAttribute(
        id: 'red_zone_targets',
        name: 'red_zone_targets',
        displayName: 'Red Zone Targets',
        category: 'Red Zone',
        position: 'TE',
        weight: 0.0,
        description: 'Total red zone targets',
        unit: 'targets',
      ),
      RankingAttribute(
        id: 'previous_season_ppg',
        name: 'previous_season_ppg',
        displayName: 'Previous Season PPG',
        category: 'Previous Performance',
        position: 'TE',
        weight: 0.0,
        description: 'Points per game from previous season',
        unit: 'points',
        isPerGame: true,
      ),
      RankingAttribute(
        id: 'snap_percentage',
        name: 'snap_percentage',
        displayName: 'Snap %',
        category: 'Efficiency',
        position: 'TE',
        weight: 0.0,
        description: 'Percentage of team snaps',
        unit: '%',
      ),
    ],
  };

  static List<RankingAttribute> getAttributesForPosition(String position) {
    return positionAttributes[position] ?? [];
  }

  static List<String> getCategories() {
    return ['Volume', 'Efficiency', 'Previous Performance', 'Red Zone', 'Advanced'];
  }
}