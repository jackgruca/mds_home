// lib/services/historical_trade_precedents.dart

/// Historical trade precedents for calibrating trade values
class TradePrecedent {
  final String playerName;
  final String position;
  final int tradeYear;
  final int age;
  final double estimatedGrade; // What our system would have graded them
  final List<String> compensation; // What they actually got
  final double totalDraftPoints; // Converted compensation to draft points
  final String context;

  const TradePrecedent({
    required this.playerName,
    required this.position,
    required this.tradeYear,
    required this.age,
    required this.estimatedGrade,
    required this.compensation,
    required this.totalDraftPoints,
    required this.context,
  });
}

class HistoricalTradePrecedents {
  /// Major EDGE/pass rusher trades for calibration
  static const List<TradePrecedent> edgeTradeHistory = [
    TradePrecedent(
      playerName: 'Khalil Mack',
      position: 'EDGE',
      tradeYear: 2018,
      age: 27,
      estimatedGrade: 95.0, // Elite player, premium position, prime age
      compensation: ['2019 1st', '2020 1st', '2018 6th'],
      totalDraftPoints: 1400.0, // Two 1st round picks ≈ 800 + 600 points
      context: 'Contract dispute, Raiders rebuilding',
    ),
    
    TradePrecedent(
      playerName: 'Von Miller',
      position: 'EDGE', 
      tradeYear: 2021,
      age: 32,
      estimatedGrade: 75.0, // Good player but aging
      compensation: ['2022 2nd', '2022 3rd'],
      totalDraftPoints: 200.0, // 2nd + 3rd ≈ 120 + 80 points
      context: 'Rental player, aging veteran',
    ),
    
    TradePrecedent(
      playerName: 'Bradley Chubb',
      position: 'EDGE',
      tradeYear: 2022, 
      age: 26,
      estimatedGrade: 82.0, // Good player, some injury concerns
      compensation: ['2023 1st', '2025 5th'],
      totalDraftPoints: 650.0, // 1st round pick ≈ 600 + 5th ≈ 50
      context: 'Injury concerns, contract year',
    ),
  ];
  
  /// Major QB trades for comparison
  static const List<TradePrecedent> qbTradeHistory = [
    TradePrecedent(
      playerName: 'Russell Wilson',
      position: 'QB',
      tradeYear: 2022,
      age: 33,
      estimatedGrade: 85.0, // Elite QB but aging
      compensation: ['2022 1st', '2022 2nd', '2023 1st', '2023 2nd', '2023 5th', 'plus players'],
      totalDraftPoints: 2000.0, // Massive haul
      context: 'Established elite QB, team wanted fresh start',
    ),
    
    TradePrecedent(
      playerName: 'Deshaun Watson', 
      position: 'QB',
      tradeYear: 2022,
      age: 26,
      estimatedGrade: 90.0, // Elite QB, prime age
      compensation: ['2022 1st', '2023 1st', '2024 1st', 'plus players'],
      totalDraftPoints: 2200.0, // Three 1st round picks
      context: 'Off-field issues, but elite talent',
    ),
  ];
  
  /// Calculate expected compensation based on precedents
  static double getExpectedDraftPointsForGrade(double playerGrade, String position) {
    List<TradePrecedent> relevantTrades;
    
    // Use position-specific precedents
    switch (position) {
      case 'EDGE':
      case 'DE':
        relevantTrades = edgeTradeHistory;
        break;
      case 'QB':
        relevantTrades = qbTradeHistory;
        break;
      default:
        // Use all precedents if no position-specific data
        relevantTrades = [...edgeTradeHistory, ...qbTradeHistory];
    }
    
    // Find trades with similar grades
    var similarTrades = relevantTrades
        .where((trade) => (trade.estimatedGrade - playerGrade).abs() <= 10.0)
        .toList();
        
    if (similarTrades.isEmpty) {
      // Fallback to interpolation
      return _interpolateFromAllTrades(playerGrade, relevantTrades);
    }
    
    // Average the compensation for similar players
    double avgCompensation = similarTrades
        .map((trade) => trade.totalDraftPoints)
        .reduce((a, b) => a + b) / similarTrades.length;
        
    return avgCompensation;
  }
  
  static double _interpolateFromAllTrades(double playerGrade, List<TradePrecedent> trades) {
    if (trades.isEmpty) return 500.0; // Default fallback
    
    // Sort by grade
    var sortedTrades = [...trades]..sort((a, b) => a.estimatedGrade.compareTo(b.estimatedGrade));
    
    // Find the two trades that bracket our player's grade
    TradePrecedent? lower, upper;
    
    for (int i = 0; i < sortedTrades.length - 1; i++) {
      if (sortedTrades[i].estimatedGrade <= playerGrade && 
          sortedTrades[i + 1].estimatedGrade >= playerGrade) {
        lower = sortedTrades[i];
        upper = sortedTrades[i + 1];
        break;
      }
    }
    
    if (lower == null || upper == null) {
      // Player grade is outside our precedent range
      if (playerGrade < sortedTrades.first.estimatedGrade) {
        return sortedTrades.first.totalDraftPoints;
      } else {
        return sortedTrades.last.totalDraftPoints;
      }
    }
    
    // Linear interpolation
    double gradeDiff = upper.estimatedGrade - lower.estimatedGrade;
    double valueDiff = upper.totalDraftPoints - lower.totalDraftPoints;
    double gradeOffset = playerGrade - lower.estimatedGrade;
    
    return lower.totalDraftPoints + (valueDiff * gradeOffset / gradeDiff);
  }
  
  /// Get market adjustment factor based on current vs. historical context
  static double getMarketInflationFactor(int currentYear) {
    // NFL salary cap has grown ~5-7% per year, trade values should follow
    double yearsSince2018 = (currentYear - 2018).toDouble();
    return 1.0 + (0.06 * yearsSince2018); // 6% annual inflation
  }
  
  /// Get a realistic trade suggestion for a player
  static String getTradeRecommendation(double playerGrade, String position) {
    double expectedPoints = getExpectedDraftPointsForGrade(playerGrade, position);
    double inflatedPoints = expectedPoints * getMarketInflationFactor(DateTime.now().year);
    
    // Convert draft points to realistic packages
    if (inflatedPoints >= 1800) {
      return "3 first-round picks or 2 firsts + elite player";
    } else if (inflatedPoints >= 1200) {
      return "2 first-round picks + additional assets";
    } else if (inflatedPoints >= 800) {
      return "1 first-round pick + quality starter";
    } else if (inflatedPoints >= 400) {
      return "1 first-round pick";
    } else if (inflatedPoints >= 200) {
      return "2nd round pick + additional assets";
    } else {
      return "Mid-round pick";
    }
  }
}