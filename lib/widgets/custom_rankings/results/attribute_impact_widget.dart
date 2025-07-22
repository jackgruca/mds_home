import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';

class AttributeImpactWidget extends StatelessWidget {
  final List<AttributeImpact> impacts;
  final Function(EnhancedRankingAttribute) onAttributeAdjust;

  const AttributeImpactWidget({
    super.key,
    required this.impacts,
    required this.onAttributeAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildSummaryCard(context),
          const SizedBox(height: 16),
          _buildAttributeList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        const Icon(Icons.tune, color: ThemeConfig.darkNavy),
        const SizedBox(width: 8),
        Text(
          'Attribute Impact Analysis',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final totalWeight = impacts.fold(0.0, (sum, impact) => sum + impact.weight);
    final effectiveWeight = impacts.fold(0.0, (sum, impact) => sum + impact.effectiveWeight);
    final highImpactCount = impacts.where((i) => i.impactLevel == 'High').length;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Total Weight Assigned',
                    '${(totalWeight * 100).toStringAsFixed(0)}%',
                    Icons.scale,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Actual Ranking Impact',
                    '${(effectiveWeight * 100).toStringAsFixed(0)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'High Impact',
                    '$highImpactCount/${impacts.length}',
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Efficiency',
                    '${_calculateOverallEfficiency().toStringAsFixed(2)}',
                    Icons.speed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: ThemeConfig.darkNavy, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateOverallEfficiency() {
    if (impacts.isEmpty) return 0.0;
    return impacts.fold(0.0, (sum, impact) => sum + impact.efficiency) / impacts.length;
  }

  Widget _buildAttributeList(BuildContext context) {
    return Column(
      children: impacts.map((impact) => _buildAttributeCard(context, impact)).toList(),
    );
  }

  Widget _buildAttributeCard(BuildContext context, AttributeImpact impact) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            impact.attribute.categoryEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              impact.attribute.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildImpactBadge(context, impact),
                        ],
                      ),
                      Text(
                        impact.attribute.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => onAttributeAdjust(impact.attribute),
                  color: ThemeConfig.darkNavy,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricsRow(context, impact),
            const SizedBox(height: 12),
            _buildImpactBars(context, impact),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactBadge(BuildContext context, AttributeImpact impact) {
    final color = _getImpactColor(impact.impactLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        impact.impactLevel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, AttributeImpact impact) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem(
            context,
            'Weight',
            '${(impact.weight * 100).toStringAsFixed(0)}%',
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            context,
            'Correlation',
            impact.correlation.toStringAsFixed(3),
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            context,
            'Efficiency',
            impact.efficiency.toStringAsFixed(2),
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            context,
            'Avg Contribution',
            impact.averageContribution.toStringAsFixed(3),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeConfig.darkNavy,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImpactBars(BuildContext context, AttributeImpact impact) {
    final maxEffectiveWeight = impacts.isNotEmpty 
        ? impacts.map((i) => i.effectiveWeight).reduce((a, b) => a > b ? a : b)
        : 1.0;
    
    return Column(
      children: [
        _buildBar(
          context,
          'Assigned Weight',
          impact.weight,
          1.0,
          ThemeConfig.darkNavy.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 4),
        _buildBar(
          context,
          'Effective Impact',
          impact.effectiveWeight,
          maxEffectiveWeight,
          ThemeConfig.darkNavy,
        ),
      ],
    );
  }

  Widget _buildBar(BuildContext context, String label, double value, double maxValue, Color color) {
    final theme = Theme.of(context);
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getImpactColor(String impactLevel) {
    switch (impactLevel) {
      case 'High':
        return ThemeConfig.successGreen;
      case 'Medium':
        return ThemeConfig.gold;
      case 'Low':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}