class HistoricalDraftPick {
  final int year;
  final int round;
  final int pick;
  final String player;
  final String position;
  final String school;
  final String team;
  final String pickId;
  final DateTime lastUpdated;

  HistoricalDraftPick({
    required this.year,
    required this.round,
    required this.pick,
    required this.player,
    required this.position,
    required this.school,
    required this.team,
    required this.pickId,
    required this.lastUpdated,
  });

  factory HistoricalDraftPick.fromFirestore(Map<String, dynamic> data) {
    return HistoricalDraftPick(
      year: data['year'] ?? 0,
      round: data['round'] ?? 0,
      pick: data['pick'] ?? 0,
      player: data['player'] ?? '',
      position: data['position'] ?? '',
      school: data['school'] ?? '',
      team: data['team'] ?? '',
      pickId: data['pick_id'] ?? '',
      lastUpdated: data['last_updated'] != null 
        ? _parseTimestamp(data['last_updated'])
        : DateTime.now(),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    try {
      // Handle Firestore Timestamp objects
      if (timestamp.runtimeType.toString().contains('Timestamp')) {
        // Use reflection-safe approach for Firestore Timestamps
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch as int
        );
      }
      // Handle string timestamps
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      // Handle DateTime objects
      if (timestamp is DateTime) {
        return timestamp;
      }
      // Fallback
      return DateTime.now();
    } catch (e) {
      print('Error parsing timestamp: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'round': round,
      'pick': pick,
      'player': player,
      'position': position,
      'school': school,
      'team': team,
      'pick_id': pickId,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'HistoricalDraftPick(year: $year, round: $round, pick: $pick, player: $player, position: $position, team: $team)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoricalDraftPick &&
        other.year == year &&
        other.round == round &&
        other.pick == pick;
  }

  @override
  int get hashCode {
    return year.hashCode ^ round.hashCode ^ pick.hashCode;
  }

  // Helper methods
  String get displayName => player.isNotEmpty ? player : 'Unknown Player';
  String get displayPosition => position.isNotEmpty ? position : 'Unknown';
  String get displaySchool => school.isNotEmpty ? school : 'Unknown';
  String get displayTeam => team.isNotEmpty ? team : 'Unknown';
  
  // Overall pick number (calculated)
  int get overallPick => pick;
  
  // Round name helper
  String get roundName {
    switch (round) {
      case 1: return '1st';
      case 2: return '2nd';  
      case 3: return '3rd';
      default: return '${round}th';
    }
  }
  
  // Draft description helper
  String get draftDescription => '$year NFL Draft - Round $round, Pick $pick';
}