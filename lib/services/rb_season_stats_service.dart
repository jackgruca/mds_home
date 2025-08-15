import 'package:flutter/services.dart';

class RBSeasonStats {
  // Basic fields
  final String fantasyPlayerId;
  final String fantasyPlayerName;
  final String posteam;
  final int season;
  final int numGames;
  final int numRush;
  final int numYards;
  final int totalTD;
  final double yardsPerRush;
  final double rushPerGame;
  final double yardsPerGame;
  final double tdPerGame;
  final int numRec;
  final int recYards;
  final int recTD;
  final int myRankNum;
  final int tier;
  
  // Advanced fields
  final double totalEPA;
  final double avgEPA;
  final int numFD;
  final double FDperRush;
  final double runShare;
  final double tgtShare;
  final double? conversion;
  final int? numRzOpps;
  final double? explosiveRate;
  final double avgEff;
  final double avgRYOEperAtt;
  final int thirdDownAtt;
  final int thirdDownConversions;
  final double thirdDownRate;
  
  // Receiving stats
  final int numTgt;
  final double recPerGame;
  final double tgtPerGame;
  final double recYardsPerGame;
  final double catchPct;
  final double YAC;
  
  // Rank fields
  final double? EPARank;
  final double? tdRank;
  final double? runRank;
  final double? tgtRank;
  final double? YPGRank;
  final double? conversionRank;
  final double? explosiveRank;
  final double? RYOERank;
  final double? effRank;
  final double? thirdRank;
  final int? rbRank;
  
  RBSeasonStats({
    required this.fantasyPlayerId,
    required this.fantasyPlayerName,
    required this.posteam,
    required this.season,
    required this.numGames,
    required this.numRush,
    required this.numYards,
    required this.totalTD,
    required this.yardsPerRush,
    required this.rushPerGame,
    required this.yardsPerGame,
    required this.tdPerGame,
    required this.numRec,
    required this.recYards,
    required this.recTD,
    required this.myRankNum,
    required this.tier,
    required this.totalEPA,
    required this.avgEPA,
    required this.numFD,
    required this.FDperRush,
    required this.runShare,
    required this.tgtShare,
    this.conversion,
    this.numRzOpps,
    this.explosiveRate,
    required this.avgEff,
    required this.avgRYOEperAtt,
    required this.thirdDownAtt,
    required this.thirdDownConversions,
    required this.thirdDownRate,
    required this.numTgt,
    required this.recPerGame,
    required this.tgtPerGame,
    required this.recYardsPerGame,
    required this.catchPct,
    required this.YAC,
    this.EPARank,
    this.tdRank,
    this.runRank,
    this.tgtRank,
    this.YPGRank,
    this.conversionRank,
    this.explosiveRank,
    this.RYOERank,
    this.effRank,
    this.thirdRank,
    this.rbRank,
  });
  
