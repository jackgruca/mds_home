// lib/widgets/player/player_link_widget.dart
import 'package:flutter/material.dart';
import '../../models/nfl_player.dart';
import '../../services/nfl_player_service.dart';
import '../../services/instant_player_cache.dart';
import '../../services/super_fast_player_service.dart';
import 'nfl_player_modal.dart';

class PlayerLinkWidget extends StatefulWidget {
  final String playerName;
  final TextStyle? style;
  final Color? hoverColor;
  final bool showPosition;
  final VoidCallback? onFullProfileTap;
  
  const PlayerLinkWidget({
    super.key,
    required this.playerName,
    this.style,
    this.hoverColor,
    this.showPosition = false,
    this.onFullProfileTap,
  });

  @override
  State<PlayerLinkWidget> createState() => _PlayerLinkWidgetState();
}

class _PlayerLinkWidgetState extends State<PlayerLinkWidget> {
  bool _isHovering = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _isLoading ? null : _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: Text(
            widget.playerName,
            style: _getTextStyle(isDarkMode),
          ),
        ),
      ),
    );
  }

  TextStyle _getTextStyle(bool isDarkMode) {
    final baseStyle = widget.style ?? TextStyle(
      color: isDarkMode ? Colors.white : Colors.black87,
      fontSize: 14,
    );

    if (_isHovering) {
      return baseStyle.copyWith(
        color: widget.hoverColor ?? Colors.blue.shade600,
        decoration: TextDecoration.underline,
        decorationColor: widget.hoverColor ?? Colors.blue.shade600,
      );
    }

    return baseStyle.copyWith(
      color: Colors.blue.shade700,
      decoration: TextDecoration.underline,
      decorationColor: Colors.blue.shade700.withValues(alpha: 0.6),
    );
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;
    
    // Use super fast service for instant loading
    final player = await SuperFastPlayerService.getFastPlayer(widget.playerName);
    
    if (player != null && mounted) {
      await _showPlayerModal(player);
      // Load full data in background and update cache
      _loadFullPlayerDataBackground();
    } else if (mounted) {
      // Show loading state only if no cached data available
      setState(() => _isLoading = true);
      
      try {
        final fallbackPlayer = await NFLPlayerService.getPlayerByName(widget.playerName, includeHistoricalStats: false);
        
        if (fallbackPlayer != null && mounted) {
          await _showPlayerModal(fallbackPlayer);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not find player: ${widget.playerName}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load player data for ${widget.playerName}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  void _loadFullPlayerDataBackground() async {
    try {
      final fullPlayer = await NFLPlayerService.getPlayerByName(widget.playerName, includeHistoricalStats: true);
      if (fullPlayer != null) {
        InstantPlayerCache.cachePlayer(widget.playerName, fullPlayer);
      }
    } catch (e) {
      // Silently fail background loading
    }
  }

  Future<void> _showPlayerModal(NFLPlayer player) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return NFLPlayerModal(
          player: player,
          onViewFullProfile: () {
            if (widget.onFullProfileTap != null) {
              widget.onFullProfileTap!();
            } else {
              // Use player name instead of ID for more reliable navigation
              Navigator.pushNamed(
                context, 
                '/player/${Uri.encodeComponent(player.playerName)}',
              );
            }
          },
        );
      },
    );
  }
}

/// Utility class for creating player links from data tables
class PlayerLinkHelper {
  /// Create a player link widget from a data row
  static Widget? createFromRow(
    Map<String, dynamic> row, {
    TextStyle? style,
    Color? hoverColor,
    bool showPosition = false,
  }) {
    final playerName = NFLPlayerService.extractPlayerName(row);
    
    if (playerName == null || !NFLPlayerService.hasPlayerData(row)) {
      return null;
    }
    
    return PlayerLinkWidget(
      playerName: playerName,
      style: style,
      hoverColor: hoverColor,
      showPosition: showPosition,
    );
  }

  /// Replace plain text player names with clickable links in a text widget
  static Widget enhanceTextWithPlayerLinks(
    String text,
    BuildContext context, {
    TextStyle? style,
  }) {
    // Simple implementation - can be enhanced with regex for player name detection
    final words = text.split(' ');
    final widgets = <InlineSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // Simple heuristic: if it looks like a player name (2+ uppercase words)
      if (i < words.length - 1 && 
          word.isNotEmpty && 
          word[0].toUpperCase() == word[0] &&
          words[i + 1].isNotEmpty &&
          words[i + 1][0].toUpperCase() == words[i + 1][0]) {
        
        final possibleName = '$word ${words[i + 1]}';
        widgets.add(
          WidgetSpan(
            child: PlayerLinkWidget(
              playerName: possibleName,
              style: style,
            ),
          ),
        );
        i++; // Skip next word as it's part of the name
      } else {
        widgets.add(TextSpan(text: '$word '));
      }
    }
    
    return RichText(
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: widgets,
      ),
    );
  }

  /// Check if a cell value should be converted to a player link
  static bool shouldConvertToLink(String? value, String columnName) {
    if (value == null || value.trim().isEmpty) return false;
    
    // Column names that typically contain player names
    final playerColumns = [
      'player_name',
      'name', 
      'passer_player_name',
      'rusher_player_name',
      'receiver_player_name',
      'fantasy_player_name',
      'player',
    ];
    
    return playerColumns.any((col) => 
      columnName.toLowerCase().contains(col.toLowerCase()));
  }
}