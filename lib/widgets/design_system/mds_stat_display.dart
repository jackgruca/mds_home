import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

enum MdsStatType { 
  standard, 
  performance, 
  comparison, 
  trend,
  highlight
}

class MdsStatDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final MdsStatType type;
  final Color? accentColor;
  final Widget? trailing;
  final bool showTrend;
  final double? trendValue; // Positive for up, negative for down
  final VoidCallback? onTap;

  const MdsStatDisplay({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.type = MdsStatType.standard,
    this.accentColor,
    this.trailing,
    this.showTrend = false,
    this.trendValue,
    this.onTap,
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
      case MdsStatType.highlight:
        return const EdgeInsets.all(20);
      case MdsStatType.performance:
        return const EdgeInsets.all(16);
      default:
        return const EdgeInsets.all(12);
    }
  }

  BoxDecoration _buildDecoration(bool isDarkMode) {
    final baseColor = accentColor ?? _getDefaultAccentColor();
    
    switch (type) {
      case MdsStatType.highlight:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              baseColor,
              baseColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case MdsStatType.performance:
        return BoxDecoration(
          color: isDarkMode ? ThemeConfig.darkGray : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: baseColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case MdsStatType.comparison:
        return BoxDecoration(
          color: isDarkMode 
            ? ThemeConfig.darkNavy.withOpacity(0.6) 
            : ThemeConfig.lightGray.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: baseColor.withOpacity(0.4),
            width: 1,
          ),
        );

      case MdsStatType.trend:
        return BoxDecoration(
          color: isDarkMode ? ThemeConfig.darkGray.withOpacity(0.7) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case MdsStatType.standard:
      default:
        return BoxDecoration(
          color: isDarkMode ? ThemeConfig.darkGray.withOpacity(0.5) : ThemeConfig.lightGray,
          borderRadius: BorderRadius.circular(8),
        );
    }
  }

  Widget _buildContent(BuildContext context, bool isDarkMode, ThemeData theme) {
    final isHighlight = type == MdsStatType.highlight;
    final textColor = isHighlight ? Colors.white : (isDarkMode ? Colors.white : ThemeConfig.darkNavy);
    final subtitleColor = isHighlight 
      ? Colors.white.withOpacity(0.8) 
      : (isDarkMode ? ThemeConfig.mediumGray : ThemeConfig.darkGray);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with icon and trend
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: _getIconSize(),
                color: isHighlight ? Colors.white : (accentColor ?? _getDefaultAccentColor()),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: _getLabelFontSize(),
                ),
              ),
            ),
            if (showTrend && trendValue != null) _buildTrendIndicator(isHighlight),
            if (trailing != null) trailing!,
          ],
        ),
        
        SizedBox(height: _getSpacing()),
        
        // Value
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: _getValueFontSize(),
          ),
        ),
        
        // Subtitle
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor,
              fontSize: _getSubtitleFontSize(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendIndicator(bool isHighlight) {
    if (trendValue == null) return const SizedBox.shrink();
    
    final isPositive = trendValue! > 0;
    final color = isHighlight 
      ? Colors.white 
      : (isPositive ? ThemeConfig.successGreen : ThemeConfig.deepRed);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${trendValue!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDefaultAccentColor() {
    switch (type) {
      case MdsStatType.highlight:
        return ThemeConfig.brightRed;
      case MdsStatType.performance:
        return ThemeConfig.gold;
      case MdsStatType.comparison:
        return ThemeConfig.darkNavy;
      case MdsStatType.trend:
        return ThemeConfig.brightRed;
      default:
        return ThemeConfig.mediumGray;
    }
  }

  double _getIconSize() {
    switch (type) {
      case MdsStatType.highlight:
        return 24;
      case MdsStatType.performance:
        return 20;
      default:
        return 18;
    }
  }

  double _getLabelFontSize() {
    switch (type) {
      case MdsStatType.highlight:
        return 14;
      default:
        return 12;
    }
  }

  double _getValueFontSize() {
    switch (type) {
      case MdsStatType.highlight:
        return 28;
      case MdsStatType.performance:
        return 24;
      default:
        return 20;
    }
  }

  double _getSubtitleFontSize() {
    switch (type) {
      case MdsStatType.highlight:
        return 13;
      default:
        return 11;
    }
  }

  double _getSpacing() {
    switch (type) {
      case MdsStatType.highlight:
        return 8;
      case MdsStatType.performance:
        return 6;
      default:
        return 4;
    }
  }
} 