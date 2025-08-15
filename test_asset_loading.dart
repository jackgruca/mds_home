import 'package:flutter/services.dart';

void main() async {
  try {
    print('Testing asset loading...');
    
    // Test FF_ranks.csv
    try {
      final data1 = await rootBundle.loadString('data/processed/draft_sim/2025/FF_ranks.csv');
      print('✅ FF_ranks.csv loaded successfully, length: ${data1.length}');
    } catch (e) {
      print('❌ FF_ranks.csv failed to load: $e');
    }
    
    // Test available_players.csv
    try {
      final data2 = await rootBundle.loadString('data/processed/draft_sim/2026/available_players.csv');
      print('✅ available_players.csv loaded successfully, length: ${data2.length}');
    } catch (e) {
      print('❌ available_players.csv failed to load: $e');
    }
    
    // Test existing working file
    try {
      final data3 = await rootBundle.loadString('data/processed/team_data/current_players_combined.csv');
      print('✅ current_players_combined.csv loaded successfully, length: ${data3.length}');
    } catch (e) {
      print('❌ current_players_combined.csv failed to load: $e');
    }
    
  } catch (e) {
    print('Error in test: $e');
  }
}