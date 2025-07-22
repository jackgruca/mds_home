import 'package:flutter/material.dart';
import 'package:mds_home/models/projections/player_projection.dart';
import 'package:mds_home/models/projections/team_projections.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/widgets/design_system/mds_button.dart';
import 'package:mds_home/widgets/design_system/mds_card.dart';
import 'package:mds_home/widgets/projections/player_projection_row.dart';

class TeamProjectionsCard extends StatefulWidget {
  final TeamProjections teamProjections;
  final Function(PlayerProjection) onPlayerUpdated;
  final VoidCallback onAddPlayer;
  final Function(String) onRemovePlayer;
  final VoidCallback onNormalizeTargetShares;
  final Function(TeamProjections) onTeamTiersUpdated;

  const TeamProjectionsCard({
    super.key,
    required this.teamProjections,
    required this.onPlayerUpdated,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    required this.onNormalizeTargetShares,
    required this.onTeamTiersUpdated,
  });

  @override
  State<TeamProjectionsCard> createState() => _TeamProjectionsCardState();
}

class _TeamProjectionsCardState extends State<TeamProjectionsCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTargetShare = widget.teamProjections.totalTargetShare;
    final totalProjectedPoints = widget.teamProjections.totalProjectedPoints;
    
    return MdsCard(
      type: MdsCardType.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, totalTargetShare, totalProjectedPoints),
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildPlayersList(),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, double totalTargetShare, double totalProjectedPoints) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Team logo placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ThemeConfig.darkNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.teamProjections.teamCode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teamProjections.teamName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.teamProjections.players.length} players • ${(totalTargetShare * 100).toStringAsFixed(1)}% target share',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatBadge(
                  '${totalProjectedPoints.toStringAsFixed(0)} pts',
                  Colors.green,
                ),
                const SizedBox(height: 4),
                _buildTargetShareBadge(totalTargetShare),
              ],
            ),
            
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTargetShareBadge(double targetShare) {
    final percentage = targetShare * 100;
    Color color;
    
    if (percentage > 100) {
      color = Colors.red;
    } else if (percentage > 95) {
      color = Colors.green;
    } else if (percentage > 85) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }
    
    return _buildStatBadge('${percentage.toStringAsFixed(1)}%', color);
  }

  Widget _buildPlayersList() {
    final sortedPlayers = widget.teamProjections.playersByRank;
    
    return Column(
      children: [
        ...sortedPlayers.map((player) => PlayerProjectionRow(
          player: player,
          onPlayerUpdated: widget.onPlayerUpdated,
          onRemovePlayer: widget.onRemovePlayer,
        )),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              MdsButton(
                text: 'Add Player',
                onPressed: widget.onAddPlayer,
                type: MdsButtonType.secondary,
                icon: Icons.add,
              ),
              const SizedBox(width: 12),
              MdsButton(
                text: 'Normalize to 95%',
                onPressed: widget.onNormalizeTargetShares,
                type: MdsButtonType.secondary,
                icon: Icons.balance,
              ),
              const SizedBox(width: 12),
              MdsButton(
                text: 'Team Settings',
                onPressed: () => _showTeamSettings(context),
                type: MdsButtonType.secondary,
                icon: Icons.settings,
              ),
              const Spacer(),
              Text(
                'QB Tier ${widget.teamProjections.qbTier} • Pass Off Tier ${widget.teamProjections.passOffenseTier}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTeamSettings(BuildContext context) {
    int selectedQbTier = widget.teamProjections.qbTier;
    int selectedPassOffenseTier = widget.teamProjections.passOffenseTier;
    int selectedRunOffenseTier = widget.teamProjections.runOffenseTier;
    int selectedPassFreqTier = widget.teamProjections.passFreqTier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Team Settings - ${widget.teamProjections.teamName}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTeamTierDropdown('QB Tier', selectedQbTier, (value) {
                  setState(() {
                    selectedQbTier = value;
                  });
                }),
                const SizedBox(height: 12),
                _buildTeamTierDropdown('Pass Offense Tier', selectedPassOffenseTier, (value) {
                  setState(() {
                    selectedPassOffenseTier = value;
                  });
                }),
                const SizedBox(height: 12),
                _buildTeamTierDropdown('Run Offense Tier', selectedRunOffenseTier, (value) {
                  setState(() {
                    selectedRunOffenseTier = value;
                  });
                }),
                const SizedBox(height: 12),
                _buildTeamTierDropdown('Pass Frequency Tier', selectedPassFreqTier, (value) {
                  setState(() {
                    selectedPassFreqTier = value;
                  });
                }),
                const SizedBox(height: 16),
                Text(
                  'Lower tier numbers = better performance\nChanging team tiers will update all players on this team',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedTeam = widget.teamProjections.copyWith(
                  qbTier: selectedQbTier,
                  passOffenseTier: selectedPassOffenseTier,
                  runOffenseTier: selectedRunOffenseTier,
                  passFreqTier: selectedPassFreqTier,
                );
                widget.onTeamTiersUpdated(updatedTeam);
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTierDropdown(String label, int currentValue, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: DropdownButton<int>(
            value: currentValue,
            isExpanded: true,
            items: List.generate(8, (index) {
              final tier = index + 1;
              return DropdownMenuItem(
                value: tier,
                child: Text('Tier $tier'),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
} 