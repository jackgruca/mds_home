import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_player.dart';
import '../models/ff_team.dart';
import '../models/ff_position_constants.dart';
import '../providers/ff_draft_provider.dart';
import 'ff_player_list.dart';

class FFMobileDraftInterface extends StatefulWidget {
  const FFMobileDraftInterface({super.key});

  @override
  State<FFMobileDraftInterface> createState() => _FFMobileDraftInterfaceState();
}

class _FFMobileDraftInterfaceState extends State<FFMobileDraftInterface>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FFTeam? _selectedRosterTeam;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        if (provider.availablePlayers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64),
                SizedBox(height: 16),
                Text('Loading players...'),
              ],
            ),
          );
        }
        
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, provider),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDraftBoardTab(provider),
                      _buildPlayersTab(provider),
                      _buildRosterTab(provider),
                    ],
                  ),
                ),
                if (provider.isUserTurn()) _buildDraftAction(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FFDraftProvider provider) {
    final theme = Theme.of(context);
    final currentPick = provider.getCurrentPick();
    final isUserTurn = provider.isUserTurn();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round ${currentPick?.round ?? 1}, Pick ${currentPick?.pickNumber ?? 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isUserTurn ? 'Your Turn!' : '${currentPick?.team.name ?? "Team"} is picking...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUserTurn ? Colors.green[700] : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isUserTurn)
                Row(
                  children: [
                    // Control buttons when it's user's turn
                    _buildControlButtons(context, provider),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'YOUR TURN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Draft Board'),
        Tab(text: 'Players'),
        Tab(text: 'Roster'),
      ],
    );
  }

  Widget _buildDraftBoardTab(FFDraftProvider provider) {
    return Column(
      children: [
        // Position legend
        _buildPositionLegend(),
        
        // Draft board header
        _buildDraftBoardHeader(provider),
        
        // Draft board grid
        Expanded(
          child: _buildDraftBoard(provider),
        ),
      ],
    );
  }

  Widget _buildPositionLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      child:         Wrap(
        spacing: 8,
        children: [
          _buildLegendItem('QB', FFPositionConstants.getPositionColor('QB')),
          _buildLegendItem('RB', FFPositionConstants.getPositionColor('RB')),
          _buildLegendItem('WR', FFPositionConstants.getPositionColor('WR')),
          _buildLegendItem('TE', FFPositionConstants.getPositionColor('TE')),
          _buildLegendItem('K', FFPositionConstants.getPositionColor('K')),
          _buildLegendItem('DST', FFPositionConstants.getPositionColor('DST')),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String position, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          position,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDraftBoardHeader(FFDraftProvider provider) {
    return Container(
      height: 40,
      color: Colors.grey[100],
      child: Row(
        children: [
          // Round header
          Container(
            width: 50,
            alignment: Alignment.center,
            child: const Text(
              'R',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          
          // Team headers
          Expanded(
            child: Row(
              children: provider.teams.map((team) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    alignment: Alignment.center,
                    child: Text(
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftBoard(FFDraftProvider provider) {
    final teams = provider.teams;
    final draftPicks = provider.draftPicks;
    final totalRounds = provider.settings.numRounds;
    
    return SingleChildScrollView(
      child: Column(
        children: List.generate(totalRounds, (roundIndex) {
          final round = roundIndex + 1;
          return _buildRoundRow(provider, round, teams, draftPicks);
        }),
      ),
    );
  }

  Widget _buildRoundRow(
    FFDraftProvider provider,
    int round,
    List<FFTeam> teams,
    List<FFDraftPick> draftPicks,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Round number
          Container(
            width: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                right: BorderSide(color: Colors.grey[400]!, width: 1),
              ),
            ),
            child: Text(
              '$round',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          
          // Team picks for this round
          Expanded(
            child: Row(
              children: teams.asMap().entries.map((entry) {
                final teamIndex = entry.key;
                final team = entry.value;
                
                // Calculate pick number for this team in this round
                final pickNumber = _calculatePickNumber(round, teamIndex, teams.length);
                final pick = draftPicks.firstWhere(
                  (p) => p.pickNumber == pickNumber,
                  orElse: () => FFDraftPick(
                    pickNumber: pickNumber,
                    round: round,
                    team: team,
                    isUserPick: team.isUserTeam,
                  ),
                );
                
                return Expanded(
                  child: _buildPickCell(provider, pick),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickCell(FFDraftProvider provider, FFDraftPick pick) {
    final isSelected = pick.isSelected;
    final isCurrentPick = provider.getCurrentPick() == pick;
    final player = pick.selectedPlayer;
    
    Color backgroundColor;
    Color textColor = Colors.white;
    
    if (isCurrentPick) {
      backgroundColor = Colors.amber[600]!;
      textColor = Colors.black;
    } else if (!isSelected) {
      backgroundColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
    } else if (player != null) {
      backgroundColor = _getPositionColor(player.position);
    } else {
      backgroundColor = Colors.grey[400]!;
    }
    
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        border: isCurrentPick
            ? Border.all(color: Colors.amber[800]!, width: 2)
            : null,
      ),
      child: InkWell(
        onTap: isSelected ? () => _showPlayerDetails(player) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected && player != null) ...[
                Text(
                  _getPlayerDisplayName(player.name),
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  player.position,
                  style: TextStyle(
                    fontSize: 6,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (isCurrentPick) ...[
                Icon(
                  Icons.timer,
                  size: 10,
                  color: textColor,
                ),
                Text(
                  'Picking',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  '${pick.pickNumber}',
                  style: TextStyle(
                    fontSize: 8,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPlayerDisplayName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}. ${parts.last}';
    }
    return fullName.length > 8 ? '${fullName.substring(0, 8)}...' : fullName;
  }

  Color _getPositionColor(String position) {
    return FFPositionConstants.getPositionColor(position);
  }

  int _calculatePickNumber(int round, int teamIndex, int totalTeams) {
    if (round % 2 == 1) {
      // Odd rounds: normal order (1, 2, 3, ...)
      return (round - 1) * totalTeams + teamIndex + 1;
    } else {
      // Even rounds: reverse order (snake draft)
      return (round - 1) * totalTeams + (totalTeams - teamIndex);
    }
  }

  void _showPlayerDetails(FFPlayer? player) {
    if (player == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Position: ${player.position}'),
            Text('Team: ${player.team}'),
            if (player.adp < 999) Text('ADP: ${player.adp.toStringAsFixed(1)}'),
            if (player.consensusRank != null) Text('Rank: ${player.consensusRank}'),
            if (player.projectedPoints > 0) 
              Text('Projected Points: ${player.projectedPoints.toStringAsFixed(1)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab(FFDraftProvider provider) {
    return FFPlayerList(
      onPlayerSelected: (player) => provider.handlePlayerSelection(player),
    );
  }

  Widget _buildRosterTab(FFDraftProvider provider) {
    // Initialize selected team if not set
    if (_selectedRosterTeam == null && provider.teams.isNotEmpty) {
      _selectedRosterTeam = provider.teams.first;
    }
    
    return Column(
      children: [
        // Team selector dropdown
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Team: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: DropdownButton<FFTeam>(
                  isExpanded: true,
                  value: _selectedRosterTeam,
                  items: provider.teams.map((team) {
                    return DropdownMenuItem<FFTeam>(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                  onChanged: (team) {
                    setState(() {
                      _selectedRosterTeam = team;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Roster display
        Expanded(
          child: _selectedRosterTeam != null 
            ? _buildTeamRoster(provider, _selectedRosterTeam!)
            : const Center(child: Text('No team selected')),
        ),
      ],
    );
  }

  Widget _buildTeamRoster(FFDraftProvider provider, FFTeam team) {
    // Get all picks for this team
    final teamPicks = provider.draftPicks
        .where((pick) => pick.team.id == team.id && pick.isSelected)
        .toList();
    
    // Group by position
    final positionGroups = <String, List<FFDraftPick>>{};
    for (final pick in teamPicks) {
      if (pick.selectedPlayer != null) {
        final position = pick.selectedPlayer!.position;
        positionGroups.putIfAbsent(position, () => []);
        positionGroups[position]!.add(pick);
      }
    }
    
    // Define position order
    const positionOrder = ['QB', 'RB', 'WR', 'TE', 'K', 'DST'];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team name header
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.group, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                '${team.name} Roster',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Position sections
        ...positionOrder.map((position) {
          final picks = positionGroups[position] ?? [];
          return _buildPositionSection(position, picks);
        }),
      ],
    );
  }

  Widget _buildPositionSection(String position, List<FFDraftPick> picks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPositionColor(position).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              '$position (${picks.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _getPositionColor(position),
              ),
            ),
          ),
          
          // Players in this position
          if (picks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No $position selected',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...picks.map((pick) => _buildRosterPlayerCard(pick)),
        ],
      ),
    );
  }

  Widget _buildRosterPlayerCard(FFDraftPick pick) {
    final player = pick.selectedPlayer!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPositionColor(player.position),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                player.position,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Player details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      player.team,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (player.adp < 999) ...[
                      const Text(' • '),
                      Text(
                        'ADP ${player.adp.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Pick number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Pick ${pick.pickNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, FFDraftProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: () {
              if (!provider.paused) {
                provider.pauseDraft();
              } else {
                provider.startDraftSimulation();
              }
            },
            padding: EdgeInsets.zero,
            icon: Icon(
              !provider.paused ? Icons.pause : Icons.play_arrow,
              size: 20,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: !provider.paused 
                ? Colors.red[600] 
                : Colors.green[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Undo button
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: provider.userPickHistory.isNotEmpty ? () => provider.undoLastPick() : null,
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.undo,
              size: 20,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: provider.userPickHistory.isNotEmpty 
                ? Colors.blue[600] 
                : Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraftAction(BuildContext context, FFDraftProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          top: BorderSide(color: Colors.green[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Auto-pick best available using existing method
                final recommendations = provider.getRecommendations(count: 1);
                if (recommendations.isNotEmpty) {
                  provider.handlePlayerSelection(recommendations.first);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Auto Pick Best Available'),
            ),
          ),
        ],
      ),
    );
  }
}