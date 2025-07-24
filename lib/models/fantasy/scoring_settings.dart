enum ScoringType {
  standard,
  halfPPR,
  ppr,
  custom,
}

class ScoringSettings {
  // Basic scoring type
  final ScoringType scoringType;
  
  // Passing
  final double passingYardsPerPoint; // 1 point per 25 yards
  final double passingTDPoints;
  final double interceptionPoints;
  
  // Rushing
  final double rushingYardsPerPoint; // 1 point per 10 yards
  final double rushingTDPoints;
  
  // Receiving
  final double receptionPoints; // PPR value
  final double receivingYardsPerPoint; // 1 point per 10 yards
  final double receivingTDPoints;
  
  // TE Premium
  final double tePremiumBonus; // Additional points per TE reception
  
  // Common bonuses
  final bool passing300YardBonus;
  final double passing300YardBonusPoints;
  final bool rushing100YardBonus;
  final double rushing100YardBonusPoints;
  final bool receiving100YardBonus;
  final double receiving100YardBonusPoints;
  
  // Other scoring
  final double fumbleLostPoints;
  final double twoPointConversionPoints;
  
  // Metadata
  final String? customName;
  final DateTime? createdAt;
  final DateTime? lastModified;

  const ScoringSettings({
    required this.scoringType,
    this.passingYardsPerPoint = 0.04,
    this.passingTDPoints = 4,
    this.interceptionPoints = -2,
    this.rushingYardsPerPoint = 0.1,
    this.rushingTDPoints = 6,
    this.receptionPoints = 1.0,
    this.receivingYardsPerPoint = 0.1,
    this.receivingTDPoints = 6,
    this.tePremiumBonus = 0,
    this.passing300YardBonus = false,
    this.passing300YardBonusPoints = 3,
    this.rushing100YardBonus = false,
    this.rushing100YardBonusPoints = 3,
    this.receiving100YardBonus = false,
    this.receiving100YardBonusPoints = 3,
    this.fumbleLostPoints = -2,
    this.twoPointConversionPoints = 2,
    this.customName,
    this.createdAt,
    this.lastModified,
  });

