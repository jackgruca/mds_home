// lib/utils/constants.dart

/// Contains app-wide constants
class AppConstants {
  // Draft simulation constants
  static const int defaultDraftSpeed = 700; // milliseconds between picks
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

// In lib/utils/constants.dart, add this map after your NFLTeams class
class NFLTeamMappings {
  static const Map<String, String> fullNameToAbbreviation = {
    "Arizona Cardinals": "ARI",
    "Atlanta Falcons": "ATL",
    "Baltimore Ravens": "BAL",
    "Buffalo Bills": "BUF",
    "Carolina Panthers": "CAR",
    "Chicago Bears": "CHI",
    "Cincinnati Bengals": "CIN",
    "Cleveland Browns": "CLE",
    "Dallas Cowboys": "DAL",
    "Denver Broncos": "DEN",
    "Detroit Lions": "DET",
    "Green Bay Packers": "GB",
    "Houston Texans": "HOU",
    "Indianapolis Colts": "IND",
    "Jacksonville Jaguars": "JAX",
    "Kansas City Chiefs": "KC",
    "Las Vegas Raiders": "LV",
    "Los Angeles Chargers": "LAC",
    "Los Angeles Rams": "LAR",
    "Miami Dolphins": "MIA",
    "Minnesota Vikings": "MIN",
    "New England Patriots": "NE",
    "New Orleans Saints": "NO",
    "New York Giants": "NYG",
    "New York Jets": "NYJ",
    "Philadelphia Eagles": "PHI",
    "Pittsburgh Steelers": "PIT",
    "San Francisco 49ers": "SF",
    "Seattle Seahawks": "SEA",
    "Tampa Bay Buccaneers": "TB",
    "Tennessee Titans": "TEN",
    "Washington Commanders": "WAS"
  };
}

// Add this class to your lib/utils/constants.dart file

class CollegeTeamMappings {
  static const Map<String, String> fullNameToAbbreviation = {
     "Alabama": "333",
    "Alabama Crimson Tide": "333",
    "Arkansas": "8",
    "Arkansas Razorbacks": "8",
    "Auburn": "2",
    "Auburn Tigers": "2",
    "Florida": "57",
    "Florida Gators": "57",
    "Georgia": "61",
    "Georgia Bulldogs": "61",
    "Kentucky": "96",
    "Kentucky Wildcats": "96",
    "LSU": "99",
    "LSU Tigers": "99",
    "Ole Miss": "145",
    "Mississippi": "145",
    "Ole Miss Rebels": "145",
    "Mississippi State": "344",
    "Mississippi State Bulldogs": "344",
    "Missouri": "142",
    "Missouri Tigers": "142",
    "South Carolina": "2579",
    "South Carolina Gamecocks": "2579",
    "Tennessee": "2633",
    "Tennessee Volunteers": "2633",
    "Texas": "251",
    "Texas Longhorns": "251",
    "Texas A&M": "245",
    "Texas A&M Aggies": "245",
    "Vanderbilt": "238",
    "Vanderbilt Commodores": "238",
    "Oklahoma": "201",
    "Oklahoma Sooners": "201",
    "Illinois": "356",
    "Illinois Fighting Illini": "356",
    "Indiana": "84",
    "Indiana Hoosiers": "84",
    "Iowa": "2294",
    "Iowa Hawkeyes": "2294",
    "Maryland": "120",
    "Maryland Terrapins": "120",
    "Michigan": "130",
    "Michigan Wolverines": "130",
    "Michigan State": "127",
    "Michigan State Spartans": "127",
    "Minnesota": "135",
    "Minnesota Golden Gophers": "135",
    "Nebraska": "158",
    "Nebraska Cornhuskers": "158",
    "Northwestern": "77",
    "Northwestern Wildcats": "77",
    "Ohio State": "194",
    "Ohio State Buckeyes": "194",
    "Penn State": "213",
    "Penn State Nittany Lions": "213",
    "Purdue": "2509",
    "Purdue Boilermakers": "2509",
    "Rutgers": "164",
    "Rutgers Scarlet Knights": "164",
    "Wisconsin": "275",
    "Wisconsin Badgers": "275",
    "Boston College": "103",
    "Boston College Eagles": "103",
    "Clemson": "228",
    "Clemson Tigers": "228",
    "Duke": "150",
    "Duke Blue Devils": "150",
    "Florida State": "52",
    "Florida State Seminoles": "52",
    "Georgia Tech": "59",
    "Georgia Tech Yellow Jackets": "59",
    "Louisville": "97",
    "Louisville Cardinals": "97",
    "Miami": "2390",
    "Miami Hurricanes": "2390",
    "North Carolina": "153",
    "North Carolina Tar Heels": "153",
    "NC State": "152",
    "North Carolina State": "152",
    "NC State Wolfpack": "152",
    "North Carolina State Wolfpack": "152",
    "Pittsburgh": "221",
    "Pittsburgh Panthers": "221",
    "Syracuse": "183",
    "Syracuse Orange": "183",
    "Virginia": "258",
    "Virginia Cavaliers": "258",
    "Virginia Tech": "259",
    "Virginia Tech Hokies": "259",
    "Wake Forest": "154",
    "Wake Forest Demon Deacons": "154",
    "Baylor": "239",
    "Baylor Bears": "239",
    "Iowa State": "66",
    "Iowa State Cyclones": "66",
    "Kansas": "2305",
    "Kansas Jayhawks": "2305",
    "Kansas State": "2306",
    "Kansas State Wildcats": "2306",
    "Oklahoma State": "197",
    "Oklahoma State Cowboys": "197",
    "TCU": "2628",
    "TCU Horned Frogs": "2628",
    "Texas Tech": "2641",
    "Texas Tech Red Raiders": "2641",
    "West Virginia": "277",
    "West Virginia Mountaineers": "277",
    "BYU": "252",
    "BYU Cougars": "252",
    "UCF": "2116",
    "UCF Knights": "2116",
    "Cincinnati": "2132",
    "Cincinnati Bearcats": "2132",
    "Houston": "248",
    "Houston Cougars": "248",
    "Arizona": "12",
    "Arizona Wildcats": "12",
    "Arizona State": "9",
    "Arizona State Sun Devils": "9",
    "California": "25",
    "Cal": "25",
    "California Golden Bears": "25",
    "Colorado": "38",
    "Colorado Buffaloes": "38",
    "Oregon": "2483",
    "Oregon Ducks": "2483",
    "Oregon State": "204",
    "Oregon State Beavers": "204",
    "Stanford": "24",
    "Stanford Cardinal": "24",
    "UCLA": "26",
    "UCLA Bruins": "26",
    "USC": "30",
    "USC Trojans": "30",
    "Utah": "254",
    "Utah Utes": "254",
    "Washington": "264",
    "Washington Huskies": "264",
    "Washington State": "265",
    "Washington State Cougars": "265",
  };

  // Attempt to guess abbreviation from school name
  static String? guessAbbreviation(String schoolName) {
    // Try to match the full name first
    if (fullNameToAbbreviation.containsKey(schoolName)) {
      return fullNameToAbbreviation[schoolName];
    }
    
    // Try to match parts of the name
    for (var entry in fullNameToAbbreviation.entries) {
      if (schoolName.contains(entry.key) || entry.key.contains(schoolName)) {
        return entry.value;
      }
    }
    
    // If no match found but name is short (likely an abbreviation)
    if (schoolName.length <= 5) {
      return schoolName.toUpperCase();
    }
    
    // Last resort: create abbreviation from first letters of words
    final words = schoolName.split(' ');
    if (words.length > 1) {
      return words.map((word) => word.isNotEmpty ? word[0] : '').join('').toUpperCase();
    }
    
    // Can't determine abbreviation
    return null;
  }
}