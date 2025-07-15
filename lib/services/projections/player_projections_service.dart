import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:mds_home/models/projections/player_projection.dart';
import 'package:mds_home/models/projections/team_projections.dart';

class PlayerProjectionsService {
  static const String _csvAssetPath = 'assets/2025/FF_WR_2025_v2.csv';
  
  // Team name mappings
  static const Map<String, String> _teamNames = {
    'ARI': 'Arizona Cardinals',
    'ATL': 'Atlanta Falcons',
    'BAL': 'Baltimore Ravens',
    'BUF': 'Buffalo Bills',
    'CAR': 'Carolina Panthers',
    'CHI': 'Chicago Bears',
    'CIN': 'Cincinnati Bengals',
    'CLE': 'Cleveland Browns',
    'DAL': 'Dallas Cowboys',
    'DEN': 'Denver Broncos',
    'DET': 'Detroit Lions',
    'GB': 'Green Bay Packers',
    'HOU': 'Houston Texans',
    'IND': 'Indianapolis Colts',
    'JAX': 'Jacksonville Jaguars',
    'KC': 'Kansas City Chiefs',
    'LV': 'Las Vegas Raiders',
    'LAC': 'Los Angeles Chargers',
    'LAR': 'Los Angeles Rams',
    'MIA': 'Miami Dolphins',
    'MIN': 'Minnesota Vikings',
    'NE': 'New England Patriots',
    'NO': 'New Orleans Saints',
    'NYG': 'New York Giants',
    'NYJ': 'New York Jets',
    'PHI': 'Philadelphia Eagles',
    'PIT': 'Pittsburgh Steelers',
    'SF': 'San Francisco 49ers',
    'SEA': 'Seattle Seahawks',
    'TB': 'Tampa Bay Buccaneers',
    'TEN': 'Tennessee Titans',
    'WAS': 'Washington Commanders',
  };

  List<PlayerProjection>? _cachedProjections;
  Map<String, TeamProjections>? _cachedTeamProjections;

  // Load initial projections from CSV
  Future<List<PlayerProjection>> loadInitialProjections() async {
    if (_cachedProjections != null) {
      return _cachedProjections!;
    }

    try {
      final csvString = await rootBundle.loadString(_csvAssetPath);
      final csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final headers = csvData.first.map((e) => e.toString()).toList();
      final rows = csvData.skip(1).toList();

      final projections = <PlayerProjection>[];
      
      for (final row in rows) {
        try {
          final rowMap = <String, dynamic>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i];
          }

          // Skip rows without essential data
          if (rowMap['receiver_player_name'] == null || 
              rowMap['receiver_player_name'].toString().isEmpty ||
              rowMap['NY_posteam'] == null || 
              rowMap['NY_posteam'].toString().isEmpty) {
            continue;
          }

          final projection = PlayerProjection.fromCsvRow(rowMap);
          projections.add(projection);
        } catch (e) {
          // Skip malformed rows
          continue;
        }
      }

