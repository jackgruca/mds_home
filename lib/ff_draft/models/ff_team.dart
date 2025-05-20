import 'ff_player.dart';

class FFTeam {
  final String id;
  final String name;
  List<FFPlayer> roster;
  final int? draftPosition;
  final Map<String, int>? positionCounts;
  final bool isUserTeam;

  FFTeam({
    required this.id,
    required this.name,
    List<FFPlayer>? roster,
    this.draftPosition,
    this.positionCounts,
    this.isUserTeam = false,
  }) : roster = roster ?? [];

  // Factory constructor to create a team from JSON
  factory FFTeam.fromJson(Map<String, dynamic> json) {
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
  }) {
    return FFTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      roster: roster ?? this.roster,
      draftPosition: draftPosition ?? this.draftPosition,
      positionCounts: positionCounts ?? this.positionCounts,
      isUserTeam: isUserTeam ?? this.isUserTeam,
    );
  }
} 