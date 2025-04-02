// lib/models/draft_session.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'draft_pick.dart';
import 'trade_package.dart';

class DraftSession {
  final String id;
  final String userId;
  final String userTeam;
  final DateTime timestamp;
  final int draftYear;
  final List<Map<String, dynamic>> picks;
  final List<Map<String, dynamic>> trades;

  DraftSession({
    required this.id,
    required this.userId,
    required this.userTeam,
    required this.timestamp,
    required this.draftYear,
    required this.picks,
    required this.trades,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userTeam': userTeam,
      'timestamp': timestamp,
      'draftYear': draftYear,
      'picks': picks,
      'trades': trades,
    };
  }

  factory DraftSession.fromJson(Map<String, dynamic> json) {
    return DraftSession(
      id: json['id'],
      userId: json['userId'],
      userTeam: json['userTeam'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      draftYear: json['draftYear'],
      picks: List<Map<String, dynamic>>.from(json['picks']),
      trades: List<Map<String, dynamic>>.from(json['trades']),
    );
  }

  // Helper to convert a DraftPick to a storable map
  static Map<String, dynamic> pickToMap(DraftPick pick) {
    return {
      'pickNumber': pick.pickNumber,
      'teamName': pick.teamName,
      'playerName': pick.selectedPlayer?.name,
      'playerPosition': pick.selectedPlayer?.position,
      'playerSchool': pick.selectedPlayer?.school,
      'playerRank': pick.selectedPlayer?.rank,
      'round': pick.round,
      'tradeInfo': pick.tradeInfo,
    };
  }

  // Helper to convert a TradePackage to a storable map
  static Map<String, dynamic> tradeToMap(TradePackage trade) {
    return {
      'teamOffering': trade.teamOffering,
      'teamReceiving': trade.teamReceiving,
      'pickNumbers': trade.picksOffered.map((p) => p.pickNumber).toList(),
      'targetPickNumber': trade.targetPick.pickNumber,
      'totalValueOffered': trade.totalValueOffered,
      'targetPickValue': trade.targetPickValue,
      'includesFuturePick': trade.includesFuturePick,
      'futurePickDescription': trade.futurePickDescription,
    };
  }
}