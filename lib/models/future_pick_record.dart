// lib/models/future_pick_record.dart
class FutureDraftPick {
  final String teamOwning;
  final String teamOriginal;
  final int round;
  final String year;
  final double value;
  final String? tradeInfo;
  bool isTraded = false;
  
  FutureDraftPick({
    required this.teamOwning,
    required this.teamOriginal,
    required this.round,
    required this.year,
    required this.value,
    this.tradeInfo,
    this.isTraded = false,
  });
  
  // Create a copy with updated fields
  FutureDraftPick copyWith({
    String? teamOwning,
    String? teamOriginal,
    int? round,
    String? year,
    double? value,
    String? tradeInfo,
    bool? isTraded,
  }) {
    return FutureDraftPick(
      teamOwning: teamOwning ?? this.teamOwning,
      teamOriginal: teamOriginal ?? this.teamOriginal,
      round: round ?? this.round,
      year: year ?? this.year,
      value: value ?? this.value,
      tradeInfo: tradeInfo ?? this.tradeInfo,
      isTraded: isTraded ?? this.isTraded,
    );
  }
}