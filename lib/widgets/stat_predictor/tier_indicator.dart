import 'package:flutter/material.dart';

class TierIndicator extends StatelessWidget {
  final int? tier;
  final String tierType;
  final bool compact;

  const TierIndicator({
    super.key,
    required this.tier,
    required this.tierType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == null) {
      return compact 
          ? const Text('N/A', style: TextStyle(fontSize: 10, color: Colors.grey))
          : const Chip(
              label: Text('N/A', style: TextStyle(fontSize: 10)),
              backgroundColor: Colors.grey,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
    }

    final tierData = _getTierData(tier!);
    
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: tierData.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tierData.shortLabel,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Tooltip(
      message: '${_getTierTypeDisplay(tierType)}: ${tierData.fullLabel}',
      child: Chip(
        label: Text(
          tierData.shortLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: tierData.color,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  _TierData _getTierData(int tier) {
    switch (tier) {
      case 1:
        return _TierData(
          shortLabel: 'T1',
          fullLabel: 'Elite (Tier 1)',
          color: Colors.green,
        );
      case 2:
        return _TierData(
          shortLabel: 'T2',
          fullLabel: 'Good (Tier 2)',
          color: Colors.lightGreen,
        );
      case 3:
        return _TierData(
          shortLabel: 'T3',
          fullLabel: 'Average (Tier 3)',
          color: Colors.orange,
        );
      case 4:
        return _TierData(
          shortLabel: 'T4',
          fullLabel: 'Below Average (Tier 4)',
          color: Colors.deepOrange,
        );
      case 5:
        return _TierData(
          shortLabel: 'T5',
          fullLabel: 'Poor (Tier 5)',
          color: Colors.red,
        );
      default:
        return _TierData(
          shortLabel: 'T?',
          fullLabel: 'Unranked',
          color: Colors.grey,
        );
    }
  }

  String _getTierTypeDisplay(String tierType) {
    switch (tierType) {
      case 'passOffense':
        return 'Pass Offense';
      case 'qb':
        return 'QB Quality';
      case 'passFreq':
        return 'Pass Frequency';
      case 'epa':
        return 'EPA';
      default:
        return tierType;
    }
  }
}

class _TierData {
  final String shortLabel;
  final String fullLabel;
  final Color color;

  _TierData({
    required this.shortLabel,
    required this.fullLabel,
    required this.color,
  });
}

class TierLegend extends StatelessWidget {
  const TierLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tier Legend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLegendItem(1, 'Elite'),
                _buildLegendItem(2, 'Good'),
                _buildLegendItem(3, 'Average'),
                _buildLegendItem(4, 'Below Avg'),
                _buildLegendItem(5, 'Poor'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(int tier, String label) {
    final tierIndicator = TierIndicator(tier: tier, tierType: '', compact: true);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tierIndicator,
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class MultiTierDisplay extends StatelessWidget {
  final int? passOffenseTier;
  final int? qbTier;
  final int? passFreqTier;
  final int? epaTier;
  final bool vertical;

  const MultiTierDisplay({
    super.key,
    this.passOffenseTier,
    this.qbTier,
    this.passFreqTier,
    this.epaTier,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    
    if (passOffenseTier != null) {
      widgets.add(
        Tooltip(
          message: 'Pass Offense Tier',
          child: TierIndicator(
            tier: passOffenseTier,
            tierType: 'passOffense',
            compact: true,
          ),
        ),
      );
    }
    
    if (qbTier != null) {
      widgets.add(
        Tooltip(
          message: 'QB Tier',
          child: TierIndicator(
            tier: qbTier,
            tierType: 'qb',
            compact: true,
          ),
        ),
      );
    }
    
    if (passFreqTier != null) {
      widgets.add(
        Tooltip(
          message: 'Pass Frequency Tier',
          child: TierIndicator(
            tier: passFreqTier,
            tierType: 'passFreq',
            compact: true,
          ),
        ),
      );
    }
    
    if (epaTier != null) {
      widgets.add(
        Tooltip(
          message: 'EPA Tier',
          child: TierIndicator(
            tier: epaTier,
            tierType: 'epa',
            compact: true,
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return const Text('N/A', style: TextStyle(fontSize: 10, color: Colors.grey));
    }

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets
            .map((w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: w,
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: widgets,
    );
  }
}