  factory ScoringSettings.fromJson(Map<String, dynamic> json) {
    return ScoringSettings(
      scoringType: ScoringType.values[json['scoringType'] ?? 0],
      passingYardsPerPoint: (json['passingYardsPerPoint'] ?? 0.04).toDouble(),
      passingTDPoints: (json['passingTDPoints'] ?? 4).toDouble(),
      interceptionPoints: (json['interceptionPoints'] ?? -2).toDouble(),
      rushingYardsPerPoint: (json['rushingYardsPerPoint'] ?? 0.1).toDouble(),
      rushingTDPoints: (json['rushingTDPoints'] ?? 6).toDouble(),
      receptionPoints: (json['receptionPoints'] ?? 1.0).toDouble(),
      receivingYardsPerPoint: (json['receivingYardsPerPoint'] ?? 0.1).toDouble(),
      receivingTDPoints: (json['receivingTDPoints'] ?? 6).toDouble(),
      tePremiumBonus: (json['tePremiumBonus'] ?? 0).toDouble(),
      passing300YardBonus: json['passing300YardBonus'] ?? false,
      passing300YardBonusPoints: (json['passing300YardBonusPoints'] ?? 3).toDouble(),
      rushing100YardBonus: json['rushing100YardBonus'] ?? false,
      rushing100YardBonusPoints: (json['rushing100YardBonusPoints'] ?? 3).toDouble(),
      receiving100YardBonus: json['receiving100YardBonus'] ?? false,
      receiving100YardBonusPoints: (json['receiving100YardBonusPoints'] ?? 3).toDouble(),
      fumbleLostPoints: (json['fumbleLostPoints'] ?? -2).toDouble(),
      twoPointConversionPoints: (json['twoPointConversionPoints'] ?? 2).toDouble(),
      customName: json['customName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'scoringType': scoringType.index,
      'passingYardsPerPoint': passingYardsPerPoint,
      'passingTDPoints': passingTDPoints,
      'interceptionPoints': interceptionPoints,
      'rushingYardsPerPoint': rushingYardsPerPoint,
      'rushingTDPoints': rushingTDPoints,
      'receptionPoints': receptionPoints,
      'receivingYardsPerPoint': receivingYardsPerPoint,
      'receivingTDPoints': receivingTDPoints,
      'tePremiumBonus': tePremiumBonus,
      'passing300YardBonus': passing300YardBonus,
      'passing300YardBonusPoints': passing300YardBonusPoints,
      'rushing100YardBonus': rushing100YardBonus,
      'rushing100YardBonusPoints': rushing100YardBonusPoints,
      'receiving100YardBonus': receiving100YardBonus,
      'receiving100YardBonusPoints': receiving100YardBonusPoints,
      'fumbleLostPoints': fumbleLostPoints,
      'twoPointConversionPoints': twoPointConversionPoints,
      'customName': customName,
      'createdAt': createdAt?.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  // Preset configurations
  static const standard = ScoringSettings(
    scoringType: ScoringType.standard,
    receptionPoints: 0,
  );

  static const halfPPR = ScoringSettings(
    scoringType: ScoringType.halfPPR,
    receptionPoints: 0.5,
  );

  static const ppr = ScoringSettings(
    scoringType: ScoringType.ppr,
    receptionPoints: 1.0,
  );

  static const dynastySuperFlex = ScoringSettings(
    scoringType: ScoringType.custom,
    receptionPoints: 1.0,
    passingTDPoints: 6,
    tePremiumBonus: 0.5,
    customName: 'Dynasty SuperFlex',
  );

  static const bestBall = ScoringSettings(
    scoringType: ScoringType.custom,
    receptionPoints: 1.0,
    passing300YardBonus: true,
    rushing100YardBonus: true,
    receiving100YardBonus: true,
    customName: 'Best Ball',
  );

  // Helper methods
  bool get isCustom => scoringType == ScoringType.custom;
  
  String get displayName {
    if (customName != null) return customName!;
    switch (scoringType) {
      case ScoringType.standard:
        return 'Standard';
      case ScoringType.halfPPR:
        return 'Half-PPR';
      case ScoringType.ppr:
        return 'PPR';
      case ScoringType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (scoringType) {
      case ScoringType.standard:
        return 'No points for receptions';
      case ScoringType.halfPPR:
        return '0.5 points per reception';
      case ScoringType.ppr:
        return '1 point per reception';
      case ScoringType.custom:
        return _buildCustomDescription();
    }
  }

  String _buildCustomDescription() {
    final features = <String>[];
    
    if (receptionPoints != 1.0) {
      features.add('${receptionPoints} PPR');
    }
    if (passingTDPoints != 4) {
      features.add('${passingTDPoints.toStringAsFixed(0)}pt Pass TD');
    }
    if (tePremiumBonus > 0) {
      features.add('TE Premium +${tePremiumBonus}');
    }
    
    return features.isEmpty ? 'Custom scoring' : features.join(', ');
  }

  // Calculate points for a player's projected stats
  double calculatePoints({
    required String position,
    double passingYards = 0,
    double passingTDs = 0,
    double interceptions = 0,
    double rushingYards = 0,
    double rushingTDs = 0,
    double receptions = 0,
    double receivingYards = 0,
    double receivingTDs = 0,
    double fumblesLost = 0,
  }) {
    double points = 0;

    // Passing
    points += passingYards * passingYardsPerPoint;
    points += passingTDs * passingTDPoints;
    points += interceptions * interceptionPoints;

    // Rushing
    points += rushingYards * rushingYardsPerPoint;
    points += rushingTDs * rushingTDPoints;

    // Receiving
    points += receptions * receptionPoints;
    points += receivingYards * receivingYardsPerPoint;
    points += receivingTDs * receivingTDPoints;

    // TE Premium
    if (position == 'TE' && tePremiumBonus > 0) {
      points += receptions * tePremiumBonus;
    }

    // Bonuses
    if (passing300YardBonus && passingYards >= 300) {
      points += passing300YardBonusPoints;
    }
    if (rushing100YardBonus && rushingYards >= 100) {
      points += rushing100YardBonusPoints;
    }
    if (receiving100YardBonus && receivingYards >= 100) {
      points += receiving100YardBonusPoints;
    }

    // Other
    points += fumblesLost * fumbleLostPoints;

    return points;
  }
}

// Preset template for UI
class ScoringPreset {
  final String name;
  final String description;
  final String emoji;
  final ScoringSettings settings;
  final List<String> features;

  const ScoringPreset({
    required this.name,
    required this.description,
    required this.emoji,
    required this.settings,
    this.features = const [],
  });

  factory ScoringPreset.fromJson(Map<String, dynamic> json) {
    return ScoringPreset(
      name: json['name'],
      description: json['description'],
      emoji: json['emoji'],
      settings: ScoringSettings.fromJson(json['settings']),
      features: List<String>.from(json['features'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'emoji': emoji,
      'settings': settings.toJson(),
      'features': features,
    };
  }
}

// Common preset templates
class ScoringPresets {
  static final List<ScoringPreset> all = [
    ScoringPreset(
      name: 'Standard',
      description: 'Traditional scoring without reception points',
      emoji: '⚡',
      settings: ScoringSettings.standard,
      features: ['No PPR', 'TD-focused', 'RB-friendly'],
    ),
    ScoringPreset(
      name: 'Half-PPR',
      description: 'Balanced scoring with 0.5 points per catch',
      emoji: '⚖️',
      settings: ScoringSettings.halfPPR,
      features: ['0.5 PPR', 'Balanced', 'Most common'],
    ),
    ScoringPreset(
      name: 'Full PPR',
      description: '1 point per reception favoring pass-catchers',
      emoji: '🎯',
      settings: ScoringSettings.ppr,
      features: ['1.0 PPR', 'WR/TE boost', 'High scoring'],
    ),
    ScoringPreset(
      name: 'Dynasty SuperFlex',
      description: '2QB dynasty leagues with TE premium',
      emoji: '🏆',
      settings: ScoringSettings.dynastySuperFlex,
      features: ['6pt Pass TD', 'TE Premium', 'QB-heavy'],
    ),
    ScoringPreset(
      name: 'Best Ball',
      description: 'Full PPR with performance bonuses',
      emoji: '🎲',
      settings: ScoringSettings.bestBall,
      features: ['Full PPR', 'Big play bonuses', 'No waivers'],
    ),
  ];
}