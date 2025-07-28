import 'package:flutter/material.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';

class SimpleDataHubScreen extends StatefulWidget {
  const SimpleDataHubScreen({super.key});

  @override
  State<SimpleDataHubScreen> createState() => _SimpleDataHubScreenState();
}

class _SimpleDataHubScreenState extends State<SimpleDataHubScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('NFL Data Hub'),
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
                  // Header
                  _buildHeader(isDarkMode),
                  
                  const SizedBox(height: 32),
                  
                  // Main navigation cards
                  _buildNavigationCards(isDarkMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFL Data Hub',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your data level and statistical focus',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCards(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Player Season Stats Card
        _buildDataCard(
          title: 'Player Season Stats',
          description: 'Season-level statistics by position',
          icon: Icons.person,
          color: Colors.blue,
          isDarkMode: isDarkMode,
          options: [
            {'label': 'Passing (QB)', 'route': '/data/passing'},
            {'label': 'Rushing (RB)', 'route': '/data/rushing'},
            {'label': 'Receiving (WR/TE)', 'route': '/data/receiving'},
            {'label': 'All Positions', 'route': '/player-season-stats'},
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Player Game Stats Card
        _buildDataCard(
          title: 'Player Game Stats',
          description: 'Game-by-game player performance',
          icon: Icons.sports_football,
          color: Colors.green,
          isDarkMode: isDarkMode,
          options: [
            {'label': '🏈 QB Game Stats', 'route': '/player-game-stats'},
            {'label': '💪 RB Game Stats', 'route': '/player-game-stats'},
            {'label': '🏃 WR Game Stats', 'route': '/player-game-stats'},
            {'label': '🤾 TE Game Stats', 'route': '/player-game-stats'},
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Game Stats Card
        _buildDataCard(
          title: 'Game Stats',
          description: 'Game-level data and context',
          icon: Icons.scoreboard,
          color: Colors.orange,
          isDarkMode: isDarkMode,
          options: [
            {'label': 'Game Results', 'route': '/games'},
            {'label': 'Historical Games', 'route': '/historical-game-data'},
            {'label': 'Betting & Weather', 'route': '/games/betting'},
          ],
        ),
      ],
    );
  }

  Widget _buildDataCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required List<Map<String, String>> options,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Options buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) => InkWell(
              onTap: () => Navigator.pushNamed(context, option['route']!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}