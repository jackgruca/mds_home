class EnhancedRankingAttribute {
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
  final String dataSource;
  final List<String> csvMappings;
  final String calculationType;
  final Map<String, dynamic> metadata;

  const EnhancedRankingAttribute({
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
    this.dataSource = 'csv',
    this.csvMappings = const [],
    this.calculationType = 'direct',
    this.metadata = const {},
  });

  factory EnhancedRankingAttribute.fromJson(Map<String, dynamic> json) {
    return EnhancedRankingAttribute(
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
      dataSource: json['dataSource'] as String? ?? 'csv',
      csvMappings: List<String>.from(json['csvMappings'] as List<dynamic>? ?? []),
      calculationType: json['calculationType'] as String? ?? 'direct',
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
      'dataSource': dataSource,
      'csvMappings': csvMappings,
      'calculationType': calculationType,
      'metadata': metadata,
    };
  }

  EnhancedRankingAttribute copyWith({
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
    String? dataSource,
    List<String>? csvMappings,
    String? calculationType,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedRankingAttribute(
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
      dataSource: dataSource ?? this.dataSource,
      csvMappings: csvMappings ?? this.csvMappings,
      calculationType: calculationType ?? this.calculationType,
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
      case 'consensus':
        return '👥';
      default:
        return '⚡';
    }
  }

  bool get hasRealData => csvMappings.isNotEmpty && !isCustom;
}

class EnhancedAttributeLibrary {
  static final Map<String, List<EnhancedRankingAttribute>> positionAttributes = {
    'QB': [
      // Consensus Rankings
      const EnhancedRankingAttribute(
        id: 'consensus_rank',
        name: 'consensus_rank',
        displayName: 'Consensus Ranking',
        category: 'Consensus',
        position: 'QB',
        weight: 0.0,
        description: 'Overall consensus ranking from multiple experts',
        csvMappings: ['consensus_rank'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'projected_points',
        name: 'projected_points',
        displayName: 'Projected Points',
        category: 'Previous Performance',
        position: 'QB',
        weight: 0.0,
        description: 'Season projected fantasy points',
        unit: 'points',
        csvMappings: ['Projected Points'],
        calculationType: 'direct',
      ),
      const EnhancedRankingAttribute(
        id: 'adp',
        name: 'adp',
        displayName: 'Average Draft Position',
        category: 'Consensus',
        position: 'QB',
        weight: 0.0,
        description: 'Average draft position across leagues',
        csvMappings: ['ADP'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'auction_value',
        name: 'auction_value',
        displayName: 'Auction Value',
        category: 'Consensus',
        position: 'QB',
        weight: 0.0,
        description: 'Projected auction draft value',
        unit: '\$',
        csvMappings: ['Auction Value'],
        calculationType: 'direct',
      ),
      // Estimated Performance Metrics (would be real in production)
      const EnhancedRankingAttribute(
        id: 'passing_yards_per_game',
        name: 'passing_yards_per_game',
        displayName: 'Passing Yards/Game',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Estimated passing yards per game',
        unit: 'yards',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'passing_tds',
        name: 'passing_tds',
        displayName: 'Passing TDs',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Estimated season passing touchdowns',
        unit: 'TDs',
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'rushing_yards_per_game',
        name: 'rushing_yards_per_game',
        displayName: 'Rushing Yards/Game',
        category: 'Volume',
        position: 'QB',
        weight: 0.0,
        description: 'Estimated rushing yards per game',
        unit: 'yards',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'completion_percentage',
        name: 'completion_percentage',
        displayName: 'Completion %',
        category: 'Efficiency',
        position: 'QB',
        weight: 0.0,
        description: 'Estimated completion percentage',
        unit: '%',
        calculationType: 'estimated',
      ),
    ],
    'RB': [
      // Consensus Rankings
      const EnhancedRankingAttribute(
        id: 'consensus_rank',
        name: 'consensus_rank',
        displayName: 'Consensus Ranking',
        category: 'Consensus',
        position: 'RB',
        weight: 0.0,
        description: 'Overall consensus ranking from multiple experts',
        csvMappings: ['consensus_rank'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'projected_points',
        name: 'projected_points',
        displayName: 'Projected Points',
        category: 'Previous Performance',
        position: 'RB',
        weight: 0.0,
        description: 'Season projected fantasy points',
        unit: 'points',
        csvMappings: ['Projected Points'],
        calculationType: 'direct',
      ),
      const EnhancedRankingAttribute(
        id: 'adp',
        name: 'adp',
        displayName: 'Average Draft Position',
        category: 'Consensus',
        position: 'RB',
        weight: 0.0,
        description: 'Average draft position across leagues',
        csvMappings: ['ADP'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'auction_value',
        name: 'auction_value',
        displayName: 'Auction Value',
        category: 'Consensus',
        position: 'RB',
        weight: 0.0,
        description: 'Projected auction draft value',
        unit: '\$',
        csvMappings: ['Auction Value'],
        calculationType: 'direct',
      ),
      // Estimated Performance Metrics
      const EnhancedRankingAttribute(
        id: 'rushing_yards_per_game',
        name: 'rushing_yards_per_game',
        displayName: 'Rushing Yards/Game',
        category: 'Volume',
        position: 'RB',
        weight: 0.0,
        description: 'Estimated rushing yards per game',
        unit: 'yards',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'receptions_per_game',
        name: 'receptions_per_game',
        displayName: 'Receptions/Game',
        category: 'Volume',
        position: 'RB',
        weight: 0.0,
        description: 'Estimated receptions per game',
        unit: 'receptions',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'target_share',
        name: 'target_share',
        displayName: 'Target Share',
        category: 'Efficiency',
        position: 'RB',
        weight: 0.0,
        description: 'Estimated percentage of team targets',
        unit: '%',
        calculationType: 'estimated',
      ),
    ],
    'WR': [
      // Consensus Rankings
      const EnhancedRankingAttribute(
        id: 'consensus_rank',
        name: 'consensus_rank',
        displayName: 'Consensus Ranking',
        category: 'Consensus',
        position: 'WR',
        weight: 0.0,
        description: 'Overall consensus ranking from multiple experts',
        csvMappings: ['consensus_rank'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'projected_points',
        name: 'projected_points',
        displayName: 'Projected Points',
        category: 'Previous Performance',
        position: 'WR',
        weight: 0.0,
        description: 'Season projected fantasy points',
        unit: 'points',
        csvMappings: ['Projected Points'],
        calculationType: 'direct',
      ),
      const EnhancedRankingAttribute(
        id: 'adp',
        name: 'adp',
        displayName: 'Average Draft Position',
        category: 'Consensus',
        position: 'WR',
        weight: 0.0,
        description: 'Average draft position across leagues',
        csvMappings: ['ADP'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'auction_value',
        name: 'auction_value',
        displayName: 'Auction Value',
        category: 'Consensus',
        position: 'WR',
        weight: 0.0,
        description: 'Projected auction draft value',
        unit: '\$',
        csvMappings: ['Auction Value'],
        calculationType: 'direct',
      ),
      // Estimated Performance Metrics
      const EnhancedRankingAttribute(
        id: 'receptions_per_game',
        name: 'receptions_per_game',
        displayName: 'Receptions/Game',
        category: 'Volume',
        position: 'WR',
        weight: 0.0,
        description: 'Estimated receptions per game',
        unit: 'receptions',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'receiving_yards_per_game',
        name: 'receiving_yards_per_game',
        displayName: 'Receiving Yards/Game',
        category: 'Volume',
        position: 'WR',
        weight: 0.0,
        description: 'Estimated receiving yards per game',
        unit: 'yards',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'target_share',
        name: 'target_share',
        displayName: 'Target Share',
        category: 'Efficiency',
        position: 'WR',
        weight: 0.0,
        description: 'Estimated percentage of team targets',
        unit: '%',
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'red_zone_targets',
        name: 'red_zone_targets',
        displayName: 'Red Zone Targets',
        category: 'Red Zone',
        position: 'WR',
        weight: 0.0,
        description: 'Estimated red zone targets per season',
        unit: 'targets',
        calculationType: 'estimated',
      ),
    ],
    'TE': [
      // Consensus Rankings
      const EnhancedRankingAttribute(
        id: 'consensus_rank',
        name: 'consensus_rank',
        displayName: 'Consensus Ranking',
        category: 'Consensus',
        position: 'TE',
        weight: 0.0,
        description: 'Overall consensus ranking from multiple experts',
        csvMappings: ['consensus_rank'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'projected_points',
        name: 'projected_points',
        displayName: 'Projected Points',
        category: 'Previous Performance',
        position: 'TE',
        weight: 0.0,
        description: 'Season projected fantasy points',
        unit: 'points',
        csvMappings: ['Projected Points'],
        calculationType: 'direct',
      ),
      const EnhancedRankingAttribute(
        id: 'adp',
        name: 'adp',
        displayName: 'Average Draft Position',
        category: 'Consensus',
        position: 'TE',
        weight: 0.0,
        description: 'Average draft position across leagues',
        csvMappings: ['ADP'],
        calculationType: 'inverse_rank',
      ),
      const EnhancedRankingAttribute(
        id: 'auction_value',
        name: 'auction_value',
        displayName: 'Auction Value',
        category: 'Consensus',
        position: 'TE',
        weight: 0.0,
        description: 'Projected auction draft value',
        unit: '\$',
        csvMappings: ['Auction Value'],
        calculationType: 'direct',
      ),
      // Estimated Performance Metrics
      const EnhancedRankingAttribute(
        id: 'receptions_per_game',
        name: 'receptions_per_game',
        displayName: 'Receptions/Game',
        category: 'Volume',
        position: 'TE',
        weight: 0.0,
        description: 'Estimated receptions per game',
        unit: 'receptions',
        isPerGame: true,
        calculationType: 'estimated',
      ),
      const EnhancedRankingAttribute(
        id: 'target_share',
        name: 'target_share',
        displayName: 'Target Share',
        category: 'Efficiency',
        position: 'TE',
        weight: 0.0,
        description: 'Estimated percentage of team targets',
        unit: '%',
        calculationType: 'estimated',
      ),
    ],
  };

  static List<EnhancedRankingAttribute> getAttributesForPosition(String position) {
    return positionAttributes[position] ?? [];
  }

  static List<String> getCategories() {
    return ['Consensus', 'Volume', 'Efficiency', 'Previous Performance', 'Red Zone', 'Advanced'];
  }

  static List<EnhancedRankingAttribute> getAttributesByCategory(String position, String category) {
    final attributes = getAttributesForPosition(position);
    return attributes.where((attr) => attr.category == category).toList();
  }

  static EnhancedRankingAttribute? getAttributeById(String id) {
    for (final positionAttrs in positionAttributes.values) {
      for (final attr in positionAttrs) {
        if (attr.id == id) return attr;
      }
    }
    return null;
  }

  static List<EnhancedRankingAttribute> getAttributesWithRealData(String position) {
    return getAttributesForPosition(position)
        .where((attr) => attr.hasRealData)
        .toList();
  }
}