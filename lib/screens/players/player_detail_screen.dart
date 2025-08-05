import 'package:flutter/material.dart';
import '../../models/player_info.dart';

class PlayerDetailScreen extends StatelessWidget {
  final PlayerInfo player;

  const PlayerDetailScreen({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.displayNameOrFullName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  // Position Badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getPositionColor(player.positionGroup),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.position,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (player.jerseyNumber != null)
                          Text(
                            '#${player.jerseyNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Player Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.displayNameOrFullName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.team} • ${player.position}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (player.college != null)
                          Text(
                            player.college!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Physical Info
            if (player.height != null || player.weight != null || player.yearsExp != null)
              _buildSection(
                context,
                'Physical Info',
                [
                  if (player.height != null)
                    _buildInfoRow('Height', player.height!),
                  if (player.weight != null)
                    _buildInfoRow('Weight', '${player.weight} lbs'),
                  if (player.yearsExp != null)
                    _buildInfoRow('Experience', '${player.yearsExp} years'),
                ],
              ),
            
            // 2024 Season Stats
            _buildSection(
              context,
              '2024 Season Stats',
              [
                _buildInfoRow('Games', player.games.toString()),
                _buildInfoRow('Fantasy PPG', player.fantasyPpg.toStringAsFixed(1)),
                _buildInfoRow('Total Fantasy Points', player.fantasyPointsPpr.toStringAsFixed(1)),
                _buildInfoRow('Total TDs', player.totalTds.toString()),
              ],
            ),
            
            // Position-specific stats
            if (player.isQuarterback && player.attempts > 0)
              _buildSection(
                context,
                'Passing Stats',
                [
                  _buildInfoRow('Completions/Attempts', '${player.completions}/${player.attempts}'),
                  _buildInfoRow('Passing Yards', '${player.passingYards} (${player.passYpg.toStringAsFixed(1)}/game)'),
                  _buildInfoRow('Passing TDs', player.passingTds.toString()),
                  _buildInfoRow('Interceptions', player.interceptions.toString()),
                  if (player.attempts > 0)
                    _buildInfoRow('Completion %', '${((player.completions / player.attempts) * 100).toStringAsFixed(1)}%'),
                ],
              ),
            
            if ((player.isQuarterback || player.isRunningBack) && player.carries > 0)
              _buildSection(
                context,
                'Rushing Stats',
                [
                  _buildInfoRow('Carries', player.carries.toString()),
                  _buildInfoRow('Rushing Yards', '${player.rushingYards} (${player.rushYpg.toStringAsFixed(1)}/game)'),
                  _buildInfoRow('Rushing TDs', player.rushingTds.toString()),
                  if (player.carries > 0)
                    _buildInfoRow('Yards/Carry', (player.rushingYards / player.carries).toStringAsFixed(1)),
                ],
              ),
            
            if ((player.isRunningBack || player.isWideReceiver || player.isTightEnd) && player.targets > 0)
              _buildSection(
                context,
                'Receiving Stats',
                [
                  _buildInfoRow('Receptions/Targets', '${player.receptions}/${player.targets}'),
                  _buildInfoRow('Receiving Yards', '${player.receivingYards} (${player.recYpg.toStringAsFixed(1)}/game)'),
                  _buildInfoRow('Receiving TDs', player.receivingTds.toString()),
                  if (player.targets > 0)
                    _buildInfoRow('Catch %', '${((player.receptions / player.targets) * 100).toStringAsFixed(1)}%'),
                  if (player.receptions > 0)
                    _buildInfoRow('Yards/Reception', (player.receivingYards / player.receptions).toStringAsFixed(1)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}