import 'package:flutter/material.dart';
import 'theme_config.dart';

class ThemeAwareColors {
  static Color getTableHeaderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : ThemeConfig.darkNavy;
  }

  static Color getTableHeaderTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.onSurface
      : Colors.white;
  }

  static Color getTableRowColor(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return index.isEven 
        ? Theme.of(context).colorScheme.surfaceContainerLowest
        : Theme.of(context).colorScheme.surfaceContainer;
    } else {
      return index.isEven 
        ? Colors.grey.shade100
        : Colors.white;
    }
  }

  static Color getInputFillColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : Colors.grey.shade50;
  }

  static Color getInputBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.outline
      : Colors.grey.shade300;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
      : Colors.grey.shade700;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getSearchBarFillColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : Colors.grey.shade100;
  }

  static Color getSearchBarHintColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
      : Colors.grey.shade600;
  }

  static Color getSearchBarTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getFilterChipBackgroundColor(BuildContext context, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSelected) {
      return isDark ? ThemeConfig.gold.withOpacity(0.3) : ThemeConfig.darkNavy;
    } else {
      return isDark 
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : Colors.grey.shade200;
    }
  }

  static Color getFilterChipTextColor(BuildContext context, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSelected) {
      return isDark ? ThemeConfig.gold : Colors.white;
    } else {
      return Theme.of(context).colorScheme.onSurface;
    }
  }

  static Color getButtonBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? ThemeConfig.gold : ThemeConfig.darkNavy;
  }

  static Color getButtonTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? ThemeConfig.darkNavy : Colors.white;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getSuccessColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.green.shade400 : Colors.green.shade600;
  }

  static Color getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.orange.shade400 : Colors.orange.shade600;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getOnSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getOnPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }
} 