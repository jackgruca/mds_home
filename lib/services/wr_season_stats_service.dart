import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class WRSeasonStats {
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
  final int wrRank;
  
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
  final double? firstDownRank;
  final double? yacOERank;
  final double? YACperRecRank;
  final double? myRank;
  final int? myRankNum;
  final int? qbTier;
  
  WRSeasonStats({
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
    required this.wrRank,
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
    this.firstDownRank,
    this.yacOERank,
    this.YACperRecRank,
    this.myRank,
    this.myRankNum,
    this.qbTier,
  });
  
  factory WRSeasonStats.fromCsvRow(List<dynamic> row) {
    return WRSeasonStats(
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
      wrRank: int.tryParse(row[22]?.toString() ?? '0') ?? 0,
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
      EPARank: row.length > 34 ? double.tryParse(row[34]?.toString() ?? '0') : null,
      tgtRank: row.length > 35 ? double.tryParse(row[35]?.toString() ?? '0') : null,
      YPGRank: row.length > 36 ? double.tryParse(row[36]?.toString() ?? '0') : null,
      tdRank: row.length > 37 ? double.tryParse(row[37]?.toString() ?? '0') : null,
      conversionRank: row.length > 38 ? double.tryParse(row[38]?.toString() ?? '0') : null,
      explosiveRank: row.length > 39 ? double.tryParse(row[39]?.toString() ?? '0') : null,
      sepRank: row.length > 40 ? double.tryParse(row[40]?.toString() ?? '0') : null,
      intendedAirRank: row.length > 41 ? double.tryParse(row[41]?.toString() ?? '0') : null,
      catchRank: row.length > 42 ? double.tryParse(row[42]?.toString() ?? '0') : null,
      thirdDownRank: row.length > 43 ? double.tryParse(row[43]?.toString() ?? '0') : null,
      firstDownRank: row.length > 44 ? double.tryParse(row[44]?.toString() ?? '0') : null,
      yacOERank: row.length > 45 ? double.tryParse(row[45]?.toString() ?? '0') : null,
      YACperRecRank: row.length > 46 ? double.tryParse(row[46]?.toString() ?? '0') : null,
      myRank: row.length > 47 ? double.tryParse(row[47]?.toString() ?? '0') : null,
      myRankNum: row.length > 48 ? int.tryParse(row[48]?.toString() ?? '0') : null,
      qbTier: row.length > 49 ? int.tryParse(row[49]?.toString() ?? '0') : null,
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
      'wr_rank': wrRank,
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
      'EPA_rank': EPARank,
      'tgt_rank_pct': tgtRank,
      'YPG_rank': YPGRank,
      'td_rank': tdRank,
      'conversion_rank': conversionRank,
      'explosive_rank': explosiveRank,
      'sep_rank': sepRank,
      'intended_air_rank': intendedAirRank,
      'catch_rank': catchRank,
      'third_down_rank': thirdDownRank,
      'first_down_rank': firstDownRank,
      'yacOE_rank': yacOERank,
      'YACperRec_rank': YACperRecRank,
      'myRank': myRank,
      'myRankNum': myRankNum,
      'qbTier': qbTier,
    };
  }
}

class WRSeasonStatsService {
  static final WRSeasonStatsService _instance = WRSeasonStatsService._internal();
  factory WRSeasonStatsService() => _instance;
  WRSeasonStatsService._internal();
  
  List<WRSeasonStats>? _cache;
  
  Future<List<WRSeasonStats>> loadWRStats({
    int? season,
    String? team,
    String? playerName,
  }) async {
    print('🔍 [WR_LOAD_DEBUG] loadWRStats called with season: $season, team: $team, playerName: $playerName');
    
    // Load from cache or CSV
    if (_cache == null) {
      print('🔍 [WR_LOAD_DEBUG] Cache is null, loading from CSV...');
      await _loadFromCsv();
    } else {
      print('🔍 [WR_LOAD_DEBUG] Using cached data: ${_cache!.length} records');
    }
    
    List<WRSeasonStats> stats = _cache ?? [];
    print('🔍 [WR_LOAD_DEBUG] Starting with ${stats.length} records from cache');
    
    // Apply filters
    if (season != null) {
      stats = stats.where((s) => s.season == season).toList();
      print('🔍 [WR_LOAD_DEBUG] After season filter ($season): ${stats.length} records');
    }
    
    if (team != null && team != 'All') {
      stats = stats.where((s) => s.posteam == team).toList();
      print('🔍 [WR_LOAD_DEBUG] After team filter ($team): ${stats.length} records');
    }
    
    if (playerName != null && playerName.isNotEmpty) {
      final searchTerm = playerName.toLowerCase();
      stats = stats.where((s) => 
        s.receiverPlayerName.toLowerCase().contains(searchTerm)
      ).toList();
      print('🔍 [WR_LOAD_DEBUG] After player name filter ($playerName): ${stats.length} records');
    }
    
    print('🔍 [WR_LOAD_DEBUG] Final result: ${stats.length} records');
    return stats;
  }
  
