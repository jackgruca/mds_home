// lib/models/nfl_trade/trade_asset.dart

import 'nfl_player.dart';

abstract class TradeAsset {
  String get displayName;
  double get marketValue;
  String get description;
  TradeAssetType get type;
  
  Map<String, dynamic> toJson();
}

enum TradeAssetType {
  player,
  draftPick,
  futurePick,
  conditionalPick,
}

class PlayerAsset extends TradeAsset {
  final NFLPlayer player;

  PlayerAsset(this.player);

  @override
  String get displayName => player.name;

  @override
  double get marketValue => player.positionAdjustedValue;

  @override
  String get description => '${player.position} - Age ${player.age} - \$${player.annualSalary.toStringAsFixed(1)}M/yr';

  @override
  TradeAssetType get type => TradeAssetType.player;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'player',
    'playerId': player.playerId,
    'name': player.name,
    'value': marketValue,
  };
}

class DraftPickAsset extends TradeAsset {
  final int year;
  final int round;
  final int? pickNumber; // null for future picks where exact pick isn't known
  final String originalTeam; // team that originally owned the pick

  DraftPickAsset({
    required this.year,
    required this.round,
    this.pickNumber,
    required this.originalTeam,
  });

  @override
  String get displayName {
    if (pickNumber != null) {
      return '$year Pick #$pickNumber';
    } else {
      return '$year ${_ordinal(round)} Round Pick';
    }
  }

  @override
  double get marketValue {
    // Base values for draft picks by round
    const roundValues = {
      1: 25.0, // 1st round average value
      2: 12.0, // 2nd round average value
      3: 6.0,  // 3rd round average value
      4: 3.0,  // 4th round average value
      5: 2.0,  // 5th round average value
      6: 1.5,  // 6th round average value
      7: 1.0,  // 7th round average value
    };

    double baseValue = roundValues[round] ?? 0.5;
    
    // Adjust for specific pick position if known
    if (pickNumber != null) {
      // Early picks in round are more valuable
      int roundStart = ((round - 1) * 32) + 1;
      int positionInRound = pickNumber! - roundStart + 1;
      double positionMultiplier = 1.0 + ((32 - positionInRound) * 0.02); // Up to +64% for #1 overall
      baseValue *= positionMultiplier;
    }

    // Future year discount
    int yearOffset = year - DateTime.now().year;
    if (yearOffset > 0) {
      baseValue *= (0.85 * (1.0 / (yearOffset + 1))); // Discount future picks
    }

    return baseValue;
  }

  @override
  String get description {
    String desc = '${_ordinal(round)} Round';
    if (pickNumber != null) {
      desc += ' (Pick #$pickNumber)';
    }
    if (originalTeam != 'Current') {
      desc += ' (via $originalTeam)';
    }
    return desc;
  }

  @override
  TradeAssetType get type => year == DateTime.now().year 
      ? TradeAssetType.draftPick 
      : TradeAssetType.futurePick;

  String _ordinal(int number) {
    switch (number) {
      case 1: return '1st';
      case 2: return '2nd';
      case 3: return '3rd';
      default: return '${number}th';
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'draftPick',
    'year': year,
    'round': round,
    'pickNumber': pickNumber,
    'originalTeam': originalTeam,
    'value': marketValue,
  };
}

class TradeSlot {
  final int slotIndex;
  TradeAsset? asset;

  TradeSlot({required this.slotIndex, this.asset});

  bool get isEmpty => asset == null;
  bool get isFilled => asset != null;

  void clear() => asset = null;
  void setAsset(TradeAsset newAsset) => asset = newAsset;
}

class TeamTradePackage {
  final String teamName;
  final List<TradeSlot> slots;
  
  TeamTradePackage({
    required this.teamName,
  }) : slots = List.generate(5, (index) => TradeSlot(slotIndex: index));

  List<TradeAsset> get assets => slots
      .where((slot) => slot.isFilled)
      .map((slot) => slot.asset!)
      .toList();

  double get totalValue => assets.fold(0.0, (sum, asset) => sum + asset.marketValue);

  int get filledSlots => slots.where((slot) => slot.isFilled).length;
  int get emptySlots => 5 - filledSlots;

  bool get hasAssets => filledSlots > 0;

  void addAsset(TradeAsset asset) {
    final emptySlot = slots.firstWhere((slot) => slot.isEmpty);
    emptySlot.setAsset(asset);
  }

  bool canAddAsset() => emptySlots > 0;

  void removeAssetFromSlot(int slotIndex) {
    if (slotIndex >= 0 && slotIndex < 5) {
      slots[slotIndex].clear();
    }
  }

  void clearAllAssets() {
    for (var slot in slots) {
      slot.clear();
    }
  }
}