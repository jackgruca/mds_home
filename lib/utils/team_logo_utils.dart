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
    // Handle null, empty, or whitespace-only team names
    if (teamName.trim().isEmpty) {
      return _buildPlaceholderLogo(
        'NFL',
        size: size,
        color: Colors.grey.shade600,
        customBuilder: placeholderBuilder,
      );
    }
    
    // Handle unknown teams specifically
    if (teamName.trim().toLowerCase() == 'unk' || teamName.trim().toLowerCase() == 'unknown') {
      return _buildPlaceholderLogo(
        'UNK',
        size: size,
        color: Colors.grey.shade600,
        customBuilder: placeholderBuilder,
      );
    }
    
    // Try to find the abbreviation in the mapping
    String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName.trim()];
    
    // If we can't find it in the mapping, check if it's already an abbreviation
    if (abbr == null && teamName.trim().length <= 3) {
      abbr = teamName.trim();
      
      // Check historical abbreviation mapping
      if (NFLTeamMappings.historicalAbbreviationMap.containsKey(abbr!.toUpperCase())) {
        abbr = NFLTeamMappings.historicalAbbreviationMap[abbr.toUpperCase()];
      }
    }
    
    // If we still don't have an abbreviation or it's empty, create a placeholder
    if (abbr == null || abbr.trim().isEmpty) {
      return _buildPlaceholderLogo(
        teamName.isNotEmpty ? teamName : 'NFL',
        size: size,
        color: Colors.blue.shade700,
        customBuilder: placeholderBuilder,
      );
    }
    
    // Additional check for known problematic abbreviations
    if (abbr.toLowerCase() == 'unk') {
      return _buildPlaceholderLogo(
        'UNK',
        size: size,
        color: Colors.grey.shade600,
        customBuilder: placeholderBuilder,
      );
    }
    
    // Convert abbreviation to lowercase for URL
    final logoUrl = 'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.trim().toLowerCase()}.png';
    
    // Handle the image with error fallback
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // On error, return the placeholder
            debugPrint('Error loading team logo for $teamName ($abbr): $error');
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade700,
              ),
              child: Center(
                child: Text(
                  _getTeamInitials(teamName),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.4,
                  ),
                ),
              ),
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