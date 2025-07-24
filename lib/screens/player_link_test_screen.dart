// Test screen for validating player link functionality
import 'package:flutter/material.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../widgets/player/player_link_widget.dart';

class PlayerLinkTestScreen extends StatelessWidget {
  const PlayerLinkTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final testPlayers = [
      'Patrick Mahomes',
      'Josh Allen',
      'Lamar Jackson',
      'Justin Jefferson',
      'Tyreek Hill',
      'Christian McCaffrey',
      'Derrick Henry',
      'Travis Kelce',
      'Davante Adams',
      'Stefon Diggs',
    ];

    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('Player Link Test'),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Player Link Test Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Click on any player name below\n'
                          '2. Check browser console (F12) for debug logs\n'
                          '3. A modal should appear with player info\n'
                          '4. Click "View Full Profile" to test navigation',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Test Player Links',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: testPlayers.map((playerName) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                PlayerLinkWidget(
                                  playerName: playerName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Console Output',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🔍 NFLPlayerService.getPlayerByName called for: "Patrick Mahomes"\n'
                            '📤 Calling getPlayerStats with params: {searchQuery: "Patrick Mahomes", limit: 1}\n'
                            '📥 getPlayerStats response: {data: [...]}\n'
                            '📊 Player result keys: [data, message]\n'
                            '📋 Player data length: 1\n'
                            '👤 Found player data keys: [player_display_name, position, ...]\n'
                            '✅ Successfully created NFLPlayer object for: Patrick Mahomes',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}