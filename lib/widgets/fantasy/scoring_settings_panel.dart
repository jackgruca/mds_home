import 'package:flutter/material.dart';
import '../../models/fantasy/scoring_settings.dart';

class ScoringSettingsPanel extends StatefulWidget {
  final ScoringSettings currentSettings;
  final Function(ScoringSettings) onSettingsChanged;
  final VoidCallback? onClose;

  const ScoringSettingsPanel({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
    this.onClose,
  });

  @override
  State<ScoringSettingsPanel> createState() => _ScoringSettingsPanelState();
}

class _ScoringSettingsPanelState extends State<ScoringSettingsPanel> {
  late ScoringSettings _settings;
  bool _showAdvancedSettings = false;
  int _selectedPresetIndex = -1;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
    _findMatchingPreset();
  }

  void _findMatchingPreset() {
    for (int i = 0; i < ScoringPresets.all.length; i++) {
      final preset = ScoringPresets.all[i];
      if (_settingsMatchPreset(preset.settings)) {
        setState(() => _selectedPresetIndex = i);
        return;
      }
    }
    setState(() => _selectedPresetIndex = -1);
  }

  bool _settingsMatchPreset(ScoringSettings preset) {
    return _settings.scoringType == preset.scoringType &&
        _settings.receptionPoints == preset.receptionPoints &&
        _settings.passingTDPoints == preset.passingTDPoints &&
        _settings.tePremiumBonus == preset.tePremiumBonus;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;
    
    return Container(
      width: panelWidth,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPresetSelector(context),
                  const SizedBox(height: 24),
                  _buildCommonSettings(context),
                  const SizedBox(height: 16),
                  _buildAdvancedToggle(context),
                  if (_showAdvancedSettings) ...[
                    const SizedBox(height: 16),
                    _buildAdvancedSettings(context),
                  ],
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'League Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'League Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...ScoringPresets.all.asMap().entries.map((entry) {
          final index = entry.key;
          final preset = entry.value;
          final isSelected = index == _selectedPresetIndex;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 4 : 1,
            child: InkWell(
              onTap: () {
                setState(() {
                  _settings = preset.settings;
                  _selectedPresetIndex = index;
                  _showAdvancedSettings = false;
                });
                widget.onSettingsChanged(_settings);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(preset.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            preset.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (preset.features.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: preset.features.map((feature) {
                                return Chip(
                                  label: Text(
                                    feature,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCommonSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scoring Adjustments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildReceptionPointsSlider(context),
        const SizedBox(height: 16),
        _buildPassingTDSlider(context),
        const SizedBox(height: 16),
        _buildTEPremiumSlider(context),
      ],
    );
  }

  Widget _buildReceptionPointsSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reception Points',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _settings.receptionPoints.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('No Points', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: _settings.receptionPoints,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _settings = ScoringSettings(
                      scoringType: ScoringType.custom,
                      receptionPoints: value,
                      passingTDPoints: _settings.passingTDPoints,
                      tePremiumBonus: _settings.tePremiumBonus,
                      passingYardsPerPoint: _settings.passingYardsPerPoint,
                      interceptionPoints: _settings.interceptionPoints,
                      rushingYardsPerPoint: _settings.rushingYardsPerPoint,
                      rushingTDPoints: _settings.rushingTDPoints,
                      receivingYardsPerPoint: _settings.receivingYardsPerPoint,
                      receivingTDPoints: _settings.receivingTDPoints,
                      passing300YardBonus: _settings.passing300YardBonus,
                      passing300YardBonusPoints: _settings.passing300YardBonusPoints,
                      rushing100YardBonus: _settings.rushing100YardBonus,
                      rushing100YardBonusPoints: _settings.rushing100YardBonusPoints,
                      receiving100YardBonus: _settings.receiving100YardBonus,
                      receiving100YardBonusPoints: _settings.receiving100YardBonusPoints,
                      fumbleLostPoints: _settings.fumbleLostPoints,
                      twoPointConversionPoints: _settings.twoPointConversionPoints,
                      customName: _settings.customName,
                    );
                    _selectedPresetIndex = -1;
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
            ),
            const Text('Full Point (1.0)', style: TextStyle(fontSize: 12)),
          ],
        ),
        Center(
          child: Text(
            '↑ Half-PPR (0.5)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassingTDSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Passing TDs',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_settings.passingTDPoints.toStringAsFixed(0)} pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Standard (4)', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: _settings.passingTDPoints,
                min: 4,
                max: 6,
                divisions: 2,
                onChanged: (value) {
                  setState(() {
                    _settings = ScoringSettings(
                      scoringType: ScoringType.custom,
                      receptionPoints: _settings.receptionPoints,
                      passingTDPoints: value,
                      tePremiumBonus: _settings.tePremiumBonus,
                      passingYardsPerPoint: _settings.passingYardsPerPoint,
                      interceptionPoints: _settings.interceptionPoints,
                      rushingYardsPerPoint: _settings.rushingYardsPerPoint,
                      rushingTDPoints: _settings.rushingTDPoints,
                      receivingYardsPerPoint: _settings.receivingYardsPerPoint,
                      receivingTDPoints: _settings.receivingTDPoints,
                      passing300YardBonus: _settings.passing300YardBonus,
                      passing300YardBonusPoints: _settings.passing300YardBonusPoints,
                      rushing100YardBonus: _settings.rushing100YardBonus,
                      rushing100YardBonusPoints: _settings.rushing100YardBonusPoints,
                      receiving100YardBonus: _settings.receiving100YardBonus,
                      receiving100YardBonusPoints: _settings.receiving100YardBonusPoints,
                      fumbleLostPoints: _settings.fumbleLostPoints,
                      twoPointConversionPoints: _settings.twoPointConversionPoints,
                      customName: _settings.customName,
                    );
                    _selectedPresetIndex = -1;
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
            ),
            const Text('High-Value (6)', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildTEPremiumSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TE Premium',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+${_settings.tePremiumBonus.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _settings.tePremiumBonus,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (value) {
            setState(() {
              _settings = ScoringSettings(
                scoringType: ScoringType.custom,
                receptionPoints: _settings.receptionPoints,
                passingTDPoints: _settings.passingTDPoints,
                tePremiumBonus: value,
                passingYardsPerPoint: _settings.passingYardsPerPoint,
                interceptionPoints: _settings.interceptionPoints,
                rushingYardsPerPoint: _settings.rushingYardsPerPoint,
                rushingTDPoints: _settings.rushingTDPoints,
                receivingYardsPerPoint: _settings.receivingYardsPerPoint,
                receivingTDPoints: _settings.receivingTDPoints,
                passing300YardBonus: _settings.passing300YardBonus,
                passing300YardBonusPoints: _settings.passing300YardBonusPoints,
                rushing100YardBonus: _settings.rushing100YardBonus,
                rushing100YardBonusPoints: _settings.rushing100YardBonusPoints,
                receiving100YardBonus: _settings.receiving100YardBonus,
                receiving100YardBonusPoints: _settings.receiving100YardBonusPoints,
                fumbleLostPoints: _settings.fumbleLostPoints,
                twoPointConversionPoints: _settings.twoPointConversionPoints,
                customName: _settings.customName,
              );
              _selectedPresetIndex = -1;
            });
            widget.onSettingsChanged(_settings);
          },
        ),
        Text(
          'Additional points per TE reception',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAdvancedToggle(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _showAdvancedSettings = !_showAdvancedSettings),
      child: Row(
        children: [
          Icon(
            _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Advanced Settings',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Scoring Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildBonusSettings(context),
      ],
    );
  }

  Widget _buildBonusSettings(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('300+ Yard Passing Bonus'),
          subtitle: Text('${_settings.passing300YardBonusPoints.toStringAsFixed(0)} points'),
          value: _settings.passing300YardBonus,
          onChanged: (value) {
            setState(() {
              _settings = ScoringSettings(
                scoringType: ScoringType.custom,
                receptionPoints: _settings.receptionPoints,
                passingTDPoints: _settings.passingTDPoints,
                tePremiumBonus: _settings.tePremiumBonus,
                passingYardsPerPoint: _settings.passingYardsPerPoint,
                interceptionPoints: _settings.interceptionPoints,
                rushingYardsPerPoint: _settings.rushingYardsPerPoint,
                rushingTDPoints: _settings.rushingTDPoints,
                receivingYardsPerPoint: _settings.receivingYardsPerPoint,
                receivingTDPoints: _settings.receivingTDPoints,
                passing300YardBonus: value,
                passing300YardBonusPoints: _settings.passing300YardBonusPoints,
                rushing100YardBonus: _settings.rushing100YardBonus,
                rushing100YardBonusPoints: _settings.rushing100YardBonusPoints,
                receiving100YardBonus: _settings.receiving100YardBonus,
                receiving100YardBonusPoints: _settings.receiving100YardBonusPoints,
                fumbleLostPoints: _settings.fumbleLostPoints,
                twoPointConversionPoints: _settings.twoPointConversionPoints,
                customName: _settings.customName,
              );
              _selectedPresetIndex = -1;
            });
            widget.onSettingsChanged(_settings);
          },
        ),
        SwitchListTile(
          title: const Text('100+ Yard Rushing Bonus'),
          subtitle: Text('${_settings.rushing100YardBonusPoints.toStringAsFixed(0)} points'),
          value: _settings.rushing100YardBonus,
          onChanged: (value) {
            setState(() {
              _settings = ScoringSettings(
                scoringType: ScoringType.custom,
                receptionPoints: _settings.receptionPoints,
                passingTDPoints: _settings.passingTDPoints,
                tePremiumBonus: _settings.tePremiumBonus,
                passingYardsPerPoint: _settings.passingYardsPerPoint,
                interceptionPoints: _settings.interceptionPoints,
                rushingYardsPerPoint: _settings.rushingYardsPerPoint,
                rushingTDPoints: _settings.rushingTDPoints,
                receivingYardsPerPoint: _settings.receivingYardsPerPoint,
                receivingTDPoints: _settings.receivingTDPoints,
                passing300YardBonus: _settings.passing300YardBonus,
                passing300YardBonusPoints: _settings.passing300YardBonusPoints,
                rushing100YardBonus: value,
                rushing100YardBonusPoints: _settings.rushing100YardBonusPoints,
                receiving100YardBonus: _settings.receiving100YardBonus,
                receiving100YardBonusPoints: _settings.receiving100YardBonusPoints,
                fumbleLostPoints: _settings.fumbleLostPoints,
                twoPointConversionPoints: _settings.twoPointConversionPoints,
                customName: _settings.customName,
              );
              _selectedPresetIndex = -1;
            });
            widget.onSettingsChanged(_settings);
          },
        ),
        SwitchListTile(
          title: const Text('100+ Yard Receiving Bonus'),
          subtitle: Text('${_settings.receiving100YardBonusPoints.toStringAsFixed(0)} points'),
          value: _settings.receiving100YardBonus,
          onChanged: (value) {
            setState(() {
              _settings = ScoringSettings(
                scoringType: ScoringType.custom,
                receptionPoints: _settings.receptionPoints,
                passingTDPoints: _settings.passingTDPoints,
                tePremiumBonus: _settings.tePremiumBonus,
                passingYardsPerPoint: _settings.passingYardsPerPoint,
                interceptionPoints: _settings.interceptionPoints,
                rushingYardsPerPoint: _settings.rushingYardsPerPoint,
                rushingTDPoints: _settings.rushingTDPoints,
                receivingYardsPerPoint: _settings.receivingYardsPerPoint,
                receivingTDPoints: _settings.receivingTDPoints,
                passing300YardBonus: _settings.passing300YardBonus,
                passing300YardBonusPoints: _settings.passing300YardBonusPoints,
                rushing100YardBonus: _settings.rushing100YardBonus,
                rushing100YardBonusPoints: _settings.rushing100YardBonusPoints,
                receiving100YardBonus: value,
                receiving100YardBonusPoints: _settings.receiving100YardBonusPoints,
                fumbleLostPoints: _settings.fumbleLostPoints,
                twoPointConversionPoints: _settings.twoPointConversionPoints,
                customName: _settings.customName,
              );
              _selectedPresetIndex = -1;
            });
            widget.onSettingsChanged(_settings);
          },
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_settings.isCustom) ...[
            Text(
              'Custom Scoring Active',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
          TextButton(
            onPressed: () {
              setState(() {
                _settings = ScoringSettings.ppr;
                _selectedPresetIndex = 2; // PPR index
              });
              widget.onSettingsChanged(_settings);
            },
            child: const Text('Reset to PPR'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: widget.onClose,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}