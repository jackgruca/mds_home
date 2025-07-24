// lib/widgets/player/nfl_player_modal.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/nfl_player.dart';
import '../../utils/team_logo_utils.dart';

class NFLPlayerModal extends StatelessWidget {
  final NFLPlayer player;
  final VoidCallback? onViewFullProfile;
  
  const NFLPlayerModal({
    super.key,
    required this.player,
    this.onViewFullProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: _buildContent(context, isDarkMode),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDarkMode) {
    final headerColor = _getPositionColor(player.position ?? '');
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with player info and close button
          _buildHeader(context, isDarkMode, headerColor),
          
          // Quick stats banner
          _buildQuickStats(context, isDarkMode),
          
          // Main content area
          Flexible(
            child: _buildMainContent(context, isDarkMode),
          ),
          
          // Footer with action buttons
          _buildFooter(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode, Color headerColor) {
    return Container(
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: isDarkMode ? 0.7 : 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Player headshot
          _buildPlayerImage(isDarkMode),
          
          const SizedBox(width: 16),
          
          // Player name and position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.positionTeam,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                if (player.experienceText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    player.experienceText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Close button
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerImage(bool isDarkMode) {
    if (player.headshotUrl != null && player.headshotUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: player.headshotUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 60,
            height: 60,
            color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(isDarkMode),
        ),
      );
    }
    
    return _buildFallbackImage(isDarkMode);
  }

  Widget _buildFallbackImage(bool isDarkMode) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 28,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          if (player.team != null && player.team!.isNotEmpty)
            SizedBox(
              width: 16,
              height: 16,
              child: TeamLogoUtils.buildNFLTeamLogo(
                player.team!,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (player.formattedHeight != 'N/A')
            _buildQuickStat('HT', player.formattedHeight, isDarkMode),
          if (player.formattedWeight != 'N/A')
            _buildQuickStat('WT', player.formattedWeight, isDarkMode),
          if (player.age != null)
            _buildQuickStat('Age', '${player.age}', isDarkMode),
          if (player.college != null)
            _buildQuickStat('College', player.college!, isDarkMode, isLong: true),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, bool isDarkMode, {bool isLong = false}) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: isLong ? 11 : 13,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draft info
          if (player.draftInfo != 'Draft info unavailable') ...[
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Draft Info',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              player.draftInfo,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Current season stats (if available)
          if (player.currentSeasonStats != null && player.currentSeasonStats!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Season (2024)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCurrentSeasonStats(isDarkMode),
            
            // Add historical context if available
            if (player.historicalStats != null && player.historicalStats!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Career: ${player.historicalStats!.length} seasons • ${player.experienceText}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentSeasonStats(bool isDarkMode) {
    final stats = player.currentSeasonStats!;
    final statWidgets = <Widget>[];
    
    // Show position-specific stats
    if (player.position == 'QB') {
      if (stats['passing_yards'] != null) {
        statWidgets.add(_buildStatItem('Pass Yds', '${stats['passing_yards']}', isDarkMode));
      }
      if (stats['passing_tds'] != null) {
        statWidgets.add(_buildStatItem('Pass TDs', '${stats['passing_tds']}', isDarkMode));
      }
      if (stats['interceptions'] != null) {
        statWidgets.add(_buildStatItem('INTs', '${stats['interceptions']}', isDarkMode));
      }
    } else if (player.position == 'RB') {
      if (stats['rushing_yards'] != null) {
        statWidgets.add(_buildStatItem('Rush Yds', '${stats['rushing_yards']}', isDarkMode));
      }
      if (stats['rushing_tds'] != null) {
        statWidgets.add(_buildStatItem('Rush TDs', '${stats['rushing_tds']}', isDarkMode));
      }
    } else if (['WR', 'TE'].contains(player.position)) {
      if (stats['receiving_yards'] != null) {
        statWidgets.add(_buildStatItem('Rec Yds', '${stats['receiving_yards']}', isDarkMode));
      }
      if (stats['receiving_tds'] != null) {
        statWidgets.add(_buildStatItem('Rec TDs', '${stats['receiving_tds']}', isDarkMode));
      }
      if (stats['receptions'] != null) {
        statWidgets.add(_buildStatItem('Rec', '${stats['receptions']}', isDarkMode));
      }
    }
    
    // Show generic stats if no position-specific ones
    if (statWidgets.isEmpty) {
      stats.entries.take(3).forEach((entry) {
        statWidgets.add(_buildStatItem(entry.key, '${entry.value}', isDarkMode));
      });
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statWidgets,
    );
  }

  Widget _buildStatItem(String label, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onViewFullProfile != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onViewFullProfile!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('View Full Profile'),
            ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    // Different colors for different position groups
    if (['QB'].contains(position)) {
      return Colors.blue.shade700;
    } else if (['RB', 'FB'].contains(position)) {
      return Colors.green.shade700;
    } else if (['WR', 'TE'].contains(position)) {
      return Colors.purple.shade700;
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.orange.shade700;
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700;
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.teal.shade700;
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.indigo.shade700;
    }
    return Colors.grey.shade700;
  }
}