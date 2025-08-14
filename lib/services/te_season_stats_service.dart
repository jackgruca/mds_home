import 'package:flutter/services.dart';

class TESeasonStats {
  // Basic fields
  final String receiverPlayerId;
  final String receiverPlayerName;
  final String posteam;
  final int season;
  final int numGames;
  final int numTgt;
  final int numRec;
  final int numYards;
  final int totalTD;
  final double recPerGame;
  final double tgtPerGame;
  final double yardsPerGame;
  final double catchPct;
  final int YAC;
  final double aDoT;
  final double tgtShare;
  final int teRank;
  
  // Advanced fields
  final double totalEPA;
  final double avgEPA;
  final int numFD;
  final double FDperTgt;
  final double YACperRec;
  final int? numRzOpps;
  final double? conversion;
  final double? explosiveRate;
  final double? avgSeparation;
  final double? avgIntendedAirYards;
  final double? catchPercentage;
  final double? yacAboveExpected;
  final int? thirdDownTargets;
  final int? thirdDownConversions;
  final double? thirdDownRate;
  
  // Rank fields (for future toggle)
  final double? EPARank;
  final double? tgtRank;
  final double? YPGRank;
  final double? tdRank;
  final double? conversionRank;
  final double? explosiveRank;
  final double? sepRank;
  final double? intendedAirRank;
  final double? catchRank;
  final double? thirdDownRank;
  final double? yacOERank;
  final double? yacRank;
  final double? myRank;
  final int? myRankNum;
  final int? teTier;
  
  TESeasonStats({
    required this.receiverPlayerId,
    required this.receiverPlayerName,
    required this.posteam,
    required this.season,
    required this.numGames,
    required this.numTgt,
    required this.numRec,
    required this.numYards,
    required this.totalTD,
    required this.recPerGame,
    required this.tgtPerGame,
    required this.yardsPerGame,
    required this.catchPct,
    required this.YAC,
    required this.aDoT,
    required this.tgtShare,
    required this.teRank,
    required this.totalEPA,
    required this.avgEPA,
    required this.numFD,
    required this.FDperTgt,
    required this.YACperRec,
    this.numRzOpps,
    this.conversion,
    this.explosiveRate,
    this.avgSeparation,
    this.avgIntendedAirYards,
    this.catchPercentage,
    this.yacAboveExpected,
    this.thirdDownTargets,
    this.thirdDownConversions,
    this.thirdDownRate,
    this.EPARank,
    this.tgtRank,
    this.YPGRank,
    this.tdRank,
    this.conversionRank,
    this.explosiveRank,
    this.sepRank,
    this.intendedAirRank,
    this.catchRank,
    this.thirdDownRank,
    this.yacOERank,
    this.yacRank,
    this.myRank,
    this.myRankNum,
    this.teTier,
  });
  