      _cachedProjections = projections;
      return projections;
    } catch (e) {
      throw Exception('Failed to load projections: $e');
    }
  }

  // Load team projections grouped by team
  Future<Map<String, TeamProjections>> loadTeamProjections() async {
    if (_cachedTeamProjections != null) {
      return _cachedTeamProjections!;
    }

    final projections = await loadInitialProjections();
    final teamProjectionsMap = <String, TeamProjections>{};

    // Group players by team
    final playersByTeam = <String, List<PlayerProjection>>{};
    for (final projection in projections) {
      final team = projection.team;
      if (!playersByTeam.containsKey(team)) {
        playersByTeam[team] = [];
      }
      playersByTeam[team]!.add(projection);
    }

    // Create TeamProjections for each team and calculate projections
    for (final entry in playersByTeam.entries) {
      final teamCode = entry.key;
      final players = entry.value;
      
      if (players.isEmpty) continue;

      // Calculate projections for all players using the calculation engine
      final calculatedPlayers = <PlayerProjection>[];
      for (final player in players) {
        final calculatedPlayer = await calculateProjections(player);
        calculatedPlayers.add(calculatedPlayer);
      }

      // Use the first player's team context as default
      final firstPlayer = calculatedPlayers.first;
      
      final teamProjections = TeamProjections(
        teamCode: teamCode,
        teamName: _teamNames[teamCode] ?? teamCode,
        players: calculatedPlayers,
        passOffenseTier: firstPlayer.passOffenseTier,
        qbTier: firstPlayer.qbTier,
        runOffenseTier: firstPlayer.runOffenseTier,
        passFreqTier: firstPlayer.passFreqTier,
        lastModified: DateTime.now(),
      );

      teamProjectionsMap[teamCode] = teamProjections;
    }

    _cachedTeamProjections = teamProjectionsMap;
    return teamProjectionsMap;
  }

  // Calculate projections for a player
  Future<PlayerProjection> calculateProjections(PlayerProjection player) async {
    // Use baseline points from CSV as starting point
    final baselinePoints = player.projectedPoints > 0 ? player.projectedPoints : 100.0;
    
    // Calculate the adjustments based on tier changes from baseline
    final baselineTargetShare = player.targetShare;
    final baselineWrRank = player.wrRank;
    
    // Calculate projected stats using season-long scale
    final projectedReceptions = _calculateProjectedReceptions(
      targetShare: player.targetShare,
      passOffenseTier: player.passOffenseTier,
      qbTier: player.qbTier,
      passFreqTier: player.passFreqTier,
    );
    
    final projectedYards = _calculateProjectedYards(
      targetShare: player.targetShare,
      wrRank: player.wrRank,
      passOffenseTier: player.passOffenseTier,
      qbTier: player.qbTier,
      epaTier: player.epaTier,
    );
    
    final projectedTDs = _calculateProjectedTDs(
      targetShare: player.targetShare,
      wrRank: player.wrRank,
      passOffenseTier: player.passOffenseTier,
      qbTier: player.qbTier,
    );
    
    final projectedPoints = _calculateProjectedPoints(
      receptions: projectedReceptions,
      yards: projectedYards,
      touchdowns: projectedTDs,
    );
    
    return player.copyWith(
      projectedReceptions: projectedReceptions,
      projectedYards: projectedYards,
      projectedTDs: projectedTDs,
      projectedPoints: projectedPoints,
    );
  }

  // Calculate projected receptions (season-long)
  double _calculateProjectedReceptions({
    required double targetShare,
    required int passOffenseTier,
    required int qbTier,
    required int passFreqTier,
  }) {
    // Base pass attempts per game adjusted for team context
    final basePassAttempts = _getBasePassAttempts(passFreqTier);
    const gamesPerSeason = 17.0; // NFL season length
    
    // Adjust for offense and QB quality
    final offenseMultiplier = _getOffenseMultiplier(passOffenseTier);
    final qbMultiplier = _getQbMultiplier(qbTier);
    
    // Calculate season targets
    final seasonTargets = targetShare * basePassAttempts * gamesPerSeason * offenseMultiplier * qbMultiplier;
    
    // Apply catch rate
    final catchRate = _getCatchRate(targetShare);
    
    return seasonTargets * catchRate;
  }

  // Calculate projected yards (season-long)
  double _calculateProjectedYards({
    required double targetShare,
    required int wrRank,
    required int passOffenseTier,
    required int qbTier,
    required int epaTier,
  }) {
    // Base yards per target by WR rank
    final baseYardsPerTarget = _getBaseYardsPerTarget(wrRank);
    
    // Base pass attempts per game (using tier 4 as default)
    final basePassAttempts = _getBasePassAttempts(4);
    const gamesPerSeason = 17.0;
    
    // Adjust for offense quality
    final offenseMultiplier = _getOffenseMultiplier(passOffenseTier);
    
    // Adjust for QB quality
    final qbMultiplier = _getQbMultiplier(qbTier);
    
    // Adjust for player efficiency
    final efficiencyMultiplier = _getEfficiencyMultiplier(epaTier);
    
    // Calculate season targets
    final seasonTargets = targetShare * basePassAttempts * gamesPerSeason * offenseMultiplier * qbMultiplier;
    
    return seasonTargets * baseYardsPerTarget * efficiencyMultiplier;
  }

  // Calculate projected TDs (season-long)
  double _calculateProjectedTDs({
    required double targetShare,
    required int wrRank,
    required int passOffenseTier,
    required int qbTier,
  }) {
    // Base TD rate by WR rank (per target)
    final baseTdRate = _getBaseTdRate(wrRank);
    
    // Base pass attempts per game
    final basePassAttempts = _getBasePassAttempts(4);
    const gamesPerSeason = 17.0;
    
    // Adjust for offense quality (better offenses get more red zone opportunities)
    final offenseMultiplier = _getOffenseMultiplier(passOffenseTier);
    
    // Adjust for QB quality
    final qbMultiplier = _getQbMultiplier(qbTier);
    
    // Calculate season targets
    final seasonTargets = targetShare * basePassAttempts * gamesPerSeason * offenseMultiplier * qbMultiplier;
    
    return seasonTargets * baseTdRate;
  }

  // Calculate projected fantasy points (PPR)
  double _calculateProjectedPoints({
    required double receptions,
    required double yards,
    required double touchdowns,
  }) {
    return receptions + (yards * 0.1) + (touchdowns * 6);
  }

  // Helper methods for multipliers based on R script logic
  double _getBasePassAttempts(int passFreqTier) {
    switch (passFreqTier) {
      case 1: return 42.0;
      case 2: return 38.0;
      case 3: return 35.0;
      case 4: return 32.0;
      case 5: return 29.0;
      case 6: return 26.0;
      case 7: return 23.0;
      case 8: return 20.0;
      default: return 32.0;
    }
  }

  double _getOffenseMultiplier(int offenseTier) {
    switch (offenseTier) {
      case 1: return 1.15;
      case 2: return 1.10;
      case 3: return 1.05;
      case 4: return 1.00;
      case 5: return 0.95;
      case 6: return 0.90;
      case 7: return 0.85;
      case 8: return 0.80;
      default: return 1.00;
    }
  }

  double _getQbMultiplier(int qbTier) {
    switch (qbTier) {
      case 1: return 1.12;
      case 2: return 1.08;
      case 3: return 1.04;
      case 4: return 1.00;
      case 5: return 0.96;
      case 6: return 0.92;
      case 7: return 0.88;
      case 8: return 0.84;
      default: return 1.00;
    }
  }

  double _getEfficiencyMultiplier(int epaTier) {
    switch (epaTier) {
      case 1: return 1.10;
      case 2: return 1.06;
      case 3: return 1.03;
      case 4: return 1.00;
      case 5: return 0.97;
      case 6: return 0.94;
      case 7: return 0.91;
      case 8: return 0.88;
      default: return 1.00;
    }
  }

  double _getCatchRate(double targetShare) {
    // Higher target share players tend to have slightly lower catch rates
    if (targetShare > 0.25) return 0.65;
    if (targetShare > 0.20) return 0.68;
    if (targetShare > 0.15) return 0.70;
    if (targetShare > 0.10) return 0.72;
    return 0.75;
  }

  double _getBaseYardsPerTarget(int wrRank) {
    switch (wrRank) {
      case 1: return 9.5;  // Elite WR1s
      case 2: return 8.8;  // High-end WR1s
      case 3: return 8.2;  // Mid-tier WR1s
      case 4: return 7.6;  // Low-end WR1s
      case 5: return 7.0;  // High-end WR2s
      case 6: return 6.4;  // Mid-tier WR2s
      default: return 5.8; // WR3s and below
    }
  }

  double _getBaseTdRate(int wrRank) {
    switch (wrRank) {
      case 1: return 0.095;  // Elite WR1s - ~9.5% of targets become TDs
      case 2: return 0.085;  // High-end WR1s
      case 3: return 0.075;  // Mid-tier WR1s
      case 4: return 0.065;  // Low-end WR1s
      case 5: return 0.055;  // High-end WR2s
      case 6: return 0.045;  // Mid-tier WR2s
      default: return 0.035; // WR3s and below
    }
  }

  // Update team projections with new player data
  Future<Map<String, TeamProjections>> updateTeamProjections(
    Map<String, TeamProjections> currentTeamProjections,
    String teamCode,
    PlayerProjection updatedPlayer,
  ) async {
    final updatedTeamProjections = Map<String, TeamProjections>.from(currentTeamProjections);
    
    if (updatedTeamProjections.containsKey(teamCode)) {
      updatedTeamProjections[teamCode] = updatedTeamProjections[teamCode]!
          .addOrUpdatePlayer(updatedPlayer);
    }

    return updatedTeamProjections;
  }

  // Create a new manual player entry
  PlayerProjection createManualPlayer({
    required String playerName,
    required String team,
    required String position,
    int wrRank = 1,
    double targetShare = 0.15,
    int playerYear = 2,
    int passOffenseTier = 4,
    int qbTier = 4,
    int runOffenseTier = 4,
    int epaTier = 4,
    int passFreqTier = 4,
  }) {
    final playerId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
    
    return PlayerProjection(
      playerId: playerId,
      playerName: playerName,
      position: position,
      team: team,
      wrRank: wrRank,
      targetShare: targetShare,
      projectedYards: 0,
      projectedTDs: 0,
      projectedReceptions: 0,
      projectedPoints: 0,
      playerYear: playerYear,
      passOffenseTier: passOffenseTier,
      qbTier: qbTier,
      runOffenseTier: runOffenseTier,
      epaTier: epaTier,
      passFreqTier: passFreqTier,
      isManualEntry: true,
      lastModified: DateTime.now(),
    );
  }

  // Clear cache to force reload
  void clearCache() {
    _cachedProjections = null;
    _cachedTeamProjections = null;
  }
} 