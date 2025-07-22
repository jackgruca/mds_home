import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

enum MdsCardType { 
  standard, 
  elevated, 
  outlined, 
  player, 
  stat, 
  feature,
  gradient 
}

class MdsCard extends StatelessWidget {
  final Widget child;
  final MdsCardType type;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? customColor;
  final List<Color>? gradientColors;
  final bool showShadow;
  final double? elevation;
  final BorderRadius? borderRadius;

  const MdsCard({
    super.key,
    required this.child,
    this.type = MdsCardType.standard,
    this.onTap,
    this.padding,
    this.customColor,
    this.gradientColors,
    this.showShadow = true,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding ?? _getDefaultPadding(),
        decoration: _buildDecoration(context, isDarkMode),
        child: child,
      ),
    );
  }

  EdgeInsetsGeometry _getDefaultPadding() {
    switch (type) {
      case MdsCardType.stat:
        return const EdgeInsets.all(12);
      case MdsCardType.player:
        return const EdgeInsets.all(16);
      case MdsCardType.feature:
        return const EdgeInsets.all(24);
      default:
        return const EdgeInsets.all(16);
    }
  }

  BoxDecoration _buildDecoration(BuildContext context, bool isDarkMode) {
    final baseRadius = borderRadius ?? BorderRadius.circular(_getBorderRadius());
    
    switch (type) {
      case MdsCardType.elevated:
        return BoxDecoration(
          color: customColor ?? (isDarkMode ? ThemeConfig.darkGray : Colors.white),
          borderRadius: baseRadius,
          boxShadow: showShadow ? [
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.15),
              blurRadius: elevation ?? 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ] : null,
        );

      case MdsCardType.outlined:
        return BoxDecoration(
          color: customColor ?? (isDarkMode ? ThemeConfig.darkGray.withOpacity(0.3) : Colors.white),
          borderRadius: baseRadius,
          border: Border.all(
            color: isDarkMode ? ThemeConfig.mediumGray.withOpacity(0.3) : ThemeConfig.mediumGray.withOpacity(0.5),
            width: 1,
          ),
        );

      case MdsCardType.player:
        return BoxDecoration(
          color: customColor ?? (isDarkMode ? ThemeConfig.darkGray : Colors.white),
          borderRadius: baseRadius,
          border: Border.all(
            color: ThemeConfig.gold.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: showShadow ? [
            BoxShadow(
              color: ThemeConfig.gold.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        );

      case MdsCardType.stat:
        return BoxDecoration(
          color: customColor ?? (isDarkMode ? ThemeConfig.darkNavy.withOpacity(0.8) : ThemeConfig.lightGray),
          borderRadius: baseRadius,
          border: Border.all(
            color: ThemeConfig.brightRed.withOpacity(0.2),
            width: 1,
          ),
        );

      case MdsCardType.feature:
        return BoxDecoration(
          gradient: gradientColors != null 
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  ThemeConfig.darkNavy,
                  ThemeConfig.darkNavy.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: baseRadius,
          boxShadow: showShadow ? [
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ] : null,
        );

      case MdsCardType.gradient:
        return BoxDecoration(
          gradient: gradientColors != null 
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  ThemeConfig.brightRed,
                  ThemeConfig.deepRed,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: baseRadius,
          boxShadow: showShadow ? [
            BoxShadow(
              color: (gradientColors?.first ?? ThemeConfig.brightRed).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ] : null,
        );

      case MdsCardType.standard:
      default:
        return BoxDecoration(
          color: customColor ?? (isDarkMode ? ThemeConfig.darkGray.withOpacity(0.5) : Colors.white),
          borderRadius: baseRadius,
          boxShadow: showShadow ? [
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        );
    }
  }

  double _getBorderRadius() {
    switch (type) {
      case MdsCardType.stat:
        return 8;
      case MdsCardType.feature:
        return 16;
      case MdsCardType.player:
        return 12;
      default:
        return 12;
    }
  }
} 