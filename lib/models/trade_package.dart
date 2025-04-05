// lib/models/trade_package.dart
import 'package:mds_home/models/future_pick.dart';

import 'draft_pick.dart';

/// Represents a package of draft picks offered in a trade
class TradePackage {
  final String teamOffering;
  final String teamReceiving;
  final List<DraftPick> picksOffered;
  final DraftPick targetPick;
  final List<DraftPick> additionalTargetPicks;
  final double totalValueOffered;
  final double targetPickValue;
  final bool includesFuturePick;
  final String? futurePickDescription;
  final double? futurePickValue;
  final List<String>? targetReceivedFuturePicks;
  // Add this property
  final bool forceAccept;
  final List<FuturePick>? offeredFuturePicks;
  final List<FuturePick>? targetFuturePicks;

const TradePackage({
  required this.teamOffering,
  required this.teamReceiving,
  required this.picksOffered,
  required this.targetPick,
  this.additionalTargetPicks = const [],
  required this.totalValueOffered,
  required this.targetPickValue,
  this.includesFuturePick = false,
  this.futurePickDescription,
  this.futurePickValue,
  this.targetReceivedFuturePicks,
  this.forceAccept = false,
  this.offeredFuturePicks,
  this.targetFuturePicks,
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
    
    final targetDescription = [targetPick, ...additionalTargetPicks]
        .map((p) => "Pick #${p.pickNumber}")
        .join(", ");
    
    final targetFutureText = targetReceivedFuturePicks != null && targetReceivedFuturePicks!.isNotEmpty
        ? " + ${targetReceivedFuturePicks!.join(", ")}"
        : "";
    
    return "$teamOffering receives: $targetDescription$targetFutureText\n"
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