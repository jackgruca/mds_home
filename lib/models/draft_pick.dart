// lib/models/draft_pick.dart
import 'player.dart';

class DraftPick {
  final int pickNumber;
  String teamName;
  Player? selectedPlayer;
  final String round;
  final int? originalPickNumber;
  String? tradeInfo;
  
  DraftPick({
    required this.pickNumber,
    required this.teamName,
    this.selectedPlayer,
    required this.round,
    this.originalPickNumber,
    this.tradeInfo,
  });
  
  // Create a DraftPick from CSV row data
  factory DraftPick.fromCsvRow(List<dynamic> row) {
    return DraftPick(
      pickNumber: int.tryParse(row[0].toString()) ?? 0,
      teamName: row[1].toString(),
      round: row.length > 4 ? row[4].toString() : '1',
      originalPickNumber: row.length > 3 ? int.tryParse(row[3].toString()) : null,
      tradeInfo: row.length > 5 ? row[5].toString() : null,
    );
  }
  
  // Convert draft pick back to a list for compatibility with existing code
  List<dynamic> toList() {
    return [
      pickNumber,
      teamName,
      selectedPlayer?.name ?? '',
      selectedPlayer?.position ?? '',
      round,
      tradeInfo ?? '',
    ];
  }
  
  bool get isSelected => selectedPlayer != null;
  
  @override
  String toString() => 'Pick #$pickNumber: $teamName - ${selectedPlayer?.name ?? "Not Selected"}';
}