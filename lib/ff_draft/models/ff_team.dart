import 'ff_player.dart';
import 'ff_ai_personality.dart';

class FFTeam {
  final String id;
  final String name;
  List<FFPlayer> roster;
  final int? draftPosition;
  final Map<String, int>? positionCounts;
  final bool isUserTeam;
  final FFAIPersonality? aiPersonality;
  final Map<String, dynamic>? draftTendencies;

  FFTeam({
    required this.id,
    required this.name,
    List<FFPlayer>? roster,
    this.draftPosition,
    this.positionCounts,
    this.isUserTeam = false,
    this.aiPersonality,
    this.draftTendencies,
  }) : roster = roster ?? [];

  // Factory constructor to create a team from JSON
  factory FFTeam.fromJson(Map<String, dynamic> json) {
    FFAIPersonality? personality;
    if (json['aiPersonalityType'] != null) {
      final personalityType = FFAIPersonalityType.values.firstWhere(
        (type) => type.toString() == json['aiPersonalityType'],
        orElse: () => FFAIPersonalityType.valueHunter,
      );
      personality = FFAIPersonality.getPersonality(personalityType);
    }

    return FFTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      roster: (json['roster'] as List)
          .map((player) => FFPlayer.fromJson(player as Map<String, dynamic>))
          .toList(),
      draftPosition: json['draftPosition'] as int?,
      positionCounts: (json['positionCounts'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ),
      isUserTeam: json['isUserTeam'] as bool? ?? false,
      aiPersonality: personality,
      draftTendencies: json['draftTendencies'] as Map<String, dynamic>?,
    );
  }

  // Convert team to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roster': roster.map((player) => player.toJson()).toList(),
      'draftPosition': draftPosition,
      'positionCounts': positionCounts,
      'isUserTeam': isUserTeam,
      'aiPersonalityType': aiPersonality?.type.toString(),
      'draftTendencies': draftTendencies,
    };
  }

  // Add a player to the roster
  FFTeam addPlayer(FFPlayer player) {
    final newRoster = List<FFPlayer>.from(roster)..add(player);
    final newPositionCounts = Map<String, int>.from(positionCounts ?? {});
    newPositionCounts[player.position] = (newPositionCounts[player.position] ?? 0) + 1;
    
    return FFTeam(
      id: id,
      name: name,
      roster: newRoster,
      draftPosition: draftPosition,
      positionCounts: newPositionCounts,
      isUserTeam: isUserTeam,
      aiPersonality: aiPersonality,
      draftTendencies: draftTendencies,
    );
  }

  // Remove a player from the roster
  FFTeam removePlayer(FFPlayer player) {
    final newRoster = List<FFPlayer>.from(roster)..remove(player);
    final newPositionCounts = Map<String, int>.from(positionCounts ?? {});
    newPositionCounts[player.position] = (newPositionCounts[player.position] ?? 1) - 1;
    
    return FFTeam(
      id: id,
      name: name,
      roster: newRoster,
      draftPosition: draftPosition,
      positionCounts: newPositionCounts,
      isUserTeam: isUserTeam,
      aiPersonality: aiPersonality,
      draftTendencies: draftTendencies,
    );
  }

  // Get players by position
  List<FFPlayer> getPlayersByPosition(String position) {
    return roster.where((player) => player.position == position).toList();
  }

  // Get count of players by position
  int getPositionCount(String position) {
    return positionCounts?[position] ?? 0;
  }

  // Get all position counts as a map
  Map<String, int> getPositionCounts() {
    final counts = <String, int>{
      'QB': 0,
      'RB': 0,
      'WR': 0,
      'TE': 0,
      'K': 0,
      'DEF': 0,
    };
    
    // Count actual players in roster
    for (final player in roster) {
      counts[player.position] = (counts[player.position] ?? 0) + 1;
    }
    
    return counts;
  }

  // Check if team needs a position
  bool needsPosition(String position, int requiredCount) {
    return getPositionCount(position) < requiredCount;
  }

  FFTeam copyWith({
    String? id,
    String? name,
    List<FFPlayer>? roster,
    int? draftPosition,
    Map<String, int>? positionCounts,
    bool? isUserTeam,
    FFAIPersonality? aiPersonality,
    Map<String, dynamic>? draftTendencies,
  }) {
    return FFTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      roster: roster ?? this.roster,
      draftPosition: draftPosition ?? this.draftPosition,
      positionCounts: positionCounts ?? this.positionCounts,
      isUserTeam: isUserTeam ?? this.isUserTeam,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      draftTendencies: draftTendencies ?? this.draftTendencies,
    );
  }

  // AI-specific helper methods
  String get personalityName => aiPersonality?.name ?? 'Unknown';
  String get personalityDescription => aiPersonality?.description ?? '';
  bool get hasAIPersonality => aiPersonality != null && !isUserTeam;

  // Get tendency value
  double getTendency(String tendencyKey, {double defaultValue = 0.5}) {
    if (draftTendencies == null) return defaultValue;
    return (draftTendencies![tendencyKey] as double?) ?? defaultValue;
  }

  // Factory method to create AI team with personality
  factory FFTeam.createAITeam({
    required String id,
    required String name,
    required int draftPosition,
    required FFAIPersonality personality,
  }) {
    return FFTeam(
      id: id,
      name: name,
      draftPosition: draftPosition,
      isUserTeam: false,
      aiPersonality: personality,
      draftTendencies: {
        'aggressiveness': personality.getTrait('reachTolerance'),
        'conservatism': personality.getTrait('riskTolerance'),
        'needFocus': personality.getTrait('needWeight'),
        'valueFocus': personality.getTrait('valueWeight'),
      },
    );
  }
} 