  factory TESeasonStats.fromCsvRow(List<dynamic> row) {
    return TESeasonStats(
      receiverPlayerId: row[0]?.toString() ?? '',
      receiverPlayerName: row[1]?.toString() ?? '',
      posteam: row[2]?.toString() ?? '',
      season: int.tryParse(row[3]?.toString() ?? '0') ?? 0,
      numGames: int.tryParse(row[4]?.toString() ?? '0') ?? 0,
      totalEPA: double.tryParse(row[5]?.toString() ?? '0') ?? 0.0,
      avgEPA: double.tryParse(row[6]?.toString() ?? '0') ?? 0.0,
      totalTD: int.tryParse(row[7]?.toString() ?? '0') ?? 0,
      numTgt: int.tryParse(row[8]?.toString() ?? '0') ?? 0,
      numRec: int.tryParse(row[9]?.toString() ?? '0') ?? 0,
      numYards: int.tryParse(row[10]?.toString() ?? '0') ?? 0,
      numFD: int.tryParse(row[11]?.toString() ?? '0') ?? 0,
      FDperTgt: double.tryParse(row[12]?.toString() ?? '0') ?? 0.0,
      recPerGame: double.tryParse(row[13]?.toString() ?? '0') ?? 0.0,
      tgtPerGame: double.tryParse(row[14]?.toString() ?? '0') ?? 0.0,
      yardsPerGame: double.tryParse(row[15]?.toString() ?? '0') ?? 0.0,
      catchPct: double.tryParse(row[16]?.toString() ?? '0') ?? 0.0,
      YAC: int.tryParse(row[17]?.toString() ?? '0') ?? 0,
      YACperRec: double.tryParse(row[18]?.toString() ?? '0') ?? 0.0,
      aDoT: double.tryParse(row[19]?.toString() ?? '0') ?? 0.0,
      tgtShare: double.tryParse(row[21]?.toString() ?? '0') ?? 0.0,
      teRank: int.tryParse(row[22]?.toString() ?? '0') ?? 0,
      numRzOpps: row.length > 23 ? int.tryParse(row[23]?.toString() ?? '') : null,
      conversion: row.length > 24 ? double.tryParse(row[24]?.toString() ?? '') : null,
      explosiveRate: row.length > 25 ? double.tryParse(row[25]?.toString() ?? '') : null,
      avgSeparation: row.length > 27 ? double.tryParse(row[27]?.toString() ?? '') : null,
      avgIntendedAirYards: row.length > 28 ? double.tryParse(row[28]?.toString() ?? '') : null,
      catchPercentage: row.length > 29 ? double.tryParse(row[29]?.toString() ?? '') : null,
      yacAboveExpected: row.length > 30 ? double.tryParse(row[30]?.toString() ?? '') : null,
      thirdDownTargets: row.length > 31 ? int.tryParse(row[31]?.toString() ?? '') : null,
      thirdDownConversions: row.length > 32 ? int.tryParse(row[32]?.toString() ?? '') : null,
      thirdDownRate: row.length > 33 ? double.tryParse(row[33]?.toString() ?? '') : null,
      EPARank: row.length > 34 ? double.tryParse(row[34]?.toString() ?? '') : null,
      tdRank: row.length > 35 ? double.tryParse(row[35]?.toString() ?? '') : null,
      tgtRank: row.length > 36 ? double.tryParse(row[36]?.toString() ?? '') : null,
      YPGRank: row.length > 37 ? double.tryParse(row[37]?.toString() ?? '') : null,
      conversionRank: row.length > 38 ? double.tryParse(row[38]?.toString() ?? '') : null,
      explosiveRank: row.length > 39 ? double.tryParse(row[39]?.toString() ?? '') : null,
      sepRank: row.length > 40 ? double.tryParse(row[40]?.toString() ?? '') : null,
      intendedAirRank: row.length > 41 ? double.tryParse(row[41]?.toString() ?? '') : null,
      catchRank: row.length > 42 ? double.tryParse(row[42]?.toString() ?? '') : null,
      thirdDownRank: row.length > 43 ? double.tryParse(row[43]?.toString() ?? '') : null,
      yacOERank: row.length > 44 ? double.tryParse(row[44]?.toString() ?? '') : null,
      yacRank: row.length > 45 ? double.tryParse(row[45]?.toString() ?? '') : null,
      myRank: row.length > 46 ? double.tryParse(row[46]?.toString() ?? '') : null,
      myRankNum: row.length > 47 ? int.tryParse(row[47]?.toString() ?? '') : null,
      teTier: row.length > 48 ? int.tryParse(row[48]?.toString() ?? '') : null,
    );
  }
  
  Map<String, dynamic> toBasicMap() {
    return {
      'receiver_player_id': receiverPlayerId,
      'receiver_player_name': receiverPlayerName,
      'posteam': posteam,
      'season': season,
      'numGames': numGames,
      'numTgt': numTgt,
      'numRec': numRec,
      'numYards': numYards,
      'totalTD': totalTD,
      'recPerGame': recPerGame.toStringAsFixed(2),
      'tgtPerGame': tgtPerGame.toStringAsFixed(2),
      'yardsPerGame': yardsPerGame.toStringAsFixed(2),
      'catchPct': catchPct.toStringAsFixed(2),
      'YAC': YAC,
      'aDoT': aDoT.toStringAsFixed(2),
      'tgt_share': tgtShare.toStringAsFixed(2),
      'te_rank': teRank,
    };
  }
  
