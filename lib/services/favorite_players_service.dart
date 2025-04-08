// lib/services/favorite_players_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritePlayersService {
  static Set<int> _favoritePlayerIds = {};
  static bool _initialized = false;

  // Initialize from SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFavorites = prefs.getString('favorite_players');
      if (savedFavorites != null) {
        final List<dynamic> decoded = jsonDecode(savedFavorites);
        _favoritePlayerIds = decoded.map<int>((id) => id as int).toSet();
      }
      _initialized = true;
    } catch (e) {
      print('Failed to load favorites: $e');
      _favoritePlayerIds = {};
      _initialized = true;
    }
  }

  // Save to SharedPreferences
  static Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = jsonEncode(_favoritePlayerIds.toList());
      await prefs.setString('favorite_players', jsonList);
    } catch (e) {
      print('Failed to save favorites: $e');
    }
  }

  // Check if a player is favorited
  static bool isFavorite(int playerId) {
    return _favoritePlayerIds.contains(playerId);
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(int playerId) async {
    if (_favoritePlayerIds.contains(playerId)) {
      _favoritePlayerIds.remove(playerId);
    } else {
      _favoritePlayerIds.add(playerId);
    }
    await _saveFavorites();
    return isFavorite(playerId);
  }

  // Get all favorite player IDs
  static Set<int> get favorites => Set.from(_favoritePlayerIds);
  
  // Get count of favorites
  static int get count => _favoritePlayerIds.length;
}
