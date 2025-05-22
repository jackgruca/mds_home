import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_player.dart';
import '../providers/ff_draft_provider.dart';

class FFRiskPlayers extends StatelessWidget {
  final Function(FFPlayer) onPlayerSelected;

  const FFRiskPlayers({
    super.key,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        // TODO: Get at-risk players from provider
        final atRiskPlayers = <FFPlayer>[];

        if (atRiskPlayers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning,
                  size: 48,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No players at risk',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Players will appear here when they are at risk of being drafted',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: atRiskPlayers.length,
          itemBuilder: (context, index) {
            final player = atRiskPlayers[index];
            return _buildRiskItem(context, player);
          },
        );
      },
    );
  }

  Widget _buildRiskItem(BuildContext context, FFPlayer player) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPositionColor(player.position),
          child: Text(
            player.position,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${player.team} - ${player.position}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'At Risk',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rank: #${player.stats?['rank'] ?? 0}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onPlayerSelected(player),
        ),
        onTap: () => onPlayerSelected(player),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.blue;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.orange;
      case 'TE':
        return Colors.purple;
      case 'K':
        return Colors.red;
      case 'DEF':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
} 