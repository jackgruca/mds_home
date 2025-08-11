// lib/services/trade_valuation_service.dart

import 'package:flutter/services.dart';
import '../models/nfl_trade/nfl_player.dart';
import '../models/nfl_trade/trade_asset.dart';
import '../models/nfl_trade/nfl_team_info.dart';
import 'draft_value_service.dart';

class ContractInfo {
  final String contractId;
  final String name;
  final String team;
  final String position;
  final double totalValue;
  final double guaranteedMoney;
  final double averageAnnualValue;
  final int contractYears;
  final int yearsRemaining;
  final String tier;
  final bool isExpiring;

  const ContractInfo({
    required this.contractId,
    required this.name,
    required this.team,
    required this.position,
    required this.totalValue,
    required this.guaranteedMoney,
    required this.averageAnnualValue,
    required this.contractYears,
    required this.yearsRemaining,
    required this.tier,
    required this.isExpiring,
  });
}

class PositionRankings {
  final Map<String, List<PlayerRanking>> rankings;

  PositionRankings(this.rankings);
}

class PlayerRanking {
  final String name;
  final String team;
  final double rank;
  final int season;

  const PlayerRanking({
    required this.name,
    required this.team,
    required this.rank,
    required this.season,
  });
}

class TeamNeeds {
  final Map<String, Map<String, double>> teamNeeds; // team -> position -> weight

  TeamNeeds(this.teamNeeds);
}

class TradeValuationService {
  static Map<String, ContractInfo>? _cachedContracts;
  static PositionRankings? _cachedRankings;
  static TeamNeeds? _cachedTeamNeeds;

  /// Load contract data from CSV
  static Future<void> _loadContractData() async {
    if (_cachedContracts != null) return;

    try {
      final csvData = await rootBundle.loadString('assets/nfl_contract_data.csv');
      _cachedContracts = await _parseContractData(csvData);
    } catch (e) {
      // print('Error loading contract data: $e');
      _cachedContracts = {};
    }
  }

  /// Parse contract CSV data
  static Future<Map<String, ContractInfo>> _parseContractData(String csvData) async {
    Map<String, ContractInfo> contracts = {};
    List<String> lines = csvData.split('\n');

    if (lines.isEmpty) return contracts;

    // Parse header row
    List<String> headers = _parseCSVLine(lines[0]);
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }

