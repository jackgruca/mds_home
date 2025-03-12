// lib/utils/team_logo_utils.dart
import 'package:flutter/material.dart';
import 'constants.dart';

class TeamLogoUtils {
  // Fetch NFL team logo
  static Widget buildNFLTeamLogo(
    String teamName, {
    double size = 30.0,
    Widget Function(String)? placeholderBuilder,
  }) {
    // Try to find the abbreviation in the mapping
    String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName];
    
    // If we can't find it in the mapping, check if it's already an abbreviation
    if (abbr == null && teamName.length <= 3) {
      abbr = teamName;
    }
    
    // If we still don't have an abbreviation, create a placeholder
    if (abbr == null) {
      return _buildPlaceholderLogo(
        teamName,
        size: size,
        color: Colors.blue.shade700,
        customBuilder: placeholderBuilder,
      );
    }
    
    // Convert abbreviation to lowercase for URL
    final logoUrl = 'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png';
    
    // Handle the image with error fallback
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // On error, return the placeholder
            return _buildPlaceholderLogo(
              teamName,
              size: size,
              color: Colors.blue.shade700,
              customBuilder: placeholderBuilder,
            );
          },
        ),
      ),
    );
  }

    static Widget buildCollegeTeamLogo(
    String schoolName, {
    double size = 30.0,
    Widget Function(String)? placeholderBuilder,
  }) {
    // Try to find ESPN ID for this school
    String? espnId = CollegeTeamESPNIds.findIdForSchool(schoolName);
    
    // If we found an ID, use it to build the URL
    if (espnId != null) {
      // Use numeric ID URL pattern
      final logoUrl = 'https://a.espncdn.com/i/teamlogos/ncaa/500/$espnId.png';
      
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              // Fall back to placeholder if image fails to load
              return _buildPlaceholderLogo(
                schoolName, 
                size: size,
                color: Colors.green.shade700,
                customBuilder: placeholderBuilder,
              );
            },
          ),
        ),
      );
    }
    
    // If no ESPN ID found, just use placeholder
    return _buildPlaceholderLogo(
      schoolName,
      size: size,
      color: Colors.green.shade700,
      customBuilder: placeholderBuilder,
    );
  }
  
  // Helper method to find a working logo URL
  static Future<int> _findWorkingLogo(String abbr, List<String> formats) async {
    // In a production app, you'd implement HTTP head requests to check which URL works
    // For simplicity in this example, we'll return the first format, assuming it works
    // In a real implementation, you'd try each URL and return the index of the first working one
    
    // This is just a placeholder implementation - in your app, you'd need to check each URL
    return 0; // Return the first format
  }
  
  // Helper method to build a placeholder logo
  static Widget _buildPlaceholderLogo(
    String name, {
    required double size,
    required Color color,
    Widget Function(String)? customBuilder,
  }) {
    // If a custom builder is provided, use it
    if (customBuilder != null) {
      return customBuilder(name);
    }
    
    // Default placeholder with initials
    final initials = _getTeamInitials(name);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4, // Scale font size with container
          ),
        ),
      ),
    );
  }
  
  // Helper method for team initials
  static String _getTeamInitials(String teamName) {
    final initials = teamName.split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();
    
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }
}