import 'package:flutter/services.dart';
import 'lib/services/rankings/csv_rankings_service.dart';

void main() async {
  print('Testing CSV Rankings Service...');
  
  final csvService = CSVRankingsService();
  
  try {
    print('Testing QB Rankings...');
    final qbRankings = await csvService.fetchQBRankings();
    print('✅ QB Rankings loaded: ${qbRankings.length} players');
    if (qbRankings.isNotEmpty) {
      print('First QB: ${qbRankings.first['fantasy_player_name']}');
    }
    
    print('\nTesting RB Rankings...');
    final rbRankings = await csvService.fetchRBRankings();
    print('✅ RB Rankings loaded: ${rbRankings.length} players');
    if (rbRankings.isNotEmpty) {
      print('First RB: ${rbRankings.first['fantasy_player_name']}');
    }
    
  } catch (e) {
    print('❌ Error loading rankings: $e');
  }
}