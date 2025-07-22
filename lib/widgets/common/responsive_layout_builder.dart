import 'package:flutter/material.dart';

typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context);

class ResponsiveLayoutBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder? tablet;
  final ResponsiveWidgetBuilder desktop;

  // Define breakpoints
  static const double kTabletBreakpoint = 600.0;
  static const double kDesktopBreakpoint = 1024.0;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kDesktopBreakpoint) {
          return desktop(context);
        } else if (constraints.maxWidth >= kTabletBreakpoint) {
          // Use desktop if tablet is not provided, or tablet if it is
          return tablet != null ? tablet!(context) : desktop(context);
        } else {
          return mobile(context);
        }
      },
    );
  }
} 