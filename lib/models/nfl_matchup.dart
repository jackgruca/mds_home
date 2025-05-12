class NFLMatchup {
  final String team;
  final int season;
  final int week;
  final DateTime date;
  final String gameId;
  final int rot;
  final String vh; // V for Visitor, H for Home
  final int firstQuarter;
  final int secondQuarter;
  final int thirdQuarter;
  final int fourthQuarter;
  final int finalScore;
  final int moneyLine;
  final double halftime;
  final double pointsOpen;
  final double pointsClose;
  final double openingSpread;
  final double closingSpread;
  final double actualTotal;
  final double actualSpread;
  final String outcome; // W or L
  final String spreadResult; // Y or N
  final String pointsResult; // O or U
  final double? temperature;
  final String? setting;
  final String opponent;
  final int winsToDate;
  final int defVsWRTier;
  final int defVsRBTier;
  final int defVsQBTier;
  final int passOffTier;
  final int qbrTier;
  final int opponentWinsToDate;
  final int opponentDaysRest;
  final int opponentPassOffTier;
  final int opponentDefVsWRTier;
  final int opponentDefVsRBTier;
  final int opponentDefVsQBTier;
  final int opponentQbrTier;
  final int daysRest;

  NFLMatchup({
    required this.team,
    required this.season,
    required this.week,
    required this.date,
    required this.gameId,
    required this.rot,
    required this.vh,
    required this.firstQuarter,
    required this.secondQuarter,
    required this.thirdQuarter,
    required this.fourthQuarter,
    required this.finalScore,
    required this.moneyLine,
    required this.halftime,
    required this.pointsOpen,
    required this.pointsClose,
    required this.openingSpread,
    required this.closingSpread,
    required this.actualTotal,
    required this.actualSpread,
    required this.outcome,
    required this.spreadResult,
    required this.pointsResult,
    this.temperature,
    this.setting,
    required this.opponent,
    required this.winsToDate,
    required this.defVsWRTier,
    required this.defVsRBTier,
    required this.defVsQBTier,
    required this.passOffTier,
    required this.qbrTier,
    required this.opponentWinsToDate,
    required this.opponentDaysRest,
    required this.opponentPassOffTier,
    required this.opponentDefVsWRTier,
    required this.opponentDefVsRBTier,
    required this.opponentDefVsQBTier,
    required this.opponentQbrTier,
    required this.daysRest,
  });

  factory NFLMatchup.fromCSV(Map<String, dynamic> csv) {
    try {
      // Helper function to safely parse int values
      int safeParseInt(String key, {int defaultValue = 0}) {
        try {
          final value = csv[key]?.toString() ?? '';
          if (value.isEmpty || value == 'NA') return defaultValue;
          return int.parse(value);
        } catch (e) {
          print('Error parsing int for $key: ${csv[key]}');
          return defaultValue;
        }
      }
      
      // Helper function to safely parse double values
      double safeParseDouble(String key, {double defaultValue = 0.0}) {
        try {
          final value = csv[key]?.toString() ?? '';
          if (value.isEmpty || value == 'NA') return defaultValue;
          return double.parse(value);
        } catch (e) {
          print('Error parsing double for $key: ${csv[key]}');
          return defaultValue;
        }
      }
      
      // Helper function to safely parse DateTime values
      DateTime safeParseDatetime(String key) {
        try {
          final value = csv[key]?.toString() ?? '';
          if (value.isEmpty || value == 'NA') return DateTime.now();
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing DateTime for $key: ${csv[key]}');
          return DateTime.now();
        }
      }
      
      return NFLMatchup(
        team: csv['Team'] ?? '',
        season: safeParseInt('Season'),
        week: safeParseInt('Week'),
        date: safeParseDatetime('Date'),
        gameId: csv['gameID'] ?? '',
        rot: safeParseInt('Rot'),
        vh: csv['VH'] ?? '',
        firstQuarter: safeParseInt('1st'),
        secondQuarter: safeParseInt('2nd'),
        thirdQuarter: safeParseInt('3rd'),
        fourthQuarter: safeParseInt('4th'),
        finalScore: safeParseInt('Final'),
        moneyLine: safeParseInt('ML'),
        halftime: safeParseDouble('Halftime'),
        pointsOpen: safeParseDouble('Points_open'),
        pointsClose: safeParseDouble('Points_close'),
        openingSpread: safeParseDouble('Opening_spread'),
        closingSpread: safeParseDouble('Closing_spread'),
        actualTotal: safeParseDouble('Actual_total'),
        actualSpread: safeParseDouble('Actual_spread'),
        outcome: csv['Outcome'] ?? '',
        spreadResult: csv['Spread_result'] ?? '',
        pointsResult: csv['Points_result'] ?? '',
        temperature: csv['temp'] == 'NA' ? null : safeParseDouble('temp'),
        setting: csv['setting'] == 'NA' ? null : csv['setting'],
        opponent: csv['Opponent'] ?? '',
        winsToDate: safeParseInt('Wins_to_date'),
        defVsWRTier: safeParseInt('defVsWR_tier'),
        defVsRBTier: safeParseInt('defVsRB_tier'),
        defVsQBTier: safeParseInt('defVsQB_tier'),
        passOffTier: safeParseInt('passOffTier'),
        qbrTier: safeParseInt('QBR_tier'),
        opponentWinsToDate: safeParseInt('Opponent_wins_to_date'),
        opponentDaysRest: safeParseInt('Opponent_days_rest'),
        opponentPassOffTier: safeParseInt('Opponent_passOffTier'),
        opponentDefVsWRTier: safeParseInt('Opponent_defVsWR_tier'),
        opponentDefVsRBTier: safeParseInt('Opponent_defVsRB_tier'),
        opponentDefVsQBTier: safeParseInt('Opponent_defVsQB_tier'),
        opponentQbrTier: safeParseInt('Opponent_QBR_tier'),
        daysRest: safeParseInt('days_rest'),
      );
    } catch (e) {
      print('Error creating NFLMatchup: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team,
      'season': season,
      'week': week,
      'date': date.toIso8601String(),
      'gameId': gameId,
      'rot': rot,
      'vh': vh,
      'firstQuarter': firstQuarter,
      'secondQuarter': secondQuarter,
      'thirdQuarter': thirdQuarter,
      'fourthQuarter': fourthQuarter,
      'finalScore': finalScore,
      'moneyLine': moneyLine,
      'halftime': halftime,
      'pointsOpen': pointsOpen,
      'pointsClose': pointsClose,
      'openingSpread': openingSpread,
      'closingSpread': closingSpread,
      'actualTotal': actualTotal,
      'actualSpread': actualSpread,
      'outcome': outcome,
      'spreadResult': spreadResult,
      'pointsResult': pointsResult,
      'temperature': temperature,
      'setting': setting,
      'opponent': opponent,
      'winsToDate': winsToDate,
      'defVsWRTier': defVsWRTier,
      'defVsRBTier': defVsRBTier,
      'defVsQBTier': defVsQBTier,
      'passOffTier': passOffTier,
      'qbrTier': qbrTier,
      'opponentWinsToDate': opponentWinsToDate,
      'opponentDaysRest': opponentDaysRest,
      'opponentPassOffTier': opponentPassOffTier,
      'opponentDefVsWRTier': opponentDefVsWRTier,
      'opponentDefVsRBTier': opponentDefVsRBTier,
      'opponentDefVsQBTier': opponentDefVsQBTier,
      'opponentQbrTier': opponentQbrTier,
      'daysRest': daysRest,
    };
  }

  // Helper methods for analysis
  bool get isHome => vh == 'H';
  bool get isVisitor => vh == 'V';
  bool get isWin => outcome == 'W';
  bool get isLoss => outcome == 'L';
  bool get isSpreadWin => spreadResult == 'Y';
  bool get isOver => pointsResult == 'O';
  bool get isUnder => pointsResult == 'U';
  
  // Get opponent's score (needed for some calculations)
  int get opponentScore => (finalScore + (isHome ? actualSpread : -actualSpread)).round();
  
  // Get total points scored
  int get totalPoints => finalScore + opponentScore;
} 