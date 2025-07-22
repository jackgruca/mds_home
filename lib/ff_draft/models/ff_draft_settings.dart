class FFDraftSettings {
  final int numTeams;
  final String scoringSystem;
  final String platform;
  final int rosterSize;
  final List<String> rosterPositions;
  final bool isSnakeDraft;
  final int timePerPick; // in seconds
  final bool enableAutoPick;
  final bool enableTradeOffers;
  final int numRounds;

  const FFDraftSettings({
    required this.numTeams,
    required this.scoringSystem,
    required this.platform,
    required this.rosterSize,
    required this.rosterPositions,
    this.isSnakeDraft = true,
    this.timePerPick = 90,
    this.enableAutoPick = true,
    this.enableTradeOffers = true,
    required this.numRounds,
  });

  // Factory constructor to create settings from JSON
  factory FFDraftSettings.fromJson(Map<String, dynamic> json) {
    return FFDraftSettings(
      numTeams: json['numTeams'] as int,
      scoringSystem: json['scoringSystem'] as String,
      platform: json['platform'] as String,
      rosterSize: json['rosterSize'] as int,
      rosterPositions: List<String>.from(json['rosterPositions'] as List),
      isSnakeDraft: json['isSnakeDraft'] as bool? ?? true,
      timePerPick: json['timePerPick'] as int? ?? 90,
      enableAutoPick: json['enableAutoPick'] as bool? ?? true,
      enableTradeOffers: json['enableTradeOffers'] as bool? ?? true,
      numRounds: json['numRounds'] as int,
    );
  }

  // Convert settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'numTeams': numTeams,
      'scoringSystem': scoringSystem,
      'platform': platform,
      'rosterSize': rosterSize,
      'rosterPositions': rosterPositions,
      'isSnakeDraft': isSnakeDraft,
      'timePerPick': timePerPick,
      'enableAutoPick': enableAutoPick,
      'enableTradeOffers': enableTradeOffers,
      'numRounds': numRounds,
    };
  }

  // Create a copy of settings with some fields updated
  FFDraftSettings copyWith({
    int? numTeams,
    String? scoringSystem,
    String? platform,
    int? rosterSize,
    List<String>? rosterPositions,
    bool? isSnakeDraft,
    int? timePerPick,
    bool? enableAutoPick,
    bool? enableTradeOffers,
    int? numRounds,
  }) {
    return FFDraftSettings(
      numTeams: numTeams ?? this.numTeams,
      scoringSystem: scoringSystem ?? this.scoringSystem,
      platform: platform ?? this.platform,
      rosterSize: rosterSize ?? this.rosterSize,
      rosterPositions: rosterPositions ?? this.rosterPositions,
      isSnakeDraft: isSnakeDraft ?? this.isSnakeDraft,
      timePerPick: timePerPick ?? this.timePerPick,
      enableAutoPick: enableAutoPick ?? this.enableAutoPick,
      enableTradeOffers: enableTradeOffers ?? this.enableTradeOffers,
      numRounds: numRounds ?? this.numRounds,
    );
  }
} 