    // Parse data rows
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        List<String> values = _parseCSVLine(line);
        if (values.length >= headers.length - 3) { // Allow some missing columns
          ContractInfo contract = _parseContractRow(values, columnIndices);
          contracts[contract.contractId] = contract;
        }
      } catch (e) {
        continue; // Skip invalid rows
      }
    }

    return contracts;
  }

  /// Parse contract row to ContractInfo object
  static ContractInfo _parseContractRow(List<String> values, Map<String, int> columnIndices) {
    String getValue(String columnName, [String defaultValue = '']) {
      int? index = columnIndices[columnName];
      if (index == null || index >= values.length) return defaultValue;
      return values[index].isEmpty ? defaultValue : values[index];
    }

    double getDoubleValue(String columnName, [double defaultValue = 0.0]) {
      String value = getValue(columnName);
      return double.tryParse(value) ?? defaultValue;
    }

    int getIntValue(String columnName, [int defaultValue = 0]) {
      String value = getValue(columnName);
      return int.tryParse(value) ?? defaultValue;
    }

    bool getBoolValue(String columnName, [bool defaultValue = false]) {
      String value = getValue(columnName).toLowerCase();
      return value == 'true' || value == '1';
    }

    return ContractInfo(
      contractId: getValue('contractId'),
      name: getValue('name'),
      team: getValue('team'),
      position: getValue('position'),
      totalValue: getDoubleValue('totalValue'),
      guaranteedMoney: getDoubleValue('guaranteedMoney'),
      averageAnnualValue: getDoubleValue('averageAnnualValue'),
      contractYears: getIntValue('contractYears'),
      yearsRemaining: getIntValue('yearsRemaining'),
      tier: getValue('tier', 'rookie'),
      isExpiring: getBoolValue('isExpiring'),
    );
  }

  /// Load position rankings from existing CSV files
  static Future<void> _loadPositionRankings() async {
    if (_cachedRankings != null) return;

    Map<String, List<PlayerRanking>> rankings = {};
    
    // Load QB rankings
    rankings['QB'] = await _loadPositionRankingsFromFile('assets/rankings/qb_rankings.csv', 'QB');
    
    // Load RB rankings  
    rankings['RB'] = await _loadPositionRankingsFromFile('assets/rankings/rb_rankings.csv', 'RB');
    
    // Load WR rankings
    rankings['WR'] = await _loadPositionRankingsFromFile('assets/rankings/wr_rankings.csv', 'WR');
    
    // Load TE rankings
    rankings['TE'] = await _loadPositionRankingsFromFile('assets/rankings/te_rankings.csv', 'TE');

    _cachedRankings = PositionRankings(rankings);
  }

  /// Load individual position ranking file
  static Future<List<PlayerRanking>> _loadPositionRankingsFromFile(String filePath, String position) async {
    try {
      final csvData = await rootBundle.loadString(filePath);
      List<String> lines = csvData.split('\n');

      if (lines.isEmpty) return [];

      List<String> headers = _parseCSVLine(lines[0]);
      Map<String, int> columnIndices = {};
      for (int i = 0; i < headers.length; i++) {
        columnIndices[headers[i]] = i;
      }

      List<PlayerRanking> rankings = [];
      String nameColumn = position == 'QB' ? 'passer_player_name' : 'fantasy_player_name';
      String rankColumn = 'myRank';

      for (int i = 1; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          List<String> values = _parseCSVLine(line);
          
          String name = _getValue(nameColumn, values, columnIndices, '');
          String team = _getValue('team', values, columnIndices, '');
          double rank = double.tryParse(_getValue(rankColumn, values, columnIndices, '0')) ?? 0.0;
          int season = int.tryParse(_getValue('season', values, columnIndices, '2024')) ?? 2024;

          if (name.isNotEmpty) {
            rankings.add(PlayerRanking(
              name: name,
              team: team,
              rank: rank,
              season: season,
            ));
          }
        } catch (e) {
          continue; // Skip invalid rows
        }
      }

      return rankings;
    } catch (e) {
      return [];
    }
  }

  /// Load team needs from CSV
  static Future<void> _loadTeamNeeds() async {
    if (_cachedTeamNeeds != null) return;

    try {
      final csvData = await rootBundle.loadString('assets/2026/team_needs.csv');
      _cachedTeamNeeds = await _parseTeamNeedsData(csvData);
    } catch (e) {
      // print('Error loading team needs: $e');
      _cachedTeamNeeds = TeamNeeds({});
    }
  }

  /// Parse team needs CSV data
  static Future<TeamNeeds> _parseTeamNeedsData(String csvData) async {
    Map<String, Map<String, double>> teamNeeds = {};
    List<String> lines = csvData.split('\n');

    if (lines.isEmpty) return TeamNeeds(teamNeeds);

    // Parse data rows (skip header)
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        List<String> values = _parseCSVLine(line);
        if (values.length >= 8) { // Should have team + 7 needs
          String team = values[1].trim(); // TEAM column
          
          Map<String, double> needs = {};
          
          // Assign weights based on priority (need1 = highest priority)
          List<double> weights = [1.5, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8]; // 7 priority levels
          
          for (int j = 0; j < 7 && (j + 2) < values.length; j++) {
            String position = values[j + 2].trim(); // need1, need2, etc.
            if (position.isNotEmpty) {
              needs[position] = weights[j];
            }
          }
          
          if (team.isNotEmpty) {
            teamNeeds[team] = needs;
          }
        }
      } catch (e) {
        continue; // Skip invalid rows
      }
    }

    return TeamNeeds(teamNeeds);
  }

  /// Rank-driven player display value (0-100) with small multipliers
  /// - Base: position rank percentile (0-100)
  /// - Multipliers: position coefficient, age multiplier, need multiplier
  static double calculatePlayerDisplayValue(
    NFLPlayer player, {
    NFLTeamInfo? receivingTeam,
  }) {
    // Base from percentile-like field already on player (0-100)
    double base = player.positionRank.clamp(0.0, 100.0);

    // Position coefficients
    final String pos = player.position.toUpperCase();
    final Map<String, double> posCoeff = {
      'QB': 1.15,
      'EDGE': 1.10,
      'DE': 1.10,
      'OT': 1.08,
      'CB': 1.06,
      'WR': 1.04,
      'TE': 1.02,
      'IDL': 1.00,
      'DT': 1.00,
      'S': 1.00,
      'LB': 0.98,
      'OG': 0.97,
      'C': 0.97,
      'IOL': 0.97,
      'RB': 0.95,
    };
    double positionMultiplier = posCoeff[pos] ?? 1.00;

    // Age multiplier: triangular around peak per position, 0.90-1.10
    final Map<String, int> peakAge = {
      'QB': 27,
      'EDGE': 26,
      'DE': 26,
      'OT': 27,
      'CB': 25,
      'WR': 26,
      'TE': 27,
      'IDL': 27,
      'DT': 27,
      'LB': 26,
      'S': 26,
      'RB': 24,
      'OG': 27,
      'C': 27,
      'IOL': 27,
    };
    int pAge = peakAge[pos] ?? 26;
    double ageMultiplier = (1.10 - 0.02 * (player.age - pAge).abs()).clamp(0.90, 1.10);

    // Need multiplier: 0.90 - 1.20
    double needMultiplier = 1.0;
    if (receivingTeam != null) {
      String needPos = (pos == 'DE' || pos == 'EDGE') ? 'EDGE' : pos;
      // NFLTeamInfo has positionNeeds and helper in codebase to get level
      double needLevel = 0.5;
      try {
        // Prefer method if available
        // ignore: invalid_use_of_protected_member
        needLevel = receivingTeam.getNeedLevel(needPos);
      } catch (_) {
        needLevel = receivingTeam.positionNeeds[needPos] ?? 0.5;
      }
      needMultiplier = (0.90 + 0.30 * needLevel).clamp(0.90, 1.20);
    }

    double value = base * positionMultiplier * ageMultiplier * needMultiplier;
    return value.clamp(0.0, 100.0);
  }

  /// Calculate internal points for a single asset
  /// Players: 20x display, franchise premium 1.5 if display>=95 and age<=27
  /// Picks: chart points from DraftValueService with future-year discount
  static double calculateAssetInternalPoints(TradeAsset asset, NFLTeamInfo receivingTeam) {
    if (asset is PlayerAsset) {
      double display = calculatePlayerDisplayValue(asset.player, receivingTeam: receivingTeam);
      double points = 20.0 * display;
      if (display >= 95.0 && asset.player.age <= 27) {
        points *= 1.5; // Franchise premium
      }
      return points;
    }

    if (asset is DraftPickAsset) {
      // Determine base points
      double points;
      if (asset.pickNumber != null) {
        points = DraftValueService.getValueForPick(asset.pickNumber!);
      } else {
        // Average round value rough equivalents in chart points
        switch (asset.round) {
          case 1:
            points = 550.0; // avg 1st
            break;
          case 2:
            points = 180.0; // avg 2nd
            break;
          case 3:
            points = 90.0;
            break;
          case 4:
            points = 45.0;
            break;
          case 5:
            points = 28.0;
            break;
          case 6:
            points = 20.0;
            break;
          default:
            points = 15.0;
        }
      }

      // Future year discount (same logic as display but applied to points)
      int yearOffset = asset.year - DateTime.now().year;
      if (yearOffset > 0) {
        double discountFactor;
        if (asset.round == 1) {
          discountFactor = 0.7;
        } else if (asset.round == 2) {
          discountFactor = 0.6;
        } else {
          discountFactor = 0.5;
        }
        points *= discountFactor;
      }

      return points;
    }

    // Default
    return 0.0;
  }

  /// Sum package internal points with diminishing returns
  static double calculatePackageInternalPoints(TeamTradePackage package, NFLTeamInfo receivingTeam) {
    if (!package.hasAssets) return 0.0;

    // Separate assets
    final List<PlayerAsset> players = package.assets.whereType<PlayerAsset>().toList();
    final List<DraftPickAsset> picks = package.assets.whereType<DraftPickAsset>().toList();

    // Compute points
    final List<double> playerPoints = players
        .map((p) => calculateAssetInternalPoints(p, receivingTeam))
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final List<double> firstRoundPoints = picks
        .where((p) => p.round == 1)
        .map((p) => calculateAssetInternalPoints(p, receivingTeam))
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final List<double> otherRoundPoints = picks
        .where((p) => p.round != 1)
        .map((p) => calculateAssetInternalPoints(p, receivingTeam))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // Diminishing multipliers
    const List<double> playerMultipliers = [1.0, 0.7, 0.55, 0.45, 0.4];
    const List<double> firstMultipliers = [1.0, 0.8, 0.65, 0.55];
    const List<double> otherMultipliers = [1.0, 0.85, 0.75, 0.65, 0.6, 0.55];

    double sumWithMultipliers(List<double> values, List<double> weights) {
      double total = 0.0;
      for (int i = 0; i < values.length; i++) {
        double w = i < weights.length ? weights[i] : weights.last;
        total += values[i] * w;
      }
      return total;
    }

    double total = 0.0;
    total += sumWithMultipliers(playerPoints, playerMultipliers);
    total += sumWithMultipliers(firstRoundPoints, firstMultipliers);
    total += sumWithMultipliers(otherRoundPoints, otherMultipliers);

    return total;
  }

  /// Calculate market value using "1.1x better player" logic
  static Future<double> calculatePlayerMarketValue(NFLPlayer player, String receivingTeam) async {
    // Load data if not cached
    await _loadContractData();
    await _loadPositionRankings();
    await _loadTeamNeeds();

    // Get player's ranking percentile
    double playerPercentile = _getPlayerPercentile(player);
    
    // Get contracts for this position
    List<ContractInfo> positionContracts = _getPositionContracts(player.position);
    
    // Get team need multiplier
    double teamNeedMultiplier = _getTeamNeedMultiplier(player.position, receivingTeam);
    
    // Apply "1.1x better player" logic
    double baseMarketValue = _calculatePositionMarketValue(player, playerPercentile, positionContracts);
    
    // Apply age adjustment
    double ageMultiplier = _getAgeMultiplier(player.age, player.position);
    
    // Apply team need multiplier
    double finalValue = baseMarketValue * ageMultiplier * teamNeedMultiplier;
    
    return finalValue.clamp(1.0, 100.0); // Reasonable bounds
  }

  /// Get player percentile from rankings
  static double _getPlayerPercentile(NFLPlayer player) {
    if (_cachedRankings == null) return 0.7; // Default to 70th percentile

    List<PlayerRanking>? positionRankings = _cachedRankings!.rankings[player.position];
    if (positionRankings == null || positionRankings.isEmpty) {
      // Fallback to overall rating from CSV as percentile
      return player.overallRating / 100.0;
    }

    // Find player in rankings (match by name and team)
    for (PlayerRanking ranking in positionRankings) {
      if (_playersMatch(player.name, ranking.name) && 
          _teamsMatch(player.team, ranking.team)) {
        return ranking.rank;
      }
    }

    // If not found, fallback to overall rating
    return player.overallRating / 100.0;
  }

  /// Get contracts for a specific position
  static List<ContractInfo> _getPositionContracts(String position) {
    if (_cachedContracts == null) return [];

    return _cachedContracts!.values
        .where((contract) => contract.position == position)
        .toList()
      ..sort((a, b) => b.averageAnnualValue.compareTo(a.averageAnnualValue));
  }

  /// Calculate market value using "1.1x better player" logic
  static double _calculatePositionMarketValue(NFLPlayer player, double playerPercentile, List<ContractInfo> positionContracts) {
    if (positionContracts.isEmpty) {
      // Fallback to base position values
      return _getPositionBaseValue(player.position);
    }

    // Find highest paid player at position
    double highestAAV = positionContracts.first.averageAnnualValue;
    
    // Find the percentile of the highest paid player (estimate based on contracts)
    double highestPaidPercentile = _estimateHighestPaidPercentile(positionContracts);
    
    // If this player is better than highest paid, apply 1.1x premium
    if (playerPercentile > highestPaidPercentile) {
      return highestAAV * 1.1;
    }
    
    // Otherwise, interpolate based on percentile vs contract values
    return _interpolateValueFromContracts(playerPercentile, positionContracts);
  }

  /// Estimate the percentile of the highest paid player
  static double _estimateHighestPaidPercentile(List<ContractInfo> contracts) {
    // Assume top contract represents ~95th percentile player
    return 0.95;
  }

  /// Interpolate player value based on existing contracts
  static double _interpolateValueFromContracts(double playerPercentile, List<ContractInfo> contracts) {
    if (contracts.isEmpty) return 10.0; // Default

    // Create percentile -> contract value mapping
    List<double> contractValues = contracts.map((c) => c.averageAnnualValue).toList();
    
    // Assume contracts represent players from 95th percentile down to 50th percentile
    double maxPercentile = 0.95;
    double minPercentile = 0.5;
    
    if (playerPercentile >= maxPercentile) {
      return contractValues.first; // Top contract
    }
    
    if (playerPercentile <= minPercentile) {
      return contractValues.last * 0.5; // Below market
    }
    
    // Linear interpolation between percentiles and contract values
    double percentileRange = maxPercentile - minPercentile;
    double playerPosition = (playerPercentile - minPercentile) / percentileRange;
    
    int contractIndex = ((1.0 - playerPosition) * (contractValues.length - 1)).round();
    contractIndex = contractIndex.clamp(0, contractValues.length - 1);
    
    return contractValues[contractIndex];
  }

  /// Get base position value (fallback)
  static double _getPositionBaseValue(String position) {
    const Map<String, double> baseValues = {
      'QB': 35.0,
      'RB': 15.0,
      'WR': 20.0,
      'TE': 12.0,
      'OT': 18.0,
      'OG': 10.0,
      'C': 12.0,
      'DE': 16.0,
      'DT': 14.0,
      'EDGE': 20.0,
      'LB': 12.0,
      'CB': 18.0,
      'S': 14.0,
      'K': 4.0,
      'P': 3.0,
    };
    return baseValues[position] ?? 10.0;
  }

  /// Get team need multiplier
  static double _getTeamNeedMultiplier(String position, String team) {
    if (_cachedTeamNeeds == null) return 1.0;

    Map<String, double>? teamPositionNeeds = _cachedTeamNeeds!.teamNeeds[team];
    if (teamPositionNeeds == null) return 1.0;

    return teamPositionNeeds[position] ?? 1.0;
  }

  /// Get age multiplier for position
  static double _getAgeMultiplier(int age, String position) {
    // Position-specific age curves
    switch (position) {
      case 'QB':
        if (age <= 26) return 0.95; // Still developing
        if (age <= 32) return 1.0;  // Prime years
        if (age <= 35) return 0.9;  // Decline
        return 0.7; // Aging

      case 'RB':
        if (age <= 24) return 1.0;  // Prime
        if (age <= 27) return 0.9;  // Good
        if (age <= 30) return 0.7;  // Decline
        return 0.5; // Steep decline

      case 'WR':
      case 'TE':
        if (age <= 28) return 1.0;  // Prime
        if (age <= 32) return 0.9;  // Good
        return 0.8; // Decline

      case 'OT':
      case 'OG':
      case 'C':
        if (age <= 30) return 1.0;  // Prime
        if (age <= 34) return 0.95; // Still good
        return 0.85; // Decline

      default: // Defense, K, P
        if (age <= 29) return 1.0;  // Prime
        if (age <= 33) return 0.9;  // Good
        return 0.8; // Decline
    }
  }

  /// Calculate trade balance (closer to 1.0 = more balanced) using internal points
  static Future<double> calculateTradeBalance(
    TeamTradePackage team1Package,
    TeamTradePackage team2Package,
    NFLTeamInfo team1,
    NFLTeamInfo team2,
  ) async {
    double team1Value = calculatePackageInternalPoints(team1Package, team2);
    double team2Value = calculatePackageInternalPoints(team2Package, team1);

    if (team1Value == 0.0) return team2Value == 0.0 ? 1.0 : 0.0;
    return team2Value / team1Value;
  }

  /// Helper methods
  static List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }

    result.add(current.toString().trim());
    return result;
  }

  static String _getValue(String columnName, List<String> values, Map<String, int> columnIndices, String defaultValue) {
    int? index = columnIndices[columnName];
    if (index == null || index >= values.length) return defaultValue;
    return values[index].isEmpty ? defaultValue : values[index];
  }

  static bool _playersMatch(String name1, String name2) {
    // Simple name matching - could be enhanced with fuzzy matching
    return name1.toLowerCase().trim() == name2.toLowerCase().trim();
  }

  static bool _teamsMatch(String team1, String team2) {
    // Handle team abbreviation variations
    return team1.toUpperCase().trim() == team2.toUpperCase().trim();
  }

  /// Clear cached data (useful for testing)
  static void clearCache() {
    _cachedContracts = null;
    _cachedRankings = null;
    _cachedTeamNeeds = null;
  }
}