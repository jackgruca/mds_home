// lib/models/draft_analytics.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DraftAnalyticsRecord {
  final String id;
  final String userTeam;
  final DateTime timestamp;
  final int year;
  final List<DraftPickRecord> picks;
  final List<TradeRecord> trades;

  DraftAnalyticsRecord({
    required this.id,
    required this.userTeam,
    required this.timestamp,
    required this.year,
    required this.picks,
    required this.trades,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userTeam': userTeam,
      'timestamp': timestamp,
      'year': year,
      'picks': picks.map((pick) => pick.toFirestore()).toList(),
      'trades': trades.map((trade) => trade.toFirestore()).toList(),
    };
  }

  static DraftAnalyticsRecord fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DraftAnalyticsRecord(
      id: doc.id,
      userTeam: data['userTeam'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      year: data['year'] ?? DateTime.now().year,
      picks: (data['picks'] as List)
          .map((pick) => DraftPickRecord.fromFirestore(pick))
          .toList(),
      trades: (data['trades'] as List?)
              ?.map((trade) => TradeRecord.fromFirestore(trade))
              .toList() ??
          [],
    );
  }
}

class DraftPickRecord {
  final int pickNumber;
  final String originalTeam;
  final String actualTeam;
  final int playerId;
  final String playerName;
  final String position;
  final int playerRank;
  final String school;
  final String round;

  DraftPickRecord({
    required this.pickNumber,
    required this.originalTeam,
    required this.actualTeam,
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.playerRank,
    required this.school,
    required this.round,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'pickNumber': pickNumber,
      'originalTeam': originalTeam,
      'actualTeam': actualTeam,
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'playerRank': playerRank,
      'school': school,
      'round': round,
    };
  }

  static DraftPickRecord fromFirestore(Map<String, dynamic> data) {
    return DraftPickRecord(
      pickNumber: data['pickNumber'] ?? 0,
      originalTeam: data['originalTeam'] ?? '',
      actualTeam: data['actualTeam'] ?? '',
      playerId: data['playerId'] ?? 0,
      playerName: data['playerName'] ?? '',
      position: data['position'] ?? '',
      playerRank: data['playerRank'] ?? 0,
      school: data['school'] ?? '',
      round: data['round'] ?? '1',
    );
  }
}

class TradeRecord {
  final String teamOffering;
  final String teamReceiving;
  final List<int> picksOffered;
  final int targetPick;
  final List<int> additionalTargetPicks;
  final double valueOffered;
  final double targetValue;

  TradeRecord({
    required this.teamOffering,
    required this.teamReceiving,
    required this.picksOffered,
    required this.targetPick,
    required this.additionalTargetPicks,
    required this.valueOffered,
    required this.targetValue,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'teamOffering': teamOffering,
      'teamReceiving': teamReceiving,
      'picksOffered': picksOffered,
      'targetPick': targetPick,
      'additionalTargetPicks': additionalTargetPicks,
      'valueOffered': valueOffered,
      'targetValue': targetValue,
    };
  }

  static TradeRecord fromFirestore(Map<String, dynamic> data) {
    return TradeRecord(
      teamOffering: data['teamOffering'] ?? '',
      teamReceiving: data['teamReceiving'] ?? '',
      picksOffered: List<int>.from(data['picksOffered'] ?? []),
      targetPick: data['targetPick'] ?? 0,
      additionalTargetPicks: List<int>.from(data['additionalTargetPicks'] ?? []),
      valueOffered: (data['valueOffered'] ?? 0).toDouble(),
      targetValue: (data['targetValue'] ?? 0).toDouble(),
    );
  }
}