  factory RBSeasonStats.fromCsvRow(List<dynamic> row) {
    print('🔍 [RB_PARSE_DEBUG] Parsing CSV row with ${row.length} fields');
    print('🔍 [RB_PARSE_DEBUG] First 15 fields: ${row.take(15).join(", ")}');
    print('🔍 [RB_PARSE_DEBUG] Advanced fields [20-24]: ${row.length > 24 ? row.sublist(20, 25).join(", ") : "Not enough columns"}');
    
    // Parse core values using correct CSV column indices based on header analysis
    // Header: fantasy_player_id,fantasy_player_name,team,posteam,season,player_position,numGames,myRankNum,myRank,rbTier,tier,totalEPA,totalTD,run_share,YPG,EPA_rank,td_rank,run_rank,YPG_rank,tgt_share,conversion,explosive_rate,third_down_rate,avg_eff,avg_RYOE_perAtt,tgt_rank,third_rank,conversion_rank,explosive_rank,RYOE_rank,eff_rank
    int numGames = int.tryParse(row[6]?.toString() ?? '0') ?? 0;
    double yardsPerGame = double.tryParse(row[14]?.toString() ?? '0') ?? 0.0; // YPG column
    int totalTD = int.tryParse(row[12]?.toString() ?? '0') ?? 0; // totalTD column
    double totalEPA = double.tryParse(row[11]?.toString() ?? '0') ?? 0.0; // totalEPA column
    double runShare = double.tryParse(row[13]?.toString() ?? '0') ?? 0.0; // run_share column
    double tgtShare = double.tryParse(row[19]?.toString() ?? '0') ?? 0.0; // tgt_share column
    
    // Parse advanced fields with correct indices - handle potential null/empty values
    double? conversion = double.tryParse(row[20]?.toString() ?? ''); // conversion column
    double? explosiveRate = double.tryParse(row[21]?.toString() ?? ''); // explosive_rate column  
    double thirdDownRate = double.tryParse(row[22]?.toString() ?? '0') ?? 0.0; // third_down_rate column
    double avgEff = double.tryParse(row[23]?.toString() ?? '0') ?? 0.0; // avg_eff column
    double avgRYOEperAtt = double.tryParse(row[24]?.toString() ?? '0') ?? 0.0; // avg_RYOE_perAtt column
    
    print('🔍 [RB_PARSE_DEBUG] Parsed advanced values - conversion: $conversion, explosiveRate: $explosiveRate, thirdDownRate: $thirdDownRate');
    print('🔍 [RB_PARSE_DEBUG] Parsed advanced values - avgEff: $avgEff, avgRYOEperAtt: $avgRYOEperAtt');
    
    // Calculate derived stats
    int totalYards = (yardsPerGame * numGames).round();
    double avgEPA = numGames > 0 ? totalEPA / numGames : 0.0;
    double tdPerGame = numGames > 0 ? totalTD / numGames : 0.0;
    
    // Estimate rush attempts from run share and efficiency
    int estimatedRushAtts = avgEff > 0 ? (totalYards / avgEff).round() : (yardsPerGame * numGames / 4.2).round();
    double yardsPerRush = estimatedRushAtts > 0 ? totalYards / estimatedRushAtts : 0.0;
    double rushPerGame = numGames > 0 ? estimatedRushAtts / numGames : 0.0;
    
    // Estimate receiving stats from target share (very rough estimates)
    int estimatedTargets = (tgtShare * 600 * numGames / 17).round(); // ~600 team targets per season
    int estimatedReceptions = (estimatedTargets * 0.65).round(); // ~65% catch rate
    int estimatedRecYards = (estimatedReceptions * 8.5).round(); // ~8.5 yards per reception
    
    return RBSeasonStats(
      fantasyPlayerId: row[0]?.toString() ?? '',
      fantasyPlayerName: row[1]?.toString() ?? '',
      posteam: row[3]?.toString() ?? '',
      season: int.tryParse(row[4]?.toString() ?? '0') ?? 0,
      numGames: numGames,
      myRankNum: int.tryParse(row[7]?.toString() ?? '0') ?? 0,
      tier: int.tryParse(row[10]?.toString() ?? '0') ?? 0,
      rbRank: null,
      
      // Basic stats calculated from CSV data
      numRush: estimatedRushAtts,
      numYards: totalYards,
      totalTD: totalTD,
      yardsPerRush: yardsPerRush,
      rushPerGame: rushPerGame,
      yardsPerGame: yardsPerGame,
      tdPerGame: tdPerGame,
      
      // Receiving stats (estimated)
      numRec: estimatedReceptions,
      recYards: estimatedRecYards,
      recTD: (totalTD * 0.2).round(), // Estimate ~20% of TDs are receiving
      numFD: 0, // Not available
      FDperRush: 0.0, // Not available
      numTgt: estimatedTargets,
      recPerGame: numGames > 0 ? estimatedReceptions / numGames : 0.0,
      tgtPerGame: numGames > 0 ? estimatedTargets / numGames : 0.0,
      recYardsPerGame: numGames > 0 ? estimatedRecYards / numGames : 0.0,
      catchPct: estimatedTargets > 0 ? estimatedReceptions / estimatedTargets * 100 : 0.0,
      YAC: 0.0, // Not available
      
      // Advanced stats from CSV - now using correct indices and actual data
      totalEPA: totalEPA,
      avgEPA: avgEPA,
      runShare: runShare,
      tgtShare: tgtShare,
      conversion: conversion, // Use parsed value as-is (including 0)
      numRzOpps: null, // Not available in this CSV
      explosiveRate: explosiveRate, // Use parsed value as-is (including 0)
      avgEff: avgEff,
      avgRYOEperAtt: avgRYOEperAtt,
      thirdDownAtt: 0, // Not available in this CSV
      thirdDownConversions: 0, // Not available in this CSV
      thirdDownRate: thirdDownRate,
      
      // Rank fields from CSV - using correct column indices
      EPARank: row.length > 15 ? double.tryParse(row[15]?.toString() ?? '') : null, // EPA_rank
      tdRank: row.length > 16 ? double.tryParse(row[16]?.toString() ?? '') : null, // td_rank
      runRank: row.length > 17 ? double.tryParse(row[17]?.toString() ?? '') : null, // run_rank
      YPGRank: row.length > 18 ? double.tryParse(row[18]?.toString() ?? '') : null, // YPG_rank
      tgtRank: row.length > 25 ? double.tryParse(row[25]?.toString() ?? '') : null, // tgt_rank
      thirdRank: row.length > 26 ? double.tryParse(row[26]?.toString() ?? '') : null, // third_rank
      conversionRank: row.length > 27 ? double.tryParse(row[27]?.toString() ?? '') : null, // conversion_rank
      explosiveRank: row.length > 28 ? double.tryParse(row[28]?.toString() ?? '') : null, // explosive_rank
      RYOERank: row.length > 29 ? double.tryParse(row[29]?.toString() ?? '') : null, // RYOE_rank
      effRank: row.length > 30 ? double.tryParse(row[30]?.toString() ?? '') : null, // eff_rank
    );
  }
  
