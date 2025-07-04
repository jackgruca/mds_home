import 'package:flutter/material.dart';
import '../models/ff_player.dart';

class FFQuickActions extends StatelessWidget {
  final bool isUserTurn;
  final VoidCallback? onBestAvailable;
  final VoidCallback? onFillNeed;
  final VoidCallback? onTopValue;
  final VoidCallback? onTopRookie;
  final FFPlayer? bestAvailablePlayer;
  final FFPlayer? needPlayer;
  final FFPlayer? valuePlayer;
  final String? needPosition;

  const FFQuickActions({
    super.key,
    required this.isUserTurn,
    this.onBestAvailable,
    this.onFillNeed,
    this.onTopValue,
    this.onTopRookie,
    this.bestAvailablePlayer,
    this.needPlayer,
    this.valuePlayer,
    this.needPosition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!isUserTurn) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for your turn...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Best Available Action
          if (bestAvailablePlayer != null)
            _buildQuickActionCard(
              context,
              title: 'Best Available',
              subtitle: 'Highest ranked player',
              player: bestAvailablePlayer!,
              icon: Icons.star,
              color: Colors.purple,
              onTap: onBestAvailable,
            ),
          
          const SizedBox(height: 12),
          
          // Fill Need Action
          if (needPlayer != null && needPosition != null)
            _buildQuickActionCard(
              context,
              title: 'Fill Need',
              subtitle: 'Best $needPosition available',
              player: needPlayer!,
              icon: Icons.assignment_add,
              color: Colors.blue,
              onTap: onFillNeed,
            ),
          
          const SizedBox(height: 12),
          
          // Value Pick Action
          if (valuePlayer != null)
            _buildQuickActionCard(
              context,
              title: 'Value Pick',
              subtitle: 'Great value at this spot',
              player: valuePlayer!,
              icon: Icons.trending_up,
              color: Colors.green,
              onTap: onTopValue,
            ),
          
          const SizedBox(height: 12),
          
          // Additional actions row
          _buildAdditionalActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required FFPlayer player,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
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
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Color.fromRGBO(
                          (color.r * 0.7).round(),
                          (color.g * 0.7).round(),
                          (color.b * 0.7).round(),
                          1.0,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          player.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniPositionBadge(player.position, theme),
                        if (player.consensusRank != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '#${player.consensusRank}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPositionBadge(String position, ThemeData theme) {
    final Color positionColor;
    
    switch (position) {
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
        position,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildAdditionalActions(BuildContext context) {
    
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryAction(
            context,
            'Rookie Upside',
            Icons.new_releases,
            Colors.amber,
            onTopRookie,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSecondaryAction(
            context,
            'Safe Floor',
            Icons.security,
            Colors.teal,
            null, // TODO: Implement safe floor action
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    
    return Material(
      elevation: isEnabled ? 1 : 0,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled 
                ? color.withValues(alpha: 0.3) 
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            color: isEnabled 
              ? color.withValues(alpha: 0.05) 
              : theme.colorScheme.surface.withValues(alpha: 0.5),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isEnabled 
                  ? color 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isEnabled 
                    ? Color.fromRGBO(
                        (color.r * 0.7).round(),
                        (color.g * 0.7).round(),
                        (color.b * 0.7).round(),
                        1.0,
                      ) 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}