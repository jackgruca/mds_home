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
class CollegeTeamESPNIds {
  // This map contains known ESPN numeric IDs for college teams
  static const Map<String, String> schoolToEspnId = {
    // Big Ten
    "Penn State": "213",
    "Ohio State": "194",
    "Michigan": "130",
    "Michigan State": "127",
    "Iowa": "2294",
    "Wisconsin": "275",
    "Minnesota": "135",
    "Northwestern": "77",
    "Purdue": "2509",
    "Indiana": "84",
    "Nebraska": "158",
    "Illinois": "356",
    "Rutgers": "164",
    "Maryland": "120",
    
    // SEC
    "Alabama": "333",
    "Georgia": "61",
    "LSU": "99",
    "Florida": "57",
    "Auburn": "2",
    "Texas A&M": "245",
    "Tennessee": "2633",
    "Kentucky": "96",
    "South Carolina": "2579",
    "Ole Miss": "145",
    "Mississippi": "145",
    "Mississippi State": "344",
    "Missouri": "142",
    "Arkansas": "8",
    "Vanderbilt": "238",
    
    // ACC
    "Clemson": "228",
    "Florida State": "52",
    "Miami": "2390",
    "North Carolina": "153",
    "NC State": "152",
    "Virginia Tech": "259",
    "Pittsburgh": "221",
    "Syracuse": "183",
    "Duke": "150",
    "Boston College": "103",
    "Virginia": "258",
    "Wake Forest": "154",
    "Louisville": "97",
    "Georgia Tech": "59",
    
    // Pac-12
    "USC": "30",
    "UCLA": "26",
    "Oregon": "2483",
    "Washington": "264",
    "Utah": "254",
    "Arizona State": "9",
    "Arizona": "12",
    "Colorado": "38",
    "California": "25",
    "Washington State": "265",
    "Oregon State": "204",
    "Stanford": "24",
    
    // Big 12
    "Oklahoma": "201",
    "Texas": "251",
    "Baylor": "239",
    "Iowa State": "66",
    "Oklahoma State": "197",
    "TCU": "2628",
    "Kansas State": "2306",
    "West Virginia": "277",
    "Texas Tech": "2641",
    "Kansas": "2305",
    
    // Notable Independent and Group of 5
    "Notre Dame": "87",
    "BYU": "252",
    "Cincinnati": "2132",
    "Houston": "248",
    "UCF": "2116",
    "Boise State": "68",
    "Memphis": "235",
    "Appalachian State": "2026",
    "Coastal Carolina": "324",
    "Liberty": "2335",
    "Army": "349",
    "Navy": "2426",
    "Air Force": "2005",
    "Air Force Falcons": "8",
    "Appalachian State Mountaineers": "2026",
    "Arkansas State": "2032",
    "Arkansas State Red Wolves": "2032",
    "Army Black Knights": "349",
    "Boise State Broncos": "68",
    "Buffalo": "2084",
    "Buffalo Bulls": "2084",
    "Charlotte": "2429",
    "Charlotte 49ers": "2429",
    "Coastal Carolina Chanticleers": "324",
    "East Carolina": "151",
    "East Carolina Pirates": "151",
    "Florida Atlantic": "2226",
    "Florida Atlantic Owls": "2226",
    "Florida International": "2229",
    "FIU": "2229",
    "FIU Panthers": "2229",
    "Fresno State": "278",
    "Fresno State Bulldogs": "278",
    "Georgia Southern": "290",
    "Georgia Southern Eagles": "290",
    "Georgia State": "2247",
    "Georgia State Panthers": "2247",
    "Hawaii": "62",
    "Hawaii Rainbow Warriors": "62",
    "Liberty Flames": "2335",
    "Louisiana": "309",
    "Louisiana Ragin' Cajuns": "309",
    "Louisiana-Monroe": "2433",
    "ULM": "2433",
    "ULM Warhawks": "2433",
    "Marshall": "276",
    "Marshall Thundering Herd": "276",
    "Memphis Tigers": "235",
    "Middle Tennessee": "2393",
    "Middle Tennessee Blue Raiders": "2393",
    "Navy Midshipmen": "2426",
    "Nevada": "2440",
    "Nevada Wolf Pack": "2440",
    "New Mexico": "167",
    "New Mexico Lobos": "167",
    "New Mexico State": "166",
    "New Mexico State Aggies": "166",
    "North Texas": "249",
    "North Texas Mean Green": "249",
    "Northern Illinois": "2459",
    "Northern Illinois Huskies": "2459",
    "Ohio": "195",
    "Ohio Bobcats": "195",
    "Old Dominion": "295",
    "Old Dominion Monarchs": "295",
    "Rice": "242",
    "Rice Owls": "242",
    "San Diego State": "21",
    "San Diego State Aztecs": "21",
    "San Jose State": "23",
    "San Jose State Spartans": "23",
    "South Alabama": "6",
    "South Alabama Jaguars": "6",
    "South Florida": "58",
    "USF": "58",
    "USF Bulls": "58",
    "Southern Miss": "2572",
    "Southern Miss Golden Eagles": "2572",
    "Temple": "218",
    "Temple Owls": "218",
    "Texas State": "326",
    "Texas State Bobcats": "326",
    "Troy": "2653",
    "Troy Trojans": "2653",
    "Tulane": "2655",
    "Tulane Green Wave": "2655",
    "Tulsa": "202",
    "Tulsa Golden Hurricane": "202",
    "UAB": "5",
    "UAB Blazers": "5",
    "UMass": "113",
    "UMass Minutemen": "113",
    "UNLV": "2439",
    "UNLV Rebels": "2439",
    "UTEP": "2638",
    "UTEP Miners": "2638",
    "Western Kentucky": "98",
    "Western Kentucky Hilltoppers": "98",
    "Wyoming": "2751",
    "Wyoming Cowboys": "2751",
    "North Dakota State": "2449",
    "North Dakota State Bison": "2449",
    "Toledo": "2649",
    "Toledo Rockets": "2649",
    "Bowling Green": "189",
    "Bowling Green Falcons": "189",
    "SMU": "2567",
    "SMU Mustangs": "2567",
    "UConn": "41",
    "UConn Huskies": "41",
    "Connecticut": "41",
    "Connecticut Huskies": "41",
    "Villanova": "222",
    "Villanova Wildcats": "222",
  };
  
  // Helper method to find best match for a school name
  static String? findIdForSchool(String schoolName) {
    // Check for direct match first
    if (schoolToEspnId.containsKey(schoolName)) {
      return schoolToEspnId[schoolName];
    }
    
    // Try case-insensitive matching
    String normalizedName = schoolName.toLowerCase();
    
    // Check for partial matches
    for (var entry in schoolToEspnId.entries) {
      String keyLower = entry.key.toLowerCase();
      
      // Check if either contains the other
      if (normalizedName.contains(keyLower) || keyLower.contains(normalizedName)) {
        return entry.value;
      }
    }
    
    // No match found
    return null;
  }
}