  Map<String, dynamic> toBasicMap() {
    return {
      'fantasy_player_name': fantasyPlayerName,
      'posteam': posteam,
      'season': season,
      'numGames': numGames,
      'numRush': numRush,
      'numYards': numYards,
      'totalTD': totalTD,
      'yardsPerRush': yardsPerRush.toStringAsFixed(2),
      'rushPerGame': rushPerGame.toStringAsFixed(1),
      'yardsPerGame': yardsPerGame.toStringAsFixed(1),
      'tdPerGame': tdPerGame.toStringAsFixed(2),
      'numRec': numRec,
      'recYards': recYards,
      'recTD': recTD,
      'myRankNum': myRankNum,
      'tier': tier,
    };
  }
  
  Map<String, dynamic> toAdvancedMap() {
    print('🔍 [RB_ADVANCED_DEBUG] Creating advanced map for $fantasyPlayerName');
    print('🔍 [RB_ADVANCED_DEBUG] Raw values - totalEPA: $totalEPA, avgEPA: $avgEPA, runShare: $runShare');
    print('🔍 [RB_ADVANCED_DEBUG] Raw values - tgtShare: $tgtShare, conversion: $conversion, explosiveRate: $explosiveRate');
    print('🔍 [RB_ADVANCED_DEBUG] Raw values - avgEff: $avgEff, avgRYOEperAtt: $avgRYOEperAtt, thirdDownRate: $thirdDownRate');
    
    final advancedMap = {
      'fantasy_player_name': fantasyPlayerName,
      'posteam': posteam,
      'season': season,
      'numGames': numGames,
      'totalEPA': totalEPA.toStringAsFixed(2),
      'avgEPA': avgEPA.toStringAsFixed(3),
      'run_share': runShare.toStringAsFixed(4),
      'tgt_share': tgtShare.toStringAsFixed(4),
      'conversion': conversion?.toStringAsFixed(3),
      'explosive_rate': explosiveRate?.toStringAsFixed(3),
      'avg_eff': avgEff.toStringAsFixed(2),
      'avg_RYOE_perAtt': avgRYOEperAtt.toStringAsFixed(2),
      'third_down_rate': thirdDownRate.toStringAsFixed(3),
    };
    
    print('🔍 [RB_ADVANCED_DEBUG] Final advanced map created with ${advancedMap.length} fields');
    print('🔍 [RB_ADVANCED_DEBUG] Key values - totalEPA: ${advancedMap['totalEPA']}, conversion: ${advancedMap['conversion']}, explosive_rate: ${advancedMap['explosive_rate']}');
    
    return advancedMap;
  }
  
  Map<String, dynamic> toFullMap() {
    return {
      ...toBasicMap(),
      ...toAdvancedMap(),
      // Add rank fields for future use
      'EPA_rank': EPARank?.toStringAsFixed(2),
      'td_rank': tdRank?.toStringAsFixed(2),
      'run_rank': runRank?.toStringAsFixed(2),
      'tgt_rank': tgtRank?.toStringAsFixed(2),
      'YPG_rank': YPGRank?.toStringAsFixed(2),
      'conversion_rank': conversionRank?.toStringAsFixed(2),
      'explosive_rank': explosiveRank?.toStringAsFixed(2),
      'RYOE_rank': RYOERank?.toStringAsFixed(2),
      'eff_rank': effRank?.toStringAsFixed(2),
      'third_rank': thirdRank?.toStringAsFixed(2),
      'rb_rank': rbRank,
    };
  }
}

class RBSeasonStatsService {
  static final RBSeasonStatsService _instance = RBSeasonStatsService._internal();
  factory RBSeasonStatsService() => _instance;
  RBSeasonStatsService._internal();
  
  List<RBSeasonStats>? _cache;
  
