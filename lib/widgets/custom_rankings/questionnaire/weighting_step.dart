import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';

class WeightingStep extends StatelessWidget {
  final List<EnhancedRankingAttribute> attributes;
  final Map<String, double> weights;
  final Function(Map<String, double>) onWeightsChanged;

  const WeightingStep({
    super.key,
    required this.attributes,
    required this.weights,
    required this.onWeightsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Attribute Weights',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign importance weights to each attribute. Higher weights mean the attribute has more impact on the final rankings.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildWeightsSummary(context),
          const SizedBox(height: 24),
          _buildQuickSetButtons(context),
          const SizedBox(height: 24),
          ...attributes.map((attr) => _buildWeightSlider(context, attr)),
        ],
      ),
    );
  }

  Widget _buildWeightsSummary(BuildContext context) {
    final theme = Theme.of(context);
    final totalWeight = weights.values.fold(0.0, (sum, weight) => sum + weight);
    final isBalanced = totalWeight > 0.8 && totalWeight < 1.2;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBalanced 
          ? ThemeConfig.successGreen.withValues(alpha: 0.1)
          : ThemeConfig.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBalanced 
            ? ThemeConfig.successGreen.withValues(alpha: 0.3)
            : ThemeConfig.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle : Icons.info_outline,
            color: isBalanced ? ThemeConfig.successGreen : ThemeConfig.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Weight: ${(totalWeight * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isBalanced ? ThemeConfig.successGreen : ThemeConfig.gold,
                  ),
                ),
                Text(
                  isBalanced 
                    ? 'Weights are well balanced'
                    : 'Consider adjusting weights for better balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Set:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickSetButton(context, 'Equal', _setEqualWeights),
            _buildQuickSetButton(context, 'Volume Focus', _setVolumeFocus),
            _buildQuickSetButton(context, 'Efficiency Focus', _setEfficiencyFocus),
            _buildQuickSetButton(context, 'Clear All', _clearWeights),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSetButton(BuildContext context, String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ThemeConfig.darkNavy,
        side: const BorderSide(color: ThemeConfig.darkNavy),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildWeightSlider(BuildContext context, EnhancedRankingAttribute attribute) {
    final theme = Theme.of(context);
    final weight = weights[attribute.id] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attribute.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      attribute.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeConfig.darkNavy,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(weight * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ThemeConfig.darkNavy,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: ThemeConfig.darkNavy,
              overlayColor: ThemeConfig.darkNavy.withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: weight,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                final newWeights = Map<String, double>.from(weights);
                newWeights[attribute.id] = value;
                onWeightsChanged(newWeights);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Not Important',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Very Important',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setEqualWeights() {
    final equalWeight = 1.0 / attributes.length;
    final newWeights = <String, double>{};
    for (final attr in attributes) {
      newWeights[attr.id] = equalWeight;
    }
    onWeightsChanged(newWeights);
  }

  void _setVolumeFocus() {
    final newWeights = Map<String, double>.from(weights);
    for (final attr in attributes) {
      if (attr.category.toLowerCase() == 'volume') {
        newWeights[attr.id] = 0.4;
      } else if (attr.category.toLowerCase() == 'previous performance') {
        newWeights[attr.id] = 0.3;
      } else {
        newWeights[attr.id] = 0.2;
      }
    }
    onWeightsChanged(newWeights);
  }

  void _setEfficiencyFocus() {
    final newWeights = Map<String, double>.from(weights);
    for (final attr in attributes) {
      if (attr.category.toLowerCase() == 'efficiency') {
        newWeights[attr.id] = 0.4;
      } else if (attr.category.toLowerCase() == 'previous performance') {
        newWeights[attr.id] = 0.3;
      } else {
        newWeights[attr.id] = 0.2;
      }
    }
    onWeightsChanged(newWeights);
  }

  void _clearWeights() {
    final newWeights = <String, double>{};
    for (final attr in attributes) {
      newWeights[attr.id] = 0.0;
    }
    onWeightsChanged(newWeights);
  }
}