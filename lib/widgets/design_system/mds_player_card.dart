import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

enum MdsPlayerCardType { 
  compact, 
  standard, 
  featured, 
  comparison 
}

class MdsPlayerCard extends StatelessWidget {
  final String playerName;
  final String team;
  final String position;
  final String? imageUrl;
  final Map<String, String>? stats;
  final String? primaryStat;
  final String? primaryStatValue;
  final String? secondaryStat;
  final String? secondaryStatValue;
  final Color? teamColor;
  final MdsPlayerCardType type;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;

  const MdsPlayerCard({
    super.key,
    required this.playerName,
    required this.team,
    required this.position,
    this.imageUrl,
    this.stats,
    this.primaryStat,
    this.primaryStatValue,
    this.secondaryStat,
    this.secondaryStatValue,
    this.teamColor,
    this.type = MdsPlayerCardType.standard,
    this.onTap,
    this.trailing,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: _getPadding(),
        decoration: _buildDecoration(isDarkMode),
        child: _buildContent(context, isDarkMode, theme),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (type) {
      case MdsPlayerCardType.compact:
        return const EdgeInsets.all(12);
      case MdsPlayerCardType.featured:
        return const EdgeInsets.all(20);
      case MdsPlayerCardType.comparison:
        return const EdgeInsets.all(16);
      default:
        return const EdgeInsets.all(16);
    }
  }

  BoxDecoration _buildDecoration(bool isDarkMode) {
    final baseColor = teamColor ?? ThemeConfig.darkNavy;
    
    switch (type) {
      case MdsPlayerCardType.featured:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              baseColor.withOpacity(0.1),
              baseColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: baseColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case MdsPlayerCardType.comparison:
        return BoxDecoration(
          color: isDarkMode ? ThemeConfig.darkGray : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeConfig.gold.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.gold.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case MdsPlayerCardType.compact:
        return BoxDecoration(
          color: isDarkMode ? ThemeConfig.darkGray.withOpacity(0.7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: baseColor.withOpacity(0.2),
            width: 1,
          ),
        );

      default:
        return BoxDecoration(
          color: isDarkMode ? ThemeConfig.darkGray : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
    }
  }

  Widget _buildContent(BuildContext context, bool isDarkMode, ThemeData theme) {
    final textColor = isDarkMode ? Colors.white : ThemeConfig.darkNavy;
    final subtitleColor = isDarkMode ? ThemeConfig.mediumGray : ThemeConfig.darkGray;

    if (type == MdsPlayerCardType.compact) {
      return _buildCompactLayout(textColor, subtitleColor, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with player info and badge
        Row(
          children: [
            // Player avatar/initial circle
            _buildPlayerAvatar(textColor),
            
            const SizedBox(width: 12),
            
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          playerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: _getNameFontSize(),
                          ),
                        ),
                      ),
                      if (showBadge && badgeText != null) _buildBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$team • $position',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: _getSubtitleFontSize(),
                    ),
                  ),
                ],
              ),
            ),
            
            if (trailing != null) trailing!,
          ],
        ),
        
        // Stats section
        if (_hasStats()) ...[
          SizedBox(height: _getStatsSpacing()),
          _buildStatsSection(textColor, subtitleColor, theme),
        ],
      ],
    );
  }

  Widget _buildCompactLayout(Color textColor, Color subtitleColor, ThemeData theme) {
    return Row(
      children: [
        _buildPlayerAvatar(textColor, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$team • $position',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (primaryStatValue != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                primaryStatValue!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (primaryStat != null)
                Text(
                  primaryStat!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerAvatar(Color textColor, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (teamColor ?? ThemeConfig.darkNavy).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: teamColor ?? ThemeConfig.darkNavy,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _getPlayerInitials(),
          style: TextStyle(
            color: teamColor ?? ThemeConfig.darkNavy,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor ?? ThemeConfig.brightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsSection(Color textColor, Color subtitleColor, ThemeData theme) {
    if (type == MdsPlayerCardType.featured && primaryStatValue != null) {
      return _buildFeaturedStats(textColor, subtitleColor, theme);
    }
    
    return _buildStandardStats(textColor, subtitleColor, theme);
  }

  Widget _buildFeaturedStats(Color textColor, Color subtitleColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (teamColor ?? ThemeConfig.darkNavy).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (primaryStatValue != null) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    primaryStatValue!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (primaryStat != null)
                    Text(
                      primaryStat!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (secondaryStatValue != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Text(
                    secondaryStatValue!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (secondaryStat != null)
                    Text(
                      secondaryStat!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardStats(Color textColor, Color subtitleColor, ThemeData theme) {
    return Row(
      children: [
        if (primaryStatValue != null) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryStatValue!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (primaryStat != null)
                  Text(
                    primaryStat!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (secondaryStatValue != null) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  secondaryStatValue!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (secondaryStat != null)
                  Text(
                    secondaryStat!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getPlayerInitials() {
    final parts = playerName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0].substring(0, 1);
  }

  bool _hasStats() {
    return primaryStatValue != null || secondaryStatValue != null || stats != null;
  }

  double _getNameFontSize() {
    switch (type) {
      case MdsPlayerCardType.featured:
        return 18;
      case MdsPlayerCardType.comparison:
        return 16;
      default:
        return 15;
    }
  }

  double _getSubtitleFontSize() {
    switch (type) {
      case MdsPlayerCardType.featured:
        return 13;
      default:
        return 12;
    }
  }

  double _getStatsSpacing() {
    switch (type) {
      case MdsPlayerCardType.featured:
        return 16;
      default:
        return 12;
    }
  }
} 