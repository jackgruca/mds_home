// lib/models/trade_package.dart
import 'draft_pick.dart';

/// Represents a package of draft picks offered in a trade
class TradePackage {
  final String teamOffering;
  final String teamReceiving;
  final List<DraftPick> picksOffered;
  final DraftPick targetPick;
  final double totalValueOffered;
  final double targetPickValue;
  final bool includesFuturePick;
  final String? futurePickDescription;
  final double? futurePickValue;

  const TradePackage({
    required this.teamOffering,
    required this.teamReceiving,
    required this.picksOffered,
    required this.targetPick,
    required this.totalValueOffered,
    required this.targetPickValue,
    this.includesFuturePick = false,
    this.futurePickDescription,
    this.futurePickValue,
  });

  /// Calculate the value differential between offer and target
  double get valueDifferential => totalValueOffered - targetPickValue;

  /// Determine if this is a fair trade (within 10% of value)
  bool get isFairTrade => totalValueOffered >= targetPickValue * 0.9;

  /// Determine if this is a great trade (>10% value in favor of receiver)
  bool get isGreatTrade => totalValueOffered >= targetPickValue * 1.1;

  /// Get a text description of the trade
  String get tradeDescription {
    final offerDescription = picksOffered.map((p) => "Pick #${p.pickNumber}").join(", ");
    final futureText = includesFuturePick ? " + $futurePickDescription" : "";
    
    return "$teamOffering receives: Pick #${targetPick.pickNumber}\n"
           "$teamReceiving receives: $offerDescription$futureText";
  }

  /// Get a value summary of the trade
  String get valueSummary {
    valueFormat(double value) => value.toStringAsFixed(0);
    
    return "Offered: ${valueFormat(totalValueOffered)} points\n"
           "Target: ${valueFormat(targetPickValue)} points\n"
           "Difference: ${valueFormat(valueDifferential)} points";
  }
}

