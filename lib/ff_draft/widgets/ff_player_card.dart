import 'package:flutter/material.dart';
import '../models/ff_player.dart';

class FFPlayerCard extends StatelessWidget {
  final FFPlayer player;
  final bool isRecommended;
  final bool isSelected;
  final bool isUserTurn;
  final String? recommendationReason;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const FFPlayerCard({
    super.key,
    required this.player,
    this.isRecommended = false,
    this.isSelected = false,
    this.isUserTurn = false,
    this.recommendationReason,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        elevation: isRecommended ? 4 : 1,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isUserTurn ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getBorderColor(theme),
                width: _getBorderWidth(),
              ),
              gradient: _getGradient(theme),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Rank badge (smaller)
                _buildRankBadge(theme),
                const SizedBox(width: 8),
                
                // Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPositionBadge(theme),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            player.team,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          if (player.byeWeek != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Bye ${player.byeWeek}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Display ADP in a compact way
                          Text(
                            'ADP ${player.adp.toStringAsFixed(1)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Favorite button (smaller)
                _buildFavoriteButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(ThemeData theme) {
    final rank = player.consensusRank ?? player.rank ?? 999;
    final Color badgeColor;
    
    if (rank <= 12) {
      badgeColor = Colors.purple; // Elite tier
    } else if (rank <= 36) {
      badgeColor = Colors.blue; // First 3 rounds
    } else if (rank <= 60) {
      badgeColor = Colors.green; // Middle rounds
    } else if (rank <= 100) {
      badgeColor = Colors.orange; // Late rounds
    } else {
      badgeColor = Colors.grey; // Deep sleepers
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rank <= 999 ? '$rank' : '?',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildPositionBadge(ThemeData theme) {
    final Color positionColor;
    
    switch (player.position) {
      case 'QB':
        positionColor = Colors.red;
        break;
      case 'RB':
        positionColor = Colors.green;
        break;
      case 'WR':
        positionColor = Colors.blue;
        break;
      case 'TE':
        positionColor = Colors.orange;
        break;
      case 'K':
        positionColor = Colors.purple;
        break;
      case 'DEF':
        positionColor = Colors.brown;
        break;
      default:
        positionColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: positionColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        player.positionRank,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(ThemeData theme) {
    return IconButton(
      onPressed: onFavorite,
      icon: Icon(
        player.isFavorite ? Icons.star : Icons.star_border,
        color: player.isFavorite ? Colors.amber : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        size: 20,
      ),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Color _getBorderColor(ThemeData theme) {
    if (isRecommended) return Colors.green;
    if (isSelected) return theme.colorScheme.primary;
    if (!isUserTurn) return theme.colorScheme.outline.withValues(alpha: 0.3);
    return theme.colorScheme.outline;
  }

  double _getBorderWidth() {
    if (isRecommended || isSelected) return 2;
    return 1;
  }

  Gradient? _getGradient(ThemeData theme) {
    if (isRecommended) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.withValues(alpha: 0.05),
          Colors.green.withValues(alpha: 0.02),
        ],
      );
    }
    return null;
  }

  String _getTierText() {
    final rank = player.consensusRank ?? player.rank ?? 999;
    if (rank <= 12) return 'ELITE';
    if (rank <= 36) return 'TIER 1';
    if (rank <= 60) return 'TIER 2';
    if (rank <= 100) return 'TIER 3';
    return 'DEEP';
  }
}