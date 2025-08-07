import 'package:flutter/material.dart';

class DesignSystem {
  // Base unit for spacing (8px grid system)
  static const double spaceUnit = 8.0;
  
  // Spacing multipliers
  static const double spaceXS = spaceUnit * 0.5;   // 4px
  static const double spaceS = spaceUnit;          // 8px
  static const double spaceM = spaceUnit * 2;      // 16px
  static const double spaceL = spaceUnit * 3;      // 24px
  static const double spaceXL = spaceUnit * 4;     // 32px
  static const double spaceXXL = spaceUnit * 6;    // 48px
  
  // Colors - Jony Ive inspired minimalism
  static const Color primaryText = Color(0xFF1A1A1A);      // Near black
  static const Color secondaryText = Color(0xFF6B7280);    // Gray 500
  static const Color tertiaryText = Color(0xFF9CA3AF);     // Gray 400
  static const Color dividerColor = Color(0xFFE5E7EB);     // Gray 200
  static const Color backgroundColor = Color(0xFFFAFAFA);   // Off white
  static const Color cardBackground = Colors.white;
  static const Color accentBlue = Color(0xFF007AFF);       // iOS blue
  static const Color successGreen = Color(0xFF10B981);     // Modern green
  static const Color warningOrange = Color(0xFFF59E0B);    // Modern amber
  static const Color errorRed = Color(0xFFEF4444);         // Modern red
  
  // Border radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  
  // Shadows - subtle depth
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  // Typography
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: primaryText,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.3,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryText,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: tertiaryText,
    height: 1.4,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: tertiaryText,
    letterSpacing: 0.5,
    height: 1.3,
  );
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}