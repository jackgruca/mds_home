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
  // New fields
  final String playerName;
  final String collegeName;
  final String collegeConference;
  final String draftClub;
  final String position;
  final String positionGroup;
  final int height;
  final int weight;
  final int? draftNumber;
  final int? draftRound;
  final int entryYear;
  final DateTime? birthDate;
  final double? forty;
  final int? bench;
  final double? vertical;
  final int? broadJump;
  final double? cone;
  final double? shuttle;

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
    required this.playerName,
    required this.collegeName,
    required this.collegeConference,
    required this.draftClub,
    required this.position,
    required this.positionGroup,
    required this.height,
    required this.weight,
    this.draftNumber,
    this.draftRound,
    required this.entryYear,
    this.birthDate,
    this.forty,
    this.bench,
    this.vertical,
    this.broadJump,
    this.cone,
    this.shuttle,
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

    DateTime? getDateTime(String key) {
      final val = map[key];
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
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
      // New fields
      playerName: getString('player_name'),
      collegeName: getString('college_name'),
      collegeConference: getString('college_conference'),
      draftClub: getString('draft_club'),
      position: getString('position'),
      positionGroup: getString('position_group'),
      height: getInt('height'),
      weight: getInt('weight'),
      draftNumber: getInt('draft_number'),
      draftRound: getInt('draftround'),
      entryYear: getInt('entry_year'),
      birthDate: getDateTime('birth_date'),
      forty: getDouble('forty'),
      bench: getInt('bench'),
      vertical: getDouble('vertical'),
      broadJump: getInt('broad_jump'),
      cone: getDouble('cone'),
      shuttle: getDouble('shuttle'),
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
      // New fields
      'player_name': playerName,
      'college_name': collegeName,
      'college_conference': collegeConference,
      'draft_club': draftClub,
      'position': position,
      'position_group': positionGroup,
      'height': height,
      'weight': weight,
      'draft_number': draftNumber,
      'draftround': draftRound,
      'entry_year': entryYear,
      'birth_date': birthDate?.toIso8601String(),
      'forty': forty,
      'bench': bench,
      'vertical': vertical,
      'broad_jump': broadJump,
      'cone': cone,
      'shuttle': shuttle,
    };
  }
} 