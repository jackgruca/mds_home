class DraftPlayer {
  final String name;
  final String position;
  final String school;
  final int rank;
  final String source;
  final DateTime lastUpdated;
  final Map<String, dynamic> additionalRanks;

  DraftPlayer({
    required this.name,
    required this.position,
    required this.school,
    required this.rank,
    required this.source,
    required this.lastUpdated,
    required this.additionalRanks,
  });

  DraftPlayer copyWith({
    String? name,
    String? position,
    String? school,
    int? rank,
    String? source,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalRanks,
  }) {
    return DraftPlayer(
      name: name ?? this.name,
      position: position ?? this.position,
      school: school ?? this.school,
      rank: rank ?? this.rank,
      source: source ?? this.source,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      additionalRanks: additionalRanks ?? this.additionalRanks,
    );
  }

  String get id => '$name-$school'; // Use name + school as unique identifier

  @override
  String toString() {
    return 'DraftPlayer(name: $name, position: $position, school: $school, rank: $rank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DraftPlayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}