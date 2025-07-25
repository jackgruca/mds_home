// Pre-computed 2024 stats for instant loading
class StaticPlayerStats2024 {
  static final Map<String, Map<String, dynamic>> _stats = {
    'Josh Allen': {
      'position': 'QB',
      'team': 'BUF',
      'passing_yards': 4306,
      'completions': 359,
      'attempts': 543,
      'passing_tds': 28,
    },
    'Patrick Mahomes': {
      'position': 'QB', 
      'team': 'KC',
      'passing_yards': 4183,
      'completions': 355,
      'attempts': 570,
      'passing_tds': 26,
    },
    'Lamar Jackson': {
      'position': 'QB',
      'team': 'BAL', 
      'passing_yards': 3678,
      'completions': 290,
      'attempts': 456,
      'passing_tds': 24,
    },
    'Christian McCaffrey': {
      'position': 'RB',
      'team': 'SF',
      'rush_att': 272,
      'rushing_yards': 1459,
      'rushing_tds': 14,
    },
    'Derrick Henry': {
      'position': 'RB',
      'team': 'BAL',
      'rush_att': 325,
      'rushing_yards': 1921,
      'rushing_tds': 16,
    },
    'Cooper Kupp': {
      'position': 'WR',
      'team': 'LAR',
      'targets': 123,
      'receptions': 91,
      'receiving_yards': 1147,
      'receiving_tds': 6,
    },
    'Tyreek Hill': {
      'position': 'WR', 
      'team': 'MIA',
      'targets': 171,
      'receptions': 80,
      'receiving_yards': 1799,
      'receiving_tds': 13,
    },
    'Travis Kelce': {
      'position': 'TE',
      'team': 'KC',
      'targets': 121,
      'receptions': 91,
      'receiving_yards': 823,
      'receiving_tds': 3,
    },
    // Add 200+ more players here from your data
  };
  
  static Map<String, dynamic>? getPlayerStats(String playerName) {
    return _stats[playerName];
  }
  
  static bool hasPlayer(String playerName) {
    return _stats.containsKey(playerName);
  }
  
  static List<String> getAllPlayerNames() {
    return _stats.keys.toList();
  }
}