// lib/models/custom_draft_data.dart
class CustomDraftData {
  final String name;
  final int year;
  final DateTime lastModified;
  final List<List<dynamic>>? teamNeeds;
  final List<List<dynamic>>? playerRankings;
  
  CustomDraftData({
    required this.name,
    required this.year,
    required this.lastModified,
    this.teamNeeds,
    this.playerRankings,
  });
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'lastModified': lastModified.toIso8601String(),
      'teamNeeds': teamNeeds != null ? _encodeNestedList(teamNeeds!) : null,
      'playerRankings': playerRankings != null ? _encodeNestedList(playerRankings!) : null,
    };
  }
  
  // Create from JSON
  factory CustomDraftData.fromJson(Map<String, dynamic> json) {
    return CustomDraftData(
      name: json['name'] ?? 'Unnamed Dataset',
      year: json['year'] ?? DateTime.now().year,
      lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toIso8601String()),
      teamNeeds: json['teamNeeds'] != null ? _decodeNestedList(json['teamNeeds']) : null,
      playerRankings: json['playerRankings'] != null ? _decodeNestedList(json['playerRankings']) : null,
    );
  }
  
  // Encode nested list for JSON storage
  static List<List<dynamic>> _decodeNestedList(List<dynamic> jsonList) {
    return jsonList.map<List<dynamic>>((item) => 
      List<dynamic>.from(item)
    ).toList();
  }
  
  // Decode nested list from JSON
  static List<dynamic> _encodeNestedList(List<List<dynamic>> nestedList) {
    return nestedList.map((innerList) => 
      List<dynamic>.from(innerList)
    ).toList();
  }
  
  // Clone with modifications
  CustomDraftData copyWith({
    String? name,
    int? year,
    DateTime? lastModified,
    List<List<dynamic>>? teamNeeds,
    List<List<dynamic>>? playerRankings,
  }) {
    return CustomDraftData(
      name: name ?? this.name,
      year: year ?? this.year,
      lastModified: lastModified ?? this.lastModified,
      teamNeeds: teamNeeds ?? this.teamNeeds,
      playerRankings: playerRankings ?? this.playerRankings,
    );
  }
}