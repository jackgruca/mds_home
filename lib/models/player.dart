// lib/models/player.dart
import 'package:flutter/material.dart';

// lib/models/player.dart (update to make properties mutable)
class Player {
  final int id;
  String name;
  String position;
  int rank;
  String school;
  String? notes;
  double? height;
  double? weight;
  double? rasScore;
  String? description;
  String? strengths;
  String? weaknesses;
  String? fortyTime;
  String? tenYardSplit;
  String? twentyYardShuttle;
  String? threeConeDrill;
  String? armLength;
  String? benchPress;
  String? broadJump;
  String? handSize;
  String? verticalJump;
  String? wingspan;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.rank,
    this.school = '',
    this.notes = '',
    this.height,
    this.weight,
    this.rasScore,
    this.description,
    this.strengths,
    this.weaknesses,
    this.fortyTime,
    this.tenYardSplit,
    this.twentyYardShuttle,
    this.threeConeDrill,
    this.armLength,
    this.benchPress,
    this.broadJump,
    this.handSize,
    this.verticalJump,
    this.wingspan,
  });
  
  // Create a Player from CSV row data
  factory Player.fromCsvRow(List<dynamic> row) {
    try {
      // Make sure row has enough elements
      if (row.length < 3) {
        debugPrint("Warning: Player row has insufficient columns: $row");
        return  Player(
          id: 0,
          name: "Unknown Player",
          position: "NA",
          rank: 999,
        );
      }
      
      // Parse ID safely
      int id = 0;
      try {
        id = int.tryParse(row[0].toString()) ?? 0;
      } catch (e) {
        debugPrint("Failed to parse player ID: ${row[0]}");
      }
      
      // Get name and position
      String name = row[1].toString();
      String position = row[2].toString();
      
      // Parse rank (which could be in different positions)
      int rank = 999;
      if (row.length > 3) {
        try {
          // Try to get rank from the last column
          rank = int.tryParse(row.last.toString()) ?? 999;
        } catch (e) {
          debugPrint("Failed to parse player rank from last column: ${row.last}");
        }
      }
      
      // Additional fields if available
      String school = row.length > 3 ? row[3].toString() : '';
      String? notes = row.length > 4 ? row[4].toString() : null;
      
      return Player(
        id: id,
        name: name,
        position: position,
        rank: rank,
        school: school,
        notes: notes,
      );
    } catch (e) {
      debugPrint("Error creating Player from row: $e");
      return  Player(
        id: 0,
        name: "Error Player",
        position: "NA",
        rank: 999,
      );
    }
  }
  
  // Add this method to the Player class
  factory Player.fromCsvRowWithHeaders(List<dynamic> row, Map<String, int> columnIndices) {
    try {
      // Get column indices (with fallbacks)
      int idIndex = columnIndices['ID'] ?? 0;
      int nameIndex = columnIndices['NAME'] ?? columnIndices['NAME'] ?? 1;
      int positionIndex = columnIndices['POSITION'] ?? columnIndices['POS'] ?? 2;
      int schoolIndex = columnIndices['SCHOOL'] ?? columnIndices['COLLEGE'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('SCHOOL') || entry.key.contains('COLLEGE'), 
              orElse: () => const MapEntry('', 3))
          .value;
      int notesIndex = columnIndices['NOTES'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('NOTES'), 
              orElse: () => const MapEntry('', -1))
          .value;
      
      // Find rank index - specifically look for combined_rank
      int rankIndex = -1;
      for (var entry in columnIndices.entries) {
        if (entry.key.contains('COMBINED_RANK') || entry.key.contains('RANK_COMBINED')) {
          rankIndex = entry.value;
          break;
        }
      }
      
      // If no combined rank found, try any rank column
      if (rankIndex == -1) {
        rankIndex = columnIndices.entries
            .firstWhere((entry) => entry.key.contains('RANK'), 
                orElse: () => MapEntry('', row.length - 1))
            .value;
      }
      
      // Height/Weight indices
      int heightIndex = columnIndices['HEIGHT'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('HEIGHT'), 
              orElse: () => const MapEntry('', -1))
          .value;
      
      int weightIndex = columnIndices['WEIGHT'] ?? columnIndices['WT'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('WEIGHT') || entry.key.contains('WT'), 
              orElse: () => const MapEntry('', -1))
          .value;
      
      int rasIndex = columnIndices['RAS'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('RAS') || entry.key.contains('ATHLETIC'), 
              orElse: () => const MapEntry('', -1))
          .value;
      
      int descriptionIndex = columnIndices['DESCRIPTION'] ?? columnIndices['ANALYSIS'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('DESCRIPTION') || entry.key.contains('ANALYSIS'), 
              orElse: () => const MapEntry('', -1))
          .value;
      
      int strengthsIndex = columnIndices['STRENGTHS'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('STRENGTH'), 
              orElse: () => const MapEntry('', -1))
          .value;
      
      int weaknessesIndex = columnIndices['WEAKNESSES'] ?? columnIndices.entries
          .firstWhere((entry) => entry.key.contains('WEAKNESS'), 
              orElse: () => const MapEntry('', -1))
          .value;

      int fortyTimeIndex = columnIndices['FORTY_TIME'] ?? columnIndices['40_TIME'] ?? columnIndices['40TIME'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('FORTY') || entry.key.contains('40_TIME'), 
            orElse: () => const MapEntry('', -1))
        .value;

      int tenYardSplitIndex = columnIndices['10_YARD_SPLIT'] ?? columnIndices['10YD_SPLIT'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('10_YARD') || entry.key.contains('10YD'), 
        orElse: () => const MapEntry('', -1))
    .value;

int twentyYardShuttleIndex = columnIndices['20_YARD_SHUTTLE'] ?? columnIndices['20YD_SHUTTLE'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('20_YARD') || entry.key.contains('20YD'), 
        orElse: () => const MapEntry('', -1))
    .value;

int threeConeDrillIndex = columnIndices['3_CONE_DRILL'] ?? columnIndices['3CONE'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('3_CONE') || entry.key.contains('3CONE'), 
        orElse: () => const MapEntry('', -1))
    .value;

int armLengthIndex = columnIndices['ARM_LENGTH'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('ARM_LENGTH') || entry.key.contains('ARM'), 
        orElse: () => const MapEntry('', -1))
    .value;

int benchPressIndex = columnIndices['BENCH_PRESS'] ?? columnIndices['BENCH'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('BENCH_PRESS') || entry.key.contains('BENCH'), 
        orElse: () => const MapEntry('', -1))
    .value;

int broadJumpIndex = columnIndices['BROAD_JUMP'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('BROAD_JUMP') || entry.key.contains('BROAD'), 
        orElse: () => const MapEntry('', -1))
    .value;

int handSizeIndex = columnIndices['HAND_SIZE'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('HAND_SIZE') || entry.key.contains('HAND'), 
        orElse: () => const MapEntry('', -1))
    .value;

int verticalJumpIndex = columnIndices['VERTICAL_JUMP'] ?? columnIndices['VERTICAL'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('VERTICAL_JUMP') || entry.key.contains('VERTICAL'), 
        orElse: () => const MapEntry('', -1))
    .value;

int wingspanIndex = columnIndices['WINGSPAN'] ?? columnIndices.entries
    .firstWhere((entry) => entry.key.contains('WINGSPAN') || entry.key.contains('WING'), 
        orElse: () => const MapEntry('', -1))
    .value;

      
      // Parse values safely
      int id = idIndex >= 0 && idIndex < row.length
          ? int.tryParse(row[idIndex].toString()) ?? 0
          : 0;
      
      String name = nameIndex >= 0 && nameIndex < row.length
          ? row[nameIndex].toString()
          : "Unknown Player";
      
      String position = positionIndex >= 0 && positionIndex < row.length
          ? row[positionIndex].toString()
          : "UNK";
      
      int rank = 999;
      if (rankIndex >= 0 && rankIndex < row.length) {
        String rankStr = row[rankIndex].toString().trim();
        if (rankStr.isNotEmpty) {
          rank = int.tryParse(rankStr) ?? 999;
        }
      }
      
      String school = schoolIndex >= 0 && schoolIndex < row.length
          ? row[schoolIndex].toString()
          : "";
      
      String? notes = notesIndex >= 0 && notesIndex < row.length
          ? row[notesIndex].toString()
          : null;
      
      // Parse the new fields
      double? height;
      if (heightIndex >= 0 && heightIndex < row.length) {
        String heightStr = row[heightIndex].toString().trim();
        // Try to handle height in different formats (6'2" or 74 inches)
        if (heightStr.contains("'")) {
          // Format like 6'2"
          try {
            List<String> parts = heightStr.replaceAll('"', '').split("'");
            int feet = int.tryParse(parts[0]) ?? 0;
            int inches = int.tryParse(parts[1]) ?? 0;
            height = (feet * 12 + inches).toDouble();
          } catch (e) {
            height = null;
          }
        } else {
          // Assume it's in inches
          height = double.tryParse(heightStr);
        }
      }
      
      double? weight;
      if (weightIndex >= 0 && weightIndex < row.length) {
        String weightStr = row[weightIndex].toString().trim();
        weight = double.tryParse(weightStr);
      }
      
      double? rasScore;
      if (rasIndex >= 0 && rasIndex < row.length) {
        String rasStr = row[rasIndex].toString().trim();
        rasScore = double.tryParse(rasStr);
      }
      
      String? description;
      if (descriptionIndex >= 0 && descriptionIndex < row.length) {
        description = row[descriptionIndex].toString().trim();
        if (description.isEmpty) description = null;
      }
      
      String? strengths;
      if (strengthsIndex >= 0 && strengthsIndex < row.length) {
        strengths = row[strengthsIndex].toString().trim();
        if (strengths.isEmpty) strengths = null;
      }
      
      String? weaknesses;
      if (weaknessesIndex >= 0 && weaknessesIndex < row.length) {
        weaknesses = row[weaknessesIndex].toString().trim();
        if (weaknesses.isEmpty) weaknesses = null;
      }

      String? fortyTime;
      if (fortyTimeIndex >= 0 && fortyTimeIndex < row.length) {
        fortyTime = row[fortyTimeIndex].toString().trim();
        if (fortyTime.isEmpty) fortyTime = null;
      }

      String? tenYardSplit = tenYardSplitIndex >= 0 && tenYardSplitIndex < row.length
    ? row[tenYardSplitIndex].toString().trim()
    : null;

String? twentyYardShuttle = twentyYardShuttleIndex >= 0 && twentyYardShuttleIndex < row.length
    ? row[twentyYardShuttleIndex].toString().trim()
    : null;

String? threeConeDrill = threeConeDrillIndex >= 0 && threeConeDrillIndex < row.length
    ? row[threeConeDrillIndex].toString().trim()
    : null;

String? armLength = armLengthIndex >= 0 && armLengthIndex < row.length
    ? row[armLengthIndex].toString().trim()
    : null;

String? benchPress = benchPressIndex >= 0 && benchPressIndex < row.length
    ? row[benchPressIndex].toString().trim()
    : null;

String? broadJump = broadJumpIndex >= 0 && broadJumpIndex < row.length
    ? row[broadJumpIndex].toString().trim()
    : null;

String? handSize = handSizeIndex >= 0 && handSizeIndex < row.length
    ? row[handSizeIndex].toString().trim()
    : null;

String? verticalJump = verticalJumpIndex >= 0 && verticalJumpIndex < row.length
    ? row[verticalJumpIndex].toString().trim()
    : null;

String? wingspan = wingspanIndex >= 0 && wingspanIndex < row.length
    ? row[wingspanIndex].toString().trim()
    : null;
      
      return Player(
        id: id,
        name: name,
        position: position,
        rank: rank,
        school: school,
        notes: notes,
        height: height,
        weight: weight,
        rasScore: rasScore,
        description: description,
        strengths: strengths,
        weaknesses: weaknesses,
        fortyTime: fortyTime,
        tenYardSplit: tenYardSplit,
        twentyYardShuttle: twentyYardShuttle,
        threeConeDrill: threeConeDrill,
        armLength: armLength,
        benchPress: benchPress,
        broadJump: broadJump,
        handSize: handSize,
        verticalJump: verticalJump,
        wingspan: wingspan,
      );
    } catch (e) {
      debugPrint("Error creating Player from row with headers: $e");
      return  Player(
        id: 0,
        name: "Error Player",
        position: "UNK",
        rank: 999,
      );
    }
  }
  
  // Convert player back to a list for compatibility with existing code
  List<dynamic> toList() {
    return [id.toString(), name, position, school, notes ?? '', rank.toString()];
  }
  
  // Format height from inches to feet and inches (74 -> 6'2")
  String get formattedHeight {
    if (height == null) return "N/A";
    
    int totalInches = height!.round();
    int feet = totalInches ~/ 12;
    int inches = totalInches % 12;
    
    return "$feet'$inches\"";
  }
  
  // Format weight with lbs
  String get formattedWeight {
    if (weight == null) return "N/A";
    return "${weight!.round()} lbs";
  }

  String get formatted40Time {
    if (fortyTime == null || fortyTime!.isEmpty) return "N/A";
    return "${fortyTime}s";
  }
  
  // Format RAS with 1 decimal place
  String get formattedRAS {
    if (rasScore == null) return "N/A";
    return rasScore!.toStringAsFixed(1);
  }
  
  // Create a description for the player if none exists
  String getDefaultDescription() {
    return "$name is a $position from $school. Ranked #$rank overall in this draft class.${strengths != null ? " Strengths include $strengths." : ""}${weaknesses != null ? " Areas for improvement include $weaknesses." : ""}";
  }

  String get formattedTenYardSplit => 
    tenYardSplit != null && tenYardSplit!.isNotEmpty ? "$tenYardSplit s" : "N/A";
  
  String get formattedTwentyYardShuttle => 
    twentyYardShuttle != null && twentyYardShuttle!.isNotEmpty ? "$twentyYardShuttle s" : "N/A";

  String get formattedThreeConeDrill =>
    threeConeDrill != null && threeConeDrill!.isNotEmpty ? "$threeConeDrill s" : "N/A";
  String get formattedArmLength =>
    armLength != null && armLength!.isNotEmpty ? "$armLength inches" : "N/A";
  String get formattedBenchPress =>
    benchPress != null && benchPress!.isNotEmpty ? "$benchPress reps" : "N/A";
  String get formattedBroadJump =>
    broadJump != null && broadJump!.isNotEmpty ? "$broadJump inches" : "N/A";
  String get formattedHandSize =>
    handSize != null && handSize!.isNotEmpty ? "$handSize inches" : "N/A";
  String get formattedVerticalJump =>
    verticalJump != null && verticalJump!.isNotEmpty ? "$verticalJump inches" : "N/A";
  String get formattedWingspan =>
    wingspan != null && wingspan!.isNotEmpty ? "$wingspan inches" : "N/A";
  @override
  String toString() => '$name ($position) - Rank: $rank';
}