  Future<void> _loadFromCsv() async {
    try {
      print('🔍 [WR_CSV_DEBUG] Starting to load WR stats CSV...');
      print('🔍 [WR_CSV_DEBUG] Attempting to load from path: data_processing/assets/data/wr_season_stats.csv');
      
      final String csvString = await rootBundle.loadString('data/processed/player_stats/wr_season_stats.csv');
      print('🔍 [WR_CSV_DEBUG] CSV string loaded successfully. Length: ${csvString.length} characters');
      
      // Manual line-by-line parsing (same as player_game_stats_service.dart)
      final lines = csvString.split('\n');
      print('🔍 [WR_CSV_DEBUG] Split into ${lines.length} lines');
      
      List<List<dynamic>> csvData = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Remove quotes and split by comma
          final cleanedLine = line.replaceAll('"', '');
          final fields = cleanedLine.split(',').map((f) => f.trim()).toList();
          
          // Validate we have the expected number of fields (50 for WR stats)
          if (fields.length < 30) {
            print('🔍 [WR_CSV_DEBUG] Line $i has only ${fields.length} fields, skipping');
            continue;
          }
          
          csvData.add(fields);
        } catch (e) {
          print('🔍 [WR_CSV_DEBUG] Error parsing line $i: $line - $e');
          continue;
        }
      }
      
      print('🔍 [WR_CSV_DEBUG] Manual parsing resulted in ${csvData.length} rows');
      
      if (csvData.isEmpty) {
        print('🔍 [WR_CSV_DEBUG] CSV data is empty after manual parsing!');
        _cache = [];
        return;
      }
      
      // Print header for debugging
      if (csvData.isNotEmpty) {
        print('🔍 [WR_CSV_DEBUG] Header row (${csvData[0].length} columns): ${csvData[0].take(5).join(", ")}...');
      }
      
      // Skip header row and convert to objects
      int successfulRows = 0;
      int failedRows = 0;
      
      _cache = csvData.skip(1).map((row) {
        try {
          final wrStats = WRSeasonStats.fromCsvRow(row);
          successfulRows++;
          if (successfulRows <= 3) {
            print('🔍 [WR_CSV_DEBUG] Successfully parsed row $successfulRows: ${wrStats.receiverPlayerName}, ${wrStats.posteam}, ${wrStats.season}');
            print('🔍 [WR_CSV_DEBUG] Advanced fields - numRzOpps: ${wrStats.numRzOpps}, conversion: ${wrStats.conversion}, explosiveRate: ${wrStats.explosiveRate}');
            print('🔍 [WR_CSV_DEBUG] More advanced - avgSeparation: ${wrStats.avgSeparation}, catchPercentage: ${wrStats.catchPercentage}');
            print('🔍 [WR_CSV_DEBUG] Raw row columns 23-29: ${row.length > 29 ? row.sublist(23, 30).join(", ") : "Not enough columns"}');
          }
          return wrStats;
        } catch (e) {
          failedRows++;
          if (failedRows <= 3) {
            print('🔍 [WR_CSV_DEBUG] Failed to parse row: $e');
            print('🔍 [WR_CSV_DEBUG] Row data (${row.length} columns): ${row.take(5).join(", ")}...');
          }
          rethrow;
        }
      }).toList();
      
      print('🔍 [WR_CSV_DEBUG] Final results: ${_cache!.length} total records');
      print('🔍 [WR_CSV_DEBUG] Successful rows: $successfulRows, Failed rows: $failedRows');
      print('Loaded ${_cache!.length} WR season stats from CSV');
    } catch (e) {
      print('🔍 [WR_CSV_DEBUG] ERROR loading WR stats CSV: $e');
      print('🔍 [WR_CSV_DEBUG] Stack trace: ${StackTrace.current}');
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