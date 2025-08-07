import 'package:flutter/services.dart';
import 'lib/services/rankings/csv_rankings_service.dart';

void main() async {
  print('Debugging QB CSV loading...');
  
  final csvService = CSVRankingsService();
  
  try {
    final allRankings = await csvService.fetchQBRankings();
    print('✅ QB Rankings loaded: ${allRankings.length} players');
    
    if (allRankings.isNotEmpty) {
      final firstPlayer = allRankings.first;
      print('First player data:');
      print('  fantasy_player_name: ${firstPlayer['fantasy_player_name']} (${firstPlayer['fantasy_player_name'].runtimeType})');
      print('  season: ${firstPlayer['season']} (${firstPlayer['season'].runtimeType})');
      print('  tier: ${firstPlayer['tier']} (${firstPlayer['tier'].runtimeType})');
      print('  posteam: ${firstPlayer['posteam']} (${firstPlayer['posteam'].runtimeType})');
      
      // Test filtering
      String selectedSeason = '2024';
      String selectedTier = 'All';
      
      print('\nTesting filter logic:');
      print('selectedSeason = "$selectedSeason"');
      print('selectedTier = "$selectedTier"');
      
      final filteredRankings = allRankings.where((ranking) {
        bool matchesSeason = selectedSeason == 'All' || 
                            ranking['season']?.toString() == selectedSeason;
        bool matchesTier = selectedTier == 'All' || 
                          (ranking['tier']?.toString() == selectedTier);
        print('Player ${ranking['fantasy_player_name']}: season match = $matchesSeason, tier match = $matchesTier');
        return matchesSeason && matchesTier;
      }).toList();
      
      print('\n✅ After filtering: ${filteredRankings.length} players');
    }
    
  } catch (e) {
    print('❌ Error loading QB rankings: $e');
  }
}