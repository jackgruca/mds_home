import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds_home/services/projections/player_projections_service.dart';
import 'package:mds_home/widgets/design_system/mds_button.dart';

class AddPlayerDialog extends StatefulWidget {
  final String teamCode;

  const AddPlayerDialog({
    super.key,
    required this.teamCode,
  });

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _playerNameController = TextEditingController();
  final _targetShareController = TextEditingController(text: '15.0');
  
  String _selectedPosition = 'WR';
  int _selectedWrRank = 1;
  int _selectedPlayerYear = 2;
  int _selectedPassOffenseTier = 4;
  int _selectedQbTier = 4;
  int _selectedRunOffenseTier = 4;
  int _selectedEpaTier = 4;
  int _selectedPassFreqTier = 4;

  final PlayerProjectionsService _projectionsService = PlayerProjectionsService();

  @override
  void dispose() {
    _playerNameController.dispose();
    _targetShareController.dispose();
    super.dispose();
  }

  void _createPlayer() {
    if (_formKey.currentState!.validate()) {
      final targetShare = double.tryParse(_targetShareController.text) ?? 15.0;
      
      final player = _projectionsService.createManualPlayer(
        playerName: _playerNameController.text.trim(),
        team: widget.teamCode,
        position: _selectedPosition,
        wrRank: _selectedWrRank,
        targetShare: targetShare / 100, // Convert percentage to decimal
        playerYear: _selectedPlayerYear,
        passOffenseTier: _selectedPassOffenseTier,
        qbTier: _selectedQbTier,
        runOffenseTier: _selectedRunOffenseTier,
        epaTier: _selectedEpaTier,
        passFreqTier: _selectedPassFreqTier,
      );

      Navigator.of(context).pop(player);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Player to ${widget.teamCode}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlayerNameField(),
                const SizedBox(height: 16),
                _buildPositionDropdown(),
                const SizedBox(height: 16),
                _buildWrRankDropdown(),
                const SizedBox(height: 16),
                _buildTargetShareField(),
                const SizedBox(height: 24),
                _buildAdvancedSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        MdsButton(
          text: 'Add Player',
          onPressed: _createPlayer,
          type: MdsButtonType.primary,
        ),
      ],
    );
  }

  Widget _buildPlayerNameField() {
    return TextFormField(
      controller: _playerNameController,
      decoration: const InputDecoration(
        labelText: 'Player Name',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a player name';
        }
        return null;
      },
    );
  }

  Widget _buildPositionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPosition,
      decoration: const InputDecoration(
        labelText: 'Position',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'WR', child: Text('WR')),
        DropdownMenuItem(value: 'TE', child: Text('TE')),
        DropdownMenuItem(value: 'RB', child: Text('RB')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPosition = value;
          });
        }
      },
    );
  }

  Widget _buildWrRankDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedWrRank,
      decoration: const InputDecoration(
        labelText: 'WR Rank',
        border: OutlineInputBorder(),
      ),
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
          });
        }
      },
    );
  }

  Widget _buildTargetShareField() {
    return TextFormField(
      controller: _targetShareController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Target Share (%)',
        border: OutlineInputBorder(),
        suffixText: '%',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a target share';
        }
        final targetShare = double.tryParse(value);
        if (targetShare == null || targetShare < 0 || targetShare > 50) {
          return 'Target share must be between 0 and 50%';
        }
        return null;
      },
    );
  }

  Widget _buildAdvancedSection() {
    return ExpansionTile(
      title: const Text('Advanced Settings'),
      children: [
        const SizedBox(height: 8),
        _buildTierDropdown(
          'Player Year',
          _selectedPlayerYear,
          List.generate(10, (index) => index + 1),
          (value) => setState(() => _selectedPlayerYear = value),
        ),
        const SizedBox(height: 16),
        _buildTierDropdown(
          'Pass Offense Tier',
          _selectedPassOffenseTier,
          List.generate(8, (index) => index + 1),
          (value) => setState(() => _selectedPassOffenseTier = value),
        ),
        const SizedBox(height: 16),
        _buildTierDropdown(
          'QB Tier',
          _selectedQbTier,
          List.generate(8, (index) => index + 1),
          (value) => setState(() => _selectedQbTier = value),
        ),
        const SizedBox(height: 16),
        _buildTierDropdown(
          'Run Offense Tier',
          _selectedRunOffenseTier,
          List.generate(8, (index) => index + 1),
          (value) => setState(() => _selectedRunOffenseTier = value),
        ),
        const SizedBox(height: 16),
        _buildTierDropdown(
          'EPA Tier',
          _selectedEpaTier,
          List.generate(8, (index) => index + 1),
          (value) => setState(() => _selectedEpaTier = value),
        ),
        const SizedBox(height: 16),
        _buildTierDropdown(
          'Pass Frequency Tier',
          _selectedPassFreqTier,
          List.generate(8, (index) => index + 1),
          (value) => setState(() => _selectedPassFreqTier = value),
        ),
      ],
    );
  }

  Widget _buildTierDropdown(
    String label,
    int value,
    List<int> options,
    Function(int) onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text('Tier $option'),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
} 