// lib/utils/constants.dart

/// Contains app-wide constants
class AppConstants {
  // Draft simulation constants
  static const int defaultDraftSpeed = 1000; // milliseconds between picks
  static const double defaultRandomnessFactor = 0.5; // 0.0 = no randomness, 1.0 = max randomness
  static const int maxRounds = 7; // Maximum number of rounds for NFL draft
  
  // UI constants
  static const double teamLogoSize = 100.0;
  
  // Default image for missing team logos
  static const String defaultTeamLogoUrl = 
    "https://media.istockphoto.com/id/1409329028/vector/no-picture-available-placeholder-thumbnail-icon-illustration-design.jpg?s=612x612&w=0&k=20&c=_zOuJu755g2eEUioiOUdz_mHKJQJn-tDgIAhQzyeKUQ=";
  
  // API constants
  static const String espnTeamsApi = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams";
}

/// Collection of NFL teams
class NFLTeams {
  static const List<String> allTeams = [
    "Arizona Cardinals",
    "Atlanta Falcons",
    "Baltimore Ravens",
    "Buffalo Bills",
    "Carolina Panthers",
    "Chicago Bears",
    "Cincinnati Bengals",
    "Cleveland Browns",
    "Dallas Cowboys",
    "Denver Broncos",
    "Detroit Lions",
    "Green Bay Packers",
    "Houston Texans",
    "Indianapolis Colts",
    "Jacksonville Jaguars",
    "Kansas City Chiefs",
    "Las Vegas Raiders",
    "Los Angeles Chargers",
    "Los Angeles Rams",
    "Miami Dolphins",
    "Minnesota Vikings",
    "New England Patriots",
    "New Orleans Saints",
    "New York Giants",
    "New York Jets",
    "Philadelphia Eagles",
    "Pittsburgh Steelers",
    "San Francisco 49ers",
    "Seattle Seahawks",
    "Tampa Bay Buccaneers",
    "Tennessee Titans",
    "Washington Commanders"
  ];
}