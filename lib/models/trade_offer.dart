// lib/models/trade_offer.dart
import 'trade_package.dart';

/// Represents a collection of trade packages offered for a pick
class TradeOffer {
  final List<TradePackage> packages;
  final int pickNumber;
  final bool isUserInvolved;

  const TradeOffer({
    required this.packages,
    required this.pickNumber,
    this.isUserInvolved = false,
  });

  /// Get the best trade package by value
  TradePackage? get bestPackage {
    if (packages.isEmpty) return null;
    
    return packages.reduce((best, current) => 
        current.totalValueOffered > best.totalValueOffered ? current : best);
  }

  /// Check if there are any fair trades available
  bool get hasFairTrades => packages.any((package) => package.isFairTrade);

  /// Get all packages from a specific team
  List<TradePackage> packagesFromTeam(String teamName) {
    return packages.where((package) => package.teamOffering == teamName).toList();
  }

  /// Get all teams offering trades
  List<String> get offeringTeams {
    return packages.map((package) => package.teamOffering).toSet().toList();
  }
}