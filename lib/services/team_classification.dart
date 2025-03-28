// lib/services/team_classification.dart
import '../models/trade_motivation.dart';

/// Helper service to classify teams and identify rivalries
class TeamClassification {
  // NFL divisions for rivalry detection
  static const Map<String, Set<String>> _divisions = {
    'AFC East': {'BUF', 'MIA', 'NE', 'NYJ'},
    'AFC North': {'BAL', 'CIN', 'CLE', 'PIT'},
    'AFC South': {'HOU', 'IND', 'JAC', 'TEN'},
    'AFC West': {'DEN', 'KC', 'LV', 'LAC'},
    'NFC East': {'DAL', 'NYG', 'PHI', 'WAS'},
    'NFC North': {'CHI', 'DET', 'GB', 'MIN'},
    'NFC South': {'ATL', 'CAR', 'NO', 'TB'},
    'NFC West': {'ARI', 'LAR', 'SF', 'SEA'},
  };
  
  // Team building statuses based on draft position and roster state
  static const Map<String, TeamBuildStatus> _teamBuildStatus = {
    // AFC
    'BUF': TeamBuildStatus.winNow,      // Buffalo Bills - Contender
    'MIA': TeamBuildStatus.stable,      // Miami Dolphins - Competitive
    'NE': TeamBuildStatus.rebuilding,   // New England Patriots - Rebuilding
    'NYJ': TeamBuildStatus.stable,      // New York Jets - Building
    'BAL': TeamBuildStatus.winNow,      // Baltimore Ravens - Contender
    'CIN': TeamBuildStatus.winNow,      // Cincinnati Bengals - Contender
    'CLE': TeamBuildStatus.rebuilding,  // Cleveland Browns - Rebuilding
    'PIT': TeamBuildStatus.stable,      // Pittsburgh Steelers - Retooling
    'HOU': TeamBuildStatus.stable,      // Houston Texans - Building
    'IND': TeamBuildStatus.stable,      // Indianapolis Colts - Competitive
    'JAC': TeamBuildStatus.rebuilding,  // Jacksonville Jaguars - Rebuilding
    'TEN': TeamBuildStatus.rebuilding,  // Tennessee Titans - Rebuilding
    'DEN': TeamBuildStatus.rebuilding,  // Denver Broncos - Rebuilding
    'KC': TeamBuildStatus.winNow,       // Kansas City Chiefs - Contender
    'LV': TeamBuildStatus.rebuilding,   // Las Vegas Raiders - Rebuilding
    'LAC': TeamBuildStatus.stable,      // Los Angeles Chargers - Building
    
    // NFC
    'DAL': TeamBuildStatus.winNow,      // Dallas Cowboys - Win Now
    'NYG': TeamBuildStatus.rebuilding,  // New York Giants - Rebuilding
    'PHI': TeamBuildStatus.winNow,      // Philadelphia Eagles - Contender
    'WAS': TeamBuildStatus.stable,      // Washington Commanders - Building
    'CHI': TeamBuildStatus.stable,      // Chicago Bears - Building
    'DET': TeamBuildStatus.winNow,      // Detroit Lions - Contender
    'GB': TeamBuildStatus.stable,       // Green Bay Packers - Competitive
    'MIN': TeamBuildStatus.rebuilding,  // Minnesota Vikings - Rebuilding
    'ATL': TeamBuildStatus.stable,      // Atlanta Falcons - Building
    'CAR': TeamBuildStatus.rebuilding,  // Carolina Panthers - Rebuilding
    'NO': TeamBuildStatus.rebuilding,   // New Orleans Saints - Rebuilding
    'TB': TeamBuildStatus.stable,       // Tampa Bay Buccaneers - Retooling
    'ARI': TeamBuildStatus.rebuilding,  // Arizona Cardinals - Rebuilding
    'LAR': TeamBuildStatus.stable,      // Los Angeles Rams - Competitive
    'SF': TeamBuildStatus.winNow,       // San Francisco 49ers - Contender
    'SEA': TeamBuildStatus.stable,      // Seattle Seahawks - Retooling
  };
  
  /// Get a team's current building status
  static TeamBuildStatus getTeamStatus(String teamName) {
    // Clean team name to handle different formats
    String cleanName = cleanTeamName(teamName);
    return _teamBuildStatus[cleanName] ?? TeamBuildStatus.stable;
  }
  
  /// Check if two teams are division rivals
  static bool areDivisionRivals(String team1, String team2) {
    String clean1 = cleanTeamName(team1);
    String clean2 = cleanTeamName(team2);
    
    // Check if both teams are in the same division
    for (var division in _divisions.values) {
      if (division.contains(clean1) && division.contains(clean2)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get all division rivals for a team
  static List<String> getDivisionRivals(String teamName) {
    String cleanName = cleanTeamName(teamName);
    
    // Find team's division
    for (var entry in _divisions.entries) {
      if (entry.value.contains(cleanName)) {
        return entry.value.where((team) => team != cleanName).toList();
      }
    }
    
    return [];
  }
  
  /// Classify teams by their draft position
  static TeamBuildStatus classifyByDraftPosition(int pickNumber, {bool firstRoundOnly = true}) {
    if (!firstRoundOnly || pickNumber <= 32) {
      if (pickNumber <= 10) {
        return TeamBuildStatus.rebuilding; // Top 10 picks usually rebuilding
      } else if (pickNumber <= 24) {
        return TeamBuildStatus.stable; // Middle picks often retooling
      } else {
        return TeamBuildStatus.winNow; // Late first were playoff teams
      }
    }
    
    // For non-first round, return unknown
    return TeamBuildStatus.stable;
  }
  
  /// Clean team name to standardized abbreviation
  static String cleanTeamName(String name) {
    // Handle full team names
    Map<String, String> fullNameMap = {
      'Buffalo': 'BUF',
      'Miami': 'MIA',
      'New England': 'NE',
      'NY Jets': 'NYJ',
      'New York Jets': 'NYJ',
      'Baltimore': 'BAL',
      'Cincinnati': 'CIN',
      'Cleveland': 'CLE',
      'Pittsburgh': 'PIT',
      'Houston': 'HOU',
      'Indianapolis': 'IND',
      'Jacksonville': 'JAC',
      'Tennessee': 'TEN',
      'Denver': 'DEN',
      'Kansas City': 'KC',
      'Las Vegas': 'LV',
      'LA Chargers': 'LAC',
      'Los Angeles Chargers': 'LAC',
      'Dallas': 'DAL',
      'NY Giants': 'NYG',
      'New York Giants': 'NYG',
      'Philadelphia': 'PHI',
      'Washington': 'WAS',
      'Chicago': 'CHI',
      'Detroit': 'DET',
      'Green Bay': 'GB',
      'Minnesota': 'MIN',
      'Atlanta': 'ATL',
      'Carolina': 'CAR',
      'New Orleans': 'NO',
      'Tampa Bay': 'TB',
      'Arizona': 'ARI',
      'LA Rams': 'LAR',
      'Los Angeles Rams': 'LAR',
      'San Francisco': 'SF',
      'Seattle': 'SEA',
    };
    
    // Try to match full name first
    for (var entry in fullNameMap.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // If already abbreviated, return as is
    if (name.length <= 3) {
      return name.toUpperCase();
    }
    
    return name;
  }
}