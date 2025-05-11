// lib/utils/mock_player_data.dart
import 'dart:math';

import '../models/player.dart';

class MockPlayerData {
  // In MockPlayerData.enrichPlayerData method
static Player enrichPlayerData(Player player) {
  Random random = Random();
  
  // Generate mock data only if the original is missing
  double? height = player.height ?? (68 + random.nextInt(8)).toDouble(); // 5'8" to 6'4"
  double? weight = player.weight ?? (180 + random.nextInt(80)).toDouble(); // 180-260 lbs
  double? rasScore = player.rasScore ?? (4 + random.nextDouble() * 6); // 4.0-10.0
  String? fortyTime = player.fortyTime ?? (4.3 + random.nextDouble() * 0.7).toStringAsFixed(2); // 4.3-5.0
  
  // Generate mock athletic measurements if missing
  String? tenYardSplit = player.tenYardSplit ?? (1.5 + random.nextDouble() * 0.3).toStringAsFixed(2);
  String? twentyYardShuttle = player.twentyYardShuttle ?? (4.0 + random.nextDouble() * 0.8).toStringAsFixed(2);
  String? threeConeTime = player.threeConeTime ?? (6.5 + random.nextDouble() * 1.0).toStringAsFixed(2);
  double? armLength = player.armLength ?? (30 + random.nextDouble() * 6);
  int? benchPress = player.benchPress ?? (15 + random.nextInt(20));
  double? broadJump = player.broadJump ?? (100 + random.nextDouble() * 30);
  double? handSize = player.handSize ?? (8.5 + random.nextDouble() * 2);
  double? verticalJump = player.verticalJump ?? (28 + random.nextDouble() * 14);
  double? wingspan = player.wingspan ?? (70 + random.nextDouble() * 10);
  
  // Create mock description, strengths, weaknesses if missing
  String description = player.description ?? 
    "A ${player.position} prospect from ${player.school}. Ranked #${player.rank} overall in this class.";
  String strengths = player.strengths ?? 
    "Good athleticism and technique. Shows solid fundamentals at the ${player.position} position.";
  String weaknesses = player.weaknesses ?? 
    "Needs improvement in consistency. Could develop better technique in certain areas.";
  
  return Player(
    id: player.id,
    name: player.name,
    position: player.position,
    rank: player.rank,
    school: player.school,
    notes: player.notes,
    height: height,
    weight: weight,
    rasScore: rasScore,
    description: description,
    strengths: strengths,
    weaknesses: weaknesses,
    fortyTime: fortyTime,
    tenYardSplit: tenYardSplit,
    twentyYardShuttle: twentyYardShuttle,
    threeConeTime: threeConeTime,
    armLength: armLength,
    benchPress: benchPress,
    broadJump: broadJump,
    handSize: handSize,
    verticalJump: verticalJump,
    wingspan: wingspan,
    isFavorite: player.isFavorite,
  );
}
  
  // Helper method to find mock data for a player by name
  
  // Helper method to get random mock data for a position
  
  // Sample mock data for players (would be much larger in real implementation)
}

// Class to hold mock player information
class MockPlayerInfo {
  final String name;
  final String position;
  final double height;  // in inches
  final double weight;  // in lbs
  final double rasScore;
  final String description;
  final String strengths;
  final String weaknesses;
  // Add optional fields for the new measurements
  final String? tenYardSplit;
  final String? twentyYardShuttle;
  final String? threeConeTime;
  final double? armLength;
  final int? benchPress;
  final double? broadJump;
  final double? handSize;
  final double? verticalJump;
  final double? wingspan;
  
  MockPlayerInfo({
    required this.name,
    required this.position,
    required this.height,
    required this.weight,
    required this.rasScore,
    required this.description,
    required this.strengths,
    required this.weaknesses,
    this.tenYardSplit,
    this.twentyYardShuttle,
    this.threeConeTime,
    this.armLength,
    this.benchPress,
    this.broadJump,
    this.handSize,
    this.verticalJump,
    this.wingspan,
  });
}