// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

/// Defines different layout types based on screen width
enum LayoutType {
  mobile,     // < 600px
  tablet,     // 600-900px
  desktop     // > 900px
}

/// Utility class for responsive design throughout the app
class ResponsiveUtils {
  /// Determine the current layout type based on screen width
  static LayoutType getLayoutType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return LayoutType.mobile;
    } else if (width < 900) {
      return LayoutType.tablet;
    } else {
      return LayoutType.desktop;
    }
  }
  
  /// Get a value based on the current layout type
  static T valueForLayoutType<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final layoutType = getLayoutType(context);
    
    switch (layoutType) {
      case LayoutType.mobile:
        return mobile;
      case LayoutType.tablet:
        return tablet ?? desktop;
      case LayoutType.desktop:
        return desktop;
    }
  }
  
  /// Check if the current layout is mobile
  static bool isMobile(BuildContext context) => 
      getLayoutType(context) == LayoutType.mobile;
  
  /// Check if the current layout is tablet
  static bool isTablet(BuildContext context) => 
      getLayoutType(context) == LayoutType.tablet;
  
  /// Check if the current layout is desktop
  static bool isDesktop(BuildContext context) => 
      getLayoutType(context) == LayoutType.desktop;
      
  /// Get responsive horizontal padding based on screen size
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: valueForLayoutType(
        context: context,
        mobile: 8.0,
        tablet: 16.0,
        desktop: 24.0,
      )
    );
  }
  
  /// Get responsive text styles for different layout types
  static TextStyle getResponsiveTextStyle(
    BuildContext context, 
    TextStyle baseStyle,
    {double? mobileFactor, double? tabletFactor, double? desktopFactor}
  ) {
    final layoutType = getLayoutType(context);
    
    switch (layoutType) {
      case LayoutType.mobile:
        return baseStyle.copyWith(
          fontSize: baseStyle.fontSize != null 
            ? baseStyle.fontSize! * (mobileFactor ?? 1.0)
            : null,
        );
      case LayoutType.tablet:
        return baseStyle.copyWith(
          fontSize: baseStyle.fontSize != null 
            ? baseStyle.fontSize! * (tabletFactor ?? 1.1)
            : null,
        );
      case LayoutType.desktop:
        return baseStyle.copyWith(
          fontSize: baseStyle.fontSize != null 
            ? baseStyle.fontSize! * (desktopFactor ?? 1.2)
            : null,
        );
    }
  }
  
  /// Get responsive dimensions for UI elements
  static double getResponsiveDimension(
    BuildContext context, 
    double mobileSize,
    {double? tabletSize, double? desktopSize}
  ) {
    return valueForLayoutType(
      context: context,
      mobile: mobileSize,
      tablet: tabletSize,
      desktop: desktopSize ?? (mobileSize * 1.5),
    );
  }
  
  /// Get adaptive constraint for width
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 1400) {
      return 1200; // Max content width for very large screens
    } else if (width > 900) {
      return width * 0.85; // Use 85% of screen for desktop
    }
    
    return width; // Use full width for mobile/tablet
  }
}

/// Widget that creates different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 900) {
          return tablet ?? desktop;
        } else {
          return desktop;
        }
      },
    );
  }
}

/// Widget that wraps content with responsive constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.centerContent = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final calculatedMaxWidth = maxWidth ?? ResponsiveUtils.getMaxContentWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Only apply container constraints on large screens
    if (screenWidth > 900) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: calculatedMaxWidth,
          ),
          padding: padding ?? ResponsiveUtils.getHorizontalPadding(context),
          child: child,
        ),
      );
    }
    
    // On smaller screens, just apply padding
    return Container(
      width: double.infinity,
      padding: padding ?? ResponsiveUtils.getHorizontalPadding(context),
      child: child,
    );
  }
}

/// Extension methods for responsive text sizes
extension ResponsiveTextStyles on TextStyle {
  TextStyle responsive(BuildContext context, {
    double? mobileFactor,
    double? tabletFactor,
    double? desktopFactor,
  }) {
    return ResponsiveUtils.getResponsiveTextStyle(
      context, 
      this,
      mobileFactor: mobileFactor,
      tabletFactor: tabletFactor,
      desktopFactor: desktopFactor,
    );
  }
}