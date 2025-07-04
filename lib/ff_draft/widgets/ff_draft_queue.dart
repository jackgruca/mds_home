import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_player.dart';
import '../models/ff_position_constants.dart';
import '../providers/ff_draft_provider.dart';

class FFDraftQueue extends StatelessWidget {
  final Function(FFPlayer) onPlayerSelected;

  const FFDraftQueue({
    super.key,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        // TODO: Get queued players from provider
        final queuedPlayers = <FFPlayer>[];

        if (queuedPlayers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.queue_music,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No players in queue',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add players to your queue from the player list',
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
          itemCount: queuedPlayers.length,
          itemBuilder: (context, index) {
            final player = queuedPlayers[index];
            return _buildQueueItem(context, player, index);
          },
        );
      },
    );
  }

  Widget _buildQueueItem(BuildContext context, FFPlayer player, int index) {
    return Dismissible(
      key: Key(player.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        // TODO: Remove player from queue
      },
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
        subtitle: Text(
          '${player.team} - ${player.position}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${player.stats?['rank'] ?? 0}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: index > 0 ? () {
                // TODO: Move player up in queue
              } : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: () {
                // TODO: Move player down in queue
              },
            ),
          ],
        ),
        onTap: () => onPlayerSelected(player),
      ),
    );
  }

  Color _getPositionColor(String position) {
    return FFPositionConstants.getPositionColor(position);
  }
} 