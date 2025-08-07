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
    // Use existing draft value service for accurate pick values
    double baseValue;
    
    if (pickNumber != null) {
      // Use specific pick value from chart, then convert to "grade points"
      // Draft chart: 1000 points for #1, ~184 for #32, etc.
      // Convert to our 0-100 scale: divide by 10 for rough conversion
      baseValue = _getDraftValueFromChart(pickNumber!) / 10.0;
    } else {
      // Estimate based on round when specific pick unknown
      baseValue = _getAverageRoundValue(round) / 10.0;
    }

    // Future year discount (matches existing logic)
    int yearOffset = year - DateTime.now().year;
    if (yearOffset > 0) {
      double discountFactor;
      if (round == 1) {
        discountFactor = 0.7; // 1st round: 70% of current value
      } else if (round == 2) {
        discountFactor = 0.6; // 2nd round: 60% of current value
      } else {
        discountFactor = 0.5; // 3rd+ round: 50% of current value
      }
      baseValue *= discountFactor;
    }

    return baseValue;
  }
  
  double _getDraftValueFromChart(int pick) {
    // Use the actual draft value chart data
    const Map<int, double> pickValues = {
      1: 1000, 2: 717, 3: 514, 4: 491, 5: 468,
      6: 446, 7: 426, 8: 406, 9: 387, 10: 369,
      // Add more key values...
      32: 190, 33: 184, 64: 82, 96: 39, 128: 20,
    };
    
    if (pickValues.containsKey(pick)) {
      return pickValues[pick]!;
    }
    
    // Interpolate for missing values
    if (pick <= 32) {
      return 1000 * (33 - pick) / 32; // Rough approximation
    } else if (pick <= 64) {
      return 184 * (65 - pick) / 32;
    } else if (pick <= 96) {
      return 82 * (97 - pick) / 32;
    } else {
      return 20.0;
    }
  }
  
  double _getAverageRoundValue(int round) {
    switch (round) {
      case 1: return 400.0; // Average 1st round pick value
      case 2: return 120.0; // Average 2nd round pick value  
      case 3: return 60.0;  // Average 3rd round pick value
      case 4: return 30.0;  // Average 4th round pick value
      default: return 15.0; // Average late round value
    }
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