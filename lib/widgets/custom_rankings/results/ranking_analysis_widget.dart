import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';

class RankingAnalysisWidget extends StatelessWidget {
  final RankingAnalysis analysis;
  final List<CustomRankingResult> results;

  const RankingAnalysisWidget({
    super.key,
    required this.analysis,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(context),
          const SizedBox(height: 16),
          _buildDistributionCard(context),
          const SizedBox(height: 16),
          _buildTierAnalysisCard(context),
          const SizedBox(height: 16),
          _buildInsightsCard(context),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: ThemeConfig.darkNavy),
                const SizedBox(width: 8),
                Text(
                  'Ranking Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Players',
                    '${analysis.totalPlayers}',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Score',
                    analysis.averageScore.toStringAsFixed(2),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Score Range',
                    analysis.scoreRange.toStringAsFixed(2),
                    Icons.compare_arrows,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Std Deviation',
                    analysis.standardDeviation.toStringAsFixed(3),
                    Icons.show_chart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: ThemeConfig.darkNavy, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
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

  Widget _buildDistributionCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: ThemeConfig.darkNavy),
                const SizedBox(width: 8),
                Text(
                  'Score Distribution',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDistributionBars(context),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Highest',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      analysis.highestScore.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeConfig.successGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Lowest',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      analysis.lowestScore.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBars(BuildContext context) {
    final scores = results.map((r) => r.totalScore).toList()..sort();
    final buckets = _createScoreBuckets(scores);
    final maxCount = buckets.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: buckets.entries.map((entry) {
        final range = entry.key;
        final count = entry.value;
        final percentage = count / results.length;
        final barWidth = count / maxCount;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  range,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: barWidth,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: ThemeConfig.darkNavy,
                          borderRadius: BorderRadius.circular(10),
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
                  '$count',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, int> _createScoreBuckets(List<double> scores) {
    if (scores.isEmpty) return {};
    
    final min = scores.first;
    final max = scores.last;
    final range = max - min;
    final bucketSize = range / 5; // 5 buckets
    
    final buckets = <String, int>{};
    
    for (int i = 0; i < 5; i++) {
      final bucketMin = min + (i * bucketSize);
      final bucketMax = min + ((i + 1) * bucketSize);
      final bucketKey = '${bucketMin.toStringAsFixed(1)}-${bucketMax.toStringAsFixed(1)}';
      
      final count = scores.where((score) => 
        score >= bucketMin && (i == 4 ? score <= bucketMax : score < bucketMax)
      ).length;
      
      buckets[bucketKey] = count;
    }
    
    return buckets;
  }

  Widget _buildTierAnalysisCard(BuildContext context) {
    final theme = Theme.of(context);
    final tierCounts = _calculateTierCounts();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers, color: ThemeConfig.darkNavy),
                const SizedBox(width: 8),
                Text(
                  'Tier Analysis',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tierCounts.entries.map((entry) {
              final tier = entry.key;
              final count = entry.value;
              final percentage = (count / results.length * 100).round();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getTierColor(tier),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          _getTierEmoji(tier),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$tier Tier',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$count players ($percentage%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateTierCounts() {
    final counts = <String, int>{
      'Elite': 0,
      'High': 0,
      'Mid': 0,
      'Low': 0,
      'Deep': 0,
    };
    
    for (final result in results) {
      final tier = _getPlayerTier(result.rank);
      counts[tier] = (counts[tier] ?? 0) + 1;
    }
    
    return counts;
  }

  String _getPlayerTier(int rank) {
    if (rank <= 5) return 'Elite';
    if (rank <= 12) return 'High';
    if (rank <= 24) return 'Mid';
    if (rank <= 36) return 'Low';
    return 'Deep';
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Elite':
        return ThemeConfig.successGreen;
      case 'High':
        return ThemeConfig.gold;
      case 'Mid':
        return Colors.orange;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.grey.shade300;
    }
  }

  String _getTierEmoji(String tier) {
    switch (tier) {
      case 'Elite':
        return '🏆';
      case 'High':
        return '🥇';
      case 'Mid':
        return '🥈';
      case 'Low':
        return '🥉';
      default:
        return '📊';
    }
  }

  Widget _buildInsightsCard(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _generateInsights();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: ThemeConfig.gold),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right,
                    color: ThemeConfig.darkNavy,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    
    if (analysis.hasGoodSeparation) {
      insights.add('Your weighting system creates good separation between players.');
    } else {
      insights.add('Consider adjusting weights to create more separation between players.');
    }
    
    if (analysis.isWellDistributed) {
      insights.add('Player scores are well distributed across the range.');
    } else {
      insights.add('Player scores are clustered together - consider adding more diverse attributes.');
    }
    
    if (analysis.standardDeviation < 0.05) {
      insights.add('Very low score variation - increase attribute weights for more differentiation.');
    } else if (analysis.standardDeviation > 0.3) {
      insights.add('High score variation - consider balancing your attribute weights.');
    }
    
    final topScoreGap = results.length > 1 
        ? results[0].totalScore - results[1].totalScore
        : 0.0;
    
    if (topScoreGap > analysis.standardDeviation * 2) {
      insights.add('Clear standout player at the top of your rankings.');
    }
    
    return insights.isEmpty 
        ? ['Your ranking methodology appears well balanced.']
        : insights;
  }
}