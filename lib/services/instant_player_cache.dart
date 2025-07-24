// lib/services/instant_player_cache.dart
import '../models/nfl_player.dart';

class InstantPlayerCache {
  static final Map<String, NFLPlayer> _basicPlayerCache = {};
  static final Map<String, String> _playerHeadshots = {
    // Pre-populated headshots for top players
    'Josh Allen': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/lq4ezafbszwwt2qsvhqv',
    'Patrick Mahomes': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/ysrpqmta8jmnlnfgxrp9',
    'Lamar Jackson': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/wywpvn4fxqmyha4xhjem',
    'Justin Jefferson': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/n5jw2q6tqgdilzj4jcqu',
    'Tyreek Hill': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/ejnxjhrkh5oxl2cuwz9q',
    'Christian McCaffrey': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/b6qmz0z4p3eznqxnwq6z',
    'Derrick Henry': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/wvmpubtpxxzq5hjkk1fy',
    'Travis Kelce': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/h6vgbbcsfpezblgrwh1p',
    'Davante Adams': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/xokzryfunfzw7qcnzm3r',
    'Stefon Diggs': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/gqxsqwmg1vvhgadfkmup',
    // Additional top players
    'Cooper Kupp': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/frmfbpxzdqjg8tlexjj4',
    'Aaron Donald': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/oiz8c3lzezazhfhqycsf',
    'T.J. Watt': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/qfofnafvpxqoelh6pxay',
    'Myles Garrett': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/cj3juvsjhznuuswyh0xf',
    'CeeDee Lamb': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/k6lbqfr8qkrlhdpzxlfs',
    'Ja\'Marr Chase': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/hdsrqtpifxsj5kjkv9xx',
    'Joe Burrow': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/okaxo8z1p35x8c1gd7tr',
    'Dak Prescott': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/ycxfnb0xkojhtpxcm2jh',
    'Russell Wilson': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/otvr1zirffb2lbg3aokm',
    'Aaron Rodgers': 'https://static.www.nfl.com/image/upload/f_auto,q_auto/league/l2sxvs7qbdocyv9iqqvj',
  };
  
  static final Map<String, Map<String, dynamic>> _basicPlayerData = {
    // Pre-populated basic data for instant display
    'Josh Allen': {
      'position': 'QB',
      'team': 'BUF',
      'height': 77.0,
      'weight': 237.0,
      'age': 28,
      'college': 'Wyoming',
      'years_exp': 6,
    },
    'Patrick Mahomes': {
      'position': 'QB', 
      'team': 'KC',
      'height': 75.0,
      'weight': 230.0,
      'age': 28,
      'college': 'Texas Tech',
      'years_exp': 7,
    },
    'Lamar Jackson': {
      'position': 'QB',
      'team': 'BAL', 
      'height': 74.0,
      'weight': 212.0,
      'age': 27,
      'college': 'Louisville',
      'years_exp': 6,
    },
    'Justin Jefferson': {
      'position': 'WR',
      'team': 'MIN',
      'height': 73.0,
      'weight': 202.0,
      'age': 25,
      'college': 'LSU',
      'years_exp': 4,
    },
    'Tyreek Hill': {
      'position': 'WR',
      'team': 'MIA',
      'height': 70.0,
      'weight': 185.0,
      'age': 30,
      'college': 'West Alabama',
      'years_exp': 8,
    },
    'Christian McCaffrey': {
      'position': 'RB',
      'team': 'SF',
      'height': 71.0,
      'weight': 205.0,
      'age': 28,
      'college': 'Stanford',
      'years_exp': 7,
    },
    'Cooper Kupp': {
      'position': 'WR',
      'team': 'LAR',
      'height': 74.0,
      'weight': 208.0,
      'age': 31,
      'college': 'Eastern Washington',
      'years_exp': 7,
    },
    'Aaron Donald': {
      'position': 'DT',
      'team': 'LAR',
      'height': 73.0,
      'weight': 280.0,
      'age': 33,
      'college': 'Pittsburgh',
      'years_exp': 10,
    },
    'T.J. Watt': {
      'position': 'LB',
      'team': 'PIT',
      'height': 73.0,
      'weight': 252.0,
      'age': 29,
      'college': 'Wisconsin',
      'years_exp': 7,
    },
    'CeeDee Lamb': {
      'position': 'WR',
      'team': 'DAL',
      'height': 74.0,
      'weight': 198.0,
      'age': 25,
      'college': 'Oklahoma',
      'years_exp': 4,
    },
    'Ja\'Marr Chase': {
      'position': 'WR',
      'team': 'CIN',
      'height': 72.0,
      'weight': 201.0,
      'age': 24,
      'college': 'LSU',
      'years_exp': 3,
    },
    'Joe Burrow': {
      'position': 'QB',
      'team': 'CIN',
      'height': 76.0,
      'weight': 221.0,
      'age': 27,
      'college': 'LSU',
      'years_exp': 4,
    },
    'Dak Prescott': {
      'position': 'QB',
      'team': 'DAL',
      'height': 74.0,
      'weight': 229.0,
      'age': 31,
      'college': 'Mississippi State',
      'years_exp': 8,
    },
    'Russell Wilson': {
      'position': 'QB',
      'team': 'DEN',
      'height': 71.0,
      'weight': 215.0,
      'age': 35,
      'college': 'Wisconsin',
      'years_exp': 12,
    },
    'Aaron Rodgers': {
      'position': 'QB',
      'team': 'NYJ',
      'height': 74.0,
      'weight': 225.0,
      'age': 40,
      'college': 'California',
      'years_exp': 19,
    },
  };

  /// Get instant player preview (no API calls)
  static NFLPlayer? getInstantPlayer(String playerName) {
    if (_basicPlayerCache.containsKey(playerName)) {
      return _basicPlayerCache[playerName];
    }
    
    final basicData = _basicPlayerData[playerName];
    if (basicData != null) {
      final player = NFLPlayer(
        playerName: playerName,
        position: basicData['position'],
        team: basicData['team'],
        height: basicData['height'],
        weight: basicData['weight'],
        age: basicData['age']?.toInt(),
        college: basicData['college'],
        yearsExp: basicData['years_exp']?.toInt(),
        headshotUrl: _playerHeadshots[playerName],
      );
      
      _basicPlayerCache[playerName] = player;
      return player;
    }
    
    return null;
  }
  
  /// Preload common players for instant access
  static void preloadCommonPlayers() {
    for (final playerName in _basicPlayerData.keys) {
      getInstantPlayer(playerName);
    }
  }
  
  /// Add player to cache after API fetch
  static void cachePlayer(String playerName, NFLPlayer player) {
    _basicPlayerCache[playerName] = player;
  }
  
  /// Get headshot instantly if cached
  static String? getInstantHeadshot(String playerName) {
    return _playerHeadshots[playerName];
  }
  
  /// Add more headshots dynamically
  static void cacheHeadshot(String playerName, String url) {
    _playerHeadshots[playerName] = url;
  }
  
  /// Check if we have instant data for a player
  static bool hasInstantData(String playerName) {
    return _basicPlayerData.containsKey(playerName) || _basicPlayerCache.containsKey(playerName);
  }
}