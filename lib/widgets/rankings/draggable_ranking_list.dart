import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme_config.dart';
import '../../utils/team_logo_utils.dart';

class RankingPlayerItem {
  final String id;
  final String name;
  final String position;
  final String team;
  final int rank;
  final int? tier;
  final double? projectedPoints;
  final double? vorp;
  final Map<String, dynamic> additionalData;

  RankingPlayerItem({
    required this.id,
    required this.name,
    required this.position,
    required this.team,
    required this.rank,
    this.tier,
    this.projectedPoints,
    this.vorp,
    this.additionalData = const {},
  });

  RankingPlayerItem copyWith({
    String? id,
    String? name,
    String? position,
    String? team,
    int? rank,
    int? tier,
    double? projectedPoints,
    double? vorp,
    Map<String, dynamic>? additionalData,
  }) {
    return RankingPlayerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      team: team ?? this.team,
      rank: rank ?? this.rank,
      tier: tier ?? this.tier,
      projectedPoints: projectedPoints ?? this.projectedPoints,
      vorp: vorp ?? this.vorp,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

class DraggableRankingList extends StatefulWidget {
  final List<RankingPlayerItem> players;
  final Function(List<RankingPlayerItem>) onReorder;
  final bool showVORPPreview;
  final String position;
  final bool enabled;
  final ScrollController? scrollController;

  const DraggableRankingList({
    super.key,
    required this.players,
    required this.onReorder,
    this.showVORPPreview = false,
    required this.position,
    this.enabled = true,
    this.scrollController,
  });

  @override
  State<DraggableRankingList> createState() => _DraggableRankingListState();
}

class _DraggableRankingListState extends State<DraggableRankingList> {
  late List<RankingPlayerItem> _players;

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.players);
  }

  @override
  void didUpdateWidget(DraggableRankingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.players != oldWidget.players) {
      _players = List.from(widget.players);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (!widget.enabled) return;
    
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      final item = _players.removeAt(oldIndex);
      _players.insert(newIndex, item);
      
      // Update ranks
      for (int i = 0; i < _players.length; i++) {
        _players[i] = _players[i].copyWith(rank: i + 1);
      }
    });

    HapticFeedback.mediumImpact();
    widget.onReorder(_players);
  }

  Color _getTierColor(int? tier) {
    switch (tier) {
      case 1:
        return Colors.green.shade600;
      case 2:
        return Colors.blue.shade600;
      case 3:
        return Colors.orange.shade600;
      case 4:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getVORPDisplay(double? vorp) {
    if (vorp == null) return '-';
    return vorp >= 0 ? '+${vorp.toStringAsFixed(1)}' : vorp.toStringAsFixed(1);
  }

  Color _getVORPColor(double? vorp) {
    if (vorp == null) return Colors.grey;
    if (vorp > 20) return Colors.green.shade700;
    if (vorp > 5) return Colors.blue.shade700;
    if (vorp > 0) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ReorderableListView.builder(
      scrollController: widget.scrollController,
      onReorder: _onReorder,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8,
          shadowColor: ThemeConfig.gold.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        
        return Card(
          key: ValueKey(player.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  if (widget.enabled)
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeConfig.darkNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.drag_indicator,
                          color: ThemeConfig.darkNavy,
                          size: 20,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getTierColor(player.tier),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${player.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  // Team logo
                  TeamLogoUtils.buildNFLTeamLogo(player.team, size: 24),
                  const SizedBox(width: 12),
                  // Player name
                  Expanded(
                    child: Text(
                      player.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: widget.showVORPPreview
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          // Team name
                          Text(
                            player.team.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Projected points
                          if (player.projectedPoints != null) ...[
                            Icon(
                              Icons.sports_football,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${player.projectedPoints!.toStringAsFixed(1)} pts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          // VORP
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: _getVORPColor(player.vorp),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getVORPDisplay(player.vorp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getVORPColor(player.vorp),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${player.position.toUpperCase()} • ${player.team.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
              trailing: widget.enabled
                  ? Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

// Helper extension to convert ranking data
extension RankingPlayerExtension on Map<String, dynamic> {
  RankingPlayerItem toRankingPlayerItem() {
    return RankingPlayerItem(
      id: this['player_id'] ?? this['fantasy_player_id'] ?? this['id'] ?? '',
      name: this['fantasy_player_name'] ?? 
            this['player_name'] ?? 
            this['passer_player_name'] ?? 
            this['receiver_player_name'] ?? 
            'Unknown',
      position: (this['position'] ?? '').toString().toLowerCase(),
      team: this['posteam'] ?? this['team'] ?? '',
      rank: this['myRankNum'] ?? this['rank'] ?? 0,
      tier: this['tier'] ?? this['qbTier'] ?? this['rbTier'],
      projectedPoints: this['projectedPoints'] as double?,
      vorp: this['vorp'] as double?,
      additionalData: Map<String, dynamic>.from(this),
    );
  }
}