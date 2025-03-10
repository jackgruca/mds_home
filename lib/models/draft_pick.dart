// lib/models/draft_pick.dart
import 'package:flutter/material.dart';

import 'player.dart';

class DraftPick {
  final int pickNumber;
  String teamName;
  Player? selectedPlayer;
  final String round;
  final int? originalPickNumber;
  String? tradeInfo;
  bool isActiveInDraft = true;  // New property
  
  DraftPick({
    required this.pickNumber,
    required this.teamName,
    this.selectedPlayer,
    required this.round,
    this.originalPickNumber,
    this.tradeInfo,
    this.isActiveInDraft = true,
  });
  
  // Create a DraftPick from CSV row data
  factory DraftPick.fromCsvRow(List<dynamic> row) {
  try {
    if (row.length < 2) {
      debugPrint("Warning: DraftPick row has insufficient columns: $row");
      return DraftPick(
        pickNumber: 0,
        teamName: "Unknown Team",
        round: '1',
      );
    }
    
    // Parse pick number safely
    int pickNumber = 0;
    try {
      pickNumber = int.tryParse(row[0].toString()) ?? 0;
    } catch (e) {
      debugPrint("Failed to parse pick number: ${row[0]}");
    }
    
    // Get team name
    String teamName = row[1].toString();
    
    // Try to get the round
    String round = '1';
    if (row.length > 4) {
      round = row[4].toString();
    } else {
      // Calculate round from pick number if not provided
      round = ((pickNumber - 1) / 32 + 1).floor().toString();
    }
    
    // Get other optional fields
    int? originalPickNumber = row.length > 3 ? int.tryParse(row[3].toString()) : null;
    String? tradeInfo = row.length > 5 ? row[5].toString() : null;
    
    return DraftPick(
      pickNumber: pickNumber,
      teamName: teamName,
      round: round,
      originalPickNumber: originalPickNumber,
      tradeInfo: tradeInfo,
    );
  } catch (e) {
    debugPrint("Error creating DraftPick from row: $e");
    return DraftPick(
      pickNumber: 0,
      teamName: "Error Team",
      round: '1',
    );
  }
}
// Add this method to the DraftPick class
factory DraftPick.fromCsvRowWithHeaders(List<dynamic> row, Map<String, int> columnIndices) {
  try {
    // Get column indices (with fallbacks if column names don't match exactly)
    int pickIndex = columnIndices['PICK'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('PICK'), orElse: () => const MapEntry('', 0))
        .value;
    
    int teamIndex = columnIndices['TEAM'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('TEAM'), orElse: () => const MapEntry('', 1))
        .value;
    
    int roundIndex = columnIndices['ROUND'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('ROUND'), orElse: () => const MapEntry('', -1))
        .value;
    
    int tradeIndex = columnIndices['TRADE'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('TRADE'), orElse: () => const MapEntry('', -1))
        .value;
    
    // Parse values
    int pickNumber = pickIndex >= 0 && pickIndex < row.length
        ? int.tryParse(row[pickIndex].toString()) ?? 0
        : 0;
    
    String teamName = teamIndex >= 0 && teamIndex < row.length
        ? row[teamIndex].toString()
        : "Unknown Team";
    
    String round = roundIndex >= 0 && roundIndex < row.length
        ? row[roundIndex].toString()
        : ((pickNumber - 1) / 32 + 1).floor().toString(); // Calculate round from pick number
    
    String? tradeInfo = tradeIndex >= 0 && tradeIndex < row.length
        ? row[tradeIndex].toString()
        : null;
    
    if (teamName.isEmpty) {
      teamName = "Unknown Team";
    }
    
    return DraftPick(
      pickNumber: pickNumber,
      teamName: teamName,
      round: round,
      tradeInfo: tradeInfo?.isEmpty ?? true ? null : tradeInfo,
    );
  } catch (e) {
    debugPrint("Error creating DraftPick from row with headers: $e");
    return DraftPick(
      pickNumber: 0,
      teamName: "Error Team",
      round: '1',
    );
  }
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