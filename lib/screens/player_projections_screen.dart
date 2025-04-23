// lib/screens/player_projections_screen.dart
import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import '../utils/theme_config.dart';

class PlayerProjectionsScreen extends StatelessWidget {
  const PlayerProjectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Projections'),
      ),
        drawer: const AppDrawer(currentRoute: '/player-projections'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 24),
            const Text(
              'Player Projections',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 20,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'We\'re working on detailed player projections for the upcoming NFL season.\nCheck back soon for stats, fantasy insights, and more!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}