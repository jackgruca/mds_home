import 'package:flutter/material.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../services/vorp/historical_points_service.dart';

class RankingPlayerItem {
  final String id;
  final String name;
  final String team;
  final String position;
  final int originalRank;
  final Map<String, dynamic> originalData;
  int customRank;
  double projectedPoints;
  double vorp;

  RankingPlayerItem({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    required this.originalRank,
    required this.originalData,
    required this.customRank,
    this.projectedPoints = 0.0,
    this.vorp = 0.0,
  });

  factory RankingPlayerItem.fromRankingData(Map<String, dynamic> data, int rank) {
    return RankingPlayerItem(
      id: data['player_id']?.toString() ?? 
           data['fantasy_player_id']?.toString() ?? 
           data['passer_player_id']?.toString() ?? 
           '${data['player_name'] ?? data['fantasy_player_name']}_$rank',
      name: data['fantasy_player_name'] ?? 
            data['player_name'] ?? 
            data['passer_player_name'] ?? 
            'Unknown Player',
      team: data['posteam']?.toString() ?? data['team']?.toString() ?? '',
      position: data['position']?.toString() ?? '',
      originalRank: rank,
      customRank: rank,
      originalData: Map<String, dynamic>.from(data),
      projectedPoints: (data['projectedPoints'] as num?)?.toDouble() ?? 0.0,
      vorp: (data['vorp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RankingPlayerItem copyWith({
    String? id,
    String? name,
    String? team,
    String? position,
    int? originalRank,
    int? customRank,
    double? projectedPoints,
    double? vorp,
    Map<String, dynamic>? originalData,
  }) {
    return RankingPlayerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      team: team ?? this.team,
      position: position ?? this.position,
      originalRank: originalRank ?? this.originalRank,
      customRank: customRank ?? this.customRank,
      projectedPoints: projectedPoints ?? this.projectedPoints,
      vorp: vorp ?? this.vorp,
      originalData: originalData ?? this.originalData,
    );
  }
}

class DragDropPositionRankingList extends StatefulWidget {
  final List<RankingPlayerItem> players;
  final Function(List<RankingPlayerItem>) onReorder;
  final Function(RankingPlayerItem, int) onRankChange;
  final Function()? onVORPCalculate;
  final bool showVORP;
  final bool isLoading;
  final String position;

  const DragDropPositionRankingList({
    super.key,
    required this.players,
    required this.onReorder,
    required this.onRankChange,
    this.onVORPCalculate,
    this.showVORP = false,
    this.isLoading = false,
    required this.position,
  });

  @override
  State<DragDropPositionRankingList> createState() => _DragDropPositionRankingListState();
}

class _DragDropPositionRankingListState extends State<DragDropPositionRankingList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with VORP calculation button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Text(
                'Drag to Reorder ${widget.position.toUpperCase()} Rankings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.onVORPCalculate != null)
                ElevatedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onVORPCalculate,
                  icon: widget.isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate, size: 16),
                  label: Text(widget.isLoading ? 'Calculating...' : 'Calculate VORP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.darkNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
        ),

        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40), // Space for drag handle
              const SizedBox(
                width: 60,
                child: Text(
                  'Rank',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Expanded(
                flex: 3,
                child: Text(
                  'Player',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(
                width: 60,
                child: Text(
                  'Team',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (widget.showVORP) ...[
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Proj Pts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'VORP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Reorderable list
        Expanded(
          child: ReorderableListView.builder(
            itemCount: widget.players.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex--;
              }
              
              final updatedPlayers = List<RankingPlayerItem>.from(widget.players);
              final item = updatedPlayers.removeAt(oldIndex);
              updatedPlayers.insert(newIndex, item);
              
              // Update custom ranks based on new positions
              for (int i = 0; i < updatedPlayers.length; i++) {
                updatedPlayers[i] = updatedPlayers[i].copyWith(customRank: i + 1);
              }
              
              widget.onReorder(updatedPlayers);
            },
            itemBuilder: (context, index) {
              final player = widget.players[index];
              return _buildPlayerRow(player, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(RankingPlayerItem player, int index) {
    final theme = Theme.of(context);
    final rankChange = player.customRank - player.originalRank;
    
    return Container(
      key: ValueKey(player.id),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(
            Icons.drag_handle,
            color: Colors.grey,
          ),
        ),
        title: Row(
          children: [
            // Custom Rank Input
            SizedBox(
              width: 60,
              child: TextField(
                controller: TextEditingController(text: player.customRank.toString()),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: ThemeConfig.darkNavy),
                  ),
                ),
                onSubmitted: (value) {
                  final newRank = int.tryParse(value);
                  if (newRank != null && newRank > 0 && newRank <= widget.players.length) {
                    widget.onRankChange(player, newRank);
                  }
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Player info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  TeamLogoUtils.buildNFLTeamLogo(player.team, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (rankChange != 0)
                          Row(
                            children: [
                              Icon(
                                rankChange > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                                size: 12,
                                color: rankChange > 0 ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${rankChange > 0 ? '+' : ''}$rankChange from #${player.originalRank}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: rankChange > 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Team
            SizedBox(
              width: 60,
              child: Text(
                player.team,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // VORP data if enabled
            if (widget.showVORP) ...[
              SizedBox(
                width: 80,
                child: Text(
                  player.projectedPoints > 0 
                      ? player.projectedPoints.toStringAsFixed(1)
                      : '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: player.vorp >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: player.vorp >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    player.vorp != 0 
                        ? (player.vorp >= 0 ? '+' : '') + player.vorp.toStringAsFixed(1)
                        : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: player.vorp >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper function to create RankingPlayerItem list from ranking data
List<RankingPlayerItem> createRankingPlayerItems(
  List<Map<String, dynamic>> rankings,
  String position,
) {
  return rankings.asMap().entries.map((entry) {
    final index = entry.key;
    final data = entry.value;
    return RankingPlayerItem.fromRankingData(data, index + 1);
  }).toList();
}