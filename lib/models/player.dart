// lib/models/player.dart
class Player {
  final int id;
  final String name;
  final String position;
  final int rank;
  final String school;
  final String? notes;
  
  const Player({
    required this.id,
    required this.name,
    required this.position,
    required this.rank,
    this.school = '',
    this.notes,
  });
  
  // Create a Player from CSV row data
  factory Player.fromCsvRow(List<dynamic> row) {
    return Player(
      id: int.tryParse(row[0].toString()) ?? 0,
      name: row[1].toString(),
      position: row[2].toString(),
      rank: int.tryParse(row.last.toString()) ?? 999, // Assuming last column is rank
      school: row.length > 3 ? row[3].toString() : '',
      notes: row.length > 4 ? row[4].toString() : null,
    );
  }
  
  // Convert player back to a list for compatibility with existing code
  List<dynamic> toList() {
    return [id.toString(), name, position, school, notes ?? '', rank.toString()];
  }
  
  @override
  String toString() => '$name ($position) - Rank: $rank';
}