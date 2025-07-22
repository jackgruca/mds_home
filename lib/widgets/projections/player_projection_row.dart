import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds_home/models/projections/player_projection.dart';
import 'package:mds_home/utils/theme_config.dart';

class PlayerProjectionRow extends StatefulWidget {
  final PlayerProjection player;
  final Function(PlayerProjection) onPlayerUpdated;
  final Function(String) onRemovePlayer;

  const PlayerProjectionRow({
    super.key,
    required this.player,
    required this.onPlayerUpdated,
    required this.onRemovePlayer,
  });

  @override
  State<PlayerProjectionRow> createState() => _PlayerProjectionRowState();
}

class _PlayerProjectionRowState extends State<PlayerProjectionRow> {
  late TextEditingController _targetShareController;
  late int _selectedWrRank;
  late int _selectedPassOffenseTier;
  late int _selectedQbTier;
  late int _selectedRunOffenseTier;
  late int _selectedEpaTier;
  late int _selectedPassFreqTier;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _targetShareController = TextEditingController(
      text: (widget.player.targetShare * 100).toStringAsFixed(1),
    );
    _selectedWrRank = widget.player.wrRank;
    _selectedPassOffenseTier = widget.player.passOffenseTier;
    _selectedQbTier = widget.player.qbTier;
    _selectedRunOffenseTier = widget.player.runOffenseTier;
    _selectedEpaTier = widget.player.epaTier;
    _selectedPassFreqTier = widget.player.passFreqTier;
  }

  @override
  void dispose() {
    _targetShareController.dispose();
    super.dispose();
  }

  void _updatePlayer() {
    final targetShareValue = double.tryParse(_targetShareController.text) ?? 0.0;
    final updatedPlayer = widget.player.copyWith(
      wrRank: _selectedWrRank,
      targetShare: targetShareValue / 100, // Convert percentage to decimal
      passOffenseTier: _selectedPassOffenseTier,
      qbTier: _selectedQbTier,
      runOffenseTier: _selectedRunOffenseTier,
      epaTier: _selectedEpaTier,
      passFreqTier: _selectedPassFreqTier,
      lastModified: DateTime.now(),
    );
    
    widget.onPlayerUpdated(updatedPlayer);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _targetShareController.text = (widget.player.targetShare * 100).toStringAsFixed(1);
      _selectedWrRank = widget.player.wrRank;
      _selectedPassOffenseTier = widget.player.passOffenseTier;
      _selectedQbTier = widget.player.qbTier;
      _selectedRunOffenseTier = widget.player.runOffenseTier;
      _selectedEpaTier = widget.player.epaTier;
      _selectedPassFreqTier = widget.player.passFreqTier;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Player name and position
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player.playerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildPositionBadge(widget.player.position),
                    const SizedBox(width: 8),
                    if (widget.player.isManualEntry)
                      _buildManualBadge(),
                  ],
                ),
              ],
            ),
          ),
          
          // WR Rank Dropdown
          Expanded(
            flex: 1,
            child: _buildWrRankDropdown(),
          ),
          
          const SizedBox(width: 16),
          
          // Target Share Input
          Expanded(
            flex: 2,
            child: _buildTargetShareInput(),
          ),
          
          const SizedBox(width: 16),
          
          // Projected Points
          Expanded(
            flex: 1,
            child: Text(
              '${widget.player.projectedPoints.toStringAsFixed(1)} pts',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeConfig.darkNavy,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Actions
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildPositionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ThemeConfig.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeConfig.gold.withOpacity(0.3)),
      ),
      child: Text(
        position,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: ThemeConfig.gold,
        ),
      ),
    );
  }

  Widget _buildManualBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        'MANUAL',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildWrRankDropdown() {
    return DropdownButton<int>(
      value: _selectedWrRank,
      isExpanded: true,
      underline: Container(),
      items: List.generate(8, (index) {
        final rank = index + 1;
        return DropdownMenuItem(
          value: rank,
          child: Text('WR$rank'),
        );
      }),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedWrRank = value;
            _isEditing = true;
          });
        }
      },
    );
  }

  Widget _buildTargetShareInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _targetShareController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _updatePlayer,
            tooltip: 'Save changes',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelEdit,
            tooltip: 'Cancel',
          ),
        ],
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.blue),
          onPressed: () => _showAdvancedSettings(context),
          tooltip: 'Advanced settings',
        ),
        if (widget.player.isManualEntry)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => widget.onRemovePlayer(widget.player.playerId),
            tooltip: 'Remove player',
          ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey),
          onPressed: () => _showPlayerDetails(context),
          tooltip: 'Player details',
        ),
      ],
    );
  }

  void _showAdvancedSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Advanced Settings - ${widget.player.playerName}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTierDropdown('QB Tier', _selectedQbTier, (value) {
                setState(() {
                  _selectedQbTier = value;
                  _isEditing = true;
                });
              }),
              const SizedBox(height: 12),
              _buildTierDropdown('Pass Offense Tier', _selectedPassOffenseTier, (value) {
                setState(() {
                  _selectedPassOffenseTier = value;
                  _isEditing = true;
                });
              }),
              const SizedBox(height: 12),
              _buildTierDropdown('Run Offense Tier', _selectedRunOffenseTier, (value) {
                setState(() {
                  _selectedRunOffenseTier = value;
                  _isEditing = true;
                });
              }),
              const SizedBox(height: 12),
              _buildTierDropdown('EPA Tier', _selectedEpaTier, (value) {
                setState(() {
                  _selectedEpaTier = value;
                  _isEditing = true;
                });
              }),
              const SizedBox(height: 12),
              _buildTierDropdown('Pass Frequency Tier', _selectedPassFreqTier, (value) {
                setState(() {
                  _selectedPassFreqTier = value;
                  _isEditing = true;
                });
              }),
              const SizedBox(height: 16),
              Text(
                'Lower tier numbers = better performance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (_isEditing)
            ElevatedButton(
              onPressed: () {
                _updatePlayer();
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
        ],
      ),
    );
  }

  Widget _buildTierDropdown(String label, int currentValue, Function(int) onChanged) {
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

  void _showPlayerDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.player.playerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Position', widget.player.position),
            _buildDetailRow('Team', widget.player.team),
            _buildDetailRow('WR Rank', 'WR${widget.player.wrRank}'),
            _buildDetailRow('Target Share', '${(widget.player.targetShare * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Projected Yards', widget.player.projectedYards.toStringAsFixed(0)),
            _buildDetailRow('Projected TDs', widget.player.projectedTDs.toStringAsFixed(1)),
            _buildDetailRow('Projected Receptions', widget.player.projectedReceptions.toStringAsFixed(1)),
            _buildDetailRow('Projected Points', widget.player.projectedPoints.toStringAsFixed(1)),
            const SizedBox(height: 16),
            Text(
              'Team Context',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('QB Tier', widget.player.qbTier.toString()),
            _buildDetailRow('Pass Offense Tier', widget.player.passOffenseTier.toString()),
            _buildDetailRow('EPA Tier', widget.player.epaTier.toString()),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
} 