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
  static MockPlayerInfo? _getMockPlayerInfo(String playerName) {
    return _mockPlayersInfo.firstWhere(
      (player) => player.name.toLowerCase() == playerName.toLowerCase(),
      orElse: () => MockPlayerInfo(
        name: "",
        position: "",
        height: 0,
        weight: 0,
        rasScore: 0,
        description: "",
        strengths: "",
        weaknesses: "",
      ),
    ).name.isEmpty ? null : _mockPlayersInfo.firstWhere(
      (player) => player.name.toLowerCase() == playerName.toLowerCase(),
    );
  }
  
  // Helper method to get random mock data for a position
  static MockPlayerInfo? _getRandomMockPlayerByPosition(String position) {
    List<MockPlayerInfo> positionMatches = _mockPlayersInfo
        .where((player) => player.position == position)
        .toList();
    
    if (positionMatches.isEmpty) {
      return null;
    }
    
    return positionMatches[DateTime.now().microsecond % positionMatches.length];
  }
  
  // Sample mock data for players (would be much larger in real implementation)
  static final List<MockPlayerInfo> _mockPlayersInfo = [
    // Quarterbacks
    MockPlayerInfo(
      name: "Caleb Williams",
      position: "QB",
      height: 73, // 6'1"
      weight: 214,
      rasScore: 9.2,
      description: "Williams is an ultra-talented quarterback prospect with rare arm talent and improvisational ability. He combines elite arm strength with the ability to deliver from multiple arm angles and platforms. His creativity under pressure and natural playmaking ability draw comparisons to Patrick Mahomes. Williams displays exceptional pocket awareness, escapability, and the ability to extend plays while keeping his eyes downfield. His ball placement and accuracy are plus traits, particularly when throwing on the move.",
      strengths: "Elite arm talent, exceptional creativity, natural playmaker, high-level pocket awareness, pinpoint accuracy on the move, competitive leadership",
      weaknesses: "Can be overly reliant on off-platform throws, occasional hero-ball tendencies, needs refinement in progression reads, can hold the ball too long seeking big plays",
    ),
    MockPlayerInfo(
      name: "Drake Maye",
      position: "QB",
      height: 76, // 6'4"
      weight: 223,
      rasScore: 9.0,
      description: "Maye possesses prototypical size and arm talent for the quarterback position with excellent mobility to extend plays. He's shown consistent improvement in his processing speed and decision-making. His arm strength allows him to make all NFL throws with velocity and touch when needed. Maye demonstrates good anticipation and timing, especially on intermediate routes, and has the athletic ability to be a legitimate threat in the designed run game and on scrambles.",
      strengths: "Prototypical size, excellent arm strength, advanced processing for age, plus athleticism, leadership qualities, competitive toughness",
      weaknesses: "Occasional mechanical inconsistencies, can force throws into tight windows, needs to improve eye discipline, footwork can break down under pressure",
    ),
    
    // Wide Receivers
    MockPlayerInfo(
      name: "Malik Nabers",
      position: "WR",
      height: 72, // 6'0"
      weight: 200,
      rasScore: 9.4,
      description: "Nabers is an explosive playmaker at the receiver position with exceptional route-running ability and separation skills. He possesses elite acceleration and change-of-direction ability that makes him a threat to score from anywhere on the field. His body control and ability to adjust to the ball in the air are high-end traits. After the catch, Nabers becomes a running back with vision, elusiveness, and contact balance to break tackles and create big plays.",
      strengths: "Elite acceleration, refined route runner, excellent hands, tremendous YAC ability, competitive toughness, positional versatility",
      weaknesses: "Slightly undersized frame, occasional concentration drops, could improve strength against press coverage, limited contested catch experience",
    ),
    MockPlayerInfo(
      name: "Marvin Harrison Jr.",
      position: "WR",
      height: 75, // 6'3"
      weight: 209,
      rasScore: 9.1,
      description: "Harrison Jr. possesses a rare combination of size, speed, route-running precision, and ball skills. The son of Hall of Fame receiver Marvin Harrison, he shows advanced technical refinement for his age with razor-sharp routes and excellent footwork. His body control and sideline awareness are elite, and he consistently demonstrates strong hands to pluck the ball away from his frame. Harrison's catch radius and ability to high-point the football make him a red-zone threat and reliable target at all three levels.",
      strengths: "Refined route technician, excellent hands and catch radius, body control and sideline awareness, high football IQ, red-zone effectiveness, competitive mentality",
      weaknesses: "Could improve play strength through contact, occasionally struggles with physicality against press, may need to expand route tree at next level",
    ),
    
    // Edge Rushers
    MockPlayerInfo(
      name: "Dallas Turner",
      position: "EDGE",
      height: 75, // 6'3"
      weight: 247,
      rasScore: 9.3,
      description: "Turner is an explosive edge defender with elite get-off and bend around the corner. His first-step quickness allows him to consistently pressure offensive tackles before they can set, and his ankle flexibility to flatten to the quarterback is a premium trait. Turner converts speed to power effectively and shows multiple counter moves when his initial rush is stopped. His motor runs hot, and he pursues plays with relentless effort. In run defense, he sets a firm edge with good hand placement and leverage.",
      strengths: "Elite first-step explosion, excellent bend and flexibility, developed hand usage, high motor, improving run defender, scheme versatility",
      weaknesses: "Could add functional strength, occasionally plays too high, needs to expand counter-move arsenal, can get washed out by double teams in run game",
    ),
    
    // Offensive Tackles
    MockPlayerInfo(
      name: "Olu Fashanu",
      position: "OT",
      height: 78, // 6'6"
      weight: 312,
      rasScore: 9.5,
      description: "Fashanu is a technically refined offensive tackle prospect with exceptional athleticism for his size. His quick feet and lateral mobility make him a natural pass protector on the blind side. He displays textbook hand placement and timing in pass protection, rarely getting caught out of position. As a run blocker, Fashanu shows the power to drive defenders off the ball and the mobility to excel in zone schemes. His football IQ is evident in how he handles stunts, twists, and blitzes.",
      strengths: "Elite athleticism, technical refinement, exceptional lateral agility, strong anchor, hand usage and timing, positional versatility, high football IQ",
      weaknesses: "Could play with more consistent nasty streak, occasional issues with speed-to-power conversions, needs to improve hand placement consistency",
    ),
    
    // Cornerbacks
    MockPlayerInfo(
      name: "Quinyon Mitchell",
      position: "CB",
      height: 72, // 6'0"
      weight: 195,
      rasScore: 8.9,
      description: "Mitchell is a technically refined cornerback with outstanding ball skills and route recognition. His change-of-direction ability and fluidity in his hips allow him to mirror receivers in man coverage with ease. In zone coverage, Mitchell shows excellent pattern reading and anticipation to jump routes and create turnovers. He's a willing tackler who takes good angles in run support and limits yards after catch. His competitive nature and football intelligence make him scheme-versatile at the next level.",
      strengths: "Exceptional route recognition, fluid hips, ball skills, competitive toughness, versatile coverage ability, high football IQ, reliable tackler",
      weaknesses: "Could add functional strength, occasional inconsistency in press technique, may struggle with larger receivers, limited experience against elite competition",
    ),
  ];
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