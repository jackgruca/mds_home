// lib/services/trade_data_service.dart

import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../models/nfl_trade/nfl_player.dart';
import '../models/nfl_trade/nfl_team_info.dart';
import 'trade_value_calculator.dart';

class TradeDataService {
  static final Map<String, List<NFLPlayer>> _playersCache = {};
  static final Map<String, NFLTeamInfo> _teamsCache = {};
  static bool _isInitialized = false;

  /// Initialize the trade data service by loading all CSV data
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load cap space data
    await _loadCapSpaceData();
    // Load team needs from 2026 CSV and normalize positions
    await _loadTeamNeeds2026();
    
    // Load player rankings from all position CSVs
    await _loadAllPlayerRankings();
    
    _isInitialized = true;
  }

  /// Load team cap space data from CSV
  static Future<void> _loadCapSpaceData() async {
    try {
      final String csvString = await rootBundle.loadString('assets/cap_space/team_cap_space.csv');
      // Manually parse to handle currency commas and parentheses
      final lines = const LineSplitter().convert(csvString.trim());
      if (lines.isEmpty) return;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 4) continue;
        // team name is the first token
        final String teamName = parts.first.trim();
        // last two tokens are cap_space_amount (no commas) and season
        final String capAmountStr = parts[parts.length - 2].trim();
        final double capAmount = _parseDouble(capAmountStr);
        
        // Map team names to abbreviations
        final String abbreviation = _getTeamAbbreviation(teamName);
        
        final NFLTeamInfo teamInfo = NFLTeamInfo(
          teamName: teamName,
          abbreviation: abbreviation,
          availableCapSpace: capAmount / 1000000.0, // millions
          totalCapSpace: 255.4,
          projectedCapSpace2025: (capAmount / 1000000.0) + 20,
          philosophy: _inferTeamPhilosophy(teamName, capAmount),
          status: _inferTeamStatus(teamName),
          positionNeeds: _getDefaultPositionNeeds(teamName),
          availableDraftPicks: _getDefaultDraftPicks((i % 32) + 1),
          futureFirstRounders: 1,
          tradeAggressiveness: _inferTradeAggressiveness(teamName),
          willingToOverpay: capAmount > 30000000,
          logoUrl: _logoForAbbr(abbreviation),
        );
        _teamsCache[abbreviation] = teamInfo;
      }
    } catch (e) {
      print('Error loading cap space data: $e');
      // Fallback: load default teams so UI remains usable
      _loadDefaultTeams();
    }
  }

  /// Fallback: populate all 32 NFL teams with sensible defaults
  static void _loadDefaultTeams() {
    final List<Map<String, String>> teams = [
      {'name': 'Arizona Cardinals', 'abbr': 'ARI'},
      {'name': 'Atlanta Falcons', 'abbr': 'ATL'},
      {'name': 'Baltimore Ravens', 'abbr': 'BAL'},
      {'name': 'Buffalo Bills', 'abbr': 'BUF'},
      {'name': 'Carolina Panthers', 'abbr': 'CAR'},
      {'name': 'Chicago Bears', 'abbr': 'CHI'},
      {'name': 'Cincinnati Bengals', 'abbr': 'CIN'},
      {'name': 'Cleveland Browns', 'abbr': 'CLE'},
      {'name': 'Dallas Cowboys', 'abbr': 'DAL'},
      {'name': 'Denver Broncos', 'abbr': 'DEN'},
      {'name': 'Detroit Lions', 'abbr': 'DET'},
      {'name': 'Green Bay Packers', 'abbr': 'GB'},
      {'name': 'Houston Texans', 'abbr': 'HOU'},
      {'name': 'Indianapolis Colts', 'abbr': 'IND'},
      {'name': 'Jacksonville Jaguars', 'abbr': 'JAX'},
      {'name': 'Kansas City Chiefs', 'abbr': 'KC'},
      {'name': 'Las Vegas Raiders', 'abbr': 'LV'},
      {'name': 'Los Angeles Chargers', 'abbr': 'LAC'},
      {'name': 'Los Angeles Rams', 'abbr': 'LAR'},
      {'name': 'Miami Dolphins', 'abbr': 'MIA'},
      {'name': 'Minnesota Vikings', 'abbr': 'MIN'},
      {'name': 'New England Patriots', 'abbr': 'NE'},
      {'name': 'New Orleans Saints', 'abbr': 'NO'},
      {'name': 'New York Giants', 'abbr': 'NYG'},
      {'name': 'New York Jets', 'abbr': 'NYJ'},
      {'name': 'Philadelphia Eagles', 'abbr': 'PHI'},
      {'name': 'Pittsburgh Steelers', 'abbr': 'PIT'},
      {'name': 'San Francisco 49ers', 'abbr': 'SF'},
      {'name': 'Seattle Seahawks', 'abbr': 'SEA'},
      {'name': 'Tampa Bay Buccaneers', 'abbr': 'TB'},
      {'name': 'Tennessee Titans', 'abbr': 'TEN'},
      {'name': 'Washington Commanders', 'abbr': 'WAS'},
    ];

    _teamsCache.clear();
    for (int i = 0; i < teams.length; i++) {
      final t = teams[i];
      final String teamName = t['name']!;
      final String abbr = t['abbr']!;
      final double capMillions = 25.0; // Neutral default cap
      final NFLTeamInfo teamInfo = NFLTeamInfo(
        teamName: teamName,
        abbreviation: abbr,
        availableCapSpace: capMillions,
        totalCapSpace: 255.4,
        projectedCapSpace2025: capMillions + 20,
        philosophy: _inferTeamPhilosophy(teamName, capMillions * 1000000),
        status: _inferTeamStatus(teamName),
        positionNeeds: _getDefaultPositionNeeds(teamName),
        availableDraftPicks: _getDefaultDraftPicks((i % 32) + 1),
        futureFirstRounders: 1,
        tradeAggressiveness: _inferTradeAggressiveness(teamName),
        willingToOverpay: capMillions > 30.0,
        logoUrl: _logoForAbbr(abbr),
      );
      _teamsCache[abbr] = teamInfo;
    }
  }

  /// Load all player rankings from CSV files
  static Future<void> _loadAllPlayerRankings() async {
    // Load each position group
    await _loadPositionRankings('qb', 'assets/rankings/qb_rankings.csv');
    await _loadPositionRankings('rb', 'assets/rankings/rb_rankings.csv');
    await _loadPositionRankings('wr', 'assets/rankings/wr_rankings.csv');
    await _loadPositionRankings('te', 'assets/rankings/te_rankings.csv');
    await _loadPositionRankings('edge', 'assets/rankings/edge_rankings.csv');
    await _loadPositionRankings('idl', 'assets/rankings/idl_rankings.csv');
  }

  /// Load player rankings for a specific position
  static Future<void> _loadPositionRankings(String position, String assetPath) async {
    print('🔍 DEBUG: Loading $position rankings from $assetPath');
    try {
      final String csvString = await rootBundle.loadString(assetPath);
      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      // Fallback for Flutter web where CsvToListConverter sometimes returns a single row
      if (csvData.length <= 1) {
        print('⚠️  CSV parse fallback engaged for $assetPath (rows=${csvData.length}). Using LineSplitter.');
        final lines = const LineSplitter().convert(csvString.trim());
        final parsed = <List<dynamic>>[];
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          parsed.add(line.split(','));
        }
        if (parsed.isNotEmpty) {
          csvData = parsed;
        }
      }
      
      print('🔍 DEBUG: Loaded ${csvData.length} rows for $position');
      if (csvData.isEmpty) return;
      
      // Get header row to find column indices
      final headers = csvData[0].map((h) => h.toString().toLowerCase()).toList();
      
      // Find column indices (robust to different names)
      int nameIndex = _findColumnIndex(headers, ['receiver_player_name','fantasy_player_name','name','player_name','player']);
      if (position == 'qb') {
        nameIndex = _findColumnIndex(headers, ['passer_player_name','name','player_name','player']);
      }
      int teamIndex = _findColumnIndex(headers, ['posteam','team']);
      int rankIndex = _findColumnIndex(headers, ['myranknum','myrank','rank','ranking','rank_num']);
      int seasonIndex = _findColumnIndex(headers, ['season']);
      int tierIndex = _findColumnIndex(headers, ['tier','wrtier']);
      int ageIndex = _findColumnIndex(headers, ['age','age_at_season']);
      
      // Determine latest season present in the CSV
      int latestSeason = 0;
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (seasonIndex >= 0 && row.length > seasonIndex) {
          final s = _parseInt(row[seasonIndex]);
          if (s > latestSeason) latestSeason = s;
        }
      }
      if (latestSeason == 0) latestSeason = DateTime.now().year; // fallback
      
      // Collect candidate rows for latest season with valid rank
      final List<List<dynamic>> rows = [];
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.isEmpty) continue;
        if (seasonIndex >= 0 && row.length > seasonIndex) {
          final s = _parseInt(row[seasonIndex]);
          if (s != latestSeason) continue;
        }
        if (rankIndex < 0 || row.length <= rankIndex) continue;
        if (_parseInt(row[rankIndex]) <= 0) continue;
        rows.add(row);
      }
      final int numPlayers = rows.length;
      
      List<NFLPlayer> players = [];
      int processedCount = 0;
      
      for (final row in rows) {
        processedCount++;
        if (row.length <= nameIndex || row.length <= teamIndex || row.length <= rankIndex) continue;
        String playerName = row[nameIndex].toString();
        String team = row[teamIndex].toString();
        int ranking = _parseInt(row[rankIndex]);
        int tier = tierIndex >= 0 && row.length > tierIndex ? _parseInt(row[tierIndex]) : 3;
        int age = 0;
        if (ageIndex >= 0 && row.length > ageIndex) {
          age = _parseInt(row[ageIndex]);
        }
        if (age == 0) {
          age = _estimatePlayerAge(playerName, position); // Fallback
        }
        
        // True percentile-based position score 0..100 (1 is best rank)
        double positionRankPercent = numPlayers > 0
            ? (100.0 * (numPlayers - ranking + 1) / numPlayers).clamp(1.0, 100.0)
            : 50.0;
        
        // Use trade value calculator using rank number as input
        double tradeValue = TradeValueCalculator.calculateTradeValue(
          position: position.toUpperCase(),
          positionRanking: ranking,
          tier: tier,
          age: age,
          teamNeed: 0.6,
          teamStatus: 'competitive',
        );
        
        double overallRating = _tradeValueToOverallRating(tradeValue);
        
        // DEBUG for key names
        if (playerName.toLowerCase().contains('parsons') || playerName.toLowerCase().contains('jefferson')) {
          print('  - [$position] $playerName s$latestSeason rank=$ranking of $numPlayers ⇒ positionRank=${positionRankPercent.toStringAsFixed(1)}');
        }
        
        NFLPlayer player = NFLPlayer(
          playerId: '${playerName.toLowerCase().replaceAll(' ', '_')}_$team',
          name: playerName,
          position: position.toUpperCase(),
          team: team,
          age: age,
          experience: _estimateExperience(age),
          marketValue: tradeValue,
          contractStatus: 'extension',
          contractYearsRemaining: _estimateContractYears(age, tier),
          annualSalary: _estimateSalary(position.toUpperCase(), age, tier),
          overallRating: overallRating,
          positionRank: positionRankPercent,
          ageAdjustedValue: tradeValue * _getAgeMultiplier(age),
          positionImportance: _getPositionImportance(position.toUpperCase()),
          durabilityScore: 85.0,
        );
        
        players.add(player);
      }
      
      print('🔍 DEBUG: $position summary - Processed: $processedCount, season: $latestSeason, Final players: ${players.length}');
      _playersCache[position] = players;
    } catch (e) {
      print('Error loading $position rankings: $e');
    }
  }

  /// Helper function to find column index by possible names
  static int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (String name in possibleNames) {
      int index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    return -1;
  }

  /// Parse double from various formats
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    String str = value.toString().replaceAll(r'$', '').replaceAll(',', '');
    return double.tryParse(str) ?? 0.0;
  }

  /// Parse int from various formats
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Convert trade value score (0-100) to overall rating for compatibility
  static double _tradeValueToOverallRating(double tradeValue) {
    // Map trade value to overall rating scale (75-99)
    if (tradeValue >= 90) return 99.0;
    if (tradeValue >= 80) return 95.0;
    if (tradeValue >= 70) return 92.0;
    if (tradeValue >= 60) return 88.0;
    if (tradeValue >= 50) return 85.0;
    if (tradeValue >= 40) return 82.0;
    if (tradeValue >= 30) return 78.0;
    return 75.0;
  }

  /// Estimate realistic annual salary based on position, age, and tier
  static double _estimateSalary(String position, int age, int tier) {
    // Base salary by position (in millions)
    Map<String, double> baseSalaries = {
      'QB': 30.0,
      'EDGE': 18.0,
      'WR': 15.0,
      'OT': 14.0,
      'CB': 12.0,
      'DT': 10.0,
      'IDL': 10.0,
      'TE': 8.0,
      'LB': 8.0,
      'S': 7.0,
      'RB': 6.0,
      'OG': 6.0,
      'C': 6.0,
      'K': 3.0,
      'P': 2.5,
    };
    
    double baseSalary = baseSalaries[position] ?? 5.0;
    
    // Adjust for tier
    double tierMultiplier = switch (tier) {
      1 => 2.0,   // Elite players
      2 => 1.5,   // Very good
      3 => 1.0,   // Average
      4 => 0.7,   // Below average
      5 => 0.5,   // Replacement level
      _ => 0.3,
    };
    
    // Age adjustments for salary
    double ageMultiplier = 1.0;
    if (age <= 23) {
      ageMultiplier = 0.6; // Rookie contracts
    } else if (age <= 26) {
      ageMultiplier = 0.8; // Second contracts
    } else if (age >= 32) {
      ageMultiplier = 0.7; // Veterans take discounts
    }
    
    return baseSalary * tierMultiplier * ageMultiplier;
  }

  /// Estimate player age based on position
  static int _estimateAge(String position) {
    // Average ages by position
    return switch (position.toLowerCase()) {
      'rb' => 25,
      'wr' => 26,
      'te' => 27,
      'qb' => 28,
      'edge' => 26,
      'idl' => 27,
      _ => 26,
    };
  }
  
  /// Estimate age for known players or fall back to position average
  static int _estimatePlayerAge(String playerName, String position) {
    // Known player ages (2024 season)
    if (playerName.contains('Parsons')) return 25; // Micah Parsons born 1999
    if (playerName.contains('Watt') && playerName.contains('T.J.')) return 30;
    if (playerName.contains('Donald')) return 33;
    if (playerName.contains('Garrett')) return 29;
    
    // Fall back to position average
    return _estimateAge(position);
  }

  /// Estimate years of experience based on age
  static int _estimateExperience(int age) {
    return (age - 22).clamp(1, 15);
  }

  /// Estimate contract years remaining
  static int _estimateContractYears(int age, int tier) {
    if (tier <= 2 && age < 28) return 4;
    if (tier <= 3 && age < 30) return 3;
    return 2;
  }

  /// Get age multiplier for value calculation
  static double _getAgeMultiplier(int age) {
    if (age <= 24) return 1.2;
    if (age <= 26) return 1.1;
    if (age <= 28) return 1.0;
    if (age <= 30) return 0.9;
    if (age <= 32) return 0.7;
    return 0.5;
  }

  /// Get position importance multiplier
  static double _getPositionImportance(String position) {
    return switch (position) {
      'QB' => 1.0,
      'EDGE' => 0.9,
      'OT' => 0.85,
      'CB' => 0.8,
      'WR' => 0.75,
      'DT' || 'IDL' => 0.7,
      'S' => 0.65,
      'LB' => 0.6,
      'TE' => 0.55,
      'RB' => 0.5,
      'OG' || 'C' => 0.45,
      _ => 0.5,
    };
  }

  /// Get team abbreviation from full name
  static String _getTeamAbbreviation(String teamName) {
    Map<String, String> teamMap = {
      'Patriots': 'NE',
      'Lions': 'DET',
      '49ers': 'SF',
      'Cardinals': 'ARI',
      'Raiders': 'LV',
      'Seahawks': 'SEA',
      'Cowboys': 'DAL',
      'Chargers': 'LAC',
      'Packers': 'GB',
      'Eagles': 'PHI',
      'Titans': 'TEN',
      'Bengals': 'CIN',
      'Jets': 'NYJ',
      'Buccaneers': 'TB',
      'Vikings': 'MIN',
      'Saints': 'NO',
      'Rams': 'LAR',
      'Steelers': 'PIT',
      'Browns': 'CLE',
      'Panthers': 'CAR',
      'Jaguars': 'JAX',
      'Commanders': 'WAS',
      'Colts': 'IND',
      'Chiefs': 'KC',
      'Texans': 'HOU',
      'Ravens': 'BAL',
      'Bears': 'CHI',
      'Dolphins': 'MIA',
      'Broncos': 'DEN',
      'Falcons': 'ATL',
      'Giants': 'NYG',
      'Bills': 'BUF',
    };
    
    return teamMap[teamName] ?? teamName.substring(0, 3).toUpperCase();
  }

  /// Infer team philosophy based on cap space and name
  static TeamPhilosophy _inferTeamPhilosophy(String teamName, double capSpace) {
    if (capSpace > 40000000) return TeamPhilosophy.buildThroughDraft;
    if (['Patriots', 'Ravens', 'Steelers'].contains(teamName)) return TeamPhilosophy.analytics;
    if (['Cowboys', 'Rams', 'Eagles'].contains(teamName)) return TeamPhilosophy.aggressive;
    if (['Chiefs', 'Bills', '49ers'].contains(teamName)) return TeamPhilosophy.winNow;
    return TeamPhilosophy.balanced;
  }

  /// Infer team status based on team name (simplified)
  static TeamStatus _inferTeamStatus(String teamName) {
    // Bills should be win-now given Josh Allen's prime
    List<String> winNow = ['Bills', 'Lions', 'Dolphins', 'Jets', 'Chargers', '49ers'];
    List<String> contenders = ['Chiefs', 'Eagles', 'Cowboys', 'Ravens', 'Bengals'];
    List<String> rebuilding = ['Panthers', 'Cardinals', 'Patriots', 'Bears', 'Commanders'];
    
    if (winNow.contains(teamName)) return TeamStatus.winNow;
    if (contenders.contains(teamName)) return TeamStatus.contending;
    if (rebuilding.contains(teamName)) return TeamStatus.rebuilding;
    return TeamStatus.competitive;
  }

  /// Get default position needs (with team-specific overrides)
  static Map<String, double> _getDefaultPositionNeeds([String? teamName]) {
    // Team-specific needs
    if (teamName == 'Bills' || teamName == 'BUF') {
      return {
        'QB': 0.0,    // Josh Allen
        'RB': 0.3,    // James Cook is good
        'WR': 0.7,    // Need more weapons
        'TE': 0.5,    
        'OT': 0.4,
        'OG': 0.3,
        'C': 0.3,
        'EDGE': 0.9,  // Treat DE as EDGE
        'IDL': 0.6,   // Treat DL as IDL
        'LB': 0.5,
        'CB': 0.6,
        'S': 0.4,
      };
    }
    
    // Default needs for most teams
    return {
      'QB': 0.5,
      'RB': 0.4,
      'WR': 0.6,
      'TE': 0.4,
      'OT': 0.5,
      'OG': 0.3,
      'C': 0.3,
      'EDGE': 0.7,  // include DE as EDGE
      'IDL': 0.5,   // include DL as IDL
      'LB': 0.4,
      'CB': 0.6,
      'S': 0.5,
    };
  }

  /// Load team needs from assets/2026/team_needs.csv and normalize positions.
  /// Weights decrease by slot: [1.0, 0.85, 0.7, 0.55, 0.4, 0.25, 0.15]
  static Future<void> _loadTeamNeeds2026() async {
    try {
      final String csvString = await rootBundle.loadString('assets/2026/team_needs.csv');
      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      // Web fallback: sometimes the CSV parser returns a single row; manually split
      if (csvData.length <= 1) {
        final lines = const LineSplitter().convert(csvString.trim());
        final parsed = <List<dynamic>>[];
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final cells = line.split(',').map((s) => s.trim().replaceAll('"', '').toLowerCase()).toList();
          parsed.add(cells);
        }
        if (parsed.isNotEmpty) {
          csvData = parsed;
        }
      }
      if (csvData.isEmpty) return;
      // header indices
      final headers = csvData[0].map((h) => h.toString().toLowerCase()).toList();
      int teamAbbrIdx = _findColumnIndex(headers, ['team']);
      print('🔍 TEAM NEEDS 2026: header cols=${headers.join(', ')}, teamIdx=$teamAbbrIdx, rows=${csvData.length}');
      // Collect need column indices in order
      final List<int> needIdx = [];
      for (int k = 1; k <= 7; k++) {
        int idx = _findColumnIndex(headers, ['need$k']);
        if (idx >= 0) needIdx.add(idx);
      }
      const List<double> weights = [1.0, 0.85, 0.7, 0.55, 0.4, 0.25, 0.15];
      int updated = 0;
      int skipped = 0;
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length <= teamAbbrIdx) continue;
        String abbr = row[teamAbbrIdx].toString().replaceAll('"', '').trim().toUpperCase();
        final team = _teamsCache[abbr];
        if (team == null) {
          skipped++;
          print('⚠️ TEAM NEEDS 2026: team not found in cache for abbr=$abbr (row $i)');
          continue;
        }
        final Map<String, double> needs = {};
        for (int j = 0; j < needIdx.length && j < weights.length; j++) {
          final idx = needIdx[j];
          if (row.length <= idx) continue;
          String raw = row[idx].toString().replaceAll('"', '').trim().toUpperCase();
          if (raw.isEmpty) continue;
          // Normalize positions: DE->EDGE, DL->IDL
          String pos = raw;
          if (pos == 'DE') pos = 'EDGE';
          if (pos == 'DL') pos = 'IDL';
          // Apply highest weight if duplicate appears
          if (needs.containsKey(pos)) {
            needs[pos] = needs[pos]!.compareTo(weights[j]) >= 0 ? needs[pos]! : weights[j];
          } else {
            needs[pos] = weights[j];
          }
        }
        // Recreate the NFLTeamInfo with updated needs while preserving other fields
        _teamsCache[abbr] = NFLTeamInfo(
          teamName: team.teamName,
          abbreviation: team.abbreviation,
          availableCapSpace: team.availableCapSpace,
          totalCapSpace: team.totalCapSpace,
          projectedCapSpace2025: team.projectedCapSpace2025,
          philosophy: team.philosophy,
          status: team.status,
          positionNeeds: needs.isNotEmpty ? needs : team.positionNeeds,
          availableDraftPicks: team.availableDraftPicks,
          futureFirstRounders: team.futureFirstRounders,
          logoUrl: team.logoUrl,
          tradeAggressiveness: team.tradeAggressiveness,
          valueSeeker: team.valueSeeker,
          willingToOverpay: team.willingToOverpay,
        );
        updated++;
        if (abbr == 'BUF' || abbr == 'DAL' || abbr == 'DEN') {
          final top = _teamsCache[abbr]!.topPositionNeeds;
          print('✅ TEAM NEEDS 2026 applied for $abbr: top=${top.take(3).join(', ')} (full=${_teamsCache[abbr]!.positionNeeds})');
        }
      }
      print('🔎 TEAM NEEDS 2026 summary: updated=$updated, skipped=$skipped, cacheSize=${_teamsCache.length}');
    } catch (e) {
      // If team needs CSV fails, keep defaults silently
      print('❌ Error loading team needs 2026: $e');
    }
  }

  static String _logoForAbbr(String abbr) {
    return 'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png';
  }

  /// Get default draft picks for a team (based on projected standing)
  static List<int> _getDefaultDraftPicks(int teamIndex) {
    // Simulate draft position based on index
    int firstRoundPick = teamIndex.clamp(1, 32);
    return [
      firstRoundPick,
      32 + firstRoundPick,
      64 + firstRoundPick,
      96 + firstRoundPick,
    ];
  }

  /// Infer trade aggressiveness
  static double _inferTradeAggressiveness(String teamName) {
    Map<String, double> aggressiveness = {
      'Rams': 0.9,
      'Eagles': 0.85,
      '49ers': 0.8,
      'Bills': 0.75,
      'Cowboys': 0.7,
      'Chiefs': 0.65,
      'Patriots': 0.5,
      'Steelers': 0.45,
      'Packers': 0.4,
    };
    
    return aggressiveness[teamName] ?? 0.6;
  }

  /// Get all loaded players
  static List<NFLPlayer> getAllPlayers() {
    List<NFLPlayer> allPlayers = [];
    for (var players in _playersCache.values) {
      allPlayers.addAll(players);
    }
    return allPlayers;
  }

  /// Get players by position
  static List<NFLPlayer> getPlayersByPosition(String position) {
    return _playersCache[position.toLowerCase()] ?? [];
  }

  /// Get all teams
  static List<NFLTeamInfo> getAllTeams() {
    if (_teamsCache.isEmpty) {
      _loadDefaultTeams();
    }
    return _teamsCache.values.toList();
  }

  /// Get team by abbreviation
  static NFLTeamInfo? getTeam(String abbreviation) {
    return _teamsCache[abbreviation];
  }

  /// Get players by team
  static List<NFLPlayer> getPlayersByTeam(String teamAbbreviation) {
    List<NFLPlayer> teamPlayers = [];
    for (var players in _playersCache.values) {
      teamPlayers.addAll(players.where((p) => p.team == teamAbbreviation));
    }
    return teamPlayers;
  }
}