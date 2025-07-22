import 'package:flutter/material.dart';
import 'package:mds_home/models/projections/player_projection.dart';
import 'package:mds_home/models/projections/team_projections.dart';
import 'package:mds_home/services/projections/player_projections_service.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/design_system/mds_button.dart';
import 'package:mds_home/utils/theme_config.dart';

class PlayerProjectionsScreen extends StatefulWidget {
  const PlayerProjectionsScreen({super.key});

  @override
  State<PlayerProjectionsScreen> createState() => _PlayerProjectionsScreenState();
}

class _PlayerProjectionsScreenState extends State<PlayerProjectionsScreen> {
  final PlayerProjectionsService _projectionsService = PlayerProjectionsService();
  Map<String, TeamProjections> _teamProjections = {};
  List<PlayerProjection> _allPlayers = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProjections();
  }

  Future<void> _loadProjections() async {
    try {
      setState(() => _isLoading = true);
      _teamProjections = await _projectionsService.loadTeamProjections();
      _allPlayers = _teamProjections.values
          .expand((team) => team.players)
          .toList();
      // Sort by team, then by projected points descending
      _allPlayers.sort((a, b) {
        final teamCompare = a.team.compareTo(b.team);
        if (teamCompare != 0) return teamCompare;
        return b.projectedPoints.compareTo(a.projectedPoints);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projections: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePlayer(PlayerProjection updatedPlayer) async {
    try {
      final calculatedPlayer = await _projectionsService.calculateProjections(updatedPlayer);
      
      setState(() {
        // Update in the all players list
        final index = _allPlayers.indexWhere((p) => p.playerId == calculatedPlayer.playerId);
        if (index != -1) {
          _allPlayers[index] = calculatedPlayer;
        }
        
        // Update in team projections
        _teamProjections = _teamProjections.map((teamCode, team) {
          final updatedPlayers = team.players.map((player) {
            return player.playerId == calculatedPlayer.playerId ? calculatedPlayer : player;
          }).toList();
          return MapEntry(teamCode, team.copyWith(players: updatedPlayers));
        });
        
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating player: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('Player Projections'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildProjectionsTable(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fantasy Football Player Projections',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_hasChanges) ...[
                const SizedBox(width: 16),
                MdsButton(
                  text: 'Save Changes',
                  onPressed: () {
                    // TODO: Implement save functionality
                    setState(() => _hasChanges = false);
                  },
                  type: MdsButtonType.primary,
                  icon: Icons.save,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Edit player attributes and see real-time projection updates. Players are grouped by team.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionsTable() {
    if (_allPlayers.isEmpty) {
      return const Center(
        child: Text('No players found'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 56,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          columns: _buildColumns(),
          rows: _buildRows(),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(label: Text('Player')),
      const DataColumn(label: Text('Team')),
      const DataColumn(label: Text('Pos')),
      const DataColumn(label: Text('WR Rank')),
      const DataColumn(label: Text('Target Share')),
      const DataColumn(label: Text('Pass Off Tier')),
      const DataColumn(label: Text('QB Tier')),
      const DataColumn(label: Text('Run Off Tier')),
      const DataColumn(label: Text('EPA Tier')),
      const DataColumn(label: Text('Pass Freq Tier')),
      const DataColumn(label: Text('Player Year')),
      const DataColumn(label: Text('Proj Rec')),
      const DataColumn(label: Text('Proj Yards')),
      const DataColumn(label: Text('Proj TDs')),
      const DataColumn(label: Text('Proj Points'), numeric: true),
    ];
  }

  List<DataRow> _buildRows() {
    final rows = <DataRow>[];
    String? currentTeam;
    
    for (int i = 0; i < _allPlayers.length; i++) {
      final player = _allPlayers[i];
      
      // Add team header row
      if (currentTeam != player.team) {
        currentTeam = player.team;
        rows.add(_buildTeamHeaderRow(player.team));
      }
      
      // Add player row
      rows.add(_buildPlayerRow(player));
    }
    
    return rows;
  }

  DataRow _buildTeamHeaderRow(String team) {
    final teamData = _teamProjections[team];
    final totalPoints = teamData?.totalProjectedPoints ?? 0;
    final totalTargetShare = teamData?.totalTargetShare ?? 0;
    
    return DataRow(
      color: WidgetStateProperty.all(ThemeConfig.darkNavy.withValues(alpha: 0.1)),
      cells: [
        DataCell(
          Text(
            team,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            'Total: ${totalPoints.toStringAsFixed(1)} pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        DataCell(
          Text(
            'Target Share: ${(totalTargetShare * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: totalTargetShare > 1.0 ? Colors.red : 
                     totalTargetShare > 0.95 ? Colors.green :
                     totalTargetShare > 0.85 ? Colors.orange : Colors.grey,
            ),
          ),
        ),
        ...List.generate(12, (index) => const DataCell(SizedBox.shrink())),
      ],
    );
  }

  DataRow _buildPlayerRow(PlayerProjection player) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              player.playerName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(player.team, style: const TextStyle(fontSize: 12))),
        DataCell(Text(player.position, style: const TextStyle(fontSize: 12))),
        DataCell(_buildEditableDropdown(
          player.wrRank,
          List.generate(6, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(wrRank: value)),
          (value) => value.toString(),
        )),
        DataCell(_buildEditableTargetShare(player)),
        DataCell(_buildEditableDropdown(
          player.passOffenseTier,
          List.generate(8, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(passOffenseTier: value)),
          (value) => value.toString(),
        )),
        DataCell(_buildEditableDropdown(
          player.qbTier,
          List.generate(8, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(qbTier: value)),
          (value) => value.toString(),
        )),
        DataCell(_buildEditableDropdown(
          player.runOffenseTier,
          List.generate(8, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(runOffenseTier: value)),
          (value) => value.toString(),
        )),
        DataCell(_buildEditableDropdown(
          player.epaTier,
          List.generate(8, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(epaTier: value)),
          (value) => value.toString(),
        )),
        DataCell(_buildEditableDropdown(
          player.passFreqTier,
          List.generate(8, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(passFreqTier: value)),
          (value) => value.toString(),
        )),
        DataCell(_buildEditableDropdown(
          player.playerYear,
          List.generate(10, (i) => i + 1),
          (value) => _updatePlayer(player.copyWith(playerYear: value)),
          (value) => value.toString(),
        )),
        DataCell(Text(player.projectedReceptions.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
        DataCell(Text(player.projectedYards.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
        DataCell(Text(player.projectedTDs.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPointsColor(player.projectedPoints),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.projectedPoints.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDropdown<T>(
    T value,
    List<T> items,
    Function(T?) onChanged,
    String Function(T) displayText,
  ) {
    // Ensure the current value exists in items, if not add it
    if (!items.contains(value)) {
      items = [...items, value];
    }
    
    // Create unique dropdown items by using index-based approach
    final uniqueItems = <DropdownMenuItem<T>>[];
    final seenValues = <T>{};
    
    for (final item in items) {
      if (!seenValues.contains(item)) {
        seenValues.add(item);
        uniqueItems.add(DropdownMenuItem<T>(
          value: item,
          child: Text(displayText(item)),
        ));
      }
    }
    
    return SizedBox(
      width: 60,
      child: DropdownButton<T>(
        value: value,
        items: uniqueItems,
        onChanged: onChanged,
        isExpanded: true,
        underline: Container(),
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
    );
  }

  Widget _buildEditableTargetShare(PlayerProjection player) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: (player.targetShare * 100).toStringAsFixed(1),
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          suffix: Text('%', style: TextStyle(fontSize: 10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 4),
        ),
        keyboardType: TextInputType.number,
        onFieldSubmitted: (value) {
          final newTargetShare = (double.tryParse(value) ?? (player.targetShare * 100)) / 100;
          _updatePlayer(player.copyWith(targetShare: newTargetShare));
        },
      ),
    );
  }

  Color _getPointsColor(double points) {
    if (points >= 200) return Colors.green;
    if (points >= 150) return Colors.blue;
    if (points >= 100) return Colors.orange;
    return Colors.grey;
  }
} 