  Map<String, dynamic> toAdvancedMap() {
    return {
      'receiver_player_id': receiverPlayerId,
      'receiver_player_name': receiverPlayerName,
      'posteam': posteam,
      'season': season,
      'numGames': numGames,
      'totalEPA': totalEPA.toStringAsFixed(2),
      'avgEPA': avgEPA.toStringAsFixed(2),
      'numFD': numFD,
      'FDperTgt': FDperTgt.toStringAsFixed(2),
      'YACperRec': YACperRec.toStringAsFixed(2),
      'num_rz_opps': numRzOpps,
      'conversion': conversion?.toStringAsFixed(2),
      'explosive_rate': explosiveRate?.toStringAsFixed(2),
      'avg_separation': avgSeparation?.toStringAsFixed(2),
      'avg_intended_air_yards': avgIntendedAirYards?.toStringAsFixed(2),
      'catch_percentage': catchPercentage?.toStringAsFixed(2),
      'yac_above_expected': yacAboveExpected?.toStringAsFixed(2),
      'third_down_targets': thirdDownTargets,
      'third_down_conversions': thirdDownConversions,
      'third_down_rate': thirdDownRate?.toStringAsFixed(2),
    };
  }
  
  Map<String, dynamic> toFullMap() {
    return {
      ...toBasicMap(),
      ...toAdvancedMap(),
      // Add rank fields for future use
      'EPA_rank': EPARank?.toStringAsFixed(2),
      'td_rank': tdRank?.toStringAsFixed(2),
      'tgt_rank_pct': tgtRank?.toStringAsFixed(2),
      'YPG_rank': YPGRank?.toStringAsFixed(2),
      'conversion_rank': conversionRank?.toStringAsFixed(2),
      'explosive_rank': explosiveRank?.toStringAsFixed(2),
      'sep_rank': sepRank?.toStringAsFixed(2),
      'intended_air_rank': intendedAirRank?.toStringAsFixed(2),
      'catch_rank': catchRank?.toStringAsFixed(2),
      'third_down_rank': thirdDownRank?.toStringAsFixed(2),
      'yacOE_rank': yacOERank?.toStringAsFixed(2),
      'yac_rank': yacRank?.toStringAsFixed(2),
      'myRank': myRank?.toStringAsFixed(2),
      'myRankNum': myRankNum,
      'teTier': teTier,
    };
  }
}

class TESeasonStatsService {
  static final TESeasonStatsService _instance = TESeasonStatsService._internal();
  factory TESeasonStatsService() => _instance;
  TESeasonStatsService._internal();
  
  List<TESeasonStats>? _cache;
  
  Future<List<TESeasonStats>> loadTEStats({
    int? season,
    String? team,
    String? playerName,
  }) async {
    print('🔍 [TE_LOAD_DEBUG] loadTEStats called with season: $season, team: $team, playerName: $playerName');
    
    // Load from cache or CSV
    if (_cache == null) {
      print('🔍 [TE_LOAD_DEBUG] Cache is null, loading from CSV...');
      await _loadFromCsv();
    } else {
      print('🔍 [TE_LOAD_DEBUG] Using cached data: ${_cache!.length} records');
    }
    
    List<TESeasonStats> stats = _cache ?? [];
    print('🔍 [TE_LOAD_DEBUG] Starting with ${stats.length} records from cache');
    
    // Apply filters
    if (season != null) {
      stats = stats.where((s) => s.season == season).toList();
      print('🔍 [TE_LOAD_DEBUG] After season filter ($season): ${stats.length} records');
    }
    
    if (team != null && team != 'All') {
      stats = stats.where((s) => s.posteam == team).toList();
      print('🔍 [TE_LOAD_DEBUG] After team filter ($team): ${stats.length} records');
    }
    
    if (playerName != null && playerName.isNotEmpty) {
      final searchTerm = playerName.toLowerCase();
      stats = stats.where((s) => 
        s.receiverPlayerName.toLowerCase().contains(searchTerm)
      ).toList();
      print('🔍 [TE_LOAD_DEBUG] After player name filter ($playerName): ${stats.length} records');
    }
    
    print('🔍 [TE_LOAD_DEBUG] Final result: ${stats.length} records');
    return stats;
  }
  
