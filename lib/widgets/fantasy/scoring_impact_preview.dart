import 'package:flutter/material.dart';
import '../../models/fantasy/scoring_settings.dart';
import '../../services/fantasy/vorp_service.dart';

class ScoringImpactPreview extends StatelessWidget {
  final ScoringSettings currentSettings;
  final ScoringSettings previousSettings;
  final List<VORPPlayer> players;

  const ScoringImpactPreview({
    super.key,
    required this.currentSettings,
    required this.previousSettings,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate top movers based on scoring changes
    final topMovers = _calculateTopMovers();
    
    if (topMovers.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scoring Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Adjust scoring settings to see impact on player values',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Scoring Impact Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topMovers.take(5).map((mover) => _buildMoverTile(context, mover)),
          ],
        ),
      ),
    );
  }

  List<_PlayerMover> _calculateTopMovers() {
    final movers = <_PlayerMover>[];
    
    for (final player in players) {
      // Calculate points with both scoring systems
      final currentPoints = _calculatePlayerPoints(player, currentSettings);
      final previousPoints = _calculatePlayerPoints(player, previousSettings);
      final pointsDiff = currentPoints - previousPoints;
      
      if (pointsDiff.abs() > 0.1) { // Lower threshold to show more changes
        movers.add(_PlayerMover(
          player: player,
          pointsChange: pointsDiff,
          currentPoints: currentPoints,
          previousPoints: previousPoints,
        ));
      }
    }
    
    // Sort by absolute point change
    movers.sort((a, b) => b.pointsChange.abs().compareTo(a.pointsChange.abs()));
    
    return movers;
  }

  double _calculatePlayerPoints(VORPPlayer player, ScoringSettings settings) {
    // This is a simplified calculation - in production, you'd use actual projections
    final basePoints = player.projectedPoints;
    
    // Adjust based on position and scoring differences
    if (player.position == 'RB' || player.position == 'WR' || player.position == 'TE') {
      final pprDiff = settings.receptionPoints - 1.0;
      final receptionEstimate = _estimateReceptions(player);
      return basePoints + (pprDiff * receptionEstimate);
    } else if (player.position == 'QB') {
      final tdDiff = settings.passingTDPoints - 4.0;
      final tdEstimate = _estimatePassingTDs(player);
      return basePoints + (tdDiff * tdEstimate);
    }
    
    return basePoints;
  }

  double _estimateReceptions(VORPPlayer player) {
    // Rough estimates based on position and ranking
    switch (player.position.toUpperCase()) {
      case 'RB':
        return 60 - (player.rank * 1.5);
      case 'WR':
        return 85 - (player.rank * 1.2);
      case 'TE':
        return 70 - (player.rank * 2.0);
      default:
        return 0;
    }
  }

  double _estimatePassingTDs(VORPPlayer player) {
    // Rough estimate for QBs
    return 30 - (player.rank * 0.8);
  }

  Widget _buildMoverTile(BuildContext context, _PlayerMover mover) {
    final isPositive = mover.pointsChange > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${mover.player.playerName} ${mover.player.position.toUpperCase()}${mover.player.rank}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${mover.pointsChange.toStringAsFixed(1)} pts',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerMover {
  final VORPPlayer player;
  final double pointsChange;
  final double currentPoints;
  final double previousPoints;

  _PlayerMover({
    required this.player,
    required this.pointsChange,
    required this.currentPoints,
    required this.previousPoints,
  });
}