  Future<List<RBSeasonStats>> loadRBStats({
    int? season,
    String? team,
    String? playerName,
  }) async {
    print('🔍 [RB_LOAD_DEBUG] loadRBStats called with season: $season, team: $team, playerName: $playerName');
    
    // Load from cache or CSV
    if (_cache == null) {
      print('🔍 [RB_LOAD_DEBUG] Cache is null, loading from CSV...');
      await _loadFromCsv();
    } else {
      print('🔍 [RB_LOAD_DEBUG] Using cached data: ${_cache!.length} records');
    }
    
    // Debug: If cache is still null or empty after loading, try force reload
    if (_cache == null || _cache!.isEmpty) {
      print('🔍 [RB_LOAD_DEBUG] Cache is still empty after load attempt, forcing reload...');
      _cache = null; // Force clear
      await _loadFromCsv();
    }
    
    List<RBSeasonStats> stats = _cache ?? [];
    print('🔍 [RB_LOAD_DEBUG] Starting with ${stats.length} records from cache');
    
    // Apply filters
    if (season != null) {
      stats = stats.where((s) => s.season == season).toList();
      print('🔍 [RB_LOAD_DEBUG] After season filter ($season): ${stats.length} records');
    }
    
    if (team != null && team != 'All') {
      stats = stats.where((s) => s.posteam == team).toList();
      print('🔍 [RB_LOAD_DEBUG] After team filter ($team): ${stats.length} records');
    }
    
    if (playerName != null && playerName.isNotEmpty) {
      final searchTerm = playerName.toLowerCase();
      stats = stats.where((s) => 
        s.fantasyPlayerName.toLowerCase().contains(searchTerm)
      ).toList();
      print('🔍 [RB_LOAD_DEBUG] After player name filter ($playerName): ${stats.length} records');
    }
    
    print('🔍 [RB_LOAD_DEBUG] Final result: ${stats.length} records');
    return stats;
  }
  
  Future<void> _loadFromCsv() async {
    try {
      print('🔍 [RB_CSV_DEBUG] Starting to load RB stats CSV...');
      print('🔍 [RB_CSV_DEBUG] Attempting to load from path: data_processing/assets/data/rb_season_stats.csv');
      
      final String csvString = await rootBundle.loadString('data/processed/player_stats/rb_season_stats.csv');
      print('🔍 [RB_CSV_DEBUG] CSV string loaded successfully. Length: ${csvString.length} characters');
      
      // Manual line-by-line parsing (same as player_game_stats_service.dart)
      final lines = csvString.split('\n');
      print('🔍 [RB_CSV_DEBUG] Split into ${lines.length} lines');
      
      List<List<dynamic>> csvData = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Remove quotes and split by comma
          final cleanedLine = line.replaceAll('"', '');
          final fields = cleanedLine.split(',').map((f) => f.trim()).toList();
          
          // Validate we have the expected number of fields (40+ for RB stats)
          if (fields.length < 40) {
            print('🔍 [RB_CSV_DEBUG] Line $i has only ${fields.length} fields, skipping');
            continue;
          }
          
          csvData.add(fields);
        } catch (e) {
          print('🔍 [RB_CSV_DEBUG] Error parsing line $i: $line - $e');
          continue;
        }
      }
      
      print('🔍 [RB_CSV_DEBUG] Manual parsing resulted in ${csvData.length} rows');
      
      if (csvData.isEmpty) {
        print('🔍 [RB_CSV_DEBUG] CSV data is empty after manual parsing!');
        _cache = [];
        return;
      }
      
      // Print header for debugging
      if (csvData.isNotEmpty) {
        print('🔍 [RB_CSV_DEBUG] Header row (${csvData[0].length} columns): ${csvData[0].take(5).join(", ")}...');
      }
      
      // Skip header row and convert to objects
      int successfulRows = 0;
      int failedRows = 0;
      
      _cache = csvData.skip(1).map((row) {
        try {
          final rbStats = RBSeasonStats.fromCsvRow(row);
          successfulRows++;
          if (successfulRows <= 3) {
            print('🔍 [RB_CSV_DEBUG] Successfully parsed row $successfulRows: ${rbStats.fantasyPlayerName}, ${rbStats.posteam}, ${rbStats.season}');
            print('🔍 [RB_CSV_DEBUG] Basic fields - numRush: ${rbStats.numRush}, numYards: ${rbStats.numYards}, totalTD: ${rbStats.totalTD}');
            print('🔍 [RB_CSV_DEBUG] Advanced fields - totalEPA: ${rbStats.totalEPA}, runShare: ${rbStats.runShare}');
          }
          return rbStats;
        } catch (e) {
          failedRows++;
          if (failedRows <= 3) {
            print('🔍 [RB_CSV_DEBUG] Failed to parse row: $e');
            print('🔍 [RB_CSV_DEBUG] Row data (${row.length} columns): ${row.take(10).join(", ")}...');
          }
          rethrow;
        }
      }).toList();
      
      print('🔍 [RB_CSV_DEBUG] Final results: ${_cache!.length} total records');
      print('🔍 [RB_CSV_DEBUG] Successful rows: $successfulRows, Failed rows: $failedRows');
      print('Loaded ${_cache!.length} RB season stats from CSV');
    } catch (e) {
      print('🔍 [RB_CSV_DEBUG] ERROR loading RB stats CSV: $e');
      print('🔍 [RB_CSV_DEBUG] Stack trace: ${StackTrace.current}');
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