import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/nfl_matchup.dart';
import '../screens/historical_data_screen.dart'; // Importing for QueryCondition

class HistoricalDataService {
  static List<NFLMatchup> _matchups = [];
  static bool _isInitialized = false;
  static List<String> _headers = [];
  static List<Map<String, String>> _rawRows = [];

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String data = await rootBundle.loadString('assets/data/historical_nfl_matchups.csv');
      
      const csvConverter = CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
        shouldParseNumbers: false, 
        allowInvalid: true, 
      );
      
      final List<List<dynamic>> csvTable = csvConverter.convert(data);

      if (csvTable.isEmpty) throw Exception('CSV file is empty');

      List<String> headers = csvTable[0].map((e) => e.toString()).toList();
      if (headers.isNotEmpty && headers[0].isEmpty) {
        headers.removeAt(0);
      }
      _headers = headers;
      print('CSV Headers: $_headers');

      _matchups = [];
      _rawRows = [];
      print('Total rows in CSV: ${csvTable.length}');
      
      for (int i = 1; i < csvTable.length; i++) {
        List<dynamic> row = List.from(csvTable[i]); 
        
        if (row.isEmpty) {
          print('Skipping empty row at index $i');
          continue;
        }
        if (row.isNotEmpty) row.removeAt(0);
        
        // Row length check needs to be against the number of actual data columns after removing the index
        if (row.length < _headers.length) { 
          print('Row $i has insufficient columns: ${row.length} vs ${_headers.length}. Row data: $row');
          continue;
        }

        final Map<String, dynamic> rowMap = {};
        final Map<String, String> rawRow = {};
        
        for (int j = 0; j < _headers.length && j < row.length; j++) {
          String value = row[j].toString().replaceAll('"', '');
          rowMap[_headers[j]] = value;
          rawRow[_headers[j]] = value;
        }
        
        try {
          NFLMatchup matchup = NFLMatchup.fromCSV(rowMap);
          _matchups.add(matchup);
          _rawRows.add(rawRow);
        } catch (e) {
          print('Error parsing row $i with data $rowMap: $e');
        }
      }
      
      print('Successfully parsed ${_matchups.length} matchups and ${_rawRows.length} raw rows.');
      _isInitialized = true;
    } catch (e) {
      print('Error initializing historical data: $e');
      rethrow;
    }
  }

  // Helper function to evaluate a single condition against a matchup
  static bool _checkCondition(NFLMatchup matchup, QueryCondition condition) {
    dynamic actualValue;
    String conditionStrValue = condition.value.toLowerCase();

    // Get actual value from matchup based on condition.field
    // This part needs to be robust and map string field names to NFLMatchup properties
    switch (condition.field) {
      case 'Team': actualValue = matchup.team;
        break;
      case 'Season': actualValue = matchup.season;
        break;
      case 'Week': actualValue = matchup.week;
        break;
      case 'Date': actualValue = matchup.date; // DateTime object
        break;
      case 'gameID': actualValue = matchup.gameId;
        break;
      case 'Rot': actualValue = matchup.rot;
        break;
      case 'VH': actualValue = matchup.vh;
        break;
      case '1st': actualValue = matchup.firstQuarter;
        break;
      case '2nd': actualValue = matchup.secondQuarter;
        break;
      case '3rd': actualValue = matchup.thirdQuarter;
        break;
      case '4th': actualValue = matchup.fourthQuarter;
        break;
      case 'Final': actualValue = matchup.finalScore;
        break;
      case 'ML': actualValue = matchup.moneyLine;
        break;
      case 'Halftime': actualValue = matchup.halftime;
        break;
      case 'Points_open': actualValue = matchup.pointsOpen;
        break;
      case 'Points_close': actualValue = matchup.pointsClose;
        break;
      case 'Opening_spread': actualValue = matchup.openingSpread;
        break;
      case 'Closing_spread': actualValue = matchup.closingSpread;
        break;
      case 'Actual_total': actualValue = matchup.actualTotal;
        break;
      case 'Actual_spread': actualValue = matchup.actualSpread;
        break;
      case 'Outcome': actualValue = matchup.outcome;
        break;
      case 'Spread_result': actualValue = matchup.spreadResult;
        break;
      case 'Points_result': actualValue = matchup.pointsResult;
        break;
      case 'temp': actualValue = matchup.temperature;
        break;
      case 'setting': actualValue = matchup.setting;
        break;
      case 'Opponent': actualValue = matchup.opponent;
        break;
      case 'Wins_to_date': actualValue = matchup.winsToDate;
        break;
      case 'defVsWR_tier': actualValue = matchup.defVsWRTier;
        break;
      case 'defVsRB_tier': actualValue = matchup.defVsRBTier;
        break;
      case 'defVsQB_tier': actualValue = matchup.defVsQBTier;
        break;
      case 'passOffTier': actualValue = matchup.passOffTier;
        break;
      case 'QBR_tier': actualValue = matchup.qbrTier;
        break;
      case 'Opponent_wins_to_date': actualValue = matchup.opponentWinsToDate;
        break;
      case 'Opponent_days_rest': actualValue = matchup.opponentDaysRest;
        break;
      case 'Opponent_passOffTier': actualValue = matchup.opponentPassOffTier;
        break;
      case 'Opponent_defVsWR_tier': actualValue = matchup.opponentDefVsWRTier;
        break;
      case 'Opponent_defVsRBTier': actualValue = matchup.opponentDefVsRBTier;
        break;
      case 'Opponent_defVsQB_tier': actualValue = matchup.opponentDefVsQBTier;
        break;
      case 'Opponent_QBR_tier': actualValue = matchup.opponentQbrTier;
        break;
      case 'days_rest': actualValue = matchup.daysRest;
        break;
      default:
        print('Querying unknown field: ${condition.field}');
        return false; // Field not recognized
    }

    if (actualValue == null && condition.operator != QueryOperator.equals && condition.operator != QueryOperator.notEquals) {
      // For operators other than equals/notEquals, null actual values usually mean the condition can't be met.
      // For equals/notEquals, null could be a valid state to check against (e.g., field == "NA" or field != "NA").
      // However, current logic parses "NA" to nulls or default values in NFLMatchup.fromCSV for some fields.
      // This needs careful handling depending on desired behavior for querying null/NA values.
      // For now, if actualValue is null, assume most comparisons (>, <, contains) are false unless it's an equality check for null itself.
      if (condition.value.toLowerCase() == 'na' || condition.value.toLowerCase() == 'null'){
          if(condition.operator == QueryOperator.equals) return actualValue == null;
          if(condition.operator == QueryOperator.notEquals) return actualValue != null;
      }
      return false; 
    }
    
    String actualValueStr = (actualValue ?? '').toString().toLowerCase();

    try {
      switch (condition.operator) {
        case QueryOperator.equals:
          if (actualValue is num) {
            num? conditionNum = num.tryParse(condition.value);
            return conditionNum != null && actualValue == conditionNum;
          } else if (actualValue is DateTime) {
            DateTime? conditionDate = DateTime.tryParse(condition.value);
            // For Date equality, typically compare YYYY-MM-DD part only
            return conditionDate != null && 
                   actualValue.year == conditionDate.year && 
                   actualValue.month == conditionDate.month && 
                   actualValue.day == conditionDate.day;
          }
          return actualValueStr == conditionStrValue;

        case QueryOperator.notEquals:
          if (actualValue is num) {
            num? conditionNum = num.tryParse(condition.value);
            return conditionNum == null || actualValue != conditionNum;
          } else if (actualValue is DateTime) {
            DateTime? conditionDate = DateTime.tryParse(condition.value);
             return conditionDate == null || 
                   !(actualValue.year == conditionDate.year && 
                     actualValue.month == conditionDate.month && 
                     actualValue.day == conditionDate.day);
          }
          return actualValueStr != conditionStrValue;

        case QueryOperator.greaterThan:
        case QueryOperator.greaterThanOrEquals:
        case QueryOperator.lessThan:
        case QueryOperator.lessThanOrEquals:
          if (actualValue is num) {
            double? conditionNum = double.tryParse(condition.value);
            if (conditionNum == null) return false;
            double actualNum = actualValue.toDouble();
            if (condition.operator == QueryOperator.greaterThan) return actualNum > conditionNum;
            if (condition.operator == QueryOperator.greaterThanOrEquals) return actualNum >= conditionNum;
            if (condition.operator == QueryOperator.lessThan) return actualNum < conditionNum;
            if (condition.operator == QueryOperator.lessThanOrEquals) return actualNum <= conditionNum;
          } else if (actualValue is DateTime) {
            DateTime? conditionDate = DateTime.tryParse(condition.value);
            if (conditionDate == null) return false;
            if (condition.operator == QueryOperator.greaterThan) return actualValue.isAfter(conditionDate);
            if (condition.operator == QueryOperator.greaterThanOrEquals) return actualValue.isAtSameMomentAs(conditionDate) || actualValue.isAfter(conditionDate);
            if (condition.operator == QueryOperator.lessThan) return actualValue.isBefore(conditionDate);
            if (condition.operator == QueryOperator.lessThanOrEquals) return actualValue.isAtSameMomentAs(conditionDate) || actualValue.isBefore(conditionDate);
          }
          return false; // Operator not applicable for type or parsing failed

        case QueryOperator.contains:
          return actualValueStr.contains(conditionStrValue);
        case QueryOperator.startsWith:
          return actualValueStr.startsWith(conditionStrValue);
        case QueryOperator.endsWith:
          return actualValueStr.endsWith(conditionStrValue);
      }
    } catch (e) {
      print('Error evaluating condition: $condition for value \'$actualValue\' ($actualValueStr) with query value \'${condition.value}\': $e');
      return false;
    }
    return false;
  }

  static List<NFLMatchup> getMatchups({
    DateTime? startDate,
    DateTime? endDate,
    String? team,
    String? opponent,
    int? season,
    int? week,
    bool? isHome,
    bool? isWin,
    bool? isSpreadWin,
    bool? isOver,
    int? minWinsToDate,
    int? maxWinsToDate,
    int? minOpponentWinsToDate,
    int? maxOpponentWinsToDate,
    int? minDaysRest,
    int? maxDaysRest,
    int? minOpponentDaysRest,
    int? maxOpponentDaysRest,
    int? minDefVsWRTier,
    int? maxDefVsWRTier,
    int? minDefVsRBTier,
    int? maxDefVsRBTier,
    int? minDefVsQBTier,
    int? maxDefVsQBTier,
    int? minPassOffTier,
    int? maxPassOffTier,
    int? minQbrTier,
    int? maxQbrTier,
    List<QueryCondition>? queryConditions, // Added parameter
  }) {
    if (!_isInitialized) {
      throw Exception('HistoricalDataService not initialized');
    }

    List<NFLMatchup> filteredMatchups = _matchups.where((matchup) {
      // Apply existing filters first
      if (startDate != null && matchup.date.isBefore(startDate)) return false;
      if (endDate != null && matchup.date.isAfter(endDate)) return false;
      if (team != null && matchup.team.toLowerCase() != team.toLowerCase()) return false;
      if (opponent != null && matchup.opponent.toLowerCase() != opponent.toLowerCase()) return false;
      if (season != null && matchup.season != season) return false;
      if (week != null && matchup.week != week) return false;
      if (isHome != null && matchup.isHome != isHome) return false;
      if (isWin != null && matchup.isWin != isWin) return false;
      if (isSpreadWin != null && matchup.isSpreadWin != isSpreadWin) return false;
      if (isOver != null && matchup.isOver != isOver) return false;
      if (minWinsToDate != null && matchup.winsToDate < minWinsToDate) return false;
      if (maxWinsToDate != null && matchup.winsToDate > maxWinsToDate) return false;
      if (minOpponentWinsToDate != null && matchup.opponentWinsToDate < minOpponentWinsToDate) return false;
      if (maxOpponentWinsToDate != null && matchup.opponentWinsToDate > maxOpponentWinsToDate) return false;
      if (minDaysRest != null && matchup.daysRest < minDaysRest) return false;
      if (maxDaysRest != null && matchup.daysRest > maxDaysRest) return false;
      if (minOpponentDaysRest != null && matchup.opponentDaysRest < minOpponentDaysRest) return false;
      if (maxOpponentDaysRest != null && matchup.opponentDaysRest > maxOpponentDaysRest) return false;
      if (minDefVsWRTier != null && matchup.defVsWRTier < minDefVsWRTier) return false;
      if (maxDefVsWRTier != null && matchup.defVsWRTier > maxDefVsWRTier) return false;
      if (minDefVsRBTier != null && matchup.defVsRBTier < minDefVsRBTier) return false;
      if (maxDefVsRBTier != null && matchup.defVsRBTier > maxDefVsRBTier) return false;
      if (minDefVsQBTier != null && matchup.defVsQBTier < minDefVsQBTier) return false;
      if (maxDefVsQBTier != null && matchup.defVsQBTier > maxDefVsQBTier) return false;
      if (minPassOffTier != null && matchup.passOffTier < minPassOffTier) return false;
      if (maxPassOffTier != null && matchup.passOffTier > maxPassOffTier) return false;
      if (minQbrTier != null && matchup.qbrTier < minQbrTier) return false;
      if (maxQbrTier != null && matchup.qbrTier > maxQbrTier) return false;
      return true;
    }).toList();

    // Apply dynamic query conditions
    if (queryConditions != null && queryConditions.isNotEmpty) {
      filteredMatchups = filteredMatchups.where((matchup) {
        for (var condition in queryConditions) {
          if (!_checkCondition(matchup, condition)) {
            return false; // If any condition fails, exclude the matchup
          }
        }
        return true; // All conditions passed
      }).toList();
    }
    
    print("getMatchups returning ${filteredMatchups.length} records after all filters.");
    return filteredMatchups;
  }

  static List<String> getUniqueTeams() {
    if (!_isInitialized) {
      throw Exception('HistoricalDataService not initialized');
    }
    final teams = <String>{};
    for (var matchup in _matchups) { // Use _matchups to get all possible teams before filtering
      teams.add(matchup.team);
      teams.add(matchup.opponent);
    }
    return teams.toList()..sort();
  }

  static List<int> getUniqueSeasons() {
    if (!_isInitialized) {
      throw Exception('HistoricalDataService not initialized');
    }
    final seasons = <int>{};
    for (var matchup in _matchups) {
      seasons.add(matchup.season);
    }
    return seasons.toList()..sort();
  }

  static List<int> getUniqueWeeks() {
    if (!_isInitialized) {
      throw Exception('HistoricalDataService not initialized');
    }
    final weeks = <int>{};
    for (var matchup in _matchups) {
      weeks.add(matchup.week);
    }
    return weeks.toList()..sort();
  }

  static List<String> getUniqueSettings() {
    if (!_isInitialized) {
      throw Exception('HistoricalDataService not initialized');
    }

    final settings = <String>{};
    for (var matchup in _matchups) {
      if (matchup.setting != null) {
        settings.add(matchup.setting!);
      }
    }
    return settings.toList()..sort();
  }

  // Get team statistics
  static Map<String, dynamic> getTeamStats(String team) {
    if (!_isInitialized) {
      throw Exception('HistoricalDataService not initialized');
    }
    // For now, stats are based on all data, not the current query view.
    // To make stats dynamic, pass queryConditions here or filter _matchups before calculating stats.
    final teamMatchups = _matchups.where((m) => m.team == team).toList();
    if (teamMatchups.isEmpty) return {};

    int totalGames = teamMatchups.length;
    int wins = teamMatchups.where((m) => m.isWin).length;
    int spreadWins = teamMatchups.where((m) => m.isSpreadWin).length;
    int overs = teamMatchups.where((m) => m.isOver).length;
    int homeGames = teamMatchups.where((m) => m.isHome).length;
    int homeWins = teamMatchups.where((m) => m.isHome && m.isWin).length;
    int awayGames = teamMatchups.where((m) => m.isVisitor).length;
    int awayWins = teamMatchups.where((m) => m.isVisitor && m.isWin).length;

    // Prevent division by zero if no games played in a category
    double safeDivide(int numerator, int denominator) {
      return denominator == 0 ? 0.0 : numerator / denominator;
    }

    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': totalGames - wins,
      'winPercentage': safeDivide(wins, totalGames),
      'spreadWins': spreadWins,
      'spreadLosses': totalGames - spreadWins,
      'spreadWinPercentage': safeDivide(spreadWins, totalGames),
      'overs': overs,
      'unders': totalGames - overs,
      'overPercentage': safeDivide(overs, totalGames),
      'homeGames': homeGames,
      'homeWins': homeWins,
      'homeWinPercentage': safeDivide(homeWins, homeGames),
      'awayGames': awayGames,
      'awayWins': awayWins,
      'awayWinPercentage': safeDivide(awayWins, awayGames),
    };
  }

  static List<String> getHeaders() {
    if (!_isInitialized) throw Exception('HistoricalDataService not initialized');
    return List<String>.from(_headers); // Return a copy
  }

  static List<Map<String, String>> getRawRows({
    DateTime? startDate,
    DateTime? endDate,
    String? team,
    String? opponent,
    int? season,
    int? week,
    bool? isHome,
    bool? isWin,
    bool? isSpreadWin,
    bool? isOver,
    List<QueryCondition>? queryConditions, // Added parameter
  }) {
    if (!_isInitialized) throw Exception('HistoricalDataService not initialized');
    
    // Get filtered matchups first, including dynamic queries
    final filteredMatchups = getMatchups(
      startDate: startDate,
      endDate: endDate,
      team: team,
      opponent: opponent,
      season: season,
      week: week,
      isHome: isHome,
      isWin: isWin,
      isSpreadWin: isSpreadWin,
      isOver: isOver,
      queryConditions: queryConditions, // Pass it down
      // Make sure all other filter params for getMatchups are passed here if they were added
    );

    // Now, map these filtered NFLMatchup objects back to their raw row representation.
    // This requires finding the original raw row that corresponds to the filtered matchup.
    // This assumes _matchups and _rawRows have a 1-to-1 correspondence by index BEFORE any filtering.
    
    List<Map<String, String>> resultRawRows = [];
    for (var filteredMatchup in filteredMatchups) {
        int originalIndex = -1;
        // Find the original index. This could be slow if _matchups is very large.
        // Consider adding a unique ID to NFLMatchup if performance becomes an issue.
        for(int i = 0; i < _matchups.length; i++){
            // This comparison needs to be reliable. Using gameId and date as a composite key might work.
            if(_matchups[i].gameId == filteredMatchup.gameId && 
               _matchups[i].date.isAtSameMomentAs(filteredMatchup.date) &&
               _matchups[i].team == filteredMatchup.team
            ){
                originalIndex = i;
                break;
            }
        }

        if (originalIndex != -1 && originalIndex < _rawRows.length) {
            resultRawRows.add(Map<String, String>.from(_rawRows[originalIndex]));
        } else {
            // This case should ideally not happen if data is consistent
            print("Could not find original raw row for filtered matchup: ${filteredMatchup.team} on ${filteredMatchup.date}");
        }
    }
    print("getRawRows returning ${resultRawRows.length} records.");
    return resultRawRows;
  }
} 