  Future<void> _loadFromCsv() async {
    try {
      print('🔍 [TE_CSV_DEBUG] Starting to load TE stats CSV...');
      print('🔍 [TE_CSV_DEBUG] Attempting to load from path: data_processing/assets/data/te_season_stats.csv');
      
      final String csvString = await rootBundle.loadString('data_processing/assets/data/te_season_stats.csv');
      print('🔍 [TE_CSV_DEBUG] CSV string loaded successfully. Length: ${csvString.length} characters');
      
      // Manual line-by-line parsing (avoiding the pitfall from WR stats)
      final lines = csvString.split('\n');
      print('🔍 [TE_CSV_DEBUG] Split into ${lines.length} lines');
      
      // Debug: Check first few characters of the string
      print('🔍 [TE_CSV_DEBUG] First 200 chars of CSV: ${csvString.substring(0, csvString.length > 200 ? 200 : csvString.length)}');
      
      List<List<dynamic>> csvData = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Remove quotes and split by comma
          final cleanedLine = line.replaceAll('"', '');
          final fields = cleanedLine.split(',').map((f) => f.trim()).toList();
          
          // Validate we have the expected number of fields (around 49 for TE stats)
          if (fields.length < 30) {
            print('🔍 [TE_CSV_DEBUG] Line $i has only ${fields.length} fields, skipping');
            continue;
          }
          
          csvData.add(fields);
        } catch (e) {
          print('🔍 [TE_CSV_DEBUG] Error parsing line $i: $line - $e');
          continue;
        }
      }
      
      print('🔍 [TE_CSV_DEBUG] Manual parsing resulted in ${csvData.length} rows');
      
      if (csvData.isEmpty) {
        print('🔍 [TE_CSV_DEBUG] CSV data is empty after manual parsing!');
        _cache = [];
        return;
      }
      
      // Print header for debugging
      if (csvData.isNotEmpty) {
        print('🔍 [TE_CSV_DEBUG] Header row (${csvData[0].length} columns): ${csvData[0].take(5).join(", ")}...');
      }
      
      // Skip header row and convert to objects
      int successfulRows = 0;
      int failedRows = 0;
      
      _cache = csvData.skip(1).map((row) {
        try {
          final teStats = TESeasonStats.fromCsvRow(row);
          successfulRows++;
          if (successfulRows <= 3) {
            print('🔍 [TE_CSV_DEBUG] Successfully parsed row $successfulRows: ${teStats.receiverPlayerName}, ${teStats.posteam}, ${teStats.season}');
            print('🔍 [TE_CSV_DEBUG] Advanced fields - numRzOpps: ${teStats.numRzOpps}, conversion: ${teStats.conversion}, explosiveRate: ${teStats.explosiveRate}');
            print('🔍 [TE_CSV_DEBUG] More advanced - avgSeparation: ${teStats.avgSeparation}, catchPercentage: ${teStats.catchPercentage}');
            print('🔍 [TE_CSV_DEBUG] Raw row columns 23-29: ${row.length > 29 ? row.sublist(23, 30).join(", ") : "Not enough columns"}');
          }
          return teStats;
        } catch (e) {
          failedRows++;
          if (failedRows <= 3) {
            print('🔍 [TE_CSV_DEBUG] Failed to parse row: $e');
            print('🔍 [TE_CSV_DEBUG] Row data (${row.length} columns): ${row.take(5).join(", ")}...');
          }
          rethrow;
        }
      }).toList();
      
      print('🔍 [TE_CSV_DEBUG] Final results: ${_cache!.length} total records');
      print('🔍 [TE_CSV_DEBUG] Successful rows: $successfulRows, Failed rows: $failedRows');
      print('Loaded ${_cache!.length} TE season stats from CSV');
    } catch (e) {
      print('🔍 [TE_CSV_DEBUG] ERROR loading TE stats CSV: $e');
      print('🔍 [TE_CSV_DEBUG] Stack trace: ${StackTrace.current}');
      _cache = [];
    }
  }
  
  Future<List<int>> getAvailableSeasons() async {
    if (_cache == null) {
      await _loadFromCsv();
    }
    
    final seasons = (_cache ?? [])
        .map((s) => s.season)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
    
    return seasons;
  }
  
  void clearCache() {
    _cache = null;
  }
}