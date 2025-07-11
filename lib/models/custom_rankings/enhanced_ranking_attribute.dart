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

