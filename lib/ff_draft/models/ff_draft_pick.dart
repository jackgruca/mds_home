import 'ff_player.dart';
import 'ff_team.dart';

class FFDraftPick {
  final int pickNumber;
  final int round;
  final FFTeam team;
  FFPlayer? selectedPlayer;
  final DateTime? timestamp;
  final bool isUserPick;

  FFDraftPick({
    required this.pickNumber,
    required this.round,
    required this.team,
    this.selectedPlayer,
    this.timestamp,
    this.isUserPick = false,
  });

  // Factory constructor to create a pick from JSON
  factory FFDraftPick.fromJson(Map<String, dynamic> json) {
    return FFDraftPick(
      pickNumber: json['pickNumber'] as int,
      round: json['round'] as int,
      team: FFTeam.fromJson(json['team'] as Map<String, dynamic>),
      selectedPlayer: json['selectedPlayer'] != null 
          ? FFPlayer.fromJson(json['selectedPlayer'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      isUserPick: json['isUserPick'] as bool? ?? false,
    );
  }

  // Convert pick to JSON
  Map<String, dynamic> toJson() {
    return {
      'pickNumber': pickNumber,
      'round': round,
      'team': team.toJson(),
      'selectedPlayer': selectedPlayer?.toJson(),
      'timestamp': timestamp?.toIso8601String(),
      'isUserPick': isUserPick,
    };
  }

  // Create a pick with a selected player
  FFDraftPick withPlayer(FFPlayer player) {
    return FFDraftPick(
      pickNumber: pickNumber,
      round: round,
      team: team,
      selectedPlayer: player,
      timestamp: DateTime.now(),
      isUserPick: isUserPick,
    );
  }

  // Check if the pick has been made
  bool get isSelected => selectedPlayer != null;

  // Get the pick description
  String get description {
    if (selectedPlayer == null) {
      return 'Pick #$pickNumber (Round $round) - ${team.name}';
    }
    return 'Pick #$pickNumber (Round $round) - ${team.name} selects ${selectedPlayer!.name} (${selectedPlayer!.position})';
  }

  FFDraftPick copyWith({
    int? pickNumber,
    int? round,
    FFTeam? team,
    FFPlayer? selectedPlayer,
    DateTime? timestamp,
    bool? isUserPick,
  }) {
    return FFDraftPick(
      pickNumber: pickNumber ?? this.pickNumber,
      round: round ?? this.round,
      team: team ?? this.team,
      selectedPlayer: selectedPlayer ?? this.selectedPlayer,
      timestamp: timestamp ?? this.timestamp,
      isUserPick: isUserPick ?? this.isUserPick,
    );
  }
} 