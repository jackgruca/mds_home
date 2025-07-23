import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';

class PreviewStep extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> attributes;
  final Map<String, double> weights;
  final String rankingName;
  final Function(String) onNameChanged;
  final VoidCallback onCreateRankings;

  const PreviewStep({
    super.key,
    required this.position,
    required this.attributes,
    required this.weights,
    required this.rankingName,
    required this.onNameChanged,
    required this.onCreateRankings,
  });

  @override
  State<PreviewStep> createState() => _PreviewStepState();
}

class _PreviewStepState extends State<PreviewStep> {
  bool _includeNextYearPredictions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview & Confirm',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your custom ranking setup and give it a name. You can make adjustments after creating the rankings.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildNameInput(context),
          const SizedBox(height: 24),
          if (widget.position == 'WR' || widget.position == 'TE')
            _buildNextYearPredictionsSection(context),
          const SizedBox(height: 24),
          _buildSummaryCard(context),
          const SizedBox(height: 24),
          _buildAttributesPreview(context),
          const SizedBox(height: 24),
          _buildSampleRankings(context),
        ],
      ),
    );
  }

  Widget _buildNextYearPredictionsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.blue.shade900.withOpacity(0.2) 
          : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.blue.shade700.withOpacity(0.5) 
          : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.blue.shade300 
                : Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Next Year Predictions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.shade300 
                    : Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Include AI-generated next year stat predictions in your rankings. These predictions consider team context, target share projections, and historical performance patterns.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.blue.shade300 
                : Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _includeNextYearPredictions,
                onChanged: (value) {
                  setState(() {
                    _includeNextYearPredictions = value ?? false;
                  });
                },
                activeColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blue.shade300 
                  : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Include next year predictions as ranking factors',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.blue.shade300 
                      : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_includeNextYearPredictions) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blue.shade700.withOpacity(0.3) 
                  : Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediction Data Included:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.blue.shade200 
                        : Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Next year target share projections\n'
                    '• Projected fantasy points\n'
                    '• Expected receiving yards and TDs\n'
                    '• Team context and tier adjustments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.blue.shade300 
                        : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/projections/stat-predictor');
                    },
                    child: Text(
                      'Customize predictions in Stat Predictor →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.blue.shade400 
                          : Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNameInput(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ranking System Name',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: widget.onNameChanged,
          decoration: InputDecoration(
            hintText: 'e.g., "Volume-Heavy ${widget.position} Rankings" or "My Custom ${widget.position}s"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ThemeConfig.darkNavy, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final totalWeight = widget.weights.values.fold(0.0, (sum, weight) => sum + weight);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.darkNavy.withValues(alpha: 0.1),
            ThemeConfig.gold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeConfig.darkNavy.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_football,
                color: ThemeConfig.darkNavy,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Ranking Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(context, 'Position', widget.position),
          _buildSummaryRow(context, 'Attributes', '${widget.attributes.length} selected'),
          _buildSummaryRow(context, 'Total Weight', '${(totalWeight * 100).toStringAsFixed(0)}%'),
          _buildSummaryRow(context, 'Focus Area', _getPrimaryFocus()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesPreview(BuildContext context) {
    final theme = Theme.of(context);
    final sortedAttributes = widget.attributes.toList()
      ..sort((a, b) => (widget.weights[b.id] ?? 0.0).compareTo(widget.weights[a.id] ?? 0.0));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attribute Weights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedAttributes.map((attr) => _buildAttributePreviewRow(context, attr)),
      ],
    );
  }

  Widget _buildAttributePreviewRow(BuildContext context, EnhancedRankingAttribute attribute) {
    final theme = Theme.of(context);
    final weight = widget.weights[attribute.id] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            attribute.categoryEmoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attribute.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  attribute.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: weight,
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeConfig.darkNavy,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(
              '${(weight * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleRankings(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sample Results Preview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s how your rankings will look once calculated with real player data:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildSampleRankingRow(context, 1, 'Player Name', 'Team', '95.2'),
              _buildSampleRankingRow(context, 2, 'Player Name', 'Team', '89.7'),
              _buildSampleRankingRow(context, 3, 'Player Name', 'Team', '84.1'),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '... and more players',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSampleRankingRow(BuildContext context, int rank, String name, String team, String score) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ThemeConfig.darkNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            team,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            score,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  String _getPrimaryFocus() {
    final categoryWeights = <String, double>{};
    
    for (final attr in widget.attributes) {
      final weight = widget.weights[attr.id] ?? 0.0;
      categoryWeights[attr.category] = (categoryWeights[attr.category] ?? 0.0) + weight;
    }
    
    if (categoryWeights.isEmpty) return 'None';
    
    final primaryCategory = categoryWeights.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return primaryCategory;
  }
}