class WRModelStat {
  final String receiverPlayerId;
  final String receiverPlayerName;
  final String posteam;
  final int season;
  final int numGames;
  final double tgtShare;
  final int seasonYards;
  final int wrRank;
  final int playerYear;
  final int passOffenseTier;
  final int qbTier;
  final int numTD;
  final int numRec;
  final int runOffenseTier;
  final int numRushTD;
  final double runShare;
  final int seasonRushYards;
  final double points;

  WRModelStat({
    required this.receiverPlayerId,
    required this.receiverPlayerName,
    required this.posteam,
    required this.season,
    required this.numGames,
    required this.tgtShare,
    required this.seasonYards,
    required this.wrRank,
    required this.playerYear,
    required this.passOffenseTier,
    required this.qbTier,
    required this.numTD,
    required this.numRec,
    required this.runOffenseTier,
    required this.numRushTD,
    required this.runShare,
    required this.seasonRushYards,
    required this.points,
  });

  factory WRModelStat.fromFirestoreMap(Map<String, dynamic> map) {
    // Helper functions for safe parsing
    String getString(String key, {String defaultValue = ''}) => 
        map[key]?.toString() ?? defaultValue;
    
    int getInt(String key, {int defaultValue = 0}) {
      final val = map[key];
      if (val is int) return val;
      if (val is double) return val.round();
      if (val is String) return int.tryParse(val) ?? defaultValue;
      return defaultValue;
    }
    
    double getDouble(String key, {double defaultValue = 0.0}) {
      final val = map[key];
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    return WRModelStat(
      receiverPlayerId: getString('receiver_player_id'),
      receiverPlayerName: getString('receiver_player_name'),
      posteam: getString('posteam'),
      season: getInt('season'),
      numGames: getInt('numGames'),
      tgtShare: getDouble('tgtShare'),
      seasonYards: getInt('seasonYards'),
      wrRank: getInt('wr_rank'),
      playerYear: getInt('playerYear'),
      passOffenseTier: getInt('passOffenseTier'),
      qbTier: getInt('qbTier'),
      numTD: getInt('numTD'),
      numRec: getInt('numRec'),
      runOffenseTier: getInt('runOffenseTier'),
      numRushTD: getInt('numRushTD'),
      runShare: getDouble('runShare'),
      seasonRushYards: getInt('seasonRushYards'),
      points: getDouble('points'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiver_player_id': receiverPlayerId,
      'receiver_player_name': receiverPlayerName,
      'posteam': posteam,
      'season': season,
      'numGames': numGames,
      'tgtShare': tgtShare,
      'seasonYards': seasonYards,
      'wr_rank': wrRank,
      'playerYear': playerYear,
      'passOffenseTier': passOffenseTier,
      'qbTier': qbTier,
      'numTD': numTD,
      'numRec': numRec,
      'runOffenseTier': runOffenseTier,
      'numRushTD': numRushTD,
      'runShare': runShare,
      'seasonRushYards': seasonRushYards,
      'points': points,